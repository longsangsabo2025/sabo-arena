import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
// ELON_MODE_AUTO_FIX

/// Database Connection Manager
/// Manages connection pooling, health checks, and retry logic for Supabase
class DatabaseConnectionManager {
  static DatabaseConnectionManager? _instance;
  static DatabaseConnectionManager get instance =>
      _instance ??= DatabaseConnectionManager._();

  DatabaseConnectionManager._();

  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _healthCheckTimer;
  bool _isHealthy = true;
  int _consecutiveFailures = 0;
  static const int _maxFailures = 3;
  static const Duration _healthCheckInterval = Duration(minutes: 1);
  static const Duration _retryDelay = Duration(seconds: 5);

  /// Initialize connection manager
  void initialize() {
    _startHealthChecks();
    if (kDebugMode) {}
  }

  /// Start periodic health checks
  void _startHealthChecks() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) async {
      await checkHealth();
    });
  }

  /// Check database connection health
  Future<bool> checkHealth() async {
    try {
      final startTime = DateTime.now();
      // Use users table for health check (profiles table may not exist)
      await _supabase.from('users').select('id').limit(1);
      final duration = DateTime.now().difference(startTime);

      if (duration.inMilliseconds > 1000) {
        if (kDebugMode) {}
      }

      _isHealthy = true;
      _consecutiveFailures = 0;
      return true;
    } catch (e) {
      _consecutiveFailures++;
      _isHealthy = false;

      if (kDebugMode) {}

      if (_consecutiveFailures >= _maxFailures) {
        if (kDebugMode) {}
      }

      return false;
    }
  }

  /// Get current health status
  bool get isHealthy => _isHealthy;

  /// Execute query with retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() query, {
    int maxRetries = 3,
    Duration? retryDelay,
  }) async {
    int attempts = 0;
    final delay = retryDelay ?? _retryDelay;

    while (attempts < maxRetries) {
      try {
        return await query();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }

        // Exponential backoff
        final backoffDelay = delay * (1 << (attempts - 1));
        await Future.delayed(backoffDelay);

        // Check health before retry
        if (!_isHealthy) {
          await checkHealth();
        }
      }
    }

    throw Exception('Query failed after $maxRetries attempts');
  }

  /// Execute batch queries efficiently
  Future<List<T>> executeBatchQueries<T>(
    List<Future<T>> queries, {
    int? maxConcurrency,
  }) async {
    final concurrency = maxConcurrency ?? 5; // Limit concurrent queries
    final results = <T>[];

    for (var i = 0; i < queries.length; i += concurrency) {
      final batch = queries.skip(i).take(concurrency);
      final batchResults = await Future.wait(batch);
      results.addAll(batchResults);
    }

    return results;
  }

  /// Get connection pool statistics (if available)
  Map<String, dynamic> getConnectionStats() {
    return {
      'isHealthy': _isHealthy,
      'consecutiveFailures': _consecutiveFailures,
      'lastHealthCheck': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }
}
