import 'package:supabase_flutter/supabase_flutter.dart';
import '../../universal_match_progression_service.dart';
import 'package:sabo_arena/utils/round_name_calculator.dart';

/// SABO DE32 Hardcoded Service
///
/// Structure:
/// - Total: 55 matches (all created upfront, no dynamic creation)
/// - Group A: 24 matches (SABO DE16 structure)
///   - Winner Bracket: 14 matches (3 rounds: 8+4+2)
///   - Loser Branch A: 7 matches (3 rounds: 4+2+1)
///   - Loser Branch B: 3 matches (2 rounds: 2+1)
/// - Group B: 24 matches (SABO DE16 structure)
///   - Winner Bracket: 14 matches (3 rounds: 8+4+2)
///   - Loser Branch A: 7 matches (3 rounds: 4+2+1)
///   - Loser Branch B: 3 matches (2 rounds: 2+1)
/// - Cross-Bracket Finals: 7 matches
///   - Semi-Finals: 4 matches
///   - Finals: 2 matches
///   - Grand Final: 1 match
///
/// Display Order System:
/// - Group A WB: 11xxx (11101-11302)
/// - Group A LB-A: 12xxx (12101-12301)
/// - Group A LB-B: 13xxx (13101-13201)
/// - Group B WB: 21xxx (21101-21302)
/// - Group B LB-A: 22xxx (22101-22301)
/// - Group B LB-B: 23xxx (23101-23201)
/// - Cross Semi-Finals: 31xxx (31101-31104)
/// - Cross Finals: 32xxx (32101-32102)
/// - Grand Final: 33xxx (33101)
///
/// Key Features:
/// - Each group uses SABO DE16 format (24 matches)
/// - WB R3 has NO loser advancement (stops at 2 players per group)
/// - Each group produces 4 qualifiers (2 WB + 1 LB-A + 1 LB-B)
/// - Cross-bracket finals balance WB vs LB representation
class HardcodedSaboDE32Service {
  final SupabaseClient supabase;

  HardcodedSaboDE32Service(this.supabase);

  /// Create SABO DE32 bracket with advancement and save to database
  Future<Map<String, dynamic>> createBracketWithAdvancement({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    try {
      // Generate bracket structure
      final matches = await generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
      );

      // Save to database
      await supabase.from('matches').insert(matches);

      return {
        'success': true,
        'message': 'SABO DE32 bracket created successfully',
        'total_matches': matches.length,
        'matches_generated': matches.length,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Helper to create match object with all required fields
  Map<String, dynamic> _createMatch({
    required String tournamentId,
    required int matchNumber,
    required int roundNumber,
    required String bracketType,
    required String? bracketGroup,
    required int stageRound,
    required int displayOrder,
    required int? winnerAdvancesTo,
    required int? loserAdvancesTo,
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
      'bracket_format': 'sabo_de32',
      'winner_advances_to': winnerAdvancesTo,
      'loser_advances_to': loserAdvancesTo,
      'bracket_type': bracketType,
      'bracket_group': bracketGroup,
      'stage_round': stageRound,
      'display_order': displayOrder,
      'round': RoundNameCalculator.calculate(
        bracketType: bracketType,
        stageRound: stageRound,
        displayOrder: displayOrder,
        bracketGroup: bracketGroup,
      ),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Generate complete SABO DE32 bracket structure
  Future<List<Map<String, dynamic>>> generateBracket({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    if (participantIds.length != 32) {
      throw Exception('SABO DE32 requires exactly 32 participants');
    }

    final allMatches = <Map<String, dynamic>>[];
    final advancementMap = _calculateAdvancementMap();
    int matchNumber = 1;

    // ========================================
    // GROUP A (24 matches) - Players P1-P16
    // ========================================

    // Group A - WB Round 1 (8 matches): 11101-11108
    final groupAPlayers = participantIds.sublist(0, 16);
    final wbR1Pairs = [
      [0, 15],
      [7, 8],
      [3, 12],
      [4, 11],
      [1, 14],
      [6, 9],
      [2, 13],
      [5, 10],
    ];

    for (var i = 0; i < wbR1Pairs.length; i++) {
      final pair = wbR1Pairs[i];
      final displayOrder = 11101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 1,
          bracketType: 'WB',
          bracketGroup: 'A',
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
          player1Id: groupAPlayers[pair[0]],
          player2Id: groupAPlayers[pair[1]],
        ),
      );
      matchNumber++;
    }

    // Group A - WB Round 2 (4 matches): 11201-11204
    for (var i = 0; i < 4; i++) {
      final displayOrder = 11201 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 2,
          bracketType: 'WB',
          bracketGroup: 'A',
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group A - WB Round 3 (2 matches): 11301-11302 [QUALIFIERS]
    for (var i = 0; i < 2; i++) {
      final displayOrder = 11301 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 3,
          bracketType: 'WB',
          bracketGroup: 'A',
          stageRound: 3,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'], // null - no loser advancement
        ),
      );
      matchNumber++;
    }

    // Group A - LB-A Round 1 (4 matches): 12101-12104
    for (var i = 0; i < 4; i++) {
      final displayOrder = 12101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 101, // LB-A R1 = round 101
          bracketType: 'LB-A',
          bracketGroup: 'A',
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group A - LB-A Round 2 (2 matches): 12201-12202
    for (var i = 0; i < 2; i++) {
      final displayOrder = 12201 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 102, // LB-A R2 = round 102
          bracketType: 'LB-A',
          bracketGroup: 'A',
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group A - LB-A Round 3 (1 match): 12301 [QUALIFIER]
    {
      final displayOrder = 12301;
      final advancement = advancementMap[displayOrder]!;
      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 103, // LB-A R3 = round 103
          bracketType: 'LB-A',
          bracketGroup: 'A',
          stageRound: 3,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group A - LB-B Round 1 (2 matches): 13101-13102
    for (var i = 0; i < 2; i++) {
      final displayOrder = 13101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 201, // LB-B R1 = round 201
          bracketType: 'LB-B',
          bracketGroup: 'A',
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group A - LB-B Round 2 (1 match): 13201 [QUALIFIER]
    {
      final displayOrder = 13201;
      final advancement = advancementMap[displayOrder]!;
      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 202, // LB-B R2 = round 202
          bracketType: 'LB-B',
          bracketGroup: 'A',
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // ========================================
    // GROUP B (24 matches) - Players P17-P32
    // ========================================

    // Group B - WB Round 1 (8 matches): 21101-21108
    final groupBPlayers = participantIds.sublist(16, 32);
    final wbR1PairsB = [
      [0, 15],
      [7, 8],
      [3, 12],
      [4, 11],
      [1, 14],
      [6, 9],
      [2, 13],
      [5, 10],
    ];

    for (var i = 0; i < wbR1PairsB.length; i++) {
      final pair = wbR1PairsB[i];
      final displayOrder = 21101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 1,
          bracketType: 'WB',
          bracketGroup: 'B',
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
          player1Id: groupBPlayers[pair[0]],
          player2Id: groupBPlayers[pair[1]],
        ),
      );
      matchNumber++;
    }

    // Group B - WB Round 2 (4 matches): 21201-21204
    for (var i = 0; i < 4; i++) {
      final displayOrder = 21201 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 2,
          bracketType: 'WB',
          bracketGroup: 'B',
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group B - WB Round 3 (2 matches): 21301-21302 [QUALIFIERS]
    for (var i = 0; i < 2; i++) {
      final displayOrder = 21301 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 3,
          bracketType: 'WB',
          bracketGroup: 'B',
          stageRound: 3,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'], // null - no loser advancement
        ),
      );
      matchNumber++;
    }

    // Group B - LB-A Round 1 (4 matches): 22101-22104
    for (var i = 0; i < 4; i++) {
      final displayOrder = 22101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 101, // LB-A R1 = round 101
          bracketType: 'LB-A',
          bracketGroup: 'B',
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group B - LB-A Round 2 (2 matches): 22201-22202
    for (var i = 0; i < 2; i++) {
      final displayOrder = 22201 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 102, // LB-A R2 = round 102
          bracketType: 'LB-A',
          bracketGroup: 'B',
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group B - LB-A Round 3 (1 match): 22301 [QUALIFIER]
    {
      final displayOrder = 22301;
      final advancement = advancementMap[displayOrder]!;
      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 103, // LB-A R3 = round 103
          bracketType: 'LB-A',
          bracketGroup: 'B',
          stageRound: 3,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group B - LB-B Round 1 (2 matches): 23101-23102
    for (var i = 0; i < 2; i++) {
      final displayOrder = 23101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 201, // LB-B R1 = round 201
          bracketType: 'LB-B',
          bracketGroup: 'B',
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Group B - LB-B Round 2 (1 match): 23201 [QUALIFIER]
    {
      final displayOrder = 23201;
      final advancement = advancementMap[displayOrder]!;
      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 202, // LB-B R2 = round 202
          bracketType: 'LB-B',
          bracketGroup: 'B',
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // ========================================
    // CROSS-BRACKET FINALS (7 matches)
    // 8 qualifiers (4 from Group A + 4 from Group B)
    // ========================================

    // Cross Semi-Finals (4 matches): 31101-31104
    // Round 300 (all 4 matches: 8→4 people)
    // Mix WB and LB qualifiers from same group
    final semiDisplayOrders = [31101, 31102, 31103, 31104];
    for (var i = 0; i < 4; i++) {
      final displayOrder = semiDisplayOrders[i];
      final advancement = advancementMap[displayOrder]!;

      allMatches.add({
        'tournament_id': tournamentId,
        'match_number': matchNumber,
        'round_number': 300, // ✅ All 4 matches in round 300
        'bracket_type': 'CROSS',
        'bracket_group': null,
        'stage_round': 1,
        'display_order': displayOrder,
        'winner_advances_to': advancement['winner'],
        'loser_advances_to': advancement['loser'],
        'round': RoundNameCalculator.calculate(
          bracketType: 'CROSS',
          stageRound: 1,
          displayOrder: displayOrder,
        ),
        'player1_id': null,
        'player2_id': null,
        'status': 'pending',
        'match_type': 'tournament', // ✅ ADDED
        'bracket_format': 'sabo_de32', // ✅ ADDED
        'created_at': DateTime.now().toIso8601String(),
      });
      matchNumber++;
    }

    // Cross Finals (2 matches): 32101-32102
    // Round 301 (4→2 people)
    for (var i = 0; i < 2; i++) {
      final displayOrder = 32101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add({
        'tournament_id': tournamentId,
        'match_number': matchNumber,
        'round_number': 301, // ✅ Cross Finals round 301
        'bracket_type': 'FINAL', // ✅ CHANGED from CROSS to FINAL for clarity
        'bracket_group': null,
        'stage_round': 2,
        'display_order': displayOrder,
        'winner_advances_to': advancement['winner'],
        'loser_advances_to': advancement['loser'],
        'round': RoundNameCalculator.calculate(
          bracketType: 'FINAL',
          stageRound: 2,
          displayOrder: displayOrder,
        ),
        'player1_id': null,
        'player2_id': null,
        'status': 'pending',
        'match_type': 'tournament', // ✅ ADDED
        'bracket_format': 'sabo_de32', // ✅ ADDED
        'created_at': DateTime.now().toIso8601String(),
      });
      matchNumber++;
    }

    // Grand Final (1 match): 33101
    // Round 302 (2→1 Winner!)
    {
      final displayOrder = 33101;
      final advancement = advancementMap[displayOrder]!;
      allMatches.add({
        'tournament_id': tournamentId,
        'match_number': matchNumber,
        'round_number': 302, // ✅ Grand Final round 302
        'bracket_type': 'GF',
        'bracket_group': null,
        'stage_round': 1,
        'display_order': displayOrder,
        'winner_advances_to': advancement['winner'],
        'loser_advances_to': advancement['loser'],
        'round': RoundNameCalculator.calculate(
          bracketType: 'GF',
          stageRound: 1,
          displayOrder: displayOrder,
        ),
        'player1_id': null,
        'player2_id': null,
        'status': 'pending',
        'match_type': 'tournament', // ✅ ADDED
        'bracket_format': 'sabo_de32', // ✅ ADDED
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return allMatches;
  }

  /// Calculate advancement mapping for all 55 matches
  /// Returns display_order values for winner_advances_to and loser_advances_to
  Map<int, Map<String, int?>> _calculateAdvancementMap() {
    final map = <int, Map<String, int?>>{};

    // ========================================
    // GROUP A ADVANCEMENT (24 matches)
    // ========================================

    // Group A - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[11101] = {'winner': 11201, 'loser': 12101}; // displayOrder 11101
    map[11102] = {'winner': 11201, 'loser': 12101}; // displayOrder 11102
    map[11103] = {'winner': 11202, 'loser': 12102}; // displayOrder 11103
    map[11104] = {'winner': 11202, 'loser': 12102}; // displayOrder 11104
    map[11105] = {'winner': 11203, 'loser': 12103}; // displayOrder 11105
    map[11106] = {'winner': 11203, 'loser': 12103}; // displayOrder 11106
    map[11107] = {'winner': 11204, 'loser': 12104}; // displayOrder 11107
    map[11108] = {'winner': 11204, 'loser': 12104}; // displayOrder 11108

    // Group A - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[11201] = {'winner': 11301, 'loser': 13101}; // displayOrder 11201
    map[11202] = {'winner': 11301, 'loser': 13101}; // displayOrder 11202
    map[11203] = {'winner': 11302, 'loser': 13102}; // displayOrder 11203
    map[11204] = {'winner': 11302, 'loser': 13102}; // displayOrder 11204

    // Group A - WB R3 (2 matches): winner to Cross SF, NO LOSER ADVANCEMENT
    map[11301] = {'winner': 31101, 'loser': null}; // displayOrder 11301
    map[11302] = {'winner': 31102, 'loser': null}; // displayOrder 11302

    // Group A - LB-A R1 (4 matches): winner to LB-A R2
    map[12101] = {'winner': 12201, 'loser': null}; // displayOrder 12101
    map[12102] = {'winner': 12201, 'loser': null}; // displayOrder 12102
    map[12103] = {'winner': 12202, 'loser': null}; // displayOrder 12103
    map[12104] = {'winner': 12202, 'loser': null}; // displayOrder 12104

    // Group A - LB-A R2 (2 matches): winner to LB-A R3
    map[12201] = {'winner': 12301, 'loser': null}; // displayOrder 12201
    map[12202] = {'winner': 12301, 'loser': null}; // displayOrder 12202

    // Group A - LB-A R3 (1 match): winner to Cross SF2
    map[12301] = {'winner': 31102, 'loser': null}; // displayOrder 12301

    // Group A - LB-B R1 (2 matches): winner to LB-B R2
    map[13101] = {'winner': 13201, 'loser': null}; // displayOrder 13101
    map[13102] = {'winner': 13201, 'loser': null}; // displayOrder 13102

    // Group A - LB-B R2 (1 match): winner to Cross SF1
    map[13201] = {'winner': 31101, 'loser': null}; // displayOrder 13201

    // ========================================
    // GROUP B ADVANCEMENT (24 matches)
    // ========================================

    // Group B - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[21101] = {'winner': 21201, 'loser': 22101}; // displayOrder 21101
    map[21102] = {'winner': 21201, 'loser': 22101}; // displayOrder 21102
    map[21103] = {'winner': 21202, 'loser': 22102}; // displayOrder 21103
    map[21104] = {'winner': 21202, 'loser': 22102}; // displayOrder 21104
    map[21105] = {'winner': 21203, 'loser': 22103}; // displayOrder 21105
    map[21106] = {'winner': 21203, 'loser': 22103}; // displayOrder 21106
    map[21107] = {'winner': 21204, 'loser': 22104}; // displayOrder 21107
    map[21108] = {'winner': 21204, 'loser': 22104}; // displayOrder 21108

    // Group B - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[21201] = {'winner': 21301, 'loser': 23101}; // displayOrder 21201
    map[21202] = {'winner': 21301, 'loser': 23101}; // displayOrder 21202
    map[21203] = {'winner': 21302, 'loser': 23102}; // displayOrder 21203
    map[21204] = {'winner': 21302, 'loser': 23102}; // displayOrder 21204

    // Group B - WB R3 (2 matches): winner to Cross SF, NO LOSER ADVANCEMENT
    map[21301] = {'winner': 31103, 'loser': null}; // displayOrder 21301
    map[21302] = {'winner': 31104, 'loser': null}; // displayOrder 21302

    // Group B - LB-A R1 (4 matches): winner to LB-A R2
    map[22101] = {'winner': 22201, 'loser': null}; // displayOrder 22101
    map[22102] = {'winner': 22201, 'loser': null}; // displayOrder 22102
    map[22103] = {'winner': 22202, 'loser': null}; // displayOrder 22103
    map[22104] = {'winner': 22202, 'loser': null}; // displayOrder 22104

    // Group B - LB-A R2 (2 matches): winner to LB-A R3
    map[22201] = {'winner': 22301, 'loser': null}; // displayOrder 22201
    map[22202] = {'winner': 22301, 'loser': null}; // displayOrder 22202

    // Group B - LB-A R3 (1 match): winner to Cross SF4
    map[22301] = {'winner': 31104, 'loser': null}; // displayOrder 22301

    // Group B - LB-B R1 (2 matches): winner to LB-B R2
    map[23101] = {'winner': 23201, 'loser': null}; // displayOrder 23101
    map[23102] = {'winner': 23201, 'loser': null}; // displayOrder 23102

    // Group B - LB-B R2 (1 match): winner to Cross SF3
    map[23201] = {'winner': 31103, 'loser': null}; // displayOrder 23201

    // ========================================
    // CROSS-BRACKET FINALS ADVANCEMENT (7 matches)
    // ========================================

    // Cross Semi-Finals (4 matches): winner to Finals
    map[31101] = {'winner': 32101, 'loser': null}; // displayOrder 31101
    map[31102] = {'winner': 32101, 'loser': null}; // displayOrder 31102
    map[31103] = {'winner': 32102, 'loser': null}; // displayOrder 31103
    map[31104] = {'winner': 32102, 'loser': null}; // displayOrder 31104

    // Cross Finals (2 matches): winner to Grand Final
    map[32101] = {'winner': 33101, 'loser': null}; // displayOrder 32101
    map[32102] = {'winner': 33101, 'loser': null}; // displayOrder 32102

    // Grand Final (1 match): winner is champion, no advancement
    map[33101] = {'winner': null, 'loser': null}; // displayOrder 33101

    return map;
  }

  /// Process match result
  Future<Map<String, dynamic>> processMatchResult({
    required String matchId,
    required String winnerId,
    required Map<String, int> scores,
  }) async {
    // Get match details to find loser
    final match = await supabase
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
