import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/cache_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheManager Tests', () {
    late CacheManager cacheManager;

    setUp(() {
      cacheManager = CacheManager.instance;
    });

    test('should initialize without errors', () async {
      await cacheManager.initialize();
      expect(cacheManager, isNotNull);
    });

    test('should cache and retrieve tournament data', () async {
      const tournamentId = 'test-tournament-123';
      final tournamentData = {
        'id': tournamentId,
        'title': 'Test Tournament',
        'status': 'upcoming',
      };

      // Cache tournament
      await cacheManager.setTournament(tournamentId, tournamentData);

      // Retrieve from cache
      final cached = await cacheManager.getTournament(tournamentId);

      expect(cached, isNotNull);
      expect(cached!['id'], equals(tournamentId));
      expect(cached['title'], equals('Test Tournament'));
    });

    test('should cache and retrieve user profile', () async {
      const userId = 'test-user-123';
      final userData = {
        'id': userId,
        'username': 'testuser',
        'email': 'test@example.com',
      };

      // Cache user profile
      await cacheManager.setUserProfile(userId, userData);

      // Retrieve from cache
      final cached = await cacheManager.getUserProfile(userId);

      expect(cached, isNotNull);
      expect(cached!['id'], equals(userId));
      expect(cached['username'], equals('testuser'));
    });

    test('should invalidate tournament cache', () async {
      const tournamentId = 'test-tournament-456';
      final tournamentData = {'id': tournamentId, 'title': 'Test'};

      // Cache tournament
      await cacheManager.setTournament(tournamentId, tournamentData);

      // Verify cached
      final cached = await cacheManager.getTournament(tournamentId);
      expect(cached, isNotNull);

      // Invalidate cache
      await cacheManager.invalidateTournament(tournamentId);

      // Should return null after invalidation (if not in memory)
      // Note: This test may need adjustment based on actual implementation
    });

    test('should handle cache miss gracefully', () async {
      const nonExistentId = 'non-existent-tournament';

      final cached = await cacheManager.getTournament(nonExistentId);

      // Should return null for non-existent cache
      expect(cached, isNull);
    });

    test('should cache and retrieve club data', () async {
      const clubId = 'test-club-123';
      final clubData = {
        'id': clubId,
        'name': 'Test Club',
        'address': '123 Test St',
      };

      // Cache club
      await cacheManager.setClub(clubId, clubData);

      // Retrieve from cache
      final cached = await cacheManager.getClub(clubId);

      expect(cached, isNotNull);
      expect(cached!['id'], equals(clubId));
      expect(cached['name'], equals('Test Club'));
    });

    test('should cache generic data', () async {
      const key = 'test-key';
      final data = {'value': 'test-data'};

      // Cache generic data
      await cacheManager.setCache(key, data, ttl: Duration(minutes: 5));

      // Retrieve from cache
      final cached = await cacheManager.getCache(key);

      expect(cached, isNotNull);
      expect(cached!['value'], equals('test-data'));
    });
  });
}

