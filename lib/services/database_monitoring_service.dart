import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'performance_monitor.dart';
// ELON_MODE_AUTO_FIX

/// Database Monitoring Service
/// Tracks database query performance and identifies slow queries
/// 
/// Features:
/// - Query execution time tracking
/// - Slow query detection (>100ms)
/// - Query pattern analysis
/// - Connection pool monitoring
class DatabaseMonitoringService {
  static DatabaseMonitoringService? _instance;
  static DatabaseMonitoringService get instance =>
      _instance ??= DatabaseMonitoringService._();

  DatabaseMonitoringService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor.instance;

  // Configuration
  static const int _slowQueryThresholdMs = 100;
  static const int _criticalQueryThresholdMs = 500;

  // Statistics
  final Map<String, List<int>> _queryTimes = {};
  final Map<String, int> _queryCounts = {};
  int _totalQueries = 0;
  int _slowQueries = 0;
  int _criticalQueries = 0;

  /// Track a database query
  Future<T> trackQuery<T>(
    String queryName,
    Future<T> Function() query, {
    Map<String, dynamic>? metadata,
  }) async {
    _totalQueries++;
    final startTime = DateTime.now();

    try {
      final result = await query();
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // Record query time
      _performanceMonitor.recordMetric('db_query.$queryName', duration);
      _recordQueryTime(queryName, duration);

      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      _recordQueryError(queryName, e);
      _recordQueryTime(queryName, duration); // Record failed query time too
      rethrow;
    }
  }

  /// Record query execution time
  void _recordQueryTime(String queryName, int durationMs) {
    if (!_queryTimes.containsKey(queryName)) {
      _queryTimes[queryName] = [];
    }

    _queryTimes[queryName]!.add(durationMs);
    _queryCounts[queryName] = (_queryCounts[queryName] ?? 0) + 1;

    // Keep only last 100 queries per type
    if (_queryTimes[queryName]!.length > 100) {
      _queryTimes[queryName]!.removeAt(0);
    }

    // Check for slow queries
    if (durationMs > _criticalQueryThresholdMs) {
      _criticalQueries++;
      if (kDebugMode) {
      }
    } else if (durationMs > _slowQueryThresholdMs) {
      _slowQueries++;
      if (kDebugMode) {
      }
    }
  }

  /// Record query error
  void _recordQueryError(String queryName, dynamic error) {
    if (kDebugMode) {
    }
  }

  /// Get slow queries report
  Map<String, dynamic> getSlowQueriesReport() {
    final slowQueries = <String, Map<String, dynamic>>{};

    for (final entry in _queryTimes.entries) {
      final queryName = entry.key;
      final times = entry.value;

      if (times.isEmpty) continue;

      final avgTime = times.reduce((a, b) => a + b) / times.length;
      final maxTime = times.reduce((a, b) => a > b ? a : b);
      final slowCount = times.where((t) => t > _slowQueryThresholdMs).length;

      if (avgTime > _slowQueryThresholdMs || slowCount > 0) {
        slowQueries[queryName] = {
          'average_ms': avgTime.round(),
          'max_ms': maxTime,
          'count': times.length,
          'slow_count': slowCount,
          'slow_percentage': (slowCount / times.length * 100).toStringAsFixed(1),
        };
      }
    }

    return slowQueries;
  }

  /// Get query statistics
  Map<String, dynamic> getQueryStatistics() {
    final stats = <String, Map<String, dynamic>>{};

    for (final entry in _queryTimes.entries) {
      final queryName = entry.key;
      final times = entry.value;

      if (times.isEmpty) continue;

      final sorted = List<int>.from(times)..sort();
      final avgTime = times.reduce((a, b) => a + b) / times.length;
      final medianTime = sorted[sorted.length ~/ 2];
      final p95Index = (sorted.length * 0.95).floor();
      final p99Index = (sorted.length * 0.99).floor();

      stats[queryName] = {
        'count': times.length,
        'average_ms': avgTime.round(),
        'median_ms': medianTime,
        'p95_ms': sorted[p95Index],
        'p99_ms': sorted[p99Index],
        'min_ms': sorted.first,
        'max_ms': sorted.last,
      };
    }

    return stats;
  }

  /// Get overall statistics
  Map<String, dynamic> getOverallStatistics() {
    return {
      'total_queries': _totalQueries,
      'slow_queries': _slowQueries,
      'critical_queries': _criticalQueries,
      'slow_query_percentage': _totalQueries > 0
          ? (_slowQueries / _totalQueries * 100).toStringAsFixed(2)
          : '0.00',
      'critical_query_percentage': _totalQueries > 0
          ? (_criticalQueries / _totalQueries * 100).toStringAsFixed(2)
          : '0.00',
      'unique_query_types': _queryTimes.length,
      'slow_query_threshold_ms': _slowQueryThresholdMs,
      'critical_query_threshold_ms': _criticalQueryThresholdMs,
    };
  }

  /// Check database health
  Future<Map<String, dynamic>> checkDatabaseHealth() async {
    try {
      final startTime = DateTime.now();
      // Use users table for health check (profiles table may not exist)
      await _supabase.from('users').select('id').limit(1);
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      return {
        'status': 'healthy',
        'response_time_ms': responseTime,
        'is_slow': responseTime > _slowQueryThresholdMs,
        'is_critical': responseTime > _criticalQueryThresholdMs,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
      };
    }
  }

  /// Print monitoring report
  void printReport() {
    if (kDebugMode) {
      
      // overall variable removed - only used in debug log

      final slowQueries = getSlowQueriesReport();
      if (slowQueries.isNotEmpty) {
        // for (final entry in slowQueries.entries) {
        // }
      }

    }
  }

  /// Clear statistics
  void clearStatistics() {
    _queryTimes.clear();
    _queryCounts.clear();
    _totalQueries = 0;
    _slowQueries = 0;
    _criticalQueries = 0;

    if (kDebugMode) {
    }
  }
}


