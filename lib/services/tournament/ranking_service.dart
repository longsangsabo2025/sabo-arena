import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service for calculating tournament rankings and standings
class RankingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Calculate final standings for a tournament
  /// Returns list of participants with their positions AND ALL REWARD DATA
  /// This is the SINGLE SOURCE OF TRUTH for all rewards (SPA, ELO, Prize Money)
  Future<List<Map<String, dynamic>>> calculateFinalStandings({
    required String tournamentId,
  }) async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Get tournament details (format + rewards config)
    final tournament = await _supabase
        .from('tournaments')
        .select('bracket_format, prize_pool, elo_enabled, prize_distribution')
        .eq('id', tournamentId)
        .single();

    final format = tournament['bracket_format'] as String? ?? 'single_elimination';
    final prizePool = (tournament['prize_pool'] as num?)?.toDouble() ?? 0.0;
    final eloEnabled = tournament['elo_enabled'] as bool? ?? false;
    final prizeDistribution = tournament['prize_distribution'] as Map<String, dynamic>?;
    
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Use format-specific ranking
    List<Map<String, dynamic>> standings;
    if (format == 'round_robin') {
      standings = await _calculateRoundRobinStandings(tournamentId);
    } else {
      // Elimination formats (single, double, sabo, etc.)
      standings = await _calculateEliminationStandings(tournamentId);
    }

    // CRITICAL: Calculate ALL rewards based on POSITION (not rank)
    // This is the SINGLE calculation that tournament_results will store
    final participantCount = standings.length;
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    
    for (int i = 0; i < standings.length; i++) {
      final position = standings[i]['position'] as int;
      final wins = standings[i]['wins'] as int? ?? 0;
      
      // Calculate SPA reward (position bonus + wins bonus)
      final spaReward = _calculateSpaReward(position, participantCount, wins);
      
      // Calculate ELO change (position-based, same as old EloUpdateService)
      final eloChange = eloEnabled ? _calculateEloChange(position, participantCount) : 0;
      
      // Calculate prize money (position-based from distribution template)
      final prizeMoney = _calculatePrizeMoney(position, prizePool, prizeDistribution);
      
      // Add reward data to standing (this becomes source of truth)
      standings[i]['spa_reward'] = spaReward;
      standings[i]['elo_change'] = eloChange;
      standings[i]['prize_money_vnd'] = prizeMoney;
      
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    return standings;
  }
  
  /// Calculate SPA reward based on position
  /// Uses POSITION-BASED BONUS logic (like old system)
  /// NOT prize pool distribution (since many tournaments have prize_pool = 0)
  int _calculateSpaReward(int position, int participantCount, int wins) {
    // Base position bonus (correct values from old system)
    int baseBonus;
    if (position == 1) {
      baseBonus = 200;
    } else if (position == 2) {
      baseBonus = 100;
    } else if (position == 3) {
      baseBonus = 50;
    } else if (position == 4) {
      baseBonus = 25;
    } else {
      baseBonus = 10; // All other positions
    }
    
    // Wins bonus: +10 SPA per win (like old system)
    final winsBonus = wins * 10;
    
    return baseBonus + winsBonus;
  }
  
  /// Calculate ELO change based on position
  /// ✅ FIXED: Use CORRECT logic copied from TournamentRankingsWidget
  /// ELO range: -5 to +75 (not the previous smaller realistic values)
  int _calculateEloChange(int position, int participantCount) {
    if (position == 1) {
      return 75; // ✅ 1st Place: +75 ELO (was +25)
    } else if (position == 2) {
      return 50; // ✅ 2nd Place: +50 ELO (was +15)
    } else if (position == 3 || position == 4) {
      return 35; // ✅ Đồng hạng 3 (Both 3rd & 4th): +35 ELO (was +10/+5)
    } else if (position <= participantCount * 0.25) {
      return 25; // ✅ Top 25%: +25 ELO
    } else if (position <= participantCount * 0.5) {
      return 15; // ✅ Top 50%: +15 ELO (was 0)
    } else if (position <= participantCount * 0.75) {
      return 10; // ✅ Top 75%: +10 ELO
    } else {
      return -5; // ✅ Bottom 25%: -5 ELO (unchanged)
    }
  }
  
  /// Calculate prize money based on position and distribution
  /// Returns VND amount
  double _calculatePrizeMoney(int position, double prizePool, Map<String, dynamic>? distribution) {
    if (prizePool == 0 || distribution == null) return 0.0;
    
    // Distribution format: { "1": 40, "2": 30, "3": 20, "4": 10 } (percentages)
    final percentage = distribution[position.toString()] as num? ?? 0;
    return prizePool * (percentage / 100.0);
  }

  /// Calculate standings for elimination formats
  Future<List<Map<String, dynamic>>> _calculateEliminationStandings(
    String tournamentId,
  ) async {

    // 🆕 FIX: Get ALL tournament participants first (not just from matches)
    final participantsResponse = await _supabase
        .from('tournament_participants')
        .select('''
          user_id,
          users:users!tournament_participants_user_id_fkey(id, full_name, display_name)
        ''')
        .eq('tournament_id', tournamentId);

    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Initialize all participants with 0 wins/losses
    final winCounts = <String, int>{};
    final lossCounts = <String, int>{};
    final participantNames = <String, String>{};
    
    for (final participant in participantsResponse) {
      final userId = participant['user_id'] as String;
      final userData = participant['users'] as Map<String, dynamic>?;
      
      winCounts[userId] = 0; // ✅ Initialize everyone
      lossCounts[userId] = 0; // ✅ Initialize everyone
      participantNames[userId] = userData?['display_name'] ?? userData?['full_name'] ?? 'Unknown';
    }

    // Get all completed matches WITH USER NAMES (JOIN with users table)
    final matches = await _supabase
        .from('matches')
        .select('''
          *,
          player1:users!matches_player1_id_fkey(id, full_name, display_name),
          player2:users!matches_player2_id_fkey(id, full_name, display_name)
        ''')
        .eq('tournament_id', tournamentId)
        .eq('status', 'completed');

    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Track final/semi-final results
    final participantRounds = <String, String>{}; // Track highest round reached
    
    String? championId;
    String? runnerUpId;
    final semifinalistIds = <String>[];

    for (final match in matches) {
      final winnerId = match['winner_id'] as String?;
      final round = match['round'] as String?;
      final player1Id = match['player1_id'] as String?;
      final player2Id = match['player2_id'] as String?;
      
      // Count wins and losses
      if (winnerId != null) {
        winCounts[winnerId] = (winCounts[winnerId] ?? 0) + 1;
        
        // Loser is the other player
        final loserId = (winnerId == player1Id) ? player2Id : player1Id;
        if (loserId != null) {
          lossCounts[loserId] = (lossCounts[loserId] ?? 0) + 1;
        }
      }

      // Update participant names from match data (in case different from registration)
      final player1Data = match['player1'] as Map<String, dynamic>?;
      final player2Data = match['player2'] as Map<String, dynamic>?;

      if (player1Id != null && player1Data != null) {
        participantNames[player1Id] = player1Data['display_name'] ?? player1Data['full_name'] ?? participantNames[player1Id] ?? 'Unknown Player';
      }
      if (player2Id != null && player2Data != null) {
        participantNames[player2Id] = player2Data['display_name'] ?? player2Data['full_name'] ?? participantNames[player2Id] ?? 'Unknown Player';
      }

      // Identify key positions based on final/semi-final
      if (round == 'final') {
        championId = winnerId;
        runnerUpId = (winnerId == player1Id) ? player2Id : player1Id;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } else if (round == 'semi-final' || round == 'semifinals') {
        final loserId = (winnerId == player1Id) ? player2Id : player1Id;
        if (loserId != null) {
          semifinalistIds.add(loserId);
        }
      }
      
      // Track highest round reached
      if (round != null) {
        if (player1Id != null) {
          _updateHighestRound(participantRounds, player1Id, round);
        }
        if (player2Id != null) {
          _updateHighestRound(participantRounds, player2Id, round);
        }
      }
    }

    // Create standings list with CORRECT positioning
    final standings = <Map<String, dynamic>>[];
    
    // Position 1: Champion (winner of final)
    if (championId != null) {
      standings.add({
        'participant_id': championId,
        'participant_name': participantNames[championId] ?? 'Unknown',
        'wins': winCounts[championId] ?? 0,
        'losses': lossCounts[championId] ?? 0,
        'position': 1,
      });
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
    
    // Position 2: Runner-up (loser of final)
    if (runnerUpId != null) {
      standings.add({
        'participant_id': runnerUpId,
        'participant_name': participantNames[runnerUpId] ?? 'Unknown',
        'wins': winCounts[runnerUpId] ?? 0,
        'losses': lossCounts[runnerUpId] ?? 0,
        'position': 2,
      });
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
    
    // Position 3&4: Semi-finalists (losers of semi-final)
    int position = 3;
    for (final semifinalistId in semifinalistIds) {
      if (semifinalistId != championId && semifinalistId != runnerUpId) {
        standings.add({
          'participant_id': semifinalistId,
          'participant_name': participantNames[semifinalistId] ?? 'Unknown',
          'wins': winCounts[semifinalistId] ?? 0,
          'losses': lossCounts[semifinalistId] ?? 0,
          'position': position,
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        position++;
      }
    }
    
    // Remaining participants: ALL participants not yet assigned (includes 0-win participants)
    final assignedIds = {championId, runnerUpId, ...semifinalistIds};
    final remainingParticipants = <Map<String, dynamic>>[];
    
    // 🆕 FIX: Include ALL participants (even those with 0 wins)
    participantNames.forEach((participantId, name) {
      if (!assignedIds.contains(participantId)) {
        remainingParticipants.add({
          'participant_id': participantId,
          'participant_name': name,
          'wins': winCounts[participantId] ?? 0, // Will be 0 for non-match participants
          'losses': lossCounts[participantId] ?? 0,
        });
      }
    });
    
    // Sort remaining by wins (descending)
    remainingParticipants.sort((a, b) => (b['wins'] as int).compareTo(a['wins'] as int));
    
    // Assign positions to remaining
    for (final participant in remainingParticipants) {
      participant['position'] = position;
      standings.add(participant);
      position++;
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    
    // Log top 4
    for (int i = 0; i < standings.length && i < 4; i++) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }

    return standings;
  }
  
  /// Update highest round reached for a participant
  void _updateHighestRound(Map<String, String> participantRounds, String participantId, String round) {
    final roundPriority = {
      'final': 4,
      'semi-final': 3,
      'semifinals': 3,
      'quarter-final': 2,
      'quarterfinals': 2,
      'round-16': 1,
      'round-32': 0,
    };
    
    final currentRound = participantRounds[participantId];
    final currentPriority = roundPriority[currentRound] ?? -1;
    final newPriority = roundPriority[round] ?? -1;
    
    if (newPriority > currentPriority) {
      participantRounds[participantId] = round;
    }
  }

  /// Calculate standings for Round Robin format
  Future<List<Map<String, dynamic>>> _calculateRoundRobinStandings(
    String tournamentId,
  ) async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Get all participants
    final participants = await _supabase
        .from('tournament_participants')
        .select('''
          user_id,
          users!inner(id, full_name, username)
        ''')
        .eq('tournament_id', tournamentId);

    // Get all completed matches
    final matches = await _supabase
        .from('matches')
        .select('player1_id, player2_id, winner_id, player1_score, player2_score')
        .eq('tournament_id', tournamentId)
        .eq('status', 'completed');

    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    final standings = <Map<String, dynamic>>[];

    for (final participant in participants) {
      final playerId = participant['user_id'] as String;
      final user = participant['users'] as Map<String, dynamic>;
      final participantName = user['username'] ?? user['full_name'] ?? 'Unknown';

      // Find all matches for this player
      final playerMatches = matches.where(
        (m) => m['player1_id'] == playerId || m['player2_id'] == playerId,
      ).toList();

      int wins = 0;
      int losses = 0;
      int gamesWon = 0;
      int gamesLost = 0;

      for (final match in playerMatches) {
        final isPlayer1 = match['player1_id'] == playerId;
        final playerScore = (isPlayer1 ? match['player1_score'] : match['player2_score']) as int? ?? 0;
        final opponentScore = (isPlayer1 ? match['player2_score'] : match['player1_score']) as int? ?? 0;

        gamesWon += playerScore;
        gamesLost += opponentScore;

        if (match['winner_id'] == playerId) {
          wins++;
        } else if (match['winner_id'] != null) {
          losses++;
        }
      }

      standings.add({
        'participant_id': playerId,
        'participant_name': participantName,
        'matches_played': playerMatches.length,
        'matches_won': wins,
        'matches_lost': losses,
        'wins': wins,
        'losses': losses,
        'games_won': gamesWon,
        'games_lost': gamesLost,
        'game_difference': gamesWon - gamesLost,
        'win_percentage': playerMatches.isEmpty ? 0 : (wins / playerMatches.length * 100).round(),
        'points': wins * 3, // 3 points per match win
      });
    }

    // Sort by: points > win% > game difference
    standings.sort((a, b) {
      final pointsCompare = (b['points'] as int).compareTo(a['points'] as int);
      if (pointsCompare != 0) return pointsCompare;

      final winPercentageCompare = (b['win_percentage'] as int).compareTo(a['win_percentage'] as int);
      if (winPercentageCompare != 0) return winPercentageCompare;

      return (b['game_difference'] as int).compareTo(a['game_difference'] as int);
    });

    // Assign positions
    for (int i = 0; i < standings.length; i++) {
      standings[i]['position'] = i + 1;
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    for (int i = 0; i < standings.length && i < 4; i++) {
      final s = standings[i];
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }

    return standings;
  }
}

