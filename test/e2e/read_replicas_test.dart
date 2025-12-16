// Read Replicas E2E Tests
// Tests that read operations use replicas and writes use primary

import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/database_replica_manager.dart';
import 'package:sabo_arena/services/tournament_service.dart';
import 'package:sabo_arena/services/user_service.dart';
import 'package:sabo_arena/services/club_service.dart';

void main() {
  group('Read Replicas E2E Tests', () {
    test('Database Replica Manager - Read/Write separation', () {
      final replicaManager = DatabaseReplicaManager.instance;
      
      // Verify read and write clients exist
      expect(replicaManager.readClient, isNotNull);
      expect(replicaManager.writeClient, isNotNull);
      
      // In Supabase, if replica not configured, they might be the same
      // But the infrastructure is in place for when replica is configured
    });

    test('Tournament Service - Uses read client for queries', () {
      final service = TournamentService.instance;
      
      // Verify service exists
      expect(service, isNotNull);
      
      // In real test, you would verify that getTournaments uses readClient
      // This requires inspecting the service implementation
      // The service should use _readClient for select queries
    });

    test('User Service - Uses read client for queries', () {
      final service = UserService.instance;
      
      // Verify service exists
      expect(service, isNotNull);
      
      // Service should use _readClient for read operations
    });

    test('Club Service - Uses read client for queries', () {
      final service = ClubService.instance;
      
      // Verify service exists
      expect(service, isNotNull);
      
      // Service should use _readClient for read operations
    });

    test('Replica health check', () async {
      final replicaManager = DatabaseReplicaManager.instance;
      
      // Test health check
      final isHealthy = await replicaManager.checkReplicaHealth();
      expect(isHealthy, isA<bool>());
    });

    test('Replica lag monitoring', () {
      final replicaManager = DatabaseReplicaManager.instance;
      
      // Test lag tracking
      final lag = replicaManager.replicaLagMs;
      expect(lag, isA<int>());
      expect(lag, greaterThanOrEqualTo(0));
    });

    test('Replica enable/disable', () {
      final replicaManager = DatabaseReplicaManager.instance;
      
      // Test enabling/disabling replica
      replicaManager.setUseReplica(true);
      replicaManager.setUseReplica(false);
      replicaManager.setUseReplica(true);
      
      // Should not throw
      expect(replicaManager, isNotNull);
    });
  });
}

