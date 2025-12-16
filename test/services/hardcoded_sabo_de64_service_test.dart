import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/bracket/formats/sabo_de64_format.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('HardcodedSaboDE64Service', () {
    late HardcodedSaboDE64Service service;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      service = HardcodedSaboDE64Service(mockSupabase);
    });

    test('generates exactly 111 matches for 64 participants', () async {
      // Arrange
      final participantIds = List.generate(64, (i) => 'player_$i');
      const tournamentId = 'test-tournament-id';

      // Act
      final matches = await service.generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
      );

      // Assert
      expect(matches.length, equals(111));
      print('✅ Total matches: ${matches.length}');
    });

    test('distributes matches correctly across groups', () async {
      // Arrange
      final participantIds = List.generate(64, (i) => 'player_$i');
      const tournamentId = 'test-tournament-id';

      // Act
      final matches = await service.generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
      );

      // Assert
      final groupA = matches.where((m) => m['bracket_group'] == 'A').length;
      final groupB = matches.where((m) => m['bracket_group'] == 'B').length;
      final groupC = matches.where((m) => m['bracket_group'] == 'C').length;
      final groupD = matches.where((m) => m['bracket_group'] == 'D').length;
      final cross = matches.where((m) => m['bracket_group'] == 'CROSS').length;

      expect(groupA, equals(26), reason: 'Group A should have 26 matches');
      expect(groupB, equals(26), reason: 'Group B should have 26 matches');
      expect(groupC, equals(26), reason: 'Group C should have 26 matches');
      expect(groupD, equals(26), reason: 'Group D should have 26 matches');
      expect(cross, equals(7), reason: 'Cross Finals should have 7 matches');

      print('✅ Group A: $groupA matches');
      print('✅ Group B: $groupB matches');
      print('✅ Group C: $groupC matches');
      print('✅ Group D: $groupD matches');
      print('✅ Cross Finals: $cross matches');
    });

    test('verifies WB structure for each group', () async {
      // Arrange
      final participantIds = List.generate(64, (i) => 'player_$i');
      const tournamentId = 'test-tournament-id';

      // Act
      final matches = await service.generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
      );

      // Assert - Check Group A WB rounds
      final groupAWB = matches.where((m) => 
        m['bracket_group'] == 'A' && m['bracket_type'] == 'WB'
      ).toList();

      final wbR1 = groupAWB.where((m) => m['stage_round'] == 1).length;
      final wbR2 = groupAWB.where((m) => m['stage_round'] == 2).length;
      final wbR3 = groupAWB.where((m) => m['stage_round'] == 3).length;
      final wbR4 = groupAWB.where((m) => m['stage_round'] == 4).length;

      expect(wbR1, equals(8), reason: 'WB Round 1 should have 8 matches');
      expect(wbR2, equals(4), reason: 'WB Round 2 should have 4 matches');
      expect(wbR3, equals(2), reason: 'WB Round 3 should have 2 matches');
      expect(wbR4, equals(1), reason: 'WB Round 4 should have 1 match (Group Final)');

      print('✅ WB R1: $wbR1 matches');
      print('✅ WB R2: $wbR2 matches');
      print('✅ WB R3: $wbR3 matches');
      print('✅ WB R4: $wbR4 matches (Group Final)');
    });

    test('verifies LB-B has 4 matches with Round 3', () async {
      // Arrange
      final participantIds = List.generate(64, (i) => 'player_$i');
      const tournamentId = 'test-tournament-id';

      // Act
      final matches = await service.generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
      );

      // Assert - Check Group A LB-B rounds
      final groupALBB = matches.where((m) => 
        m['bracket_group'] == 'A' && m['bracket_type'] == 'LB-B'
      ).toList();

      print('\n📋 Group A LB-B Matches:');
      for (var match in groupALBB) {
        print('  Match ${match['match_number']}: display_order=${match['display_order']}, stage_round=${match['stage_round']}');
      }

      final lbBR1 = groupALBB.where((m) => m['stage_round'] == 1).length;
      final lbBR2 = groupALBB.where((m) => m['stage_round'] == 2).length;
      final lbBR3 = groupALBB.where((m) => m['stage_round'] == 3).length;

      expect(groupALBB.length, equals(4), reason: 'LB-B should have 4 matches total');
      expect(lbBR1, equals(2), reason: 'LB-B Round 1 should have 2 matches');
      expect(lbBR2, equals(1), reason: 'LB-B Round 2 should have 1 match');
      expect(lbBR3, equals(1), reason: 'LB-B Round 3 should have 1 match (Group LB Final)');

      print('✅ LB-B Total: ${groupALBB.length} matches');
      print('✅ LB-B R1: $lbBR1 matches');
      print('✅ LB-B R2: $lbBR2 matches');
      print('✅ LB-B R3: $lbBR3 matches (Group LB Final)');
    });

    test('verifies Cross Finals advancement structure', () async {
      // Arrange
      final participantIds = List.generate(64, (i) => 'player_$i');
      const tournamentId = 'test-tournament-id';

      // Act
      final matches = await service.generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
      );

      // Assert - Find Cross Finals matches
      final qf1 = matches.firstWhere((m) => m['display_order'] == 51101);
      final qf2 = matches.firstWhere((m) => m['display_order'] == 51102);
      final qf3 = matches.firstWhere((m) => m['display_order'] == 51103);
      final qf4 = matches.firstWhere((m) => m['display_order'] == 51104);
      final sf1 = matches.firstWhere((m) => m['display_order'] == 52101);
      final sf2 = matches.firstWhere((m) => m['display_order'] == 52102);
      final gf = matches.firstWhere((m) => m['display_order'] == 53101);

      // Check QF advancement
      expect(qf1['winner_advances_to'], equals(52101), reason: 'QF1 winner should go to SF1');
      expect(qf2['winner_advances_to'], equals(52101), reason: 'QF2 winner should go to SF1');
      expect(qf3['winner_advances_to'], equals(52102), reason: 'QF3 winner should go to SF2');
      expect(qf4['winner_advances_to'], equals(52102), reason: 'QF4 winner should go to SF2');

      // Check SF advancement
      expect(sf1['winner_advances_to'], equals(53101), reason: 'SF1 winner should go to GF');
      expect(sf2['winner_advances_to'], equals(53101), reason: 'SF2 winner should go to GF');

      // Check GF has no advancement
      expect(gf['winner_advances_to'], isNull, reason: 'GF winner has no further advancement');

      print('✅ Cross Finals advancement structure verified');
    });

    test('verifies participants distribution across groups', () async {
      // Arrange
      final participantIds = List.generate(64, (i) => 'player_$i');
      const tournamentId = 'test-tournament-id';

      // Act
      final matches = await service.generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
      );

      // Assert - Check only WB R1 matches have participants assigned
      final wbR1Matches = matches.where((m) => 
        m['bracket_type'] == 'WB' && m['stage_round'] == 1
      ).toList();

      expect(wbR1Matches.length, equals(32), reason: '32 WB R1 matches (8 per group × 4 groups)');

      // Verify all participants are assigned
      final assignedPlayers = <String>{};
      for (var match in wbR1Matches) {
        if (match['player1_id'] != null) {
          assignedPlayers.add(match['player1_id']);
        }
        if (match['player2_id'] != null) {
          assignedPlayers.add(match['player2_id']);
        }
      }

      expect(assignedPlayers.length, equals(64), reason: 'All 64 participants should be assigned');

      print('✅ All 64 participants assigned to WB R1 matches');
    });

    test('verifies display order follows pattern', () async {
      // Arrange
      final participantIds = List.generate(64, (i) => 'player_$i');
      const tournamentId = 'test-tournament-id';

      // Act
      final matches = await service.generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
      );

      // Assert - Check display order patterns
      final groupAWBR1 = matches.where((m) => 
        m['bracket_group'] == 'A' && 
        m['bracket_type'] == 'WB' && 
        m['stage_round'] == 1
      ).map((m) => m['display_order']).toList()..sort();

      expect(groupAWBR1.first, equals(11101), reason: 'Group A WB R1 should start at 11101');
      expect(groupAWBR1.last, equals(11108), reason: 'Group A WB R1 should end at 11108');

      final groupBWBR1 = matches.where((m) => 
        m['bracket_group'] == 'B' && 
        m['bracket_type'] == 'WB' && 
        m['stage_round'] == 1
      ).map((m) => m['display_order']).toList()..sort();

      expect(groupBWBR1.first, equals(21101), reason: 'Group B WB R1 should start at 21101');

      print('✅ Display order follows correct pattern');
    });
  });
}
