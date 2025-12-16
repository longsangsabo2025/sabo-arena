// 🏆 SABO ARENA - Tournament Completion Service
// Handles complete tournament finishing workflow including ELO updates,
// prize distribution, social posting, and community notifications

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/tournament_constants.dart';
import '../utils/number_formatter.dart';
import 'tournament_service.dart';
import 'tournament_elo_service.dart';
import 'social_service.dart';
import 'notification_service.dart';
import 'user_stats_update_service.dart';
import 'chat_service.dart';
import 'tournament_prize_voucher_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service xử lý hoàn thành tournament và các tác vụ liên quan
class TournamentCompletionService {
  static TournamentCompletionService? _instance;
  static TournamentCompletionService get instance =>
      _instance ??= TournamentCompletionService._();
  TournamentCompletionService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final TournamentService _tournamentService = TournamentService.instance;
  final TournamentEloService _eloService = TournamentEloService.instance;
  final SocialService _socialService = SocialService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final TournamentPrizeVoucherService _prizeVoucherService = TournamentPrizeVoucherService();

  // ==================== MAIN COMPLETION WORKFLOW ====================

  /// ⛔ DEPRECATED - Use TournamentCompletionOrchestrator instead!
  /// This legacy service is disabled to prevent duplicate reward distribution.
  /// 
  /// Migration guide:
  /// ```dart
  /// // OLD (DEPRECATED):
  /// await TournamentCompletionService.instance.completeTournament(tournamentId: id);
  /// 
  /// // NEW (CORRECT):
  /// await TournamentCompletionOrchestrator.instance.completeTournament(tournamentId: id);
  /// ```
  @Deprecated('Use TournamentCompletionOrchestrator instead to prevent duplicate rewards')
  Future<Map<String, dynamic>> completeTournament({
    required String tournamentId,
    bool sendNotifications = true,
    bool postToSocial = true,
    bool updateElo = true,
    bool distributePrizes = true,
  }) async {
    // 🚨 CRITICAL: This service is DISABLED to prevent duplicate reward distribution
    // There was a bug where both TournamentCompletionService (legacy) and 
    // TournamentCompletionOrchestrator (new) were running in parallel, causing users
    // to receive double rewards (2x ELO, 2x SPA, 2x vouchers).
    // 
    // All code should now use TournamentCompletionOrchestrator exclusively.
    
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    
    throw Exception(
      '⛔ DEPRECATED: TournamentCompletionService is disabled!\n'
      'Please use TournamentCompletionOrchestrator.instance.completeTournament() instead.\n'
      'This prevents duplicate reward distribution bug.\n'
      'See DUPLICATE_REWARDS_BUG_REPORT.md for details.'
    );

    /* ORIGINAL CODE DISABLED - DO NOT UNCOMMENT WITHOUT FIXING DUPLICATE ISSUE
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // 1. Validate tournament can be completed
      final validationResult = await _validateTournamentCompletion(
        tournamentId,
      );
      if (!validationResult['canComplete']) {
        throw Exception(validationResult['reason']);
      }

      // 2. Calculate final standings
      final standings = await _calculateFinalStandings(tournamentId);
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': false,
        'error': error.toString(),
        'message': 'Failed to complete tournament',
      };
    }
    END OF ORIGINAL CODE - DISABLED */
  }

  /* LEGACY CODE BELOW - ALL DISABLED TO PREVENT DUPLICATE REWARDS
     DO NOT USE THESE METHODS - Use TournamentCompletionOrchestrator instead
  
      // 3. Update ELO ratings
      List<Map<String, dynamic>> eloChanges = [];
      if (updateElo) {
        try {
          eloChanges = await _processEloUpdates(tournamentId, standings);
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          // Don't fail tournament completion if ELO fails
        }
      }

      // 4. Distribute prize pool
      List<Map<String, dynamic>> prizeDistribution = [];
      if (distributePrizes) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        try {
          prizeDistribution = await _distributePrizes(tournamentId, standings);
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (e, stack) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          rethrow;
        }
      }

      // 5. Update tournament status
      await _updateTournamentStatus(tournamentId, standings);

      // 6. Send notifications
      if (sendNotifications) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        await _sendCompletionNotifications(
          tournamentId,
          standings,
          eloChanges,
          prizeDistribution,
        );
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        // 6.1 Send congratulatory chat messages to top performers
        await _sendCongratulatoryChatMessages(
          tournamentId,
          standings,
          prizeDistribution,
        );
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // 7. Create social posts
      if (postToSocial) {
        await _createSocialPosts(tournamentId, standings);
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // 8. Save tournament results and update user stats (NEW APPROACH)
      await TournamentResultService.instance.saveTournamentResults(
        tournamentId: tournamentId,
        standings: standings,
      );
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // 9. Update statistics (keep for compatibility)
      await _updateTournamentStatistics(tournamentId, standings);

      // 9. Create completion report
      final completionReport = await _generateCompletionReport(
        tournamentId,
        standings,
        eloChanges,
        prizeDistribution,
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      return {
        'success': true,
        'tournament_id': tournamentId,
        'completion_time': DateTime.now().toIso8601String(),
        'participants_count': standings.length,
        'champion_id': standings.isNotEmpty
            ? standings.first['participant_id']
            : null,
        'elo_changes': eloChanges.length,
        'prize_recipients': prizeDistribution.length,
        'completion_report': completionReport,
        'message': 'Tournament completed successfully with full workflow',
      };
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': false,
        'error': error.toString(),
        'message': 'Failed to complete tournament',
      };
    }
  */

  // ==================== VALIDATION ====================

  /// Validate tournament có thể được complete không
  Future<Map<String, dynamic>> _validateTournamentCompletion(
    String tournamentId,
  ) async {
    // Get tournament info
    final tournament = await _supabase
        .from('tournaments')
        .select('status, bracket_format')
        .eq('id', tournamentId)
        .single();

    if (tournament['status'] == 'completed') {
      return {
        'canComplete': false,
        'reason': 'Tournament is already completed',
      };
    }

    // Check if all matches are completed
    final matches = await _supabase
        .from('matches')
        .select('status')
        .eq('tournament_id', tournamentId);

    final totalMatches = matches.length;
    final completedMatches = matches
        .where((m) => m['status'] == 'completed')
        .length;

    if (totalMatches == 0) {
      return {
        'canComplete': false,
        'reason': 'No matches found for this tournament',
      };
    }

    if (completedMatches < totalMatches) {
      return {
        'canComplete': false,
        'reason':
            'Not all matches are completed ($completedMatches/$totalMatches)',
      };
    }

    // Format-specific validation
    final format = tournament['bracket_format'] ?? 'single_elimination';
    final formatValidation = await _validateFormatSpecificCompletion(
      tournamentId,
      format,
    );
    if (!formatValidation['valid']) {
      return {'canComplete': false, 'reason': formatValidation['reason']};
    }

    return {
      'canComplete': true,
      'total_matches': totalMatches,
      'completed_matches': completedMatches,
    };
  }

  /// Validate format-specific completion requirements
  Future<Map<String, dynamic>> _validateFormatSpecificCompletion(
    String tournamentId,
    String format,
  ) async {
    switch (format) {
      case TournamentFormats.singleElimination:
      case TournamentFormats.doubleElimination:
        // Check if final match exists và completed
        final finalMatch = await _supabase
            .from('matches')
            .select('status')
            .eq('tournament_id', tournamentId)
            .order('round_number', ascending: false)
            .limit(1)
            .maybeSingle();

        if (finalMatch == null || finalMatch['status'] != 'completed') {
          return {'valid': false, 'reason': 'Final match not completed'};
        }
        break;

      case TournamentFormats.roundRobin:
        // All round robin matches should be completed
        // Additional validation có thể add sau
        break;

      case TournamentFormats.swiss:
        // Check if minimum rounds completed
        break;

      default:
        // Default validation passed
        break;
    }

    return {'valid': true};
  }

  // ==================== FINAL STANDINGS ====================

  /// Calculate final standings dựa trên tournament format
  Future<List<Map<String, dynamic>>> _calculateFinalStandings(
    String tournamentId,
  ) async {
    final tournament = await _supabase
        .from('tournaments')
        .select('bracket_format')
        .eq('id', tournamentId)
        .single();

    final format = tournament['bracket_format'] ?? 'single_elimination';

    switch (format) {
      case TournamentFormats.singleElimination:
      case TournamentFormats.doubleElimination:
      case TournamentFormats.saboDoubleElimination:
      case TournamentFormats.saboDoubleElimination32:
        return await _calculateEliminationStandings(tournamentId, format);

      case TournamentFormats.roundRobin:
        return await _calculateRoundRobinStandings(tournamentId);

      case TournamentFormats.swiss:
        return await _calculateSwissStandings(tournamentId);

      case TournamentFormats.parallelGroups:
        return await _calculateParallelGroupsStandings(tournamentId);

      default:
        return await _calculateDefaultStandings(tournamentId);
    }
  }

  /// Calculate standings cho elimination formats
  Future<List<Map<String, dynamic>>> _calculateEliminationStandings(
    String tournamentId,
    String format,
  ) async {
    // Get all participants
    final participants = await _supabase
        .from('tournament_participants')
        .select('''
          user_id,
          users!inner(id, full_name, elo_rating, rank)
        ''')
        .eq('tournament_id', tournamentId);

    // Get all matches để determine elimination order
    final matches = await _supabase
        .from('matches')
        .select('player1_id, player2_id, winner_id, round_number, status')
        .eq('tournament_id', tournamentId)
        .eq('status', 'completed')
        .order('round_number', ascending: false);

    List<Map<String, dynamic>> standings = [];

    // Find champion (winner of final match)
    final finalMatch = matches.first;
    final championId = finalMatch['winner_id'];

    if (championId != null) {
      final champion = participants.firstWhere(
        (p) => p['user_id'] == championId,
      );
      standings.add({
        'position': 1,
        'participant_id': championId,
        'participant_name': champion['users']['display_name'] ?? champion['users']['full_name'],
        'elimination_round': null, // Champion wasn't eliminated
        'matches_played': _countMatchesPlayed(championId, matches),
        'matches_won': _countMatchesWon(championId, matches),
      });
    }

    // Find runner-up
    final runnerUpId = finalMatch['player1_id'] == championId
        ? finalMatch['player2_id']
        : finalMatch['player1_id'];

    if (runnerUpId != null) {
      final runnerUp = participants.firstWhere(
        (p) => p['user_id'] == runnerUpId,
      );
      standings.add({
        'position': 2,
        'participant_id': runnerUpId,
        'participant_name': runnerUp['users']['display_name'] ?? runnerUp['users']['full_name'],
        'elimination_round': matches.first['round_number'],
        'matches_played': _countMatchesPlayed(runnerUpId, matches),
        'matches_won': _countMatchesWon(runnerUpId, matches),
      });
    }

    // Calculate positions cho remaining participants dựa trên elimination order
    final remainingParticipants = participants
        .where((p) => p['user_id'] != championId && p['user_id'] != runnerUpId)
        .toList();

    // Group by elimination round (later rounds = higher positions)
    Map<int, List<String>> eliminationRounds = {};

    for (final participant in remainingParticipants) {
      final playerId = participant['user_id'];
      final eliminationRound = _findEliminationRound(playerId, matches);

      if (!eliminationRounds.containsKey(eliminationRound)) {
        eliminationRounds[eliminationRound] = [];
      }
      eliminationRounds[eliminationRound]!.add(playerId);
    }

    // Assign positions (higher elimination round = better position)
    int currentPosition = 3;
    final sortedRounds = eliminationRounds.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final round in sortedRounds) {
      final playersInRound = eliminationRounds[round]!;

      for (final playerId in playersInRound) {
        final participant = participants.firstWhere(
          (p) => p['user_id'] == playerId,
        );
        standings.add({
          'position': currentPosition,
          'participant_id': playerId,
          'participant_name': participant['users']['display_name'] ?? participant['users']['full_name'],
          'elimination_round': round,
          'matches_played': _countMatchesPlayed(playerId, matches),
          'matches_won': _countMatchesWon(playerId, matches),
        });
      }

      currentPosition += playersInRound.length;
    }

    return standings;
  }

  /// Calculate standings cho Round Robin
  Future<List<Map<String, dynamic>>> _calculateRoundRobinStandings(
    String tournamentId,
  ) async {
    final participants = await _supabase
        .from('tournament_participants')
        .select('''
          user_id,
          users!inner(id, full_name, elo_rating, rank)
        ''')
        .eq('tournament_id', tournamentId);

    final matches = await _supabase
        .from('matches')
        .select(
          'player1_id, player2_id, winner_id, player1_score, player2_score',
        )
        .eq('tournament_id', tournamentId)
        .eq('status', 'completed');

    List<Map<String, dynamic>> standings = [];

    for (final participant in participants) {
      final playerId = participant['user_id'];
      final playerMatches = matches
          .where(
            (m) => m['player1_id'] == playerId || m['player2_id'] == playerId,
          )
          .toList();

      int wins = 0;
      int losses = 0;
      int gamesWon = 0;
      int gamesLost = 0;

      for (final match in playerMatches) {
        final isPlayer1 = match['player1_id'] == playerId;
        final playerScore = isPlayer1
            ? match['player1_score']
            : match['player2_score'];
        final opponentScore = isPlayer1
            ? match['player2_score']
            : match['player1_score'];

        gamesWon += (playerScore as int? ?? 0);
        gamesLost += (opponentScore as int? ?? 0);

        if (match['winner_id'] == playerId) {
          wins++;
        } else if (match['winner_id'] != null) {
          losses++;
        }
      }

      standings.add({
        'participant_id': playerId,
        'participant_name': participant['users']['display_name'] ?? participant['users']['full_name'],
        'matches_played': playerMatches.length,
        'matches_won': wins,
        'matches_lost': losses,
        'games_won': gamesWon,
        'games_lost': gamesLost,
        'win_percentage': playerMatches.isEmpty
            ? 0
            : (wins / playerMatches.length * 100).round(),
        'points': wins * 3, // 3 points per match win
      });
    }

    // Sort by points, then by win percentage, then by games difference
    standings.sort((a, b) {
      final pointsCompare = (b['points'] as num).toInt().compareTo(
        (a['points'] as num).toInt(),
      );
      if (pointsCompare != 0) return pointsCompare;

      final winPercentageCompare = (b['win_percentage'] as num)
          .toInt()
          .compareTo((a['win_percentage'] as num).toInt());
      if (winPercentageCompare != 0) return winPercentageCompare;

      final gamesDiffA =
          (a['games_won'] as num).toInt() - (a['games_lost'] as num).toInt();
      final gamesDiffB =
          (b['games_won'] as num).toInt() - (b['games_lost'] as num).toInt();
      return gamesDiffB.compareTo(gamesDiffA);
    });

    // Assign positions
    for (int i = 0; i < standings.length; i++) {
      standings[i]['position'] = i + 1;
    }

    return standings;
  }

  /// Calculate standings cho Swiss System
  Future<List<Map<String, dynamic>>> _calculateSwissStandings(
    String tournamentId,
  ) async {
    // Similar to Round Robin nhưng với Swiss scoring
    // Implementation chi tiết sau
    return [];
  }

  /// Calculate standings cho Parallel Groups
  Future<List<Map<String, dynamic>>> _calculateParallelGroupsStandings(
    String tournamentId,
  ) async {
    // Combine group stage results với playoff results
    // Implementation chi tiết sau
    return [];
  }

  /// Default standings calculation
  Future<List<Map<String, dynamic>>> _calculateDefaultStandings(
    String tournamentId,
  ) async {
    // Fallback method
    final participants = await _supabase
        .from('tournament_participants')
        .select('''
          user_id,
          users!inner(id, full_name, elo_rating, rank)
        ''')
        .eq('tournament_id', tournamentId);

    return participants.asMap().entries.map((entry) {
      return {
        'position': entry.key + 1,
        'participant_id': entry.value['user_id'],
        'participant_name': entry.value['users']['display_name'] ?? entry.value['users']['full_name'],
        'matches_played': 0,
        'matches_won': 0,
      };
    }).toList();
  }

  // ==================== HELPER METHODS ====================

  /// Count matches played by a player
  int _countMatchesPlayed(String playerId, List matches) {
    return matches
        .where(
          (m) => m['player1_id'] == playerId || m['player2_id'] == playerId,
        )
        .length;
  }

  /// Count matches won by a player
  int _countMatchesWon(String playerId, List matches) {
    return matches.where((m) => m['winner_id'] == playerId).length;
  }

  /// Find elimination round for a player
  int _findEliminationRound(String playerId, List matches) {
    // Find the last match where player lost
    for (final match in matches) {
      if ((match['player1_id'] == playerId ||
              match['player2_id'] == playerId) &&
          match['winner_id'] != null &&
          match['winner_id'] != playerId) {
        return match['round_number'] as int;
      }
    }
    return 1; // Default to round 1 if no elimination found
  }

  // ==================== ELO UPDATES ====================

  /// Process ELO updates cho tournament completion
  Future<List<Map<String, dynamic>>> _processEloUpdates(
    String tournamentId,
    List<Map<String, dynamic>> standings,
  ) async {
    try {
      // Get tournament format
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('bracket_format')
          .eq('id', tournamentId)
          .single();

      final tournamentFormat =
          tournamentResponse['bracket_format'] ?? 'single_elimination';

      // Convert standings to TournamentResult format
      List<TournamentResult> results = [];
      for (int i = 0; i < standings.length; i++) {
        final standing = standings[i];
        results.add(TournamentResult(
          participantId: standing['participant_id'],
          finalPosition: i + 1, // position based on sorted standings
          matchesPlayed: standing['matches_played'] ?? 0,
          matchesWon: standing['wins'] ?? 0,
          matchesLost: standing['losses'] ?? 0,
          startingElo: standing['starting_elo'] ?? 1000,
          defeatedHigherSeeds: 0, // Not tracked in current implementation
          defeatedOpponents: [], // Not tracked in current implementation
        ));
      }

      // Process ELO changes using TournamentEloService
      final eloChanges = await _eloService.processTournamentEloChanges(
        tournamentId: tournamentId,
        results: results,
        tournamentFormat: tournamentFormat,
      );

      // Convert EloUpdateResult to Map format for compatibility
      return eloChanges.map((change) => {
        'participant_id': change.participantId,
        'old_elo': change.oldElo,
        'new_elo': change.newElo,
        'elo_change': change.change,
      }).toList();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // ==================== PRIZE DISTRIBUTION ====================

  /// Distribute prizes dựa trên tournament settings
  Future<List<Map<String, dynamic>>> _distributePrizes(
    String tournamentId,
    List<Map<String, dynamic>> standings,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      // Get tournament prize info
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      final tournament = await _supabase
          .from('tournaments')
          .select('prize_pool, entry_fee, max_participants, prize_distribution')
          .eq('id', tournamentId)
          .single();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      tournament.forEach((key, value) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      });

      final prizePool = tournament['prize_pool'] as int? ?? 0;
      final participantCount = standings.length;

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      List<Map<String, dynamic>> prizeRecipients = [];

    // ALWAYS distribute Position Bonus to ALL participants (1000 → 100 SPA)
    for (int i = 0; i < standings.length; i++) {
      final standing = standings[i];
      final position = standing['position'] as int;

      // Calculate Position Bonus (Simple: 1000 → 100 SPA based on position)
      final positionBonusSPA = _calculatePositionBonus(
        position,
        participantCount,
      );

      int prizeMoneyVND = 0;

      // If there's prize pool, calculate prize for top positions
      if (prizePool > 0) {
        // Extract template from prize_distribution Map or use default
        String distributionTemplate = 'standard';
        
        final prizeDistJson = tournament['prize_distribution'];
        if (prizeDistJson != null && prizeDistJson is Map) {
          distributionTemplate = (prizeDistJson['template'] ?? 'standard') as String;
        }
        
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        final distribution = _getPrizeDistribution(
          distributionTemplate,
          participantCount,
        );

        if (i < distribution.length) {
          final percentage = distribution[i];
          prizeMoneyVND = (prizePool * percentage / 100).round();

          // TODO: Record prize transaction when RLS policy is fixed
          // Currently skipped due to RLS restriction on transactions table
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }

      // Update user's SPA points using atomic function to prevent race conditions
      final spaResult = await _supabase.rpc('atomic_increment_spa', params: {
        'p_user_id': standing['participant_id'],
        'p_amount': positionBonusSPA,
        'p_transaction_type': 'spa_bonus',
        'p_description': 'SPA Bonus - Position $position: +$positionBonusSPA SPA',
        'p_reference_type': 'tournament',
        'p_reference_id': tournamentId,
      }) as List<dynamic>;

      if (spaResult.isNotEmpty) {
        final data = spaResult.first as Map<String, dynamic>;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      prizeRecipients.add({
        'participant_id': standing['participant_id'],
        'participant_name': standing['participant_name'],
        'position': position,
        'prize_money_vnd': prizeMoneyVND, // TIỀN (VND)
        'position_bonus_spa': positionBonusSPA, // ĐIỂM (SPA)
      });
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    return prizeRecipients;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Calculate Position Bonus (Simple: 1000 → 100 SPA based on position)
  int _calculatePositionBonus(int position, int totalParticipants) {
    // Fixed SPA bonuses based on position (1000 → 100 SPA)
    if (position == 1) {
      return 1000; // Winner: +1000 SPA
    } else if (position == 2) {
      return 800; // Runner-up: +800 SPA
    } else if (position == 3 || position == 4) {
      return 550; // Đồng hạng 3 (3rd & 4th place): +550 SPA each
    } else if (position <= totalParticipants * 0.25) {
      return 400; // Top 25%: +400 SPA
    } else if (position <= totalParticipants * 0.5) {
      return 300; // Top 50%: +300 SPA
    } else if (position <= totalParticipants * 0.75) {
      return 200; // Top 75%: +200 SPA
    } else {
      return 100; // Bottom 25%: +100 SPA (minimum participation)
    }
  }

  /// Get prize distribution percentages
  List<double> _getPrizeDistribution(String template, int participantCount) {
    final distributions = PrizeDistribution.allDistributions[template];
    if (distributions == null) return [];

    // Find closest participant count
    final availableKeys = distributions.keys.map(int.parse).toList()..sort();
    int closestKey = availableKeys.last;

    for (final key in availableKeys) {
      if (participantCount <= key) {
        closestKey = key;
        break;
      }
    }

    return distributions[closestKey.toString()] ?? [];
  }

  // ==================== STATUS UPDATES ====================

  /// Update tournament status to completed
  Future<void> _updateTournamentStatus(
    String tournamentId,
    List<Map<String, dynamic>> standings,
  ) async {
    // Only update status - champion_id and completed_at columns don't exist in DB schema
    await _supabase
        .from('tournaments')
        .update({
          'status': 'completed',
          // 'completed_at': DateTime.now().toIso8601String(), // Column doesn't exist
          // 'champion_id': championId, // Column doesn't exist
        })
        .eq('id', tournamentId);

    // Note: tournament_participants doesn't have final_position, matches_played, matches_won columns
    // Rankings are calculated dynamically from matches table in TournamentRankingsWidget
  }

  /// Helper method to increment user tournament statistics
  Future<void> _incrementUserStats(
    String participantId,
    bool isWinner,
    bool isPodium,
  ) async {
    try {
      // Get current stats
      final userStats = await _supabase
          .from('users')
          .select(
            'total_tournaments, tournament_wins, tournament_podiums, total_wins, total_losses',
          )
          .eq('id', participantId)
          .single();

      // Calculate match wins/losses for this user
      final matchWins = await _supabase
          .from('matches')
          .select('id')
          .eq('winner_id', participantId)
          .eq('status', 'completed');

      final matchesAsPlayer1 = await _supabase
          .from('matches')
          .select('id')
          .eq('player1_id', participantId)
          .eq('status', 'completed');

      final matchesAsPlayer2 = await _supabase
          .from('matches')
          .select('id')
          .eq('player2_id', participantId)
          .eq('status', 'completed');

      final totalMatches = matchesAsPlayer1.length + matchesAsPlayer2.length;
      final totalWins = matchWins.length;
      final totalLosses = totalMatches - totalWins;

      // Calculate new values
      final updates = <String, dynamic>{
        'total_tournaments': (userStats['total_tournaments'] ?? 0) + 1,
        'total_wins': totalWins,
        'total_losses': totalLosses,
      };

      if (isWinner) {
        updates['tournament_wins'] = (userStats['tournament_wins'] ?? 0) + 1;
      }

      if (isPodium) {
        updates['tournament_podiums'] =
            (userStats['tournament_podiums'] ?? 0) + 1;
      }

      // Update the stats
      await _supabase.from('users').update(updates).eq('id', participantId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Send completion notifications to ALL participants
  Future<void> _sendCompletionNotifications(
    String tournamentId,
    List<Map<String, dynamic>> standings,
    List<Map<String, dynamic>> eloChanges,
    List<Map<String, dynamic>> prizeDistribution,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      final tournament = await _supabase
          .from('tournaments')
          .select('title')
          .eq('id', tournamentId)
          .single();

      final tournamentTitle = tournament['title'] ?? 'Tournament';
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Prepare batch notifications for ALL participants with their rewards
      final batchNotifications = <Map<String, dynamic>>[];

      for (final reward in prizeDistribution) {
        final position = reward['position'];
        final prizeVND = reward['prize_money_vnd'] ?? 0;
        final bonusSPA = reward['position_bonus_spa'] ?? 0;
        
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Determine title and message based on position
        String title;
        String message;
        String notifType;

        if (position == 1) {
          title = '🏆 Chúc mừng! Bạn đã vô địch!';
          notifType = 'tournament_champion';
        } else if (position == 2) {
          title = '🥈 Chúc mừng! Bạn đã đạt Á quân!';
          notifType = 'tournament_runner_up';
        } else if (position == 3 || position == 4) {
          title = '🥉 Chúc mừng! Bạn đã đạt Đồng hạng 3!';
          notifType = 'tournament_podium';
        } else {
          title = '🎉 Giải đấu "$tournamentTitle" đã kết thúc';
          notifType = 'tournament_completed';
        }

        // Build reward message (VND và SPA là 2 loại RIÊNG BIỆT)
        if (prizeVND > 0) {
          message =
              'Vị trí #$position - Bạn đã nhận:\n💰 ${NumberFormatter.formatCurrency(prizeVND)} VND (tiền thưởng)\n⭐ ${NumberFormatter.formatCurrency(bonusSPA)} SPA (điểm thưởng)\ntừ giải đấu "$tournamentTitle"';
        } else {
          message =
              'Vị trí #$position - Bạn đã nhận ⭐ ${NumberFormatter.formatCurrency(bonusSPA)} SPA (điểm thưởng) từ giải đấu "$tournamentTitle"';
        }

        // Add to batch
        batchNotifications.add({
          'user_id': reward['participant_id'],
          'type': notifType,
          'title': title,
          'message': message,
          'data': {
            'tournament_id': tournamentId,
            'position': position,
            'prize_money_vnd': prizeVND, // TIỀN (VND) - separate
            'bonus_spa': bonusSPA, // ĐIỂM (SPA) - separate
          },
        });
      }

      // Send all notifications as batch for better performance
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      await _notificationService.sendBatchNotifications(batchNotifications);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow; // Re-throw to see the error in parent
    }
  }

  /// Send congratulatory chat messages to top performers in tournament
  Future<void> _sendCongratulatoryChatMessages(
    String tournamentId,
    List<Map<String, dynamic>> standings,
    List<Map<String, dynamic>> prizeDistribution,
  ) async {
    try {
      // Get tournament info
      final tournament = await _supabase
          .from('tournaments')
          .select('title, club_id')
          .eq('id', tournamentId)
          .single();

      final tournamentTitle = tournament['title'] ?? 'Tournament';
      final clubId = tournament['club_id'] as String?;

      if (clubId == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return;
      }

      // Get or create tournament announcement chat room
      final chatRoom = await _getOrCreateTournamentChatRoom(
        tournamentId,
        clubId,
        tournamentTitle,
      );

      if (chatRoom == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return;
      }

      final roomId = chatRoom['id'] as String;

      // Send congratulatory messages for top 3 positions (or top 4 if tie at 3rd)
      final topPerformers = prizeDistribution.where((p) {
        final pos = p['position'] as int;
        return pos <= 4; // Top 4 to include tied 3rd place
      }).toList();

      for (final performer in topPerformers) {
        final position = performer['position'] as int;
        final participantId = performer['participant_id'] as String;
        final prizeVND = performer['prize_money_vnd'] ?? 0;
        final bonusSPA = performer['position_bonus_spa'] ?? 0;

        // Get participant name
        final participant = standings.firstWhere(
          (s) => s['participant_id'] == participantId,
          orElse: () => {'participant_name': 'Player'},
        );
        final participantName = participant['participant_name'] ?? 'Player';

        // Build congratulatory message based on position
        String message;
        if (position == 1) {
          message = '''🏆🎉 CHÚC MỪNG VÔ ĐỊCH! 🎉🏆

👑 **$participantName** đã xuất sắc giành chức vô địch giải đấu "$tournamentTitle"!

🎁 Phần thưởng:
💰 ${NumberFormatter.formatCurrency(prizeVND)} VND
⭐ ${NumberFormatter.formatCurrency(bonusSPA)} SPA

Chúc mừng nhà vô địch! 🔥🏅''';
        } else if (position == 2) {
          message = '''🥈✨ CHÚC MỪNG Á QUÂN! ✨🥈

🌟 **$participantName** đã đạt vị trí Á quân tại giải đấu "$tournamentTitle"!

🎁 Phần thưởng:
💰 ${NumberFormatter.formatCurrency(prizeVND)} VND
⭐ ${NumberFormatter.formatCurrency(bonusSPA)} SPA

Thành tích xuất sắc! 👏''';
        } else if (position == 3 || position == 4) {
          message = '''🥉🎖️ CHÚC MỪNG ĐỒNG HẠNG 3! 🎖️🥉

💪 **$participantName** đã giành vị trí thứ $position (Đồng hạng 3) tại giải đấu "$tournamentTitle"!

🎁 Phần thưởng:
💰 ${NumberFormatter.formatCurrency(prizeVND)} VND
⭐ ${NumberFormatter.formatCurrency(bonusSPA)} SPA

Chúc mừng! 🎉''';
        } else {
          continue; // Skip positions > 4
        }

        // Send message to chat room
        await ChatService.sendMessage(
          roomId: roomId,
          message: message,
          messageType: 'tournament_completion',
        );

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Send final summary message
      final summaryMessage = '''📊 **KẾT QUẢ GIẢI ĐẤU "$tournamentTitle"** 📊

${standings.take(5).map((s) {
        final pos = standings.indexOf(s) + 1;
        final name = s['participant_name'];
        final wins = s['wins'] ?? 0;
        final losses = s['losses'] ?? 0;
        String medal = '';
        if (pos == 1) medal = '🥇';
        else if (pos == 2) medal = '🥈';
        else if (pos == 3 || pos == 4) medal = '🥉';
        return '$medal #$pos: **$name** ($wins-$losses)';
      }).join('\n')}

Cảm ơn tất cả các vận động viên đã tham gia! 🙏
#SABOArena #Tournament''';

      await ChatService.sendMessage(
        roomId: roomId,
        message: summaryMessage,
        messageType: 'tournament_summary',
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Get or create chat room for tournament announcements
  Future<Map<String, dynamic>?> _getOrCreateTournamentChatRoom(
    String tournamentId,
    String clubId,
    String tournamentTitle,
  ) async {
    try {
      // Try to find existing tournament chat room
      final existingRooms = await _supabase
          .from('chat_rooms')
          .select()
          .eq('club_id', clubId)
          .eq('type', 'tournament')
          .eq('is_active', true)
          .limit(1);

      if (existingRooms.isNotEmpty) {
        return existingRooms.first;
      }

      // Create new tournament announcement room
      final newRoom = await ChatService.createChatRoom(
        clubId: clubId,
        name: 'Thông báo giải đấu',
        description: 'Kênh thông báo kết quả và chúc mừng các giải đấu',
        type: 'tournament',
        isPrivate: false,
      );

      return newRoom;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  // ==================== SOCIAL POSTS ====================

  /// Create social posts về tournament completion
  Future<void> _createSocialPosts(
    String tournamentId,
    List<Map<String, dynamic>> standings,
  ) async {
    try {
      final tournament = await _supabase
          .from('tournaments')
          .select('title, organizer_id, max_participants, club_id')
          .eq('id', tournamentId)
          .single();

      final tournamentTitle = tournament['title'];
      final organizerId = tournament['organizer_id'];
      final clubId = tournament['club_id'] as String?;
      final participantCount = standings.length;

      // Create completion post by club (if tournament belongs to club) or organizer
      if (organizerId != null && standings.isNotEmpty) {
        final champion = standings.first;

        final postContent =
            '''🏆 Giải đấu "$tournamentTitle" đã kết thúc!

🥇 Vô địch: ${champion['participant_name']}
👥 Tham gia: $participantCount người chơi
🎉 Chúc mừng tất cả các vận động viên!

#SABOArena #Tournament #Champion''';

        await _socialService.createPost(
          content: postContent,
          postType: 'tournament_completion',
          tournamentId: tournamentId,
          clubId: clubId, // IMPORTANT: Post belongs to club if tournament is club tournament
          hashtags: [
            'SABOArena',
            'Tournament',
            'Champion',
            tournamentTitle.replaceAll(' ', ''),
          ],
        );

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // Champion có thể tự động share achievement (optional)
      // Implementation sau nếu cần
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  // ==================== STATISTICS ====================

  /// Update tournament và user statistics
  Future<void> _updateTournamentStatistics(
    String tournamentId,
    List<Map<String, dynamic>> standings,
  ) async {
    try {
      // Update user tournament statistics
      for (final standing in standings) {
        final participantId = standing['participant_id'];
        final position = standing['position'] as int;

        // Update user profile với tournament results
        await _incrementUserStats(
          participantId,
          position == 1, // isWinner
          position <= 4, // isPodium (includes Đồng hạng 3)
        );
      }

      // Update club statistics (if tournament belongs to club)
      final tournament = await _supabase
          .from('tournaments')
          .select('club_id')
          .eq('id', tournamentId)
          .single();

      if (tournament['club_id'] != null) {
        // Get current tournaments_hosted count
        final clubData = await _supabase
            .from('clubs')
            .select('tournaments_hosted')
            .eq('id', tournament['club_id'])
            .single();

        final newCount = (clubData['tournaments_hosted'] ?? 0) + 1;
        await _supabase
            .from('clubs')
            .update({'tournaments_hosted': newCount})
            .eq('id', tournament['club_id']);
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  // ==================== COMPLETION REPORT ====================

  /// Generate completion report
  Future<Map<String, dynamic>> _generateCompletionReport(
    String tournamentId,
    List<Map<String, dynamic>> standings,
    List<Map<String, dynamic>> eloChanges,
    List<Map<String, dynamic>> prizeDistribution,
  ) async {
    final tournament = await _supabase
        .from('tournaments')
        .select('title, start_date, entry_fee, prize_pool, max_participants')
        .eq('id', tournamentId)
        .single();

    return {
      'tournament_info': {
        'id': tournamentId,
        'title': tournament['title'],
        'start_date': tournament['start_date'],
        'entry_fee': tournament['entry_fee'],
        'prize_pool': tournament['prize_pool'],
        'participants': standings.length,
        'max_participants': tournament['max_participants'],
      },
      'standings': standings.take(10).toList(), // Top 10
      'champion': standings.isNotEmpty ? standings.first : null,
      'elo_changes': eloChanges.length,
      'total_prize_distributed': prizeDistribution.fold<int>(
        0,
        (sum, prize) => sum + (prize['prize_amount'] as int),
      ),
      'completion_time': DateTime.now().toIso8601String(),
    };
  }

  // ==================== PUBLIC UTILITY METHODS ====================

  /// Get tournament completion status
  Future<Map<String, dynamic>> getTournamentCompletionStatus(
    String tournamentId,
  ) async {
    final validation = await _validateTournamentCompletion(tournamentId);
    return validation;
  }

  /// Preview final standings before completion
  Future<List<Map<String, dynamic>>> previewFinalStandings(
    String tournamentId,
  ) async {
    return await _calculateFinalStandings(tournamentId);
  }

  // ==================== AUTO COMPLETION DETECTION ====================

  /// Tự động kiểm tra và cập nhật trạng thái giải đấu nếu đã hoàn thành
  Future<bool> checkAndAutoCompleteTournament(String tournamentId) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // 1. Lấy thông tin giải đấu hiện tại
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('id, title, status, max_participants')
          .eq('id', tournamentId)
          .single();

      final tournament = tournamentResponse;

      // Nếu đã completed thì không cần kiểm tra nữa
      if (tournament['status'] == 'completed') {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return true;
      }

      // Chỉ xử lý tournaments đang active/in_progress/upcoming (có thể complete khi matches done)
      if (![
        'active',
        'in_progress',
        'ongoing',
        'upcoming',
      ].contains(tournament['status'])) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return false;
      }

      // 2. Kiểm tra validation completion
      final validationResult = await _validateTournamentCompletion(
        tournamentId,
      );

      if (validationResult['canComplete'] == true) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // 3. Tự động complete với minimal workflow
        await _autoCompleteTournamentMinimal(tournamentId);
        return true;
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return false;
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Minimal tournament completion - chỉ cập nhật status
  Future<void> _autoCompleteTournamentMinimal(String tournamentId) async {
    try {
      // 1. Tìm winner từ match cuối cùng
      final matchesResponse = await _supabase
          .from('matches')
          .select('winner_id, round_number, match_name')
          .eq('tournament_id', tournamentId)
          .eq('status', 'completed')
          .order('round_number', ascending: false);

      final matches = matchesResponse as List<dynamic>;
      String? winnerId;

      if (matches.isNotEmpty) {
        // Lấy winner từ round cao nhất
        final finalMatch = matches.first;
        winnerId = finalMatch['winner_id'];
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // 2. Cập nhật tournament status
      final updateData = {
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('tournaments')
          .update(updateData)
          .eq('id', tournamentId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // 3. Apply tournament rewards and update user stats
      await _applyTournamentRewards(tournamentId);

      // 4. Send completion notifications to all participants
      await _sendTournamentCompletionNotifications(tournamentId, winnerId);

      // 5. Log champion info
      if (winnerId != null) {
        await _logChampionInfo(tournamentId, winnerId);
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Apply tournament completion rewards (public method)
  Future<void> applyTournamentRewards(String tournamentId) async {
    await _applyTournamentRewards(tournamentId);
  }

  /// Apply tournament completion rewards
  Future<void> _applyTournamentRewards(String tournamentId) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get tournament info for notifications and transactions
      final tournamentData = await _supabase
          .from('tournaments')
          .select('title')
          .eq('id', tournamentId)
          .single();
      
      final tournamentTitle = tournamentData['title'] as String? ?? 'Tournament';

      // 1. Analyze tournament results
      final results = await _analyzeTournamentResults(tournamentId);

      // 2. Calculate and apply rewards
      for (final result in results) {
        final position = result['position'] as int;
        final wins = result['wins'] as int;
        final userId = result['user_id'] as String;
        final username = result['username'] as String;
        final currentElo = result['current_elo'] as int;

        // Calculate rewards based on position
        int eloBonus = 0;
        int spaBonus = 5; // Minimum participation reward

        if (position == 1) {
          // Champion
          eloBonus = 75; // ✅ 1st Place
          spaBonus = 200;
        } else if (position == 2) {
          // Runner-up
          eloBonus = 50; // ✅ 2nd Place (CORRECTED: was 60)
          spaBonus = 100;
        } else if (position == 3 || position == 4) {
          // Đồng hạng 3 (Both 3rd & 4th are "3rd place")
          eloBonus = 35; // ✅ Đồng hạng 3 (CORRECTED: was 45)
          spaBonus = 37; // Equal SPA for both
        } else if (position <= 8) {
          // Top 8
          eloBonus = 25; // ✅ Top 25%
          spaBonus = 10;
        }

        // Additional bonus for wins
        eloBonus += wins * 5;
        spaBonus += wins * 10;

        final newElo = currentElo + eloBonus;

        // ✅ 1. Update ELO rating
        await _supabase
            .from('users')
            .update({'elo_rating': newElo})
            .eq('id', userId);

        // ✅ 2. Create ELO History record for audit trail
        try {
          await _supabase.from('elo_history').insert({
            'user_id': userId,
            'old_elo': currentElo,
            'new_elo': newElo,
            'elo_change': eloBonus,
            'reason': 'tournament_completion',  // Required NOT NULL column
            'change_reason': 'tournament_completion',
            'tournament_id': tournamentId,
            'created_at': DateTime.now().toIso8601String(),
          });
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }

        // ✅ 3. Update SPA points using atomic function
        try {
          final positionText = position == 1 ? '🏆 Champion' :
                               position == 2 ? '🥈 Runner-up' :
                               position == 3 || position == 4 ? '🥉 Đồng hạng 3' :
                               position <= 8 ? 'Top 8' : 'Participant';
          
          final spaResult = await _supabase.rpc('atomic_increment_spa', params: {
            'p_user_id': userId,
            'p_amount': spaBonus,
            'p_transaction_type': 'tournament_reward',
            'p_description': 'Phần thưởng giải đấu "$tournamentTitle" - $positionText (Vị trí #$position, $wins thắng)',
            'p_reference_type': 'tournament',
            'p_reference_id': tournamentId,
          }) as List<dynamic>;

          if (spaResult.isNotEmpty) {
            final data = spaResult.first as Map<String, dynamic>;
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
          }
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }

        // ✅ 5. Update tournament statistics
        await _supabase
            .from('users')
            .update({
              'tournaments_played': result['tournaments_played'] + 1,
              'tournament_wins':
                  result['tournament_wins'] + (position == 1 ? 1 : 0),
            })
            .eq('id', userId);

        // ✅ 6. Send individual reward notification
        try {
          String notifTitle;
          String notifMessage;
          
          if (position == 1) {
            notifTitle = '👑 Chúc mừng nhà vô địch!';
            notifMessage = 'Bạn đã giành chiến thắng giải đấu "$tournamentTitle"! Phần thưởng: +$eloBonus ELO, +$spaBonus SPA 🏆';
          } else if (position == 2) {
            notifTitle = '🥈 Chúc mừng á quân!';
            notifMessage = 'Bạn đạt vị trí thứ 2 tại "$tournamentTitle"! Phần thưởng: +$eloBonus ELO, +$spaBonus SPA';
          } else if (position == 3 || position == 4) {
            notifTitle = '🥉 Chúc mừng đồng hạng 3!';
            notifMessage = 'Bạn đạt vị trí thứ $position tại "$tournamentTitle"! Phần thưởng: +$eloBonus ELO, +$spaBonus SPA';
          } else if (position <= 8) {
            notifTitle = '🎯 Top 8 - Xuất sắc!';
            notifMessage = 'Bạn đạt vị trí thứ $position tại "$tournamentTitle"! Phần thưởng: +$eloBonus ELO, +$spaBonus SPA';
          } else {
            notifTitle = '🎖️ Hoàn thành giải đấu';
            notifMessage = 'Cảm ơn bạn đã tham gia "$tournamentTitle"! Phần thưởng: +$eloBonus ELO, +$spaBonus SPA';
          }

          await _notificationService.sendNotification(
            userId: userId,
            title: notifTitle,
            message: notifMessage,
            type: 'tournament_reward',
            data: {
              'tournament_id': tournamentId,
              'tournament_title': tournamentTitle,
              'position': position,
              'elo_bonus': eloBonus,
              'spa_bonus': spaBonus,
              'wins': wins,
            },
          );
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }

        // Force update toàn bộ thống kê user
        try {
          await UserStatsUpdateService.instance.updateUserStats(userId);
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }

        // ✅ 7. Auto-issue tournament prize voucher (if configured)
        if (position <= 3) {
          try {
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
            
            final voucherResult = await _prizeVoucherService
                .issuePrizeVoucher(
                  tournamentId: tournamentId,
                  userId: userId,
                  position: position,
                );
            
            if (voucherResult['success'] == true) {
              final voucherValue = voucherResult['voucher_value'] as int;
              final voucherCode = voucherResult['voucher_code'] as String;
              
              ProductionLogger.debug('Debug log', tag: 'AutoFix');
              
              // Send additional notification about voucher
              try {
                const voucherNotifTitle = '🎁 Bạn nhận được Voucher giải thưởng!';
                final voucherNotifMessage = 
                    'Chúc mừng! Bạn nhận được voucher ${NumberFormatter.formatCurrency(voucherValue)} VND '
                    'từ giải đấu "$tournamentTitle". Voucher có thể dùng để thanh toán tiền bàn tại club!';
                
                await _notificationService.sendNotification(
                  userId: userId,
                  title: voucherNotifTitle,
                  message: voucherNotifMessage,
                  type: 'prize_voucher_received',
                  data: {
                    'tournament_id': tournamentId,
                    'tournament_title': tournamentTitle,
                    'voucher_id': voucherResult['user_voucher_id'],
                    'voucher_code': voucherCode,
                    'voucher_value': voucherValue,
                    'position': position,
                  },
                );
                ProductionLogger.debug('Debug log', tag: 'AutoFix');
              } catch (notifError) {
                ProductionLogger.debug('Debug log', tag: 'AutoFix');
              }
            } else {
              ProductionLogger.debug('Debug log', tag: 'AutoFix');
            }
          } catch (voucherError) {
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
            // Không throw error - để tournament completion tiếp tục
          }
        }

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Analyze tournament results and calculate positions
  Future<List<Map<String, dynamic>>> _analyzeTournamentResults(
    String tournamentId,
  ) async {
    // Get participants
    final participantsResponse = await _supabase
        .from('tournament_participants')
        .select(
          'user_id, users!inner(username, full_name, elo_rating, spa_points, tournaments_played, tournament_wins)',
        )
        .eq('tournament_id', tournamentId);

    final participants = participantsResponse as List<dynamic>;

    // Get matches
    final matchesResponse = await _supabase
        .from('matches')
        .select('*')
        .eq('tournament_id', tournamentId);

    final matches = matchesResponse as List<dynamic>;

    // Calculate performance for each user
    final results = <Map<String, dynamic>>[];

    for (final participant in participants) {
      final userId = participant['user_id'] as String;
      final user = participant['users'] as Map<String, dynamic>;

      // Calculate wins/losses
      final userMatches = matches
          .where((m) => m['player1_id'] == userId || m['player2_id'] == userId)
          .toList();

      final wins = userMatches.where((m) => m['winner_id'] == userId).length;
      final losses = userMatches
          .where((m) => m['winner_id'] != null && m['winner_id'] != userId)
          .length;

      results.add({
        'user_id': userId,
        'username': user['username'] ?? 'Unknown',
        'wins': wins,
        'losses': losses,
        'matches_played': userMatches.length,
        'win_rate': userMatches.isNotEmpty ? wins / userMatches.length : 0.0,
        'current_elo': user['elo_rating'] ?? 1000,
        'current_spa': user['spa_points'] ?? 0,
        'tournaments_played': user['tournaments_played'] ?? 0,
        'tournament_wins': user['tournament_wins'] ?? 0,
      });
    }

    // Sort by wins, then win rate
    results.sort((a, b) {
      final winsCompare = (b['wins'] as int).compareTo(a['wins'] as int);
      if (winsCompare != 0) return winsCompare;
      return (b['win_rate'] as double).compareTo(a['win_rate'] as double);
    });

    // Assign positions
    for (int i = 0; i < results.length; i++) {
      results[i]['position'] = i + 1;
    }

    return results;
  }

  /// Log thông tin champion
  Future<void> _logChampionInfo(String tournamentId, String winnerId) async {
    try {
      final results = await Future.wait([
        _supabase
            .from('users')
            .select('username, full_name')
            .eq('id', winnerId)
            .maybeSingle(),
        _supabase
            .from('tournaments')
            .select('title')
            .eq('id', tournamentId)
            .single(),
      ]);

      final winner = results[0];
      final tournament = results[1];

      if (winner != null) {
        final winnerName =
            winner['display_name'] ?? winner['full_name'] ?? winner['username'] ?? 'Unknown';
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Quét tất cả giải đấu active để tự động complete
  Future<int> scanAndAutoCompleteActiveTournaments() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final tournamentsResponse = await _supabase
          .from('tournaments')
          .select('id, title, status')
          .or('status.eq.active,status.eq.in_progress,status.eq.ongoing');

      final tournaments = tournamentsResponse as List<dynamic>;

      if (tournaments.isEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return 0;
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      int completedCount = 0;
      for (final tournament in tournaments) {
        final wasCompleted = await checkAndAutoCompleteTournament(
          tournament['id'],
        );
        if (wasCompleted) {
          completedCount++;
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return completedCount;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return 0;
    }
  }

  /// Send tournament completion notifications to all participants
  Future<void> _sendTournamentCompletionNotifications(
    String tournamentId,
    String? winnerId,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get tournament info
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('title, club_id')
          .eq('id', tournamentId)
          .single();

      final tournament = tournamentResponse;
      final tournamentTitle = tournament['title'] ?? 'Tournament';

      // Get winner info if available
      String championName = 'Unknown Champion';
      if (winnerId != null) {
        final winnerResponse = await _supabase
            .from('users')
            .select('username, full_name')
            .eq('id', winnerId)
            .maybeSingle();

        if (winnerResponse != null) {
          championName =
              winnerResponse['display_name'] ?? winnerResponse['full_name'] ??
              winnerResponse['username'] ??
              'Unknown Champion';
        }
      }

      // Get all participants
      final participantsResponse = await _supabase
          .from('tournament_participants')
          .select('user_id')
          .eq('tournament_id', tournamentId);

      final participants = participantsResponse as List<dynamic>;

      // Send notifications to all participants
      int notificationsSent = 0;

      for (final participant in participants) {
        final userId = participant['user_id'] as String;

        try {
          // Tournament completion notification
          await _notificationService.sendNotification(
            userId: userId,
            title: '🏆 Giải đấu hoàn thành!',
            message:
                'Giải đấu "$tournamentTitle" đã kết thúc. Chúc mừng nhà vô địch $championName! 🎉',
            type: 'tournament_completed',
            data: {
              'tournament_id': tournamentId,
              'tournament_title': tournamentTitle,
              'champion_id': winnerId,
              'champion_name': championName,
            },
          );

          // Individual reward notification (if user received rewards)
          if (userId == winnerId) {
            // Champion notification
            await _notificationService.sendNotification(
              userId: userId,
              title: '👑 Chúc mừng nhà vô địch!',
              message:
                  'Bạn đã giành chiến thắng giải đấu "$tournamentTitle"! Phần thưởng ELO và SPA đã được cộng vào tài khoản. 🏆',
              type: 'tournament_champion',
              data: {
                'tournament_id': tournamentId,
                'tournament_title': tournamentTitle,
                'position': 1,
              },
            );
          } else {
            // Participation reward notification
            await _notificationService.sendNotification(
              userId: userId,
              title: '🎁 Phần thưởng tham gia',
              message:
                  'Cảm ơn bạn đã tham gia giải đấu "$tournamentTitle". Phần thưởng ELO và SPA đã được cộng vào tài khoản!',
              type: 'tournament_reward',
              data: {
                'tournament_id': tournamentId,
                'tournament_title': tournamentTitle,
              },
            );
          }

          notificationsSent += 2; // 2 notifications per user
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }
}

