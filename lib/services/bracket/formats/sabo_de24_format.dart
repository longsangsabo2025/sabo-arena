import 'package:supabase_flutter/supabase_flutter.dart';
import '../../universal_match_progression_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 🏆 SABO DE24 Tournament Format Service
///
/// Structure:
/// - 24 players total
/// - GROUP STAGE: 8 groups of 3 players each
///   • Round-robin within each group (3 matches per group)
///   • Top 2 from each group advance (16 players)
///   • Bottom 1 from each group eliminated (8 players)
/// - MAIN STAGE: SABO DE16 format (27 matches)
///   • Winners Bracket: 14 matches (R1: 8, R2: 4, R3: 2) - stops at R3, no WB Finals
///   • Loser Branch A: 7 matches (WB R1 losers)
///   • Loser Branch B: 3 matches (WB R2 losers)
///   • SABO Finals: 3 matches (2 from WB R3 + 2 from LB)
///
/// Total Matches: 24 (Group) + 27 (SABO DE16) = 51 matches
class HardcodedSaboDE24Service {
  final SupabaseClient _supabase;

  HardcodedSaboDE24Service(this._supabase);

  Future<Map<String, dynamic>> createBracketWithAdvancement({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    await createDE24Tournament(
      tournamentId: tournamentId,
      participantIds: participantIds,
    );
    return {
      'success': true,
      'message': 'SABO DE24 bracket created successfully',
      'tournamentId': tournamentId,
    };
  }

  /// Create SABO DE24 tournament structure
  Future<void> createDE24Tournament({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    if (participantIds.length != 24) {
      throw Exception('SABO DE24 requires exactly 24 participants');
    }

    // Shuffle participants for random group assignment
    final shuffled = List<String>.from(participantIds)..shuffle();

    final matches = <Map<String, dynamic>>[];
    int matchNumber = 1;

    // ==========================================
    // PHASE 1: GROUP STAGE (8 groups × 3 players)
    // ==========================================

    for (int group = 0; group < 8; group++) {
      // Get 3 players for this group
      final groupPlayers = shuffled.sublist(group * 3, (group + 1) * 3);
      final groupName =
          String.fromCharCode(65 + group); // A, B, C, D, E, F, G, H

      // Round-robin: 3 matches per group
      // Match 1: Player 0 vs Player 1
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: 1000 + (group * 10) + 1,
        round: 'Group $groupName',
        player1Id: groupPlayers[0],
        player2Id: groupPlayers[1],
        bracketType:
            'groups', // Changed from 'group_stage' (11 chars) to 'groups' (6 chars) - fits VARCHAR(10)
        metadata: {
          'group': groupName,
          'group_match': 1,
        },
      ));

      // Match 2: Player 0 vs Player 2
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: 1000 + (group * 10) + 2,
        round: 'Group $groupName',
        player1Id: groupPlayers[0],
        player2Id: groupPlayers[2],
        bracketType:
            'groups', // Changed from 'group_stage' (11 chars) to 'groups' (6 chars) - fits VARCHAR(10)
        metadata: {
          'group': groupName,
          'group_match': 2,
        },
      ));

      // Match 3: Player 1 vs Player 2
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: 1000 + (group * 10) + 3,
        round: 'Group $groupName',
        player1Id: groupPlayers[1],
        player2Id: groupPlayers[2],
        bracketType:
            'groups', // Changed from 'group_stage' (11 chars) to 'groups' (6 chars) - fits VARCHAR(10)
        metadata: {
          'group': groupName,
          'group_match': 3,
        },
      ));
    }

    // ==========================================
    // PHASE 2: MAIN STAGE - SABO DE16 FORMAT
    // ==========================================
    // Create SABO DE16 bracket structure (27 matches)
    // Players will be filled after group stage completion

    // Generate advancement map for SABO DE16
    final advancementMap = _calculateAdvancementMap();

    // ===== WINNERS BRACKET (14 matches, stops at R3) =====
    // WB Round 1: 16 → 8 (8 matches)
    for (int i = 0; i < 8; i++) {
      final displayOrder = 1101 + i;
      final advancement = advancementMap[displayOrder]!;
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: displayOrder,
        round: 'WB R1',
        roundNumber: 1,
        player1Id: null,
        player2Id: null,
        bracketType: 'WB',
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ));
    }

    // WB Round 2: 8 → 4 (4 matches)
    for (int i = 0; i < 4; i++) {
      final displayOrder = 1201 + i;
      final advancement = advancementMap[displayOrder]!;
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: displayOrder,
        round: 'WB R2',
        roundNumber: 2,
        bracketType: 'WB',
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ));
    }

    // WB Round 3: 4 → 2 (2 matches) - STOPS HERE, no WB Finals
    for (int i = 0; i < 2; i++) {
      final displayOrder = 1301 + i;
      final advancement = advancementMap[displayOrder]!;
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: displayOrder,
        round: 'WB R3',
        roundNumber: 3,
        bracketType: 'WB',
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ));
    }

    // ===== LOSER BRANCH A (7 matches - WB R1 losers) =====
    // LB-A Round 1: 8 losers from WB R1 → 4 (4 matches)
    for (int i = 0; i < 4; i++) {
      final displayOrder = 2101 + i;
      final advancement = advancementMap[displayOrder]!;
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: displayOrder,
        round: 'LB-A R1',
        roundNumber: 1,
        bracketType: 'LB-A',
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ));
    }

    // LB-A Round 2: 4 → 2 (2 matches)
    for (int i = 0; i < 2; i++) {
      final displayOrder = 2201 + i;
      final advancement = advancementMap[displayOrder]!;
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: displayOrder,
        round: 'LB-A R2',
        roundNumber: 2,
        bracketType: 'LB-A',
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ));
    }

    // LB-A Final: 2 → 1 (1 match)
    final lbaFinalAdvancement = advancementMap[2301]!;
    matches.add(_createMatch(
      tournamentId: tournamentId,
      matchNumber: matchNumber++,
      displayOrder: 2301,
      round: 'LB-A Final',
      roundNumber: 3,
      bracketType: 'LB-A',
      winnerAdvancesTo: lbaFinalAdvancement['winner'],
      loserAdvancesTo: lbaFinalAdvancement['loser'],
    ));

    // ===== LOSER BRANCH B (3 matches - WB R2 losers) =====
    // LB-B Round 1: 4 losers from WB R2 → 2 (2 matches)
    for (int i = 0; i < 2; i++) {
      final displayOrder = 3101 + i;
      final advancement = advancementMap[displayOrder]!;
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: displayOrder,
        round: 'LB-B R1',
        roundNumber: 1,
        bracketType: 'LB-B',
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ));
    }

    // LB-B Final: 2 → 1 (1 match)
    final lbbFinalAdvancement = advancementMap[3201]!;
    matches.add(_createMatch(
      tournamentId: tournamentId,
      matchNumber: matchNumber++,
      displayOrder: 3201,
      round: 'LB-B Final',
      roundNumber: 2,
      bracketType: 'LB-B',
      winnerAdvancesTo: lbbFinalAdvancement['winner'],
      loserAdvancesTo: lbbFinalAdvancement['loser'],
    ));

    // ===== SABO FINALS (3 matches - 4 players: 2 from WB R3, 1 from LB-A, 1 from LB-B) =====
    // Semifinals: 4 → 2 (2 matches)
    for (int i = 0; i < 2; i++) {
      final displayOrder = 4101 + i;
      final advancement = advancementMap[displayOrder]!;
      matches.add(_createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber++,
        displayOrder: displayOrder,
        round: 'SABO Semi',
        roundNumber: 1,
        bracketType: 'SABO',
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ));
    }

    // Final: 2 → 1 (1 match)
    final finalAdvancement = advancementMap[4201]!;
    matches.add(_createMatch(
      tournamentId: tournamentId,
      matchNumber: matchNumber++,
      displayOrder: 4201,
      round: 'SABO Final',
      roundNumber: 2,
      bracketType: 'SABO',
      winnerAdvancesTo: finalAdvancement['winner'],
      loserAdvancesTo: finalAdvancement['loser'],
    ));

    // Insert all matches (24 Group + 27 SABO DE16 = 51 total)
    await _supabase.from('matches').insert(matches);

    ProductionLogger.info(
        '✅ Created SABO DE24 tournament: ${matches.length} matches',
        tag: 'hardcoded_sabo_de24_service');
    ProductionLogger.info(
        '   📊 Group Stage: 24 matches (8 groups × 3 matches)',
        tag: 'hardcoded_sabo_de24_service');
    ProductionLogger.info(
        '   🏆 Main Stage SABO DE16: 27 matches (WB: 14, LB-A: 7, LB-B: 3, Finals: 3)',
        tag: 'hardcoded_sabo_de24_service');
  }

  /// Helper to create match data
  Map<String, dynamic> _createMatch({
    required String tournamentId,
    required int matchNumber,
    required int displayOrder,
    required String round,
    String? player1Id,
    String? player2Id,
    String? bracketType,
    int? roundNumber,
    int? winnerAdvancesTo,
    int? loserAdvancesTo,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'tournament_id': tournamentId,
      'match_number': matchNumber,
      'display_order': displayOrder,
      'round': round,
      'round_number': roundNumber,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'status':
          'pending', // All group matches start as 'pending', valid values: pending, in_progress, completed
      'bracket_type': bracketType,
      'winner_advances_to': winnerAdvancesTo,
      'loser_advances_to': loserAdvancesTo,
      'player1_score': 0,
      'player2_score': 0,
      // Note: metadata column doesn't exist in matches table, storing info in other columns
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Calculate advancement mapping for SABO DE16 structure
  /// Returns map of {display_order → {winner: next_display_order, loser: next_display_order}}
  Map<int, Map<String, int?>> _calculateAdvancementMap() {
    final map = <int, Map<String, int?>>{};

    // ========== WINNER BRACKET (14 matches) ==========

    // WB Round 1 (8 matches: display_order 1101-1108)
    // Winners → WB R2 (1201-1204)
    // Losers → LB-A R1 (2101-2104)
    map[1101] = {'winner': 1201, 'loser': 2101};
    map[1102] = {'winner': 1201, 'loser': 2101};
    map[1103] = {'winner': 1202, 'loser': 2102};
    map[1104] = {'winner': 1202, 'loser': 2102};
    map[1105] = {'winner': 1203, 'loser': 2103};
    map[1106] = {'winner': 1203, 'loser': 2103};
    map[1107] = {'winner': 1204, 'loser': 2104};
    map[1108] = {'winner': 1204, 'loser': 2104};

    // WB Round 2 (4 matches: display_order 1201-1204)
    // Winners → WB R3 (1301-1302)
    // Losers → LB-B R1 (3101-3102)
    map[1201] = {'winner': 1301, 'loser': 3101};
    map[1202] = {'winner': 1301, 'loser': 3101};
    map[1203] = {'winner': 1302, 'loser': 3102};
    map[1204] = {'winner': 1302, 'loser': 3102};

    // WB Round 3 (2 matches: display_order 1301-1302)
    // ⚠️ NO LOSER ADVANCEMENT - WB stops here!
    // Winners → SABO Finals semifinals (4101, 4102)
    map[1301] = {'winner': 4101, 'loser': null};
    map[1302] = {'winner': 4102, 'loser': null};

    // ========== LOSER BRANCH A (7 matches) ==========

    // LB-A Round 1 (4 matches: display_order 2101-2104)
    // Receive: 8 WB R1 losers
    // Winners → LB-A R2 (2201-2202)
    map[2101] = {'winner': 2201, 'loser': null};
    map[2102] = {'winner': 2201, 'loser': null};
    map[2103] = {'winner': 2202, 'loser': null};
    map[2104] = {'winner': 2202, 'loser': null};

    // LB-A Round 2 (2 matches: display_order 2201-2202)
    // Winners → LB-A Final (2301)
    map[2201] = {'winner': 2301, 'loser': null};
    map[2202] = {'winner': 2301, 'loser': null};

    // LB-A Round 3 / Final (1 match: display_order 2301)
    // Winner → SABO Finals Semi1 (4101)
    map[2301] = {'winner': 4101, 'loser': null};

    // ========== LOSER BRANCH B (3 matches) ==========

    // LB-B Round 1 (2 matches: display_order 3101-3102)
    // Receive: 4 WB R2 losers
    // Winners → LB-B Final (3201)
    map[3101] = {'winner': 3201, 'loser': null};
    map[3102] = {'winner': 3201, 'loser': null};

    // LB-B Round 2 / Final (1 match: display_order 3201)
    // Winner → SABO Finals Semi2 (4102)
    map[3201] = {'winner': 4102, 'loser': null};

    // ========== SABO FINALS (3 matches) ==========

    // Semifinal 1 (1 match: display_order 4101)
    // Receives: WB R3 1301 winner + LB-A champion (2301)
    // Winner → SABO Finals (4201)
    map[4101] = {'winner': 4201, 'loser': null};

    // Semifinal 2 (1 match: display_order 4102)
    // Receives: WB R3 1302 winner + LB-B champion (3201)
    // Winner → SABO Finals (4201)
    map[4102] = {'winner': 4201, 'loser': null};

    // SABO Finals (1 match: display_order 4201)
    // Receives: Semi1 winner + Semi2 winner
    // Winner = TOURNAMENT CHAMPION
    map[4201] = {'winner': null, 'loser': null};

    return map;
  }

  /// Calculate group standings and determine top 2 from each group
  Future<List<String>> calculateGroupStandings({
    required String tournamentId,
    required String groupName,
  }) async {
    // Get all matches for this group
    final matches = await _supabase
        .from('matches')
        .select('*')
        .eq('tournament_id', tournamentId)
        .eq('round', 'Group $groupName')
        .eq('status', 'completed');

    // Calculate standings: wins, losses, score difference (for tiebreaker)
    final standings = <String, Map<String, dynamic>>{};

    for (final match in matches) {
      final player1Id = match['player1_id'] as String;
      final player2Id = match['player2_id'] as String;
      final winnerId = match['winner_id'] as String?;
      final player1Score = (match['player1_score'] ?? 0) as int;
      final player2Score = (match['player2_score'] ?? 0) as int;

      // Initialize player stats
      standings.putIfAbsent(
          player1Id,
          () => {
                'player_id': player1Id,
                'wins': 0,
                'losses': 0,
                'points': 0,
                'score_for': 0, // Total points scored
                'score_against': 0, // Total points conceded
                'score_diff': 0, // Difference (for - against)
              });
      standings.putIfAbsent(
          player2Id,
          () => {
                'player_id': player2Id,
                'wins': 0,
                'losses': 0,
                'points': 0,
                'score_for': 0,
                'score_against': 0,
                'score_diff': 0,
              });

      // Update scores
      standings[player1Id]!['score_for'] += player1Score;
      standings[player1Id]!['score_against'] += player2Score;
      standings[player2Id]!['score_for'] += player2Score;
      standings[player2Id]!['score_against'] += player1Score;

      // Update wins/losses
      if (winnerId == player1Id) {
        standings[player1Id]!['wins'] += 1;
        standings[player1Id]!['points'] += 3;
        standings[player2Id]!['losses'] += 1;
      } else if (winnerId == player2Id) {
        standings[player2Id]!['wins'] += 1;
        standings[player2Id]!['points'] += 3;
        standings[player1Id]!['losses'] += 1;
      }
    }

    // Calculate score difference for each player
    for (final playerStats in standings.values) {
      playerStats['score_diff'] =
          playerStats['score_for'] - playerStats['score_against'];
    }

    // Sort by: 1) points, 2) score difference, 3) score_for
    final sortedStandings = standings.values.toList()
      ..sort((a, b) {
        // Primary: Points (descending)
        final pointsDiff = (b['points'] as int).compareTo(a['points'] as int);
        if (pointsDiff != 0) return pointsDiff;

        // Secondary: Score difference (descending)
        final scoreDiff =
            (b['score_diff'] as int).compareTo(a['score_diff'] as int);
        if (scoreDiff != 0) return scoreDiff;

        // Tertiary: Total score for (descending)
        return (b['score_for'] as int).compareTo(a['score_for'] as int);
      });

    // Return top 2 player IDs
    return sortedStandings
        .take(2)
        .map((s) => s['player_id'] as String)
        .toList();
  }

  /// Advance group winners to DE16 main stage
  Future<void> advanceGroupWinnersToMainStage(String tournamentId) async {
    ProductionLogger.info('🎯 Advancing group winners to DE16 main stage...',
        tag: 'hardcoded_sabo_de24_service');

    final qualifiers = <String>[];

    // Process each group
    for (int i = 0; i < 8; i++) {
      final groupName = String.fromCharCode(65 + i); // A-H
      final topTwo = await calculateGroupStandings(
        tournamentId: tournamentId,
        groupName: groupName,
      );

      qualifiers.addAll(topTwo);
      ProductionLogger.info(
          '   ✅ Group $groupName: ${topTwo.length} qualifiers',
          tag: 'hardcoded_sabo_de24_service');
    }

    if (qualifiers.length != 16) {
      throw Exception('Expected 16 qualifiers, got ${qualifiers.length}');
    }

    // Shuffle qualifiers for random seeding in DE16
    final shuffled = List<String>.from(qualifiers)..shuffle();

    // Assign to WB R1 matches (match_number 25-32 based on structure)
    final wbR1Matches = await _supabase
        .from('matches')
        .select('*')
        .eq('tournament_id', tournamentId)
        .eq('round', 'WB R1')
        .order('match_number');

    for (int i = 0; i < wbR1Matches.length; i++) {
      final match = wbR1Matches[i];
      final player1 = shuffled[i * 2];
      final player2 = shuffled[i * 2 + 1];

      await _supabase.from('matches').update({
        'player1_id': player1,
        'player2_id': player2,
        'status':
            'pending', // Changed from 'ready' to 'pending' - valid enum values: pending, in_progress, completed
      }).eq('id', match['id']);
    }

    ProductionLogger.info(
        '✅ ${qualifiers.length} players advanced to DE16 main stage',
        tag: 'hardcoded_sabo_de24_service');
  }

  /// Process match result
  Future<Map<String, dynamic>> processMatchResult({
    required String matchId,
    required String winnerId,
    required Map<String, int> scores,
  }) async {
    // Get match details
    final match = await _supabase
        .from('matches')
        .select('player1_id, player2_id, tournament_id, round, bracket_type')
        .eq('id', matchId)
        .single();

    final player1Id = match['player1_id'] as String;
    final player2Id = match['player2_id'] as String;
    final loserId = (winnerId == player1Id) ? player2Id : player1Id;
    final tournamentId = match['tournament_id'] as String;
    final bracketType = match['bracket_type'] as String?;

    // Use UniversalMatchProgressionService for immediate advancement
    final result = await UniversalMatchProgressionService.instance
        .updateMatchResultWithImmediateAdvancement(
      matchId: matchId,
      tournamentId: tournamentId,
      winnerId: winnerId,
      loserId: loserId,
      scores: scores,
    );

    // If it's a group match, check if we need to advance group winners
    if (bracketType == 'groups' ||
        (match['round'] as String).startsWith('Group')) {
      // Check if ALL group matches are completed
      final pendingMatches = await _supabase
          .from('matches')
          .select('count')
          .eq('tournament_id', tournamentId)
          .like('round', 'Group%')
          .neq('status', 'completed')
          .count();

      final count = pendingMatches.count;

      if (count == 0) {
        // All group matches done, advance winners
        await advanceGroupWinnersToMainStage(tournamentId);
        final msg = result['message'] ?? '';
        result['message'] =
            '$msg (Group Stage Completed - Advanced to Main Stage)';
      }
    }

    return result;
  }
}
