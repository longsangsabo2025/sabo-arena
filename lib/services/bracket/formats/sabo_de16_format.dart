import 'package:supabase_flutter/supabase_flutter.dart';
import '../../universal_match_progression_service.dart';
import 'package:sabo_arena/utils/round_name_calculator.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 🏆 Hardcoded SABO DE16 Service (ENHANCED v2 - COMPLETE)
/// ✅ ENHANCED STRUCTURE with LB-B R3 & R4 for WB R3 losers
///
/// Structure:
/// - Total: 29 matches (upgraded from 27 matches)
/// - Winner Bracket: 14 matches (3 rounds: 8+4+2) - same
/// - Loser Branch A: 7 matches (3 rounds: 4+2+1) - same
/// - Loser Branch B: 5 matches (4 rounds: 2+1+1+1) - ENHANCED! Added R3 and R4
/// - SABO Finals: 3 matches (2 semifinals + 1 final) - same
///
/// Enhancement Details:
/// - LB-B R3 (M25): takes 2 losers from WB R3 - "trận cứu vớt" (L13 vs L14)
/// - LB-B R4 (M26): LB-B R2 winner (W24) vs LB-B R3 winner (W25)
/// - This gives more chances to strong players who lose in Group Finals
///
/// Match Numbers:
/// - WB: M1-M14 (display_order 1101-1302)
/// - LB-A: M15-M21 (display_order 2101-2301)
/// - LB-B: M22-M26 (display_order 3101-3401) - 5 matches now!
/// - SABO Finals: M27-M29 (display_order 4101-4201)
///
/// Advancement uses display_order values:
/// - WB: 1101-1302 (priority 1, stops at R3)
/// - LB-A: 2101-2301 (priority 2)
/// - LB-B: 3101-3401 (priority 3) - ENHANCED! Added 3301, 3401
/// - SABO Finals: 4101-4201 (priority 4)
///
/// Key Differences from Standard DE16:
/// - NO WB Final: Winners stop at R3 (2 players)
/// - 2 Loser Branches: Branch A (R1 losers), Branch B (R2 losers + R3 losers)
/// - WB R3 losers get "second chance" match in LB-B R3 (trận cứu vớt)
/// - 4-Player Finals: 2 WB + 2 LB champions
/// - NO Bracket Reset: Finals is single elimination
class HardcodedSaboDE16Service {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Tạo SABO DE16 bracket với hardcoded advancement mapping
  Future<Map<String, dynamic>> createBracketWithAdvancement({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (participantIds.length != 16) {
        throw Exception('SABO DE16 requires exactly 16 participants');
      }

      // Generate advancement map
      final advancementMap = _calculateAdvancementMap();
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Generate all matches with advancement info
      final allMatches = <Map<String, dynamic>>[];

      // ========== WINNER BRACKET: 14 matches (3 rounds) ==========

      // WB Round 1: Matches 1-8 (display_order 1101-1108)
      for (int i = 1; i <= 8; i++) {
        final displayOrder = (1 * 1000) + (1 * 100) + i; // 1101-1108
        final advancement = advancementMap[displayOrder]!; // 🔥 Use display_order as key!
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
          'bracket_format': 'sabo_de16',
          'winner_advances_to': advancement['winner'], // 🔥 Now contains display_order!
          'loser_advances_to': advancement['loser'], // 🔥 Now contains display_order!
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'WB',
          'bracket_group': null,
          'stage_round': 1,
          'display_order': displayOrder,
          'round': RoundNameCalculator.calculate(
            bracketType: 'WB',
            stageRound: 1,
            displayOrder: displayOrder,
          ),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // WB Round 2: Matches 9-12 (display_order 1201-1204)
      for (int i = 9; i <= 12; i++) {
        final displayOrder = (1 * 1000) + (2 * 100) + (i - 8); // 1201-1204
        final advancement = advancementMap[displayOrder]!; // 🔥 Use display_order as key!
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
          'bracket_format': 'sabo_de16',
          'winner_advances_to': advancement['winner'], // 🔥 Now contains display_order!
          'loser_advances_to': advancement['loser'], // 🔥 Now contains display_order!
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'WB',
          'bracket_group': null,
          'stage_round': 2,
          'display_order': displayOrder,
          'round': RoundNameCalculator.calculate(
            bracketType: 'WB',
            stageRound: 2,
            displayOrder: displayOrder,
          ),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // WB Round 3: Matches 13-14 (display_order 1301-1302)
      // ⚠️ NO LOSER ADVANCEMENT - WB stops here, goes to SABO Finals
      for (int i = 13; i <= 14; i++) {
        final displayOrder = (1 * 1000) + (3 * 100) + (i - 12); // 1301-1302
        final advancement = advancementMap[displayOrder]!; // 🔥 Use display_order as key!
        allMatches.add(_createMatch(
          tournamentId: tournamentId,
          roundNumber: 3,
          matchNumber: i,
          bracketType: 'WB',
          stageRound: 3,
          displayOrder: displayOrder,
          advancement: advancement,
        ));
      }

      // ========== LOSER BRANCH A: 7 matches (3 rounds) ==========
      // Receives WB R1 losers

      // LB-A Round 1: Matches 15-18 (display_order 2101-2104)
      for (int i = 15; i <= 18; i++) {
        final displayOrder = (2 * 1000) + (1 * 100) + (i - 14); // 2101-2104
        final advancement = advancementMap[displayOrder]!; // 🔥 Use display_order as key!
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 101, // LB-A R1 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'sabo_de16',
          'winner_advances_to': advancement['winner'], // 🔥 Now contains display_order!
          'loser_advances_to': null, // Eliminated
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'LB-A', // Loser Branch A
          'bracket_group': null, // SABO DE16 doesn't use bracket_group
          'stage_round': 1,
          'display_order': displayOrder,
          'round': RoundNameCalculator.calculate(
            bracketType: 'LB-A',
            stageRound: 1,
            displayOrder: displayOrder,
          ),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // LB-A Round 2: Matches 19-20 (display_order 2201-2202)
      for (int i = 19; i <= 20; i++) {
        final displayOrder = (2 * 1000) + (2 * 100) + (i - 18); // 2201-2202
        final advancement = advancementMap[displayOrder]!; // 🔥 Use display_order as key!
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 102, // LB-A R2 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'sabo_de16',
          'winner_advances_to': advancement['winner'], // 🔥 Now contains display_order!
          'loser_advances_to': null, // Eliminated
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'LB-A',
          'bracket_group': null, // SABO DE16 doesn't use bracket_group
          'stage_round': 2,
          'display_order': displayOrder,
          'round': RoundNameCalculator.calculate(
            bracketType: 'LB-A',
            stageRound: 2,
            displayOrder: displayOrder,
          ),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // LB-A Round 3 / Final: Match 21 (display_order 2301)
      final displayOrder21 = 2301;
      final advancement21 = advancementMap[displayOrder21]!; // 🔥 Use display_order as key!
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 103, // LB-A R3 Final (legacy)
        'match_number': 21,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'sabo_de16',
        'winner_advances_to': advancement21['winner'], // 🔥 Now contains display_order! To SABO Finals Semi1
        'loser_advances_to': null, // Eliminated
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'LB-A',
        'bracket_group': null, // SABO DE16 doesn't use bracket_group
        'stage_round': 3,
        'display_order': displayOrder21,
        'round': RoundNameCalculator.calculate(
          bracketType: 'LB-A',
          stageRound: 3,
          displayOrder: displayOrder21,
        ),
        'created_at': DateTime.now().toIso8601String(),
      });

      // ========== LOSER BRANCH B ENHANCED: 5 matches (4 rounds) ==========
      // Receives WB R2 losers (R1) + WB R3 losers (R3)

      // LB-B Round 1: Matches 22-23 (display_order 3101-3102)
      for (int i = 22; i <= 23; i++) {
        final displayOrder = (3 * 1000) + (1 * 100) + (i - 21); // 3101-3102
        final advancement = advancementMap[displayOrder]!; // 🔥 Use display_order as key!
        allMatches.add({
          'tournament_id': tournamentId,
          'round_number': 201, // LB-B R1 (legacy)
          'match_number': i,
          'player1_id': null,
          'player2_id': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          'status': 'pending',
          'match_type': 'tournament',
          'bracket_format': 'sabo_de16',
          'winner_advances_to': advancement['winner'], // 🔥 Now contains display_order!
          'loser_advances_to': null, // Eliminated
          // 🔥 STANDARDIZED FIELDS
          'bracket_type': 'LB-B', // Loser Branch B
          'bracket_group': null, // SABO DE16 doesn't use bracket_group
          'stage_round': 1,
          'display_order': displayOrder,
          'round': RoundNameCalculator.calculate(
            bracketType: 'LB-B',
            stageRound: 1,
            displayOrder: displayOrder,
          ),
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // LB-B Round 2: Match 24 (display_order 3201)
      // W22 vs W23 winners meet here
      final displayOrder24 = 3201;
      final advancement24 = advancementMap[displayOrder24]!; // 🔥 Use display_order as key!
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 202, // LB-B R2 (legacy)
        'match_number': 24,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'sabo_de16',
        'winner_advances_to': advancement24['winner'], // 🔥 To LB-B R4 (3401)
        'loser_advances_to': null, // Eliminated
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'LB-B',
        'bracket_group': null, // SABO DE16 doesn't use bracket_group
        'stage_round': 2,
        'display_order': displayOrder24,
        'round': RoundNameCalculator.calculate(
          bracketType: 'LB-B',
          stageRound: 2,
          displayOrder: displayOrder24,
        ),
        'created_at': DateTime.now().toIso8601String(),
      });

      // ⭐ LB-B Round 3: Match 25 (display_order 3301) - NEW!
      // "Trận cứu vớt" for WB R3 losers: L13 vs L14
      final displayOrder25_lbb = 3301;
      final advancement25_lbb = advancementMap[displayOrder25_lbb]!;
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 203, // LB-B R3 (legacy)
        'match_number': 25,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'sabo_de16',
        'winner_advances_to': advancement25_lbb['winner'], // 🔥 To LB-B R4 (3401)
        'loser_advances_to': null, // Eliminated
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'LB-B',
        'bracket_group': null,
        'stage_round': 3,
        'display_order': displayOrder25_lbb,
        'round': RoundNameCalculator.calculate(
          bracketType: 'LB-B',
          stageRound: 3,
          displayOrder: displayOrder25_lbb,
        ),
        'created_at': DateTime.now().toIso8601String(),
      });

      // ⭐ LB-B Round 4 / Final: Match 26 (display_order 3401) - NEW!
      // W24 (LB-B R2 winner) vs W25 (LB-B R3 winner)
      final displayOrder26_lbb = 3401;
      final advancement26_lbb = advancementMap[displayOrder26_lbb]!;
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 204, // LB-B R4 Final (legacy)
        'match_number': 26,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'sabo_de16',
        'winner_advances_to': advancement26_lbb['winner'], // 🔥 To SABO Semi2 (4102)
        'loser_advances_to': null, // Eliminated
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'LB-B',
        'bracket_group': null,
        'stage_round': 4,
        'display_order': displayOrder26_lbb,
        'round': RoundNameCalculator.calculate(
          bracketType: 'LB-B',
          stageRound: 4,
          displayOrder: displayOrder26_lbb,
        ),
        'created_at': DateTime.now().toIso8601String(),
      });

      // ========== SABO FINALS: 3 matches ==========
      // 4-player format: 2 WB champions + 2 LB champions

      // Semifinal 1: Match 27 (display_order 4101)
      // WB R3 M13 winner vs LB-A champion
      final displayOrder27 = 4101;
      final advancement27 = advancementMap[displayOrder27]!; // 🔥 Use display_order as key!
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 250, // SABO Semi1 (legacy)
        'match_number': 27,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'sabo_de16',
        'winner_advances_to': advancement27['winner'], // 🔥 Now contains display_order! To Final
        'loser_advances_to': null, // 3rd place
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'SABO', // SABO Finals
        'bracket_group': null, // SABO DE16 doesn't use bracket_group
        'stage_round': 1,
        'display_order': displayOrder27,
        'round': RoundNameCalculator.calculate(
          bracketType: 'SABO',
          stageRound: 1,
          displayOrder: displayOrder27,
        ),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Semifinal 2: Match 28 (display_order 4102)
      // WB R3 M14 winner vs LB-B R4 champion
      final displayOrder28 = 4102;
      final advancement28 = advancementMap[displayOrder28]!; // 🔥 Use display_order as key!
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 251, // SABO Semi2 (legacy)
        'match_number': 28,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'sabo_de16',
        'winner_advances_to': advancement28['winner'], // 🔥 Now contains display_order! To Final
        'loser_advances_to': null, // 4th place
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'SABO',
        'bracket_group': null, // SABO DE16 doesn't use bracket_group
        'stage_round': 1,
        'display_order': displayOrder28,
        'round': RoundNameCalculator.calculate(
          bracketType: 'SABO',
          stageRound: 1,
          displayOrder: displayOrder28,
        ),
        'created_at': DateTime.now().toIso8601String(),
      });

      // SABO Finals: Match 29 (display_order 4201)
      final displayOrder29 = 4201;
      allMatches.add({
        'tournament_id': tournamentId,
        'round_number': 300, // SABO Finals (legacy)
        'match_number': 29,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'sabo_de16',
        'winner_advances_to': null, // Champion!
        'loser_advances_to': null, // Runner-up
        // 🔥 STANDARDIZED FIELDS
        'bracket_type': 'SABO',
        'bracket_group': null, // SABO DE16 doesn't use bracket_group
        'stage_round': 2,
        'display_order': displayOrder29,
        'round': RoundNameCalculator.calculate(
          bracketType: 'SABO',
          stageRound: 2,
          displayOrder: displayOrder29,
        ),
        'created_at': DateTime.now().toIso8601String(),
      });

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

  /// ✅ STANDARDIZED: Calculate advancement map for SABO DE16 ENHANCED using display_order
  /// Returns: {display_order: {'winner': display_order, 'loser': display_order}}
  /// 🔥 ENHANCED STRUCTURE: 14 WB + 7 LB-A + 5 LB-B + 3 SABO Finals = 29 matches
  /// 🔥 FIXED: Now uses display_order (like DE32) instead of match_number
  Map<int, Map<String, int?>> _calculateAdvancementMap() {
    final map = <int, Map<String, int?>>{};

    // 🔥 CRITICAL: Using display_order for both KEY and VALUE
    // This matches DE32 structure and works with DatabaseFieldAdvancementService

    // ========== WINNER BRACKET (14 matches) ==========

    // WB Round 1 (8 matches: display_order 1101-1108)
    // Winners → WB R2 (1201-1204)
    // Losers → LB-A R1 (2101-2104)
    map[1101] = {'winner': 1201, 'loser': 2101}; // DO 1101 → 1201 or 2101
    map[1102] = {'winner': 1201, 'loser': 2101}; // DO 1102 → 1201 or 2101
    map[1103] = {'winner': 1202, 'loser': 2102}; // DO 1103 → 1202 or 2102
    map[1104] = {'winner': 1202, 'loser': 2102}; // DO 1104 → 1202 or 2102
    map[1105] = {'winner': 1203, 'loser': 2103}; // DO 1105 → 1203 or 2103
    map[1106] = {'winner': 1203, 'loser': 2103}; // DO 1106 → 1203 or 2103
    map[1107] = {'winner': 1204, 'loser': 2104}; // DO 1107 → 1204 or 2104
    map[1108] = {'winner': 1204, 'loser': 2104}; // DO 1108 → 1204 or 2104

    // WB Round 2 (4 matches: display_order 1201-1204)
    // Winners → WB R3 (1301-1302)
    // Losers → LB-B R1 (3101-3102)
    map[1201] = {'winner': 1301, 'loser': 3101}; // DO 1201 → 1301 or 3101
    map[1202] = {'winner': 1301, 'loser': 3101}; // DO 1202 → 1301 or 3101
    map[1203] = {'winner': 1302, 'loser': 3102}; // DO 1203 → 1302 or 3102
    map[1204] = {'winner': 1302, 'loser': 3102}; // DO 1204 → 1302 or 3102

    // WB Round 3 (2 matches: display_order 1301-1302)
    // ⭐ ENHANCED: Losers now go to LB-B R3 (3301) instead of being eliminated!
    // Winners → SABO Finals semifinals (4101, 4102)
    // Losers → LB-B R3 (3301) - "Trận cứu vớt"
    map[1301] = {'winner': 4101, 'loser': 3301}; // DO 1301 → 4101 (Semi1), L→3301
    map[1302] = {'winner': 4102, 'loser': 3301}; // DO 1302 → 4102 (Semi2), L→3301

    // ========== LOSER BRANCH A (7 matches) ==========

    // LB-A Round 1 (4 matches: display_order 2101-2104)
    // Receive: 8 WB R1 losers
    // Winners → LB-A R2 (2201-2202)
    map[2101] = {'winner': 2201, 'loser': null}; // DO 2101 → 2201
    map[2102] = {'winner': 2201, 'loser': null}; // DO 2102 → 2201
    map[2103] = {'winner': 2202, 'loser': null}; // DO 2103 → 2202
    map[2104] = {'winner': 2202, 'loser': null}; // DO 2104 → 2202

    // LB-A Round 2 (2 matches: display_order 2201-2202)
    // Winners → LB-A Final (2301)
    map[2201] = {'winner': 2301, 'loser': null}; // DO 2201 → 2301
    map[2202] = {'winner': 2301, 'loser': null}; // DO 2202 → 2301

    // LB-A Round 3 / Final (1 match: display_order 2301)
    // Winner → SABO Finals Semi1 (4101)
    map[2301] = {'winner': 4101, 'loser': null}; // DO 2301 → 4101

    // ========== LOSER BRANCH B ENHANCED (5 matches) ==========

    // LB-B Round 1 (2 matches: display_order 3101-3102)
    // Receive: 4 WB R2 losers
    // Winners → LB-B R2 (3201)
    map[3101] = {'winner': 3201, 'loser': null}; // DO 3101 → 3201
    map[3102] = {'winner': 3201, 'loser': null}; // DO 3102 → 3201

    // LB-B Round 2 (1 match: display_order 3201)
    // Winner → LB-B R4 Final (3401)
    map[3201] = {'winner': 3401, 'loser': null}; // DO 3201 → 3401 (to LB-B R4)

    // ⭐ LB-B Round 3 - NEW! (1 match: display_order 3301)
    // "Trận cứu vớt" - WB R3 losers meet here: L13 vs L14
    // Winner → LB-B R4 Final (3401)
    map[3301] = {'winner': 3401, 'loser': null}; // DO 3301 → 3401 (to LB-B R4)

    // ⭐ LB-B Round 4 / Final - NEW! (1 match: display_order 3401)
    // W24 (LB-B R2 winner) vs W25 (LB-B R3 winner)
    // Winner → SABO Finals Semi2 (4102)
    map[3401] = {'winner': 4102, 'loser': null}; // DO 3401 → 4102 (SABO Semi2)

    // ========== SABO FINALS (3 matches) ==========

    // Semifinal 1 (1 match: display_order 4101)
    // Receives: WB R3 1301 winner + LB-A champion (2301)
    // Winner → SABO Finals (4201)
    map[4101] = {'winner': 4201, 'loser': null}; // DO 4101 → 4201

    // Semifinal 2 (1 match: display_order 4102)
    // Receives: WB R3 1302 winner + LB-B R4 champion (3401)
    // Winner → SABO Finals (4201)
    map[4102] = {'winner': 4201, 'loser': null}; // DO 4102 → 4201

    // SABO Finals (1 match: display_order 4201)
    // Receives: Semi1 winner + Semi2 winner
    // Winner = TOURNAMENT CHAMPION
    map[4201] = {'winner': null, 'loser': null};

    return map;
  }

  /// Helper to create match with auto-calculated round name
  Map<String, dynamic> _createMatch({
    required String tournamentId,
    required int roundNumber,
    required int matchNumber,
    required String bracketType,
    required int stageRound,
    required int displayOrder,
    required Map<String, dynamic> advancement,
    String? player1Id,
    String? player2Id,
  }) {
    return {
      'tournament_id': tournamentId,
      'round_number': roundNumber,
      'match_number': matchNumber,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'winner_id': null,
      'player1_score': 0,
      'player2_score': 0,
      'status': 'pending',
      'match_type': 'tournament',
      'bracket_format': 'sabo_de16',
      'winner_advances_to': advancement['winner'],
      'loser_advances_to': advancement['loser'],
      'bracket_type': bracketType,
      'bracket_group': null,
      'stage_round': stageRound,
      'display_order': displayOrder,
      'round': RoundNameCalculator.calculate(
        bracketType: bracketType,
        stageRound: stageRound,
        displayOrder: displayOrder,
      ),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Process match result
  Future<Map<String, dynamic>> processMatchResult({
    required String matchId,
    required String winnerId,
    required Map<String, int> scores,
  }) async {
    // Get match details to find loser
    final match = await _supabase
        .from('matches')
        .select('player1_id, player2_id, tournament_id')
        .eq('id', matchId)
        .single();
        
    final player1Id = match['player1_id'] as String;
    final player2Id = match['player2_id'] as String;
    final loserId = (winnerId == player1Id) ? player2Id : player1Id;
    final tournamentId = match['tournament_id'] as String;

    // Use UniversalMatchProgressionService for immediate advancement
    return await UniversalMatchProgressionService.instance.updateMatchResultWithImmediateAdvancement(
      matchId: matchId,
      tournamentId: tournamentId,
      winnerId: winnerId,
      loserId: loserId,
      scores: scores,
    );
  }
}

