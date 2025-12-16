import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/rate_limit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RateLimitService Tests', () {
    late RateLimitService rateLimitService;

    setUp(() {
      rateLimitService = RateLimitService.instance;
      // Clear by disposing and re-initializing
      rateLimitService.dispose();
      rateLimitService.initialize();
    });

    test('should initialize without errors', () {
      rateLimitService.initialize();
      expect(rateLimitService, isNotNull);
    });

    test('should allow API calls within limit', () async {
      const userId = 'test-user-1';

      // Make 50 API calls (within 100/minute limit)
      for (int i = 0; i < 50; i++) {
        final allowed = await rateLimitService.checkApiCall(userId);
        expect(allowed, isTrue, reason: 'API call $i should be allowed');
        rateLimitService.recordApiCall(userId);
      }
    });

    test('should block API calls exceeding limit', () async {
      const userId = 'test-user-2';

      // Make 101 API calls (exceeding 100/minute limit)
      bool blocked = false;
      for (int i = 0; i < 101; i++) {
        final allowed = await rateLimitService.checkApiCall(userId);
        if (!allowed) {
          blocked = true;
          break;
        }
        rateLimitService.recordApiCall(userId);
      }

      expect(blocked, isTrue, reason: 'Should block after exceeding limit');
    });

    test('should allow tournament creation within limit', () async {
      const userId = 'test-user-3';

      // Create 3 tournaments (within 5/hour limit)
      for (int i = 0; i < 3; i++) {
        final allowed = await rateLimitService.checkTournamentCreation(userId);
        expect(allowed, isTrue, reason: 'Tournament creation $i should be allowed');
        rateLimitService.recordTournamentCreation(userId);
      }
    });

    test('should block tournament creation exceeding limit', () async {
      const userId = 'test-user-4';

      // Try to create 6 tournaments (exceeding 5/hour limit)
      bool blocked = false;
      for (int i = 0; i < 6; i++) {
        final allowed = await rateLimitService.checkTournamentCreation(userId);
        if (!allowed) {
          blocked = true;
          break;
        }
        rateLimitService.recordTournamentCreation(userId);
      }

      expect(blocked, isTrue, reason: 'Should block after exceeding tournament limit');
    });

    test('should allow image uploads within limit', () async {
      const userId = 'test-user-5';

      // Upload 15 images (within 20/minute limit)
      for (int i = 0; i < 15; i++) {
        final allowed = await rateLimitService.checkImageUpload(userId);
        expect(allowed, isTrue, reason: 'Image upload $i should be allowed');
        rateLimitService.recordImageUpload(userId);
      }
    });

    test('should block image uploads exceeding limit', () async {
      const userId = 'test-user-6';

      // Try to upload 21 images (exceeding 20/minute limit)
      bool blocked = false;
      for (int i = 0; i < 21; i++) {
        final allowed = await rateLimitService.checkImageUpload(userId);
        if (!allowed) {
          blocked = true;
          break;
        }
        rateLimitService.recordImageUpload(userId);
      }

      expect(blocked, isTrue, reason: 'Should block after exceeding image upload limit');
    });

    test('should get remaining quota correctly', () {
      const userId = 'test-user-7';

      // Initially should have full quota
      expect(rateLimitService.getRemainingApiCalls(userId), equals(100));
      expect(rateLimitService.getRemainingTournamentCreations(userId), equals(5));
      expect(rateLimitService.getRemainingImageUploads(userId), equals(20));

      // Record some actions
      rateLimitService.recordApiCall(userId);
      rateLimitService.recordTournamentCreation(userId);
      rateLimitService.recordImageUpload(userId);

      // Quota should decrease
      expect(rateLimitService.getRemainingApiCalls(userId), equals(99));
      expect(rateLimitService.getRemainingTournamentCreations(userId), equals(4));
      expect(rateLimitService.getRemainingImageUploads(userId), equals(19));
    });

    test('should get stats correctly', () {
      const userId = 'test-user-8';

      // Record some actions
      rateLimitService.recordApiCall(userId);
      rateLimitService.recordTournamentCreation(userId);
      rateLimitService.recordImageUpload(userId);

      final stats = rateLimitService.getStats();

      expect(stats['api_calls_tracked'], greaterThan(0));
      expect(stats['tournament_creations_tracked'], greaterThan(0));
      expect(stats['image_uploads_tracked'], greaterThan(0));
      expect(stats['limits'], isNotNull);
    });

    test('should dispose correctly', () {
      const userId = 'test-user-9';

      // Record some actions
      rateLimitService.recordApiCall(userId);
      rateLimitService.recordTournamentCreation(userId);
      rateLimitService.recordImageUpload(userId);

      // Dispose
      rateLimitService.dispose();

      // After dispose, should still work (singleton pattern)
      expect(rateLimitService, isNotNull);
    });

    test('should track different users independently', () async {
      const user1 = 'user-1';
      const user2 = 'user-2';

      // User 1 makes 50 calls
      for (int i = 0; i < 50; i++) {
        await rateLimitService.checkApiCall(user1);
        rateLimitService.recordApiCall(user1);
      }

      // User 2 should still be able to make calls
      final allowed = await rateLimitService.checkApiCall(user2);
      expect(allowed, isTrue, reason: 'User 2 should not be affected by User 1');
    });
  });
}

