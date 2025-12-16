import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/models/tournament.dart';

void main() {
  group('Tournament Model Tests', () {
    test('should correctly parse JSON', () {
      final json = {
        'id': '123',
        'title': 'Test Tournament',
        'description': 'Description',
        'start_date': '2025-12-12T09:00:00.000Z',
        'registration_deadline': '2025-12-12T08:00:00.000Z',
        'max_participants': 16,
        'current_participants': 0,
        'entry_fee': 100000.0,
        'prize_pool': 1600000.0,
        'status': 'upcoming',
        'game_format': '9-ball',
        'bracket_format': 'double_elimination',
        'is_public': true,
        'created_at': '2025-12-11T06:29:13.928291+00:00',
        'updated_at': '2025-12-11T06:29:13.928291+00:00',
      };

      final tournament = Tournament.fromJson(json);

      expect(tournament.id, '123');
      expect(tournament.title, 'Test Tournament');
      expect(tournament.format, '9-ball');
      expect(tournament.tournamentType, 'double_elimination');
      expect(tournament.status, 'upcoming');
    });

    test('formatDisplayName should return correct display string', () {
      final t1 = Tournament(
        id: '1',
        title: 'T1',
        description: '',
        startDate: DateTime.now(),
        registrationDeadline: DateTime.now(),
        maxParticipants: 16,
        currentParticipants: 0,
        entryFee: 0,
        prizePool: 0,
        status: 'upcoming',
        format: '9-ball',
        tournamentType: 'single_elimination',
        isPublic: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(t1.formatDisplayName, 'Single Elimination');
    });
  });
}
