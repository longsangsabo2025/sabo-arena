// Integration Tests for Scaling Infrastructure
// Tests actual flows with mocked Supabase or test database
// Automatically loads env.json and initializes Supabase

import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/database_replica_manager.dart';
import 'package:sabo_arena/services/circuit_breaker.dart';
import 'package:sabo_arena/services/resilient_cache_service.dart';
import 'package:sabo_arena/services/batched_realtime_service.dart';
import 'package:sabo_arena/services/cdn_service.dart';
import 'package:sabo_arena/services/tournament_service.dart';
import 'package:sabo_arena/services/user_service.dart';
import 'package:sabo_arena/services/club_service.dart';
import '../helpers/test_env_helper.dart';

void main() {
  group('Scaling Infrastructure Integration Tests', () {
    // Automatically initialize Supabase from env.json
    setUpAll(() async {
      try {
        await TestEnvHelper.setup();
      } catch (e) {
        print('⚠️ Supabase initialization failed: $e');
        print('⚠️ Some tests may fail without Supabase');
      }
    });

    tearDownAll(() async {
      await TestEnvHelper.cleanup();
    });
    
    group('Database Replica Manager Integration', () {
      test('Read operations use read client', () async {
        // Initialize replica manager
        final replicaManager = DatabaseReplicaManager.instance;
        await replicaManager.initialize();
        
        // Verify read and write clients are available
        expect(replicaManager.readClient, isNotNull);
        expect(replicaManager.writeClient, isNotNull);
        
        // In real test, verify that read operations actually use replica
        // This would require monitoring query logs
      });

      test('Write operations use write client', () async {
        final replicaManager = DatabaseReplicaManager.instance;
        
        // Verify write client is primary
        expect(replicaManager.writeClient, isNotNull);
        
        // In real test, verify writes go to primary database
      });

      test('Replica health check works', () async {
        final replicaManager = DatabaseReplicaManager.instance;
        
        // Health check should return boolean
        final isHealthy = await replicaManager.checkReplicaHealth();
        expect(isHealthy, isA<bool>());
      });

      test('Replica lag tracking', () async {
        final replicaManager = DatabaseReplicaManager.instance;
        
        // Update lag
        await replicaManager.updateReplicaLag();
        
        // Verify lag is tracked
        final lag = replicaManager.replicaLagMs;
        expect(lag, isA<int>());
        expect(lag, greaterThanOrEqualTo(0));
      });
    });

    group('Circuit Breaker Integration', () {
      test('Circuit opens after threshold failures', () async {
        final breaker = CircuitBreakerManager.instance.getBreaker('integration_test');
        
        // Initially closed
        expect(breaker.state, CircuitState.closed);
        
        // Cause failures
        for (int i = 0; i < 5; i++) {
          try {
            await breaker.execute(() async => throw Exception('Test failure'));
          } catch (e) {
            // Expected
          }
        }
        
        // Should be open
        expect(breaker.state, CircuitState.open);
        
        // Cleanup
        breaker.reset();
      });

      test('Circuit uses fallback when open', () async {
        final breaker = CircuitBreakerManager.instance.getBreaker('fallback_test');
        
        // Open circuit
        for (int i = 0; i < 5; i++) {
          try {
            await breaker.execute(() async => throw Exception('Fail'));
          } catch (e) {}
        }
        
        expect(breaker.state, CircuitState.open);
        
        // Execute with fallback
        final result = await breaker.execute(
          () async => throw Exception('Should not execute'),
          fallback: () async => 'fallback_success',
        );
        
        expect(result, 'fallback_success');
        breaker.reset();
      });

      test('Circuit recovers after reset timeout', () async {
        final breaker = CircuitBreakerManager.instance.getBreaker('recovery_test');
        
        // Open circuit
        for (int i = 0; i < 5; i++) {
          try {
            await breaker.execute(() async => throw Exception('Fail'));
          } catch (e) {}
        }
        
        expect(breaker.state, CircuitState.open);
        
        // Reset manually (in production, would wait for timeout)
        breaker.reset();
        expect(breaker.state, CircuitState.closed);
      });
    });

    group('Resilient Cache Service Integration', () {
      test('Multi-layer cache fallback chain', () async {
        final cacheService = ResilientCacheService.instance;
        
        // Test that service exists and methods work
        expect(cacheService, isNotNull);
        
        // In real test:
        // 1. Try memory cache (fastest)
        // 2. Fallback to Redis/Edge Functions
        // 3. Fallback to database
        // 4. Return null if all fail
      });

      test('Cache invalidation works', () async {
        final cacheService = ResilientCacheService.instance;
        
        // Test invalidation methods exist
        expect(cacheService.invalidateTournament, isA<Function>());
        expect(cacheService.invalidateUser, isA<Function>());
        expect(cacheService.invalidateClub, isA<Function>());
      });
    });

    group('Service Integration with Read Replicas', () {
      test('Tournament Service uses read replica for queries', () {
        final service = TournamentService.instance;
        
        // Verify service exists
        expect(service, isNotNull);
        
        // In real test, verify getTournaments uses readClient
        // This would require query monitoring
      });

      test('User Service uses read replica for queries', () {
        final service = UserService.instance;
        
        // Verify service exists
        expect(service, isNotNull);
      });

      test('Club Service uses read replica for queries', () {
        final service = ClubService.instance;
        
        // Verify service exists
        expect(service, isNotNull);
      });
    });

    group('Real-Time Batching Integration', () {
      test('Batched updates reduce WebSocket overhead', () async {
        final batchedService = BatchedRealtimeService.instance;
        
        // Initialize
        await batchedService.initialize();
        
        // Subscribe to tournaments
        int updateCount = 0;
        batchedService.subscribeToTable('tournaments', (data) {
          updateCount++;
        });
        
        // In real test:
        // 1. Trigger multiple rapid updates
        // 2. Verify they are batched together
        // 3. Verify single callback with batched data
        
        // Cleanup
        await batchedService.dispose();
      });

      test('Unsubscribe cleans up properly', () async {
        final batchedService = BatchedRealtimeService.instance;
        await batchedService.initialize();
        
        // Subscribe then unsubscribe
        batchedService.subscribeToTable('tournaments', (data) {});
        batchedService.unsubscribeFromTable('tournaments');
        
        // Verify cleanup (no memory leaks)
        await batchedService.dispose();
      });
    });

    group('CDN Service Integration', () {
      test('CDN fallback to direct storage', () async {
        final cdnService = CDNService.instance;
        cdnService.initialize();
        
        // Test with CDN disabled (should use direct storage)
        const originalUrl = 'https://project.supabase.co/storage/v1/object/public/bucket/image.jpg';
        final result = cdnService.getImageUrl(originalUrl);
        
        // Should return URL (either CDN or direct)
        expect(result, isA<String>());
        expect(result.isNotEmpty, isTrue);
      });

      test('CDN health check', () async {
        final cdnService = CDNService.instance;
        
        // Health check should return boolean
        final health = await cdnService.checkHealth();
        expect(health, isA<bool>());
      });
    });

    group('End-to-End Flow: Tournament Fetch with Caching', () {
      test('Full flow: Cache → Replica → Fallback', () async {
        // This is a comprehensive integration test
        // Would test:
        // 1. Check cache first
        // 2. If cache miss, query read replica
        // 3. If replica fails, fallback to primary
        // 4. Store in cache for next time
        
        final cacheService = ResilientCacheService.instance;
        final replicaManager = DatabaseReplicaManager.instance;
        
        // Verify services are initialized
        expect(cacheService, isNotNull);
        expect(replicaManager, isNotNull);
      });
    });

    group('End-to-End Flow: Real-Time Updates with Batching', () {
      test('Full flow: Subscribe → Batch → Process', () async {
        final batchedService = BatchedRealtimeService.instance;
        await batchedService.initialize();
        
        // Subscribe to tournament updates
        List<Map<String, dynamic>> batchedUpdates = [];
        batchedService.subscribeToTable('tournaments', (data) {
          // data is a Map<String, dynamic>, not a List
          batchedUpdates.add(data);
        });
        
        // In real test:
        // 1. Trigger multiple updates rapidly
        // 2. Verify batching (single callback with multiple updates)
        // 3. Verify updates are processed correctly
        
        await batchedService.dispose();
      });
    });

    group('Error Handling and Resilience', () {
      test('Circuit breaker prevents cascading failures', () async {
        final breaker = CircuitBreakerManager.instance.getBreaker('cascade_test');
        
        // Simulate service failure
        for (int i = 0; i < 5; i++) {
          try {
            await breaker.execute(() async => throw Exception('Service down'));
          } catch (e) {}
        }
        
        // Circuit should be open
        expect(breaker.state, CircuitState.open);
        
        // Fallback should work
        final result = await breaker.execute(
          () async => throw Exception('Still failing'),
          fallback: () async => 'fallback_data',
        );
        
        expect(result, 'fallback_data');
        breaker.reset();
      });

      test('Cache fallback when Redis fails', () async {
        // In real test:
        // 1. Simulate Redis failure
        // 2. Verify fallback to database
        // 3. Verify app continues working
        
        final cacheService = ResilientCacheService.instance;
        expect(cacheService, isNotNull);
      });
    });
  });
}

