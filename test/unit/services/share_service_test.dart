import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/share_service.dart';

void main() {
  group('ShareService URL Generation Tests', () {
    test('generateLeaderboardQRData returns correct URL', () {
      const tournamentId = 'test-tournament-123';
      const expectedUrl = 'https://saboarena.com/leaderboard/test-tournament-123';

      final result = ShareService.generateLeaderboardQRData(tournamentId);

      expect(result, equals(expectedUrl));
    });

    test('generateLeaderboardQRData with special characters', () {
      const tournamentId = 'tournament-with-special-chars-123';
      const expectedUrl = 'https://saboarena.com/leaderboard/tournament-with-special-chars-123';

      final result = ShareService.generateLeaderboardQRData(tournamentId);

      expect(result, equals(expectedUrl));
    });

    test('generateLeaderboardQRData with empty tournament ID', () {
      const tournamentId = '';
      const expectedUrl = 'https://saboarena.com/leaderboard/';

      final result = ShareService.generateLeaderboardQRData(tournamentId);

      expect(result, equals(expectedUrl));
    });

    test('generateBracketQRData returns correct URL', () {
      const tournamentId = 'test-bracket-123';
      const expectedUrl = 'https://saboarena.com/bracket/test-bracket-123';

      final result = ShareService.generateBracketQRData(tournamentId);

      expect(result, equals(expectedUrl));
    });

    test('generateTournamentQRData returns correct URL', () {
      const tournamentId = 'test-tournament-456';
      const expectedUrl = 'https://saboarena.com/tournament/test-tournament-456';

      final result = ShareService.generateTournamentQRData(tournamentId);

      expect(result, equals(expectedUrl));
    });

    test('generateClubQRData returns correct URL', () {
      const clubId = 'test-club-789';
      const expectedUrl = 'https://saboarena.com/club/test-club-789';

      final result = ShareService.generateClubQRData(clubId);

      expect(result, equals(expectedUrl));
    });
  });

  group('ShareService Helper Functions', () {
    test('generateUserCode creates correct format', () {
      const userId = 'user12345678';
      const expectedCode = 'SABO345678';

      final result = ShareService.generateUserCode(userId);

      expect(result, equals(expectedCode));
    });

    test('generateUserCode handles short IDs', () {
      const userId = 'abc';
      const expectedCode = 'SABOABC';

      final result = ShareService.generateUserCode(userId);

      expect(result, equals(expectedCode));
    });

    test('generateUserCode converts to uppercase', () {
      const userId = 'user123abc';
      const expectedCode = 'SABO123ABC';

      final result = ShareService.generateUserCode(userId);

      expect(result, equals(expectedCode));
    });
  });
}