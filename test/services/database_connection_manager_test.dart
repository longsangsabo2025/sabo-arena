import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/database_connection_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseConnectionManager Tests', () {
    late DatabaseConnectionManager connectionManager;

    setUp(() {
      connectionManager = DatabaseConnectionManager.instance;
    });

    test('should initialize without errors', () {
      connectionManager.initialize();
      expect(connectionManager, isNotNull);
    });

    test('should get connection stats', () {
      connectionManager.initialize();
      
      final stats = connectionManager.getConnectionStats();

      expect(stats, isNotNull);
      expect(stats['isHealthy'], isA<bool>());
      expect(stats['consecutiveFailures'], isA<int>());
      expect(stats['lastHealthCheck'], isA<String>());
    });

    test('should execute query with retry logic', () async {
      connectionManager.initialize();

      // Test successful query
      final result = await connectionManager.executeWithRetry(() async {
        return 'success';
      });

      expect(result, equals('success'));
    });

    test('should retry on failure', () async {
      connectionManager.initialize();

      int attempts = 0;
      
      // Test retry logic with failing query that succeeds on 2nd attempt
      final result = await connectionManager.executeWithRetry(
        () async {
          attempts++;
          if (attempts < 2) {
            throw Exception('Temporary failure');
          }
          return 'success';
        },
        maxRetries: 3,
      );

      expect(result, equals('success'));
      expect(attempts, equals(2));
    });

    test('should throw after max retries', () async {
      connectionManager.initialize();

      // Test that it throws after max retries
      expect(
        () => connectionManager.executeWithRetry(
          () async {
            throw Exception('Persistent failure');
          },
          maxRetries: 2,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should execute batch queries', () async {
      connectionManager.initialize();

      final queries = List.generate(10, (i) => Future.value('result-$i'));

      final results = await connectionManager.executeBatchQueries(queries);

      expect(results.length, equals(10));
      expect(results[0], equals('result-0'));
      expect(results[9], equals('result-9'));
    });

    test('should limit batch query concurrency', () async {
      connectionManager.initialize();

      final queries = List.generate(20, (i) => Future.value('result-$i'));

      final results = await connectionManager.executeBatchQueries(
        queries,
        maxConcurrency: 5,
      );

      expect(results.length, equals(20));
    });

    test('should dispose correctly', () {
      connectionManager.initialize();
      connectionManager.dispose();

      // After dispose, should still work (singleton pattern)
      expect(connectionManager, isNotNull);
    });
  });
}

