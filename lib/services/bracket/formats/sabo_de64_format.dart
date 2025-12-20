import 'package:supabase_flutter/supabase_flutter.dart';
import '../../universal_match_progression_service.dart';
import 'package:sabo_arena/utils/round_name_calculator.dart';

/// SABO DE64 Hardcoded Service (ENHANCED LB-B VERSION)
///
/// Structure:
/// - Total: 119 matches (upgraded from 99 matches)
/// - Group A: 26 matches (enhanced from 21)
///   - Winner Bracket: 14 matches (8+4+2) - same
///   - Loser Branch A: 7 matches (4+2+1) - same
///   - Loser Branch B: 5 matches (2+1+1+1) - ENHANCED! Added R3 and R4
/// - Group B: 26 matches
/// - Group C: 26 matches
/// - Group D: 26 matches
/// - Cross-Bracket Finals: 15 matches (same)
///
/// Enhancement Details:
/// - Added LB-B Round 3: takes 2 losers from WB R3 (concurrent with LB-B R2)
/// - Added LB-B Round 4: LB-B R3 winner vs LB-B R2 winner
/// - This gives more chances to strong players who lose in Group Finals
///
/// Display Order System:
/// - Group A WB: 11xxx (11101-11302) - same
/// - Group A LB-A: 12xxx (12101-12301) - same
/// - Group A LB-B: 13xxx (13101-13401) - ENHANCED! Added 13301, 13401
/// - Group B WB: 21xxx (21101-21302) - same
/// - Group B LB-A: 22xxx (22101-22301) - same
/// - Group B LB-B: 23xxx (23101-23401) - ENHANCED! Added 23301, 23401
/// - Group C WB: 31xxx (31101-31302) - same
/// - Group C LB-A: 32xxx (32101-32301) - same
/// - Group C LB-B: 33xxx (33101-33401) - ENHANCED! Added 33301, 33401
/// - Group D WB: 41xxx (41101-41302) - same
/// - Group D LB-A: 42xxx (42101-42301) - same
/// - Group D LB-B: 43xxx (43101-43401) - ENHANCED! Added 43301, 43401
/// - Cross Round of 16: 51xxx (51101-51108) - same
/// - Cross Quarter-Finals: 52xxx (52101-52104) - same
/// - Cross Semi-Finals: 53xxx (53101-53102) - same
/// - Grand Final: 54xxx (54101) - same
///
/// Key Features:
/// - Each group uses enhanced SABO DE16+ format (26 matches)
/// - WB has 3 rounds: R1(8) → R2(4) → R3(2), losers from R3 go to LB-B R3
/// - LB-A has 3 rounds: R1(4) → R2(2) → R3(1 - winner to Cross Finals) - same
/// - LB-B has 4 rounds: R1(2) → R2(1) → R3(1 from WB R3 losers) → R4(1 - winner to Cross Finals)
/// - Each group produces 4 qualifiers (2 WB R3 + 1 LB-A R3 + 1 LB-B R4)
/// - Cross-bracket finals: 16 qualifiers → single elimination
class HardcodedSaboDE64Service {
  final SupabaseClient supabase;

  HardcodedSaboDE64Service(this.supabase);

  /// Create SABO DE64 bracket with advancement and save to database
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
        'message': 'SABO DE64 bracket created successfully',
        'total_matches': matches.length,
        'matches_generated': matches.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Helper to create match object with all required fields
  Map<String, dynamic> _createMatch({
    required String tournamentId,
    required int matchNumber,
    required int roundNumber,
    required String bracketType,
    required String bracketGroup,
    required int stageRound,
    required int displayOrder,
    int? winnerAdvancesTo,
    int? loserAdvancesTo,
    String? player1Id,
    String? player2Id,
    int? player1SourceMatch, // ✅ NEW: Track where player1 comes from
    int? player2SourceMatch, // ✅ NEW: Track where player2 comes from
    String? player1SourceType, // ✅ NEW: 'winner' or 'loser'
    String? player2SourceType, // ✅ NEW: 'winner' or 'loser'
  }) {
    // Calculate round name using shared utility
    final roundName = RoundNameCalculator.calculate(
      bracketType: bracketType,
      bracketGroup: bracketGroup,
      stageRound: stageRound,
      displayOrder: displayOrder,
    );

    // Auto-detect status: if both players assigned, match is ready to play
    final status = (player1Id != null && player2Id != null)
        ? 'in_progress' // Both players → ready to play
        : 'pending'; // Waiting for players

    return {
      'tournament_id': tournamentId,
      'match_number': matchNumber,
      'round_number': roundNumber,
      'bracket_type': bracketType,
      'bracket_group': bracketGroup,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'winner_advances_to':
          winnerAdvancesTo != null ? 'M$winnerAdvancesTo' : null,
      'loser_advances_to': loserAdvancesTo != null ? 'M$loserAdvancesTo' : null,
      'player1_source_match':
          player1SourceMatch != null ? 'M$player1SourceMatch' : null, // ✅ NEW
      'player2_source_match':
          player2SourceMatch != null ? 'M$player2SourceMatch' : null, // ✅ NEW
      'player1_source_type': player1SourceType, // ✅ NEW
      'player2_source_type': player2SourceType, // ✅ NEW
      'status':
          status, // ✅ SMART STATUS: 'in_progress' if both players, else 'pending'
      'stage_round': stageRound,
      'display_order': displayOrder,
      'round': roundName,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Generate complete SABO DE64 bracket structure
  Future<List<Map<String, dynamic>>> generateBracket({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    if (participantIds.length != 64) {
      throw Exception('SABO DE64 requires exactly 64 participants');
    }

    final allMatches = <Map<String, dynamic>>[];
    final advancementMap = _calculateAdvancementMap();
    int matchNumber = 1;

    // ========================================
    // GROUP A (26 matches) - Players P1-P16
    // ========================================
    matchNumber = await _generateGroupMatches(
      allMatches: allMatches,
      participantIds: participantIds.sublist(0, 16),
      groupId: 'A',
      groupPrefix: 1,
      tournamentId: tournamentId,
      advancementMap: advancementMap,
      startMatchNumber: matchNumber,
    );

    // ========================================
    // GROUP B (26 matches) - Players P17-P32
    // ========================================
    matchNumber = await _generateGroupMatches(
      allMatches: allMatches,
      participantIds: participantIds.sublist(16, 32),
      groupId: 'B',
      groupPrefix: 2,
      tournamentId: tournamentId,
      advancementMap: advancementMap,
      startMatchNumber: matchNumber,
    );

    // ========================================
    // GROUP C (26 matches) - Players P33-P48
    // ========================================
    matchNumber = await _generateGroupMatches(
      allMatches: allMatches,
      participantIds: participantIds.sublist(32, 48),
      groupId: 'C',
      groupPrefix: 3,
      tournamentId: tournamentId,
      advancementMap: advancementMap,
      startMatchNumber: matchNumber,
    );

    // ========================================
    // GROUP D (26 matches) - Players P49-P64
    // ========================================
    matchNumber = await _generateGroupMatches(
      allMatches: allMatches,
      participantIds: participantIds.sublist(48, 64),
      groupId: 'D',
      groupPrefix: 4,
      tournamentId: tournamentId,
      advancementMap: advancementMap,
      startMatchNumber: matchNumber,
    );

    // ========================================
    // CROSS-BRACKET FINALS (15 matches: 8+4+2+1)
    // ========================================
    // Each group sends 4 qualifiers:
    // - Group A: WB R3 wins (11301, 11302), LB-A R3 win (12301), LB-B R4 win (13401)
    // - Group B: WB R3 wins (21301, 21302), LB-A R3 win (22301), LB-B R4 win (23401)
    // - Group C: WB R3 wins (31301, 31302), LB-A R3 win (32301), LB-B R4 win (33401)
    // - Group D: WB R3 wins (41301, 41302), LB-A R3 win (42301), LB-B R4 win (43401)

    // Cross Round of 16 (8 matches): 51101-51108
    // Seeding: A1 vs D4, A2 vs D3, B1 vs C4, B2 vs C3, C1 vs B4, C2 vs B3, D1 vs A4, D2 vs A3
    final crossR16SourceMap = {
      51101: {
        'p1_source': 11301,
        'p1_type': 'winner',
        'p2_source': 43401,
        'p2_type': 'winner'
      }, // A1 (WB #1) vs D4 (LB-B)
      51102: {
        'p1_source': 11302,
        'p1_type': 'winner',
        'p2_source': 42301,
        'p2_type': 'winner'
      }, // A2 (WB #2) vs D3 (LB-A)
      51103: {
        'p1_source': 21301,
        'p1_type': 'winner',
        'p2_source': 33401,
        'p2_type': 'winner'
      }, // B1 (WB #1) vs C4 (LB-B)
      51104: {
        'p1_source': 21302,
        'p1_type': 'winner',
        'p2_source': 32301,
        'p2_type': 'winner'
      }, // B2 (WB #2) vs C3 (LB-A)
      51105: {
        'p1_source': 31301,
        'p1_type': 'winner',
        'p2_source': 23401,
        'p2_type': 'winner'
      }, // C1 (WB #1) vs B4 (LB-B)
      51106: {
        'p1_source': 31302,
        'p1_type': 'winner',
        'p2_source': 22301,
        'p2_type': 'winner'
      }, // C2 (WB #2) vs B3 (LB-A)
      51107: {
        'p1_source': 41301,
        'p1_type': 'winner',
        'p2_source': 13401,
        'p2_type': 'winner'
      }, // D1 (WB #1) vs A4 (LB-B)
      51108: {
        'p1_source': 41302,
        'p1_type': 'winner',
        'p2_source': 12301,
        'p2_type': 'winner'
      }, // D2 (WB #2) vs A3 (LB-A)
    };

    for (var entry in crossR16SourceMap.entries) {
      final displayOrder = entry.key;
      final sources = entry.value;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 1,
          bracketType: 'R16',
          bracketGroup: 'CROSS',
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
          player1SourceMatch: sources['p1_source'] as int,
          player2SourceMatch: sources['p2_source'] as int,
          player1SourceType: sources['p1_type'] as String,
          player2SourceType: sources['p2_type'] as String,
        ),
      );
      matchNumber++;
    }

    // Cross Quarter-Finals (4 matches): 52101-52104
    final crossQFPairs = [52101, 52102, 52103, 52104];

    for (int i = 0; i < crossQFPairs.length; i++) {
      final displayOrder = crossQFPairs[i];
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 2,
          bracketType: 'QF',
          bracketGroup: 'CROSS',
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Cross Semi-Finals (2 matches): 53101-53102
    final crossSFPairs = [53101, 53102];

    for (int i = 0; i < crossSFPairs.length; i++) {
      final displayOrder = crossSFPairs[i];
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 3,
          bracketType: 'SF',
          bracketGroup: 'CROSS',
          stageRound: 3,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // Grand Final (1 match): 54101
    final advancement = advancementMap[54101]!;
    allMatches.add(
      _createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber,
        roundNumber: 4,
        bracketType: 'GF',
        bracketGroup: 'CROSS',
        stageRound: 4,
        displayOrder: 54101,
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ),
    );

    return allMatches;
  }

  /// Generate matches for one group (26 matches each)
  Future<int> _generateGroupMatches({
    required List<Map<String, dynamic>> allMatches,
    required List<String> participantIds,
    required String groupId,
    required int groupPrefix,
    required String tournamentId,
    required Map<int, Map<String, dynamic>> advancementMap,
    required int startMatchNumber,
  }) async {
    int matchNumber = startMatchNumber;

    // Group WB Round 1 (8 matches): X1101-X1108
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
      final displayOrder = (groupPrefix * 10000) + 1101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 1,
          bracketType: 'WB',
          bracketGroup: groupId,
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
          player1Id: participantIds[pair[0]],
          player2Id: participantIds[pair[1]],
        ),
      );
      matchNumber++;
    }

    // Continue with WB Round 2, WB Round 3, LB-A, LB-B
    // (Implementation similar to DE32 but with group prefix)

    // WB Round 2 (4 matches)
    for (int i = 0; i < 4; i++) {
      final displayOrder = (groupPrefix * 10000) + 1201 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 2,
          bracketType: 'WB',
          bracketGroup: groupId,
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // WB Round 3 (2 matches - Group Finals, winners qualify for Cross Finals)
    for (int i = 0; i < 2; i++) {
      final displayOrder = (groupPrefix * 10000) + 1301 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 3,
          bracketType: 'WB',
          bracketGroup: groupId,
          stageRound: 3,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'], // To Cross Finals
          loserAdvancesTo:
              advancement['loser'], // ✅ FIXED: To LB-B R3 (not eliminated!)
        ),
      );
      matchNumber++;
    }

    // LB-A Round 1 (4 matches)
    for (int i = 0; i < 4; i++) {
      final displayOrder = (groupPrefix * 10000) + 2101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 101,
          bracketType: 'LB-A',
          bracketGroup: groupId,
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // LB-A Round 2 (2 matches)
    for (int i = 0; i < 2; i++) {
      final displayOrder = (groupPrefix * 10000) + 2201 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 102,
          bracketType: 'LB-A',
          bracketGroup: groupId,
          stageRound: 2,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // LB-A Round 3 (1 match)
    final displayOrder = (groupPrefix * 10000) + 2301;
    final advancement = advancementMap[displayOrder]!;

    allMatches.add(
      _createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber,
        roundNumber: 103,
        bracketType: 'LB-A',
        bracketGroup: groupId,
        stageRound: 3,
        displayOrder: displayOrder,
        winnerAdvancesTo: advancement['winner'],
        loserAdvancesTo: advancement['loser'],
      ),
    );
    matchNumber++;

    // LB-B Round 1 (2 matches)
    for (int i = 0; i < 2; i++) {
      final displayOrder = (groupPrefix * 10000) + 3101 + i;
      final advancement = advancementMap[displayOrder]!;

      allMatches.add(
        _createMatch(
          tournamentId: tournamentId,
          matchNumber: matchNumber,
          roundNumber: 201,
          bracketType: 'LB-B',
          bracketGroup: groupId,
          stageRound: 1,
          displayOrder: displayOrder,
          winnerAdvancesTo: advancement['winner'],
          loserAdvancesTo: advancement['loser'],
        ),
      );
      matchNumber++;
    }

    // LB-B Round 2 (1 match - LB-B Semi-Final)
    final lbBR2DisplayOrder = (groupPrefix * 10000) + 3201;
    final lbBR2Advancement = advancementMap[lbBR2DisplayOrder]!;

    allMatches.add(
      _createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber,
        roundNumber: 202,
        bracketType: 'LB-B',
        bracketGroup: groupId,
        stageRound: 2,
        displayOrder: lbBR2DisplayOrder,
        winnerAdvancesTo: lbBR2Advancement['winner'],
        loserAdvancesTo: lbBR2Advancement['loser'],
      ),
    );
    matchNumber++;

    // LB-B Round 3 (1 match - WB R3 Losers Match, concurrent with LB-B R2)
    final lbBR3DisplayOrder = (groupPrefix * 10000) + 3301;
    final lbBR3Advancement = advancementMap[lbBR3DisplayOrder]!;

    allMatches.add(
      _createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber,
        roundNumber: 202, // Same round number as LB-B R2 - concurrent
        bracketType: 'LB-B',
        bracketGroup: groupId,
        stageRound: 3,
        displayOrder: lbBR3DisplayOrder,
        winnerAdvancesTo: lbBR3Advancement['winner'],
        loserAdvancesTo: lbBR3Advancement['loser'],
      ),
    );
    matchNumber++;

    // LB-B Round 4 (1 match - LB-B Final)
    final lbBR4DisplayOrder = (groupPrefix * 10000) + 3401;
    final lbBR4Advancement = advancementMap[lbBR4DisplayOrder]!;

    allMatches.add(
      _createMatch(
        tournamentId: tournamentId,
        matchNumber: matchNumber,
        roundNumber: 203,
        bracketType: 'LB-B',
        bracketGroup: groupId,
        stageRound: 4,
        displayOrder: lbBR4DisplayOrder,
        winnerAdvancesTo: lbBR4Advancement['winner'],
        loserAdvancesTo: lbBR4Advancement['loser'],
      ),
    );
    matchNumber++;

    return matchNumber;
  }

  /// Calculate advancement map for all 111 matches
  Map<int, Map<String, dynamic>> _calculateAdvancementMap() {
    final map = <int, Map<String, dynamic>>{};

    // ========================================
    // GROUP A ADVANCEMENT (26 matches)
    // ========================================

    // Group A - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[11101] = {'winner': 11201, 'loser': 12101};
    map[11102] = {'winner': 11201, 'loser': 12101};
    map[11103] = {'winner': 11202, 'loser': 12102};
    map[11104] = {'winner': 11202, 'loser': 12102};
    map[11105] = {'winner': 11203, 'loser': 12103};
    map[11106] = {'winner': 11203, 'loser': 12103};
    map[11107] = {'winner': 11204, 'loser': 12104};
    map[11108] = {'winner': 11204, 'loser': 12104};

    // Group A - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[11201] = {'winner': 11301, 'loser': 13101};
    map[11202] = {'winner': 11301, 'loser': 13101};
    map[11203] = {'winner': 11302, 'loser': 13102};
    map[11204] = {'winner': 11302, 'loser': 13102};

    // Group A - WB R3 (2 matches - Group Finals): winners qualify for Cross R16, losers to LB-B R3
    map[11301] = {
      'winner': 51101,
      'loser': 13301
    }; // A1 (WB #1) vs B4 at R16-1, loser to LB-B R3
    map[11302] = {
      'winner': 51102,
      'loser': 13301
    }; // A2 (WB #2) vs C3 at R16-2, loser to LB-B R3

    // Group A - LB-A R1 (4 matches): winner to LB-A R2
    map[12101] = {'winner': 12201, 'loser': null};
    map[12102] = {'winner': 12201, 'loser': null};
    map[12103] = {'winner': 12202, 'loser': null};
    map[12104] = {'winner': 12202, 'loser': null};

    // Group A - LB-A R2 (2 matches): winner to LB-A R3
    map[12201] = {'winner': 12301, 'loser': null};
    map[12202] = {'winner': 12301, 'loser': null};

    // Group A - LB-A R3 (1 match): winner qualifies for Cross R16
    map[12301] = {'winner': 51106, 'loser': null}; // A3 (LB-A) vs C2 at R16-6

    // Group A - LB-B R1 (2 matches): winner to LB-B R2
    map[13101] = {'winner': 13201, 'loser': null};
    map[13102] = {'winner': 13201, 'loser': null};

    // Group A - LB-B R2 (1 match - LB-B Semi-Final): winner to LB-B R4
    map[13201] = {
      'winner': 13401,
      'loser': null
    }; // A-LB-B Semi-Final winner to LB-B R4

    // Group A - LB-B R3 (1 match - WB R3 Losers Match): winner to LB-B R4
    map[13301] = {
      'winner': 13401,
      'loser': null
    }; // WB R3 losers battle, winner to LB-B R4

    // Group A - LB-B R4 (1 match - LB-B Final): winner qualifies for Cross R16
    map[13401] = {'winner': 51107, 'loser': null}; // A4 (LB-B) vs D1 at R16-7

    // ========================================
    // GROUP B ADVANCEMENT (26 matches)
    // ========================================

    // Group B - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[21101] = {'winner': 21201, 'loser': 22101};
    map[21102] = {'winner': 21201, 'loser': 22101};
    map[21103] = {'winner': 21202, 'loser': 22102};
    map[21104] = {'winner': 21202, 'loser': 22102};
    map[21105] = {'winner': 21203, 'loser': 22103};
    map[21106] = {'winner': 21203, 'loser': 22103};
    map[21107] = {'winner': 21204, 'loser': 22104};
    map[21108] = {'winner': 21204, 'loser': 22104};

    // Group B - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[21201] = {'winner': 21301, 'loser': 23101};
    map[21202] = {'winner': 21301, 'loser': 23101};
    map[21203] = {'winner': 21302, 'loser': 23102};
    map[21204] = {'winner': 21302, 'loser': 23102};

    // Group B - WB R3 (2 matches - Group Finals): winners qualify for Cross R16, losers to LB-B R3
    map[21301] = {
      'winner': 51103,
      'loser': 23301
    }; // B1 (WB #1) vs A4 at R16-3, loser to LB-B R3
    map[21302] = {
      'winner': 51104,
      'loser': 23301
    }; // B2 (WB #2) vs D3 at R16-4, loser to LB-B R3

    // Group B - LB-A R1 (4 matches): winner to LB-A R2
    map[22101] = {'winner': 22201, 'loser': null};
    map[22102] = {'winner': 22201, 'loser': null};
    map[22103] = {'winner': 22202, 'loser': null};
    map[22104] = {'winner': 22202, 'loser': null};

    // Group B - LB-A R2 (2 matches): winner to LB-A R3
    map[22201] = {'winner': 22301, 'loser': null};
    map[22202] = {'winner': 22301, 'loser': null};

    // Group B - LB-A R3 (1 match): winner qualifies for Cross R16
    map[22301] = {'winner': 51108, 'loser': null}; // B3 (LB-A) vs D2 at R16-8

    // Group B - LB-B R1 (2 matches): winner to LB-B R2
    map[23101] = {'winner': 23201, 'loser': null};
    map[23102] = {'winner': 23201, 'loser': null};

    // Group B - LB-B R2 (1 match - LB-B Semi-Final): winner to LB-B R4
    map[23201] = {
      'winner': 23401,
      'loser': null
    }; // B-LB-B Semi-Final winner to LB-B R4

    // Group B - LB-B R3 (1 match - WB R3 Losers Match): winner to LB-B R4
    map[23301] = {
      'winner': 23401,
      'loser': null
    }; // WB R3 losers battle, winner to LB-B R4

    // Group B - LB-B R4 (1 match - LB-B Final): winner qualifies for Cross R16
    map[23401] = {'winner': 51101, 'loser': null}; // B4 (LB-B) vs A1 at R16-1

    // ========================================
    // GROUP C ADVANCEMENT (26 matches)
    // ========================================

    // Group C - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[31101] = {'winner': 31201, 'loser': 32101};
    map[31102] = {'winner': 31201, 'loser': 32101};
    map[31103] = {'winner': 31202, 'loser': 32102};
    map[31104] = {'winner': 31202, 'loser': 32102};
    map[31105] = {'winner': 31203, 'loser': 32103};
    map[31106] = {'winner': 31203, 'loser': 32103};
    map[31107] = {'winner': 31204, 'loser': 32104};
    map[31108] = {'winner': 31204, 'loser': 32104};

    // Group C - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[31201] = {'winner': 31301, 'loser': 33101};
    map[31202] = {'winner': 31301, 'loser': 33101};
    map[31203] = {'winner': 31302, 'loser': 33102};
    map[31204] = {'winner': 31302, 'loser': 33102};

    // Group C - WB R3 (2 matches - Group Finals): winners qualify for Cross R16, losers to LB-B R3
    map[31301] = {
      'winner': 51105,
      'loser': 33301
    }; // C1 (WB #1) vs D4 at R16-5, loser to LB-B R3
    map[31302] = {
      'winner': 51106,
      'loser': 33301
    }; // C2 (WB #2) vs A3 at R16-6, loser to LB-B R3

    // Group C - LB-A R1 (4 matches): winner to LB-A R2
    map[32101] = {'winner': 32201, 'loser': null};
    map[32102] = {'winner': 32201, 'loser': null};
    map[32103] = {'winner': 32202, 'loser': null};
    map[32104] = {'winner': 32202, 'loser': null};

    // Group C - LB-A R2 (2 matches): winner to LB-A R3
    map[32201] = {'winner': 32301, 'loser': null};
    map[32202] = {'winner': 32301, 'loser': null};

    // Group C - LB-A R3 (1 match): winner qualifies for Cross R16
    map[32301] = {'winner': 51102, 'loser': null}; // C3 (LB-A) vs A2 at R16-2

    // Group C - LB-B R1 (2 matches): winner to LB-B R2
    map[33101] = {'winner': 33201, 'loser': null};
    map[33102] = {'winner': 33201, 'loser': null};

    // Group C - LB-B R2 (1 match - LB-B Semi-Final): winner to LB-B R4
    map[33201] = {
      'winner': 33401,
      'loser': null
    }; // C-LB-B Semi-Final winner to LB-B R4

    // Group C - LB-B R3 (1 match - WB R3 Losers Match): winner to LB-B R4
    map[33301] = {
      'winner': 33401,
      'loser': null
    }; // WB R3 losers battle, winner to LB-B R4

    // Group C - LB-B R4 (1 match - LB-B Final): winner qualifies for Cross R16
    map[33401] = {'winner': 51102, 'loser': null}; // C4 (LB-B) vs A2 at R16-2

    // ========================================
    // GROUP D ADVANCEMENT (26 matches)
    // ========================================

    // Group D - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[41101] = {'winner': 41201, 'loser': 42101};
    map[41102] = {'winner': 41201, 'loser': 42101};
    map[41103] = {'winner': 41202, 'loser': 42102};
    map[41104] = {'winner': 41202, 'loser': 42102};
    map[41105] = {'winner': 41203, 'loser': 42103};
    map[41106] = {'winner': 41203, 'loser': 42103};
    map[41107] = {'winner': 41204, 'loser': 42104};
    map[41108] = {'winner': 41204, 'loser': 42104};

    // Group D - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[41201] = {'winner': 41301, 'loser': 43101};
    map[41202] = {'winner': 41301, 'loser': 43101};
    map[41203] = {'winner': 41302, 'loser': 43102};
    map[41204] = {'winner': 41302, 'loser': 43102};

    // Group D - WB R3 (2 matches - Group Finals): winners qualify for Cross R16, losers to LB-B R3
    map[41301] = {
      'winner': 51107,
      'loser': 43301
    }; // D1 (WB #1) vs A4 at R16-7, loser to LB-B R3
    map[41302] = {
      'winner': 51108,
      'loser': 43301
    }; // D2 (WB #2) vs B3 at R16-8, loser to LB-B R3

    // Group D - LB-A R1 (4 matches): winner to LB-A R2
    map[42101] = {'winner': 42201, 'loser': null};
    map[42102] = {'winner': 42201, 'loser': null};
    map[42103] = {'winner': 42202, 'loser': null};
    map[42104] = {'winner': 42202, 'loser': null};

    // Group D - LB-A R2 (2 matches): winner to LB-A R3
    map[42201] = {'winner': 42301, 'loser': null};
    map[42202] = {'winner': 42301, 'loser': null};

    // Group D - LB-A R3 (1 match): winner qualifies for Cross R16
    map[42301] = {'winner': 51104, 'loser': null}; // D3 (LB-A) vs B2 at R16-4

    // Group D - LB-B R1 (2 matches): winner to LB-B R2
    map[43101] = {'winner': 43201, 'loser': null};
    map[43102] = {'winner': 43201, 'loser': null};

    // Group D - LB-B R2 (1 match - LB-B Semi-Final): winner to LB-B R4
    map[43201] = {
      'winner': 43401,
      'loser': null
    }; // D-LB-B Semi-Final winner to LB-B R4

    // Group D - LB-B R3 (1 match - WB R3 Losers Match): winner to LB-B R4
    map[43301] = {
      'winner': 43401,
      'loser': null
    }; // WB R3 losers battle, winner to LB-B R4

    // Group D - LB-B R4 (1 match - LB-B Final): winner qualifies for Cross R16
    map[43401] = {'winner': 51105, 'loser': null}; // D4 (LB-B) vs C1 at R16-5

    // ========================================
    // CROSS-BRACKET FINALS ADVANCEMENT (15 matches: R16→QF→SF→GF)
    // ========================================

    // Cross Round of 16 (8 matches): winner to Quarter-Finals
    map[51101] = {'winner': 52101, 'loser': null}; // R16-1 → QF1
    map[51102] = {'winner': 52101, 'loser': null}; // R16-2 → QF1
    map[51103] = {'winner': 52102, 'loser': null}; // R16-3 → QF2
    map[51104] = {'winner': 52102, 'loser': null}; // R16-4 → QF2
    map[51105] = {'winner': 52103, 'loser': null}; // R16-5 → QF3
    map[51106] = {'winner': 52103, 'loser': null}; // R16-6 → QF3
    map[51107] = {'winner': 52104, 'loser': null}; // R16-7 → QF4
    map[51108] = {'winner': 52104, 'loser': null}; // R16-8 → QF4

    // Cross Quarter-Finals (4 matches): winner to Semi-Finals
    map[52101] = {'winner': 53101, 'loser': null}; // QF1 → SF1
    map[52102] = {'winner': 53101, 'loser': null}; // QF2 → SF1
    map[52103] = {'winner': 53102, 'loser': null}; // QF3 → SF2
    map[52104] = {'winner': 53102, 'loser': null}; // QF4 → SF2

    // Cross Semi-Finals (2 matches): winner to Grand Final
    map[53101] = {'winner': 54101, 'loser': null}; // SF1 → GF
    map[53102] = {'winner': 54101, 'loser': null}; // SF2 → GF

    // Grand Final (1 match): winner is champion, no advancement
    map[54101] = {'winner': null, 'loser': null}; // Champion!

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
    return await UniversalMatchProgressionService.instance
        .updateMatchResultWithImmediateAdvancement(
      matchId: matchId,
      tournamentId: tournamentId,
      winnerId: winnerId,
      loserId: loserId,
      scores: scores,
    );
  }
}
