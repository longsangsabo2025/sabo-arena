import 'package:flutter/foundation.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Performance Monitor
/// Tracks app performance metrics for monitoring and optimization
/// 
/// Metrics tracked:
/// - App startup time
/// - Screen load times
/// - API response times
/// - Database query times
/// - Image load times
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance => _instance ??= PerformanceMonitor._();

  PerformanceMonitor._();

  // Metrics storage
  final Map<String, List<int>> _metrics = {};
  final Map<String, DateTime> _startTimes = {};
  
  // Configuration
  static const int _maxMetricsPerKey = 100;
  static const int _slowQueryThresholdMs = 500;
  static const int _slowApiThresholdMs = 2000;
  
  // Statistics
  int _totalMetricsRecorded = 0;
  int _slowQueriesDetected = 0;
  int _slowApisDetected = 0;

  /// Start timing an operation
  void startTiming(String key) {
    _startTimes[key] = DateTime.now();
  }

  /// End timing and record metric
  void endTiming(String key) {
    final startTime = _startTimes[key];
    if (startTime == null) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      return;
    }

    final duration = DateTime.now().difference(startTime);
    final durationMs = duration.inMilliseconds;

    _recordMetric(key, durationMs);
    _startTimes.remove(key);

    // Check for slow operations
    if (key.contains('query') && durationMs > _slowQueryThresholdMs) {
      _slowQueriesDetected++;
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }

    if (key.contains('api') && durationMs > _slowApiThresholdMs) {
      _slowApisDetected++;
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Record a metric value
  void recordMetric(String key, int valueMs) {
    _recordMetric(key, valueMs);
  }

  void _recordMetric(String key, int valueMs) {
    if (!_metrics.containsKey(key)) {
      _metrics[key] = [];
    }

    final metrics = _metrics[key]!;
    metrics.add(valueMs);

    // Keep only last N metrics
    if (metrics.length > _maxMetricsPerKey) {
      metrics.removeAt(0);
    }

    _totalMetricsRecorded++;
  }

  /// Get average time for a metric
  double getAverageTime(String key) {
    final metrics = _metrics[key];
    if (metrics == null || metrics.isEmpty) {
      return 0.0;
    }

    final sum = metrics.fold<int>(0, (sum, value) => sum + value);
    return sum / metrics.length;
  }

  /// Get median time for a metric
  int getMedianTime(String key) {
    final metrics = _metrics[key];
    if (metrics == null || metrics.isEmpty) {
      return 0;
    }

    final sorted = List<int>.from(metrics)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length.isOdd) {
      return sorted[middle];
    } else {
      return ((sorted[middle - 1] + sorted[middle]) / 2).round();
    }
  }

  /// Get p95 time (95th percentile)
  int getP95Time(String key) {
    final metrics = _metrics[key];
    if (metrics == null || metrics.isEmpty) {
      return 0;
    }

    final sorted = List<int>.from(metrics)..sort();
    final index = (sorted.length * 0.95).floor();
    return sorted[index];
  }

  /// Get p99 time (99th percentile)
  int getP99Time(String key) {
    final metrics = _metrics[key];
    if (metrics == null || metrics.isEmpty) {
      return 0;
    }

    final sorted = List<int>.from(metrics)..sort();
    final index = (sorted.length * 0.99).floor();
    return sorted[index];
  }

  /// Get all metrics summary
  Map<String, dynamic> getMetricsSummary() {
    final summary = <String, dynamic>{};

    for (final key in _metrics.keys) {
      summary[key] = {
        'count': _metrics[key]!.length,
        'average': getAverageTime(key),
        'median': getMedianTime(key),
        'p95': getP95Time(key),
        'p99': getP99Time(key),
        'min': _metrics[key]!.reduce((a, b) => a < b ? a : b),
        'max': _metrics[key]!.reduce((a, b) => a > b ? a : b),
      };
    }

    return summary;
  }

  /// Get performance statistics
  Map<String, dynamic> getStats() {
    return {
      'total_metrics_recorded': _totalMetricsRecorded,
      'slow_queries_detected': _slowQueriesDetected,
      'slow_apis_detected': _slowApisDetected,
      'metrics_count': _metrics.length,
      'slow_query_threshold_ms': _slowQueryThresholdMs,
      'slow_api_threshold_ms': _slowApiThresholdMs,
    };
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _startTimes.clear();
    _totalMetricsRecorded = 0;
    _slowQueriesDetected = 0;
    _slowApisDetected = 0;

    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Clear metrics for a specific key
  void clearMetric(String key) {
    _metrics.remove(key);
    _startTimes.remove(key);
  }

  /// Print performance report
  void printReport() {
    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final summary = getMetricsSummary();
      for (final entry in summary.entries) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }
}

/// Performance timing helper class
class PerformanceTimer {
  final String key;
  final PerformanceMonitor _monitor = PerformanceMonitor.instance;

  PerformanceTimer(this.key) {
    _monitor.startTiming(key);
  }

  void stop() {
    _monitor.endTiming(key);
  }
}


