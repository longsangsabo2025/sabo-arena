import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 🏆 Hardcoded Double Elimination 16 Service
/// ✅ CORRECT STRUCTURE with standardized bracket metadata
///
/// Structure:
/// - Total: 30 matches created initially (M1-M30)
/// - M31 (GF Reset) created DYNAMICALLY if LB champion wins GF1
/// - Winner Bracket: 15 matches (4 rounds: 8+4+2+1)
/// - Loser Bracket: 15 matches (6 rounds: 4+4+2+2+1+1)
/// - Grand Final: 1 match (GF1 always created, GF2 conditional)
///
/// Advancement uses display_order values:
/// - WB: 1101-1401 (priority 1)
/// - LB: 2101-2601 (priority 2)
/// - GF: 3101-3102 (priority 3, M31 conditional)
class HardcodedDoubleEliminationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Tạo bracket với hardcoded advancement mapping
  Future<Map<String, dynamic>> createBracketWithAdvancement({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (participantIds.length != 16) {
        throw Exception('DE16 requires exactly 16 participants');
      }

      // Generate advancement map
      final advancementMap = _calculateAdvancementMap();
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Generate all matches with advancement info
      final allMatches = <Map<String, dynamic>>[];

      // Winner Bracket Round 1: Matches 1-8
      for (int i = 1; i <= 8; i++) {
        final advancement = advancementMap[i]!;
        final displayOrder =
            (1 * 1000) + (1 * 100) + i; // WB priority=1, stage_round=1
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 1, // WB R1 (legacy)
          'match_number': i,
          'player1_id': participantIds[(i - 1) * 2],
          'player2_id': participantIds[(i - 1) * 2 + 1],
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'double_elimination',
          'winner_advances_to': advancement['winner'],
          'loser_advances_to': advancement['loser'],
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'WB', // Winner Bracket
          'bracket_group': null, // DE16 doesn't use groups
          'stage_round': 1, // Normalized round
          'display_order': displayOrder, // 1101-1108
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Winner Bracket Round 2: Matches 9-12
      for (int i = 9; i <= 12; i++) {
        final advancement = advancementMap[i]!;
        final displayOrder =
            (1 * 1000) + (2 * 100) + (i - 8); // WB priority=1, stage_round=2
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 2, // WB R2 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'double_elimination',
          'winner_advances_to': advancement['winner'],
          'loser_advances_to': advancement['loser'],
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'WB',
          'bracket_group': null,
          'stage_round': 2,
          'display_order': displayOrder, // 1201-1204
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Winner Bracket Round 3: Matches 13-14
      for (int i = 13; i <= 14; i++) {
        final advancement = advancementMap[i]!;
        final displayOrder = (1 * 1000) + (3 * 100) + (i - 12);
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 3, // WB R3 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'double_elimination',
          'winner_advances_to': advancement['winner'],
          'loser_advances_to': advancement['loser'],
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'WB',
          'bracket_group': null,
          'stage_round': 3,
          'display_order': displayOrder, // 1301-1302
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Winner Bracket Final: Match 15
      final advancement15 = advancementMap[15]!;
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 4, // WB Final (legacy)
        'match_number': 15,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'winner_advances_to': advancement15['winner'], // To Grand Final
        'loser_advances_to': advancement15['loser'], // To LB Final
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'WB',
        'bracket_group': null,
        'stage_round': 4,
        'display_order': 1401, // WB Final
        'created_at': DateTime.now().toIso8601String(),
      });

      // ========== LOSER BRACKET: 15 matches (6 rounds) ==========

      // LB Round 1: Matches 16-19 (4 matches, display_order 2101-2104)
      // Receive 8 WB R1 losers (2 per match)
      for (int i = 16; i <= 19; i++) {
        final advancement = advancementMap[i]!;
        final displayOrder = (2 * 1000) + (1 * 100) + (i - 15); // 2101-2104
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 101, // LB R1 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'double_elimination',
          'winner_advances_to': advancement['winner'],
          'loser_advances_to': null, // Eliminated
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'LB',
          'bracket_group': null,
          'stage_round': 1,
          'display_order': displayOrder,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // LB Round 2: Matches 20-23 (4 matches, display_order 2201-2204)
      // Receive 4 LB R1 winners + 4 WB R2 losers
      for (int i = 20; i <= 23; i++) {
        final advancement = advancementMap[i]!;
        final displayOrder = (2 * 1000) + (2 * 100) + (i - 19); // 2201-2204
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 102, // LB R2 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'double_elimination',
          'winner_advances_to': advancement['winner'],
          'loser_advances_to': null, // Eliminated
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'LB',
          'bracket_group': null,
          'stage_round': 2,
          'display_order': displayOrder,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // LB Round 3: Matches 24-25 (2 matches, display_order 2301-2302)
      // Receive 4 LB R2 winners (2 per match)
      for (int i = 24; i <= 25; i++) {
        final advancement = advancementMap[i]!;
        final displayOrder = (2 * 1000) + (3 * 100) + (i - 23); // 2301-2302
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 103, // LB R3 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'double_elimination',
          'winner_advances_to': advancement['winner'],
          'loser_advances_to': null, // Eliminated
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'LB',
          'bracket_group': null,
          'stage_round': 3,
          'display_order': displayOrder,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // LB Round 4: Matches 26-27 (2 matches, display_order 2401-2402)
      // Receive 2 LB R3 winners + 2 WB R3 losers
      for (int i = 26; i <= 27; i++) {
        final advancement = advancementMap[i]!;
        final displayOrder = (2 * 1000) + (4 * 100) + (i - 25); // 2401-2402
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 104, // LB R4 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'double_elimination',
          'winner_advances_to': advancement['winner'],
          'loser_advances_to': null, // Eliminated
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'LB',
          'bracket_group': null,
          'stage_round': 4,
          'display_order': displayOrder,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // LB Round 5: Match 28 (1 match, display_order 2501)
      // Receive 2 LB R4 winners
      final advancement28 = advancementMap[28]!;
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 105, // LB R5 (legacy)
        'match_number': 28,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'winner_advances_to': advancement28['winner'],
        'loser_advances_to': null, // Eliminated
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'LB',
        'bracket_group': null,
        'stage_round': 5,
        'display_order': 2501,
        'created_at': DateTime.now().toIso8601String(),
      });

      // LB Round 6 / Final: Match 29 (1 match, display_order 2601)
      // Receive 1 LB R5 winner + 1 WB Final loser
      final advancement29 = advancementMap[29]!;
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 106, // LB R6 Final (legacy)
        'match_number': 29,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'winner_advances_to': advancement29['winner'], // To GF
        'loser_advances_to': null, // Eliminated (3rd place)
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'LB',
        'bracket_group': null,
        'stage_round': 6,
        'display_order': 2601,
        'created_at': DateTime.now().toIso8601String(),
      });

      // ========== GRAND FINAL ==========

      // GF1: Match 30 (display_order 3101)
      // Receive: WB Final winner + LB Final winner
      // ⚠️ Conditional advancement - M31 created by UI if LB champion wins
      final advancement30 = advancementMap[30]!;
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 999, // Grand Final (legacy)
        'match_number': 30,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'winner_advances_to':
            advancement30['winner'], // null or 3102 (if LB wins)
        'loser_advances_to': advancement30['loser'], // null
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'GF',
        'bracket_group': null,
        'stage_round': 1,
        'display_order': 3101,
        'created_at': DateTime.now().toIso8601String(),
      });

      // ⚠️ GF2 (Match 31, display_order 3102) NOT created here
      // Will be created dynamically by match_management_tab.dart when:
      //   - M30 completes with LB champion winning
      //   - Both players advance to bracket reset match

      // Save matches to database
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      await _supabase.from('matches').insert(allMatches);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': true,
        'matches_count': allMatches.length,
        'participants_count': participantIds.length,
        'advancement_mappings': advancementMap.length,
      };
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ✅ STANDARDIZED: Calculate advancement map for DE16 using display_order
  /// Returns: {matchNumber: {'winner': display_order, 'loser': display_order}}
  /// 🔥 CORRECT STRUCTURE: 15 WB + 15 LB + 1 GF = 31 matches (M31 GF Reset created dynamically)
  Map<int, Map<String, int?>> _calculateAdvancementMap() {
    final map = <int, Map<String, int?>>{};

    // ========== WINNER BRACKET (15 matches) ==========

    // WB Round 1 (8 matches → display_order 1101-1108)
    // 8 winners → WB R2 (1201-1204, 2 winners per match)
    // 8 losers → LB R1 (2101-2104, 2 losers per match)
    map[1] = {'winner': 1201, 'loser': 2101}; // WB R1 M1
    map[2] = {
      'winner': 1201,
      'loser': 2101,
    }; // WB R1 M2 → both to same WB R2 M1, LB R1 M1
    map[3] = {'winner': 1202, 'loser': 2102}; // WB R1 M3
    map[4] = {'winner': 1202, 'loser': 2102}; // WB R1 M4
    map[5] = {'winner': 1203, 'loser': 2103}; // WB R1 M5
    map[6] = {'winner': 1203, 'loser': 2103}; // WB R1 M6
    map[7] = {'winner': 1204, 'loser': 2104}; // WB R1 M7
    map[8] = {'winner': 1204, 'loser': 2104}; // WB R1 M8

    // WB Round 2 (4 matches → display_order 1201-1204)
    // 4 winners → WB R3 (1301-1302)
    // 4 losers → LB R2 (2201-2204, 1 per match)
    map[9] = {'winner': 1301, 'loser': 2201}; // WB R2 M1
    map[10] = {'winner': 1301, 'loser': 2202}; // WB R2 M2
    map[11] = {'winner': 1302, 'loser': 2203}; // WB R2 M3
    map[12] = {'winner': 1302, 'loser': 2204}; // WB R2 M4

    // WB Round 3 (2 matches → display_order 1301-1302)
    // 2 winners → WB Final (1401)
    // 2 losers → LB R4 (2401-2402, 1 per match)
    map[13] = {'winner': 1401, 'loser': 2401}; // WB R3 M1
    map[14] = {'winner': 1401, 'loser': 2402}; // WB R3 M2

    // WB Round 4 / Final (1 match → display_order 1401)
    // Winner → Grand Final (3101)
    // Loser → LB R6 Final (2601)
    map[15] = {'winner': 3101, 'loser': 2601}; // WB Final

    // ========== LOSER BRACKET (15 matches) ==========

    // LB Round 1 (4 matches → display_order 2101-2104)
    // Receive: 8 WB R1 losers (2 per match)
    // 4 winners → LB R2 (2201-2204, 1 per match)
    // 4 losers → ELIMINATED
    map[16] = {'winner': 2201, 'loser': null}; // LB R1 M1
    map[17] = {'winner': 2202, 'loser': null}; // LB R1 M2
    map[18] = {'winner': 2203, 'loser': null}; // LB R1 M3
    map[19] = {'winner': 2204, 'loser': null}; // LB R1 M4

    // LB Round 2 (4 matches → display_order 2201-2204)
    // Receive: 4 LB R1 winners + 4 WB R2 losers (1 each)
    // 4 winners → LB R3 (2301-2302, 2 winners per match)
    // 4 losers → ELIMINATED
    map[20] = {'winner': 2301, 'loser': null}; // LB R2 M1
    map[21] = {'winner': 2301, 'loser': null}; // LB R2 M2
    map[22] = {'winner': 2302, 'loser': null}; // LB R2 M3
    map[23] = {'winner': 2302, 'loser': null}; // LB R2 M4

    // LB Round 3 (2 matches → display_order 2301-2302)
    // Receive: 4 LB R2 winners (2 per match)
    // 2 winners → LB R4 (2401-2402, 1 per match)
    // 2 losers → ELIMINATED
    map[24] = {'winner': 2401, 'loser': null}; // LB R3 M1
    map[25] = {'winner': 2402, 'loser': null}; // LB R3 M2

    // LB Round 4 (2 matches → display_order 2401-2402)
    // Receive: 2 LB R3 winners + 2 WB R3 losers (1 each)
    // 2 winners → LB R5 (2501, both to same match)
    // 2 losers → ELIMINATED
    map[26] = {'winner': 2501, 'loser': null}; // LB R4 M1
    map[27] = {'winner': 2501, 'loser': null}; // LB R4 M2

    // LB Round 5 (1 match → display_order 2501)
    // Receive: 2 LB R4 winners
    // Winner → LB R6 Final (2601)
    // Loser → ELIMINATED
    map[28] = {'winner': 2601, 'loser': null}; // LB R5

    // LB Round 6 / Final (1 match → display_order 2601)
    // Receive: 1 LB R5 winner + 1 WB Final loser
    // Winner → Grand Final (3101)
    // Loser → ELIMINATED
    map[29] = {'winner': 3101, 'loser': null}; // LB Final

    // ========== GRAND FINALS (1 match, +1 conditional) ==========

    // GF1 (1 match → display_order 3101)
    // Receive: WB Final winner + LB Final winner
    // If WB champion wins → null (tournament ends, no M31)
    // If LB champion wins → null (M31 GF Reset created dynamically by UI logic)
    map[30] = {'winner': null, 'loser': null}; // GF1 - conditional advancement

    // ⚠️ M31 (GF Reset) NOT created here, created dynamically when:
    //    - M30 (GF1) completes with LB champion winning
    //    - Both players advance to M31 for bracket reset
    //    - Winner of M31 = TOURNAMENT CHAMPION

    return map;
  }
}

