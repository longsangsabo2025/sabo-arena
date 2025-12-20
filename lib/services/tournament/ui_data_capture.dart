import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Ultra-simple service: Just get what UI is showing
/// NO re-calculation, NO duplicate logic
class UIDataCapture {
  /// Capture EXACTLY what UI is showing using same live calculation
  /// This is the SIMPLEST approach: UI calculates once, we capture it
  /// 🔧 ENHANCED: Guarantees ALL tournament participants are included
  static Future<List<Map<String, dynamic>>> captureUIRankings(
      String tournamentId) async {
    try {
      ProductionLogger.info(
          '📸 [UI CAPTURE] Capturing exact UI ranking data for $tournamentId',
          tag: 'ui_data_capture');

      // 🎯 ROBUST: Get ALL tournament participants directly (bypass filtering)
      // This ensures we include even orphaned participants for complete results
      final participantsResponse = await Supabase.instance.client
          .from('tournament_participants')
          .select('''
            user_id,
            status,
            registered_at,
            users (
              id,
              display_name,
              full_name,
              email
            )
          ''')
          .eq('tournament_id', tournamentId)
          .order('registered_at');

      ProductionLogger.info(
          '🔍 [UI CAPTURE] Got ${participantsResponse.length} participants from tournament_participants',
          tag: 'ui_data_capture');

      // ═══════════════════════════════════════════════════════════════
      // 🆕 NEW: Get tournament info for prize calculation
      // ═══════════════════════════════════════════════════════════════
      final tournamentResponse = await Supabase.instance.client
          .from('tournaments')
          .select('prize_pool, prize_distribution, custom_distribution')
          .eq('id', tournamentId)
          .single();

      final prizePool =
          (tournamentResponse['prize_pool'] as num?)?.toDouble() ?? 0.0;

      // Handle prize_distribution - can be either String or Map
      String prizeDistribution = 'standard';
      List<Map<String, dynamic>>? customDistribution;
      final prizeDistData = tournamentResponse['prize_distribution'];

      if (prizeDistData is String) {
        prizeDistribution = prizeDistData;
      } else if (prizeDistData is Map) {
        prizeDistribution = prizeDistData['template']?.toString() ?? 'standard';
        if (prizeDistribution == 'custom' &&
            prizeDistData['distribution'] != null) {
          customDistribution = (prizeDistData['distribution'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      // Fallback: Check custom_distribution column
      if (customDistribution == null &&
          tournamentResponse['custom_distribution'] != null) {
        try {
          customDistribution =
              (tournamentResponse['custom_distribution'] as List)
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
        } catch (e) {
          ProductionLogger.info(
              '⚠️ [UI CAPTURE] Error parsing custom_distribution column: $e',
              tag: 'ui_data_capture');
        }
      }

      // 🛡️ FALLBACK: Create participant objects with graceful handling
      final participants = participantsResponse.map((participantData) {
        final userData = participantData['users'] as Map<String, dynamic>?;
        final userId = participantData['user_id'] as String;

        if (userData != null) {
          // ✅ Valid user data available
          return {
            'id': userData['id'] as String,
            'displayName': userData['display_name'] as String? ??
                userData['full_name'] as String? ??
                'User',
            'isOrphaned': false,
          };
        } else {
          // ⚠️ Orphaned participant - create placeholder
          ProductionLogger.info(
              '⚠️ [UI CAPTURE] Orphaned participant: $userId (creating placeholder)',
              tag: 'ui_data_capture');
          return {
            'id': userId,
            'displayName':
                'Player_${userId.substring(0, 8)}', // Use first 8 chars of ID
            'isOrphaned': true,
          };
        }
      }).toList();

      ProductionLogger.info(
          '📊 [UI CAPTURE] Processing ${participants.length} participants (including ${participants.where((p) => p['isOrphaned'] == true).length} orphaned)',
          tag: 'ui_data_capture');

      // Get matches to calculate stats
      final matchesResponse = await Supabase.instance.client
          .from('matches')
          .select('player1_id, player2_id, winner_id, status')
          .eq('tournament_id', tournamentId);

      final matches = matchesResponse as List<dynamic>;
      ProductionLogger.info('🎯 [UI CAPTURE] Got ${matches.length} matches',
          tag: 'ui_data_capture');

      // Calculate stats for each participant (EXACT UI logic + orphan handling)
      final rankings = participants.map((participant) {
        int wins = 0;
        int losses = 0;
        int totalGames = 0;

        for (final match in matches) {
          final player1Id = match['player1_id'] as String?;
          final player2Id = match['player2_id'] as String?;
          final winnerId = match['winner_id'] as String?;
          final status = match['status'] as String?;

          if (status != 'completed' || winnerId == null) continue;

          final participantId = participant['id'] as String;
          if (participantId == player1Id || participantId == player2Id) {
            totalGames++;
            if (participantId == winnerId) {
              wins++;
            } else {
              losses++;
            }
          }
        }

        double winRate = totalGames > 0 ? (wins / totalGames) * 100 : 0.0;

        return {
          'participant_id':
              participant['id'] as String, // For tournament_results
          'participant_name': participant['displayName'] as String,
          'wins': wins,
          'losses': losses,
          'total_games': totalGames,
          'win_rate': winRate,
          'points': wins * 3,
          'is_orphaned': participant['isOrphaned'] as bool,
        };
      }).toList();

      // 🎯 REFACTORED: Sort by BRACKET POSITION first (Elimination logic), then by points/win_rate
      // This ensures Finals winner = Rank 1, Finals loser = Rank 2, Semi-finals losers = Rank 3-4 (tie)
      await _assignBracketPositions(rankings, tournamentId);

      rankings.sort((a, b) {
        // PRIMARY: Bracket rank (1, 2, 3, 5, 9, 17...) from elimination rounds
        final rankA = a['bracket_rank'] as int? ?? 999;
        final rankB = b['bracket_rank'] as int? ?? 999;
        if (rankA != rankB) return rankA.compareTo(rankB);

        // SECONDARY: Points (for tie-breaking within same bracket round)
        int pointsCompare = (b['points'] as int).compareTo(a['points'] as int);
        if (pointsCompare != 0) return pointsCompare;

        // TERTIARY: Win rate (final tie-breaker)
        return (b['win_rate'] as double).compareTo(a['win_rate'] as double);
      });

      // Assign positions and calculate rewards (EXACT UI logic)
      final totalParticipants = rankings.length;
      int currentRank = 1;

      // Prepare prize distribution
      List<double> prizePercentages = [];
      List<int> customPrizeAmounts = [];

      if (customDistribution != null) {
        customPrizeAmounts = customDistribution.map((item) {
          final amount = item['cashAmount'] ?? item['amount'] ?? 0;
          return (amount is int) ? amount : (amount as double).toInt();
        }).toList();
      } else {
        prizePercentages =
            _getPrizeDistribution(prizeDistribution, totalParticipants);
      }

      for (int i = 0; i < rankings.length; i++) {
        final position = i + 1;

        // Tie handling
        if (i > 0) {
          final prevPoints = rankings[i - 1]['points'] as int;
          final prevWinRate = rankings[i - 1]['win_rate'] as double;
          final currPoints = rankings[i]['points'] as int;
          final currWinRate = rankings[i]['win_rate'] as double;

          if (prevPoints != currPoints || prevWinRate != currWinRate) {
            currentRank = position;
          }
        }

        rankings[i]['position'] = position;
        rankings[i]['rank'] = currentRank;

        // 🚀 ELON MODE: ELO calculation uses POSITION (not rank) - only top 4 positions get full bonus
        rankings[i]['elo_change'] =
            _calculateEloBonus(position, totalParticipants);
        rankings[i]['spa_reward'] =
            _calculateSpaBonus(position, totalParticipants);

        // Calculate prize money
        int prizeMoney = 0;
        if (customPrizeAmounts.isNotEmpty && i < customPrizeAmounts.length) {
          prizeMoney = customPrizeAmounts[i];
        } else if (prizePool > 0 && i < prizePercentages.length) {
          prizeMoney = (prizePool * prizePercentages[i] / 100).round();
        }

        // Additional fields for tournament_results
        rankings[i]['matches_won'] = rankings[i]['wins'] as int;
        rankings[i]['matches_lost'] = rankings[i]['losses'] as int;
        rankings[i]['matches_played'] = rankings[i]['total_games'] as int;
        rankings[i]['win_percentage'] = rankings[i]['win_rate'] as double;
        rankings[i]['prize_money_vnd'] = prizeMoney;
      }

      ProductionLogger.info(
          '✅ [UI CAPTURE] Captured ${rankings.length} rankings with UI-identical logic',
          tag: 'ui_data_capture');

      int orphanedCount = 0;
      for (int i = 0; i < rankings.length; i++) {
        final r = rankings[i];
        final isOrphaned = r['is_orphaned'] as bool? ?? false;
        final orphanFlag = isOrphaned ? ' [ORPHANED]' : '';
        ProductionLogger.info(
            '  ${i + 1}. ${r['participant_name']}$orphanFlag (ID: ${r['participant_id']}) → Position ${r['position']}, ${r['spa_reward']} SPA, ${r['elo_change']} ELO',
            tag: 'ui_data_capture');
        if (isOrphaned) orphanedCount++;
      }

      if (orphanedCount > 0) {
        ProductionLogger.info(
            '⚠️ [UI CAPTURE] Included $orphanedCount orphaned participants with placeholder data',
            tag: 'ui_data_capture');
      }
      ProductionLogger.info(
          '🎯 [UI CAPTURE] GUARANTEED: All ${rankings.length} tournament participants will be saved!',
          tag: 'ui_data_capture');

      return rankings;
    } catch (e) {
      ProductionLogger.info('❌ [UI CAPTURE] Error: $e', tag: 'ui_data_capture');
      rethrow;
    }
  }

  /// ELO calculation - EXACT copy from UI
  static int _calculateEloBonus(int position, int totalParticipants) {
    if (position == 1) return 75;
    if (position == 2) return 50;
    if (position == 3 || position == 4) return 35;
    if (position <= totalParticipants * 0.25) return 25;
    if (position <= totalParticipants * 0.5) return 15;
    if (position <= totalParticipants * 0.75) return 10;
    return -5;
  }

  /// SPA calculation - EXACT copy from UI
  static int _calculateSpaBonus(int position, int totalParticipants) {
    final top25 = (totalParticipants * 0.25).ceil();
    final top50 = (totalParticipants * 0.5).ceil();
    final top75 = (totalParticipants * 0.75).ceil();

    if (position == 1) return 1000;
    if (position == 2) return 800;
    if (position == 3 || position == 4) return 550;
    if (position <= top25) return 400;
    if (position <= top50) return 300;
    if (position <= top75) return 200;
    return 100;
  }

  /// Get prize distribution percentages (matches TournamentRankingsWidget logic)
  static List<double> _getPrizeDistribution(
      String template, int participantCount) {
    switch (template) {
      case 'winner_takes_all':
        return [100.0];
      case 'top_3':
        return [60.0, 25.0, 15.0];
      case 'top_4':
        return [40.0, 30.0, 15.0, 15.0];
      case 'top_8':
        return [35.0, 25.0, 15.0, 10.0, 5.0, 5.0, 2.5, 2.5];
      case 'dong_hang_3':
        return [40.0, 30.0, 15.0, 15.0];
      case 'top_heavy':
        if (participantCount <= 4) return [60.0, 30.0, 10.0];
        if (participantCount <= 8) return [50.0, 30.0, 12.0, 8.0];
        return [40.0, 25.0, 15.0, 10.0, 5.0, 3.0, 2.0];
      case 'flat':
        if (participantCount <= 4) return [40.0, 30.0, 20.0, 10.0];
        if (participantCount <= 8) return [30.0, 25.0, 20.0, 12.0, 8.0, 5.0];
        return [25.0, 20.0, 15.0, 12.0, 10.0, 8.0, 5.0, 3.0, 2.0];
      case 'standard':
      default:
        if (participantCount <= 4) return [50.0, 30.0, 20.0];
        if (participantCount <= 8)
          return [40.0, 25.0, 15.0, 10.0, 5.0, 3.0, 2.0];
        return [40.0, 25.0, 15.0, 10.0, 5.0, 3.0, 2.0];
    }
  }

  /// Assign bracket positions based on elimination round analysis
  /// - Rank 1: Finals winner
  /// - Rank 2: Finals loser
  /// - Rank 3: Semi-finals losers (tie rank - đồng hạng)
  /// - Rank 5: Quarter-finals losers (tie rank)
  /// - Rank 9: Round of 16 losers (tie rank)
  /// - Rank 17: Round of 32 losers (tie rank)
  static Future<void> _assignBracketPositions(
      List<Map<String, dynamic>> rankings, String tournamentId) async {
    try {
      // Query all matches with round information
      final matchesResponse = await Supabase.instance.client
          .from('matches')
          .select('round_name, winner_id, player1_id, player2_id, status')
          .eq('tournament_id', tournamentId)
          .eq('status', 'completed');

      final matches = matchesResponse as List<dynamic>;

      // Find Finals match (Rank 1 & 2)
      final finalsMatch = matches.firstWhere(
        (m) => (m['round_name'] as String?)?.toLowerCase() == 'finals',
        orElse: () => null,
      );

      if (finalsMatch != null) {
        final championId = finalsMatch['winner_id'] as String?;
        final player1Id = finalsMatch['player1_id'] as String?;
        final player2Id = finalsMatch['player2_id'] as String?;
        final runnerUpId = (player1Id == championId) ? player2Id : player1Id;

        // Assign Rank 1 (Champion) and Rank 2 (Runner-up)
        for (final ranking in rankings) {
          if (ranking['participant_id'] == championId) {
            ranking['bracket_rank'] = 1;
          } else if (ranking['participant_id'] == runnerUpId) {
            ranking['bracket_rank'] = 2;
          }
        }
      }

      // Find Semi-finals matches (Rank 3-4, tie rank)
      final semiMatches = matches
          .where((m) =>
              (m['round_name'] as String?)?.toLowerCase().contains('semi') ??
              false)
          .toList();

      for (final match in semiMatches) {
        final winnerId = match['winner_id'] as String?;
        final player1Id = match['player1_id'] as String?;
        final player2Id = match['player2_id'] as String?;
        final loserId = (player1Id == winnerId) ? player2Id : player1Id;

        // Assign Rank 3 (tie rank) to semi-finals losers
        for (final ranking in rankings) {
          if (ranking['participant_id'] == loserId &&
              ranking['bracket_rank'] == null) {
            ranking['bracket_rank'] = 3;
          }
        }
      }

      // Find Quarter-finals matches (Rank 5-8, tie rank)
      final quarterMatches = matches
          .where((m) =>
              (m['round_name'] as String?)?.toLowerCase().contains('quarter') ??
              false)
          .toList();

      for (final match in quarterMatches) {
        final winnerId = match['winner_id'] as String?;
        final player1Id = match['player1_id'] as String?;
        final player2Id = match['player2_id'] as String?;
        final loserId = (player1Id == winnerId) ? player2Id : player1Id;

        // Assign Rank 5 (tie rank) to quarter-finals losers
        for (final ranking in rankings) {
          if (ranking['participant_id'] == loserId &&
              ranking['bracket_rank'] == null) {
            ranking['bracket_rank'] = 5;
          }
        }
      }

      // Find Round of 16 matches (Rank 9-16, tie rank)
      final round16Matches = matches
          .where((m) =>
              (m['round_name'] as String?)
                  ?.toLowerCase()
                  .contains('round of 16') ??
              false)
          .toList();

      for (final match in round16Matches) {
        final winnerId = match['winner_id'] as String?;
        final player1Id = match['player1_id'] as String?;
        final player2Id = match['player2_id'] as String?;
        final loserId = (player1Id == winnerId) ? player2Id : player1Id;

        // Assign Rank 9 (tie rank)
        for (final ranking in rankings) {
          if (ranking['participant_id'] == loserId &&
              ranking['bracket_rank'] == null) {
            ranking['bracket_rank'] = 9;
          }
        }
      }

      // Find Round of 32 matches (Rank 17-32, tie rank)
      final round32Matches = matches
          .where((m) =>
              (m['round_name'] as String?)
                  ?.toLowerCase()
                  .contains('round of 32') ??
              false)
          .toList();

      for (final match in round32Matches) {
        final winnerId = match['winner_id'] as String?;
        final player1Id = match['player1_id'] as String?;
        final player2Id = match['player2_id'] as String?;
        final loserId = (player1Id == winnerId) ? player2Id : player1Id;

        // Assign Rank 17 (tie rank)
        for (final ranking in rankings) {
          if (ranking['participant_id'] == loserId &&
              ranking['bracket_rank'] == null) {
            ranking['bracket_rank'] = 17;
          }
        }
      }

      ProductionLogger.info(
          '🏆 [BRACKET POSITION] Assigned bracket ranks based on elimination rounds',
          tag: 'ui_data_capture');
    } catch (e) {
      ProductionLogger.info(
          '⚠️ [BRACKET POSITION] Error assigning bracket positions: $e',
          tag: 'ui_data_capture');
      // Continue without bracket positions - will fall back to points/win_rate sorting
    }
  }
}
