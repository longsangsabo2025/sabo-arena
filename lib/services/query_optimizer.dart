// Query Optimizer Service
// Utilities for query optimization and pagination
// 
// Features:
// - Pagination helpers
// - N+1 query detection
// - Query batching utilities
// - Performance tracking

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_monitoring_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class QueryOptimizer {
  static QueryOptimizer? _instance;
  static QueryOptimizer get instance => _instance ??= QueryOptimizer._();

  QueryOptimizer._();

  final DatabaseMonitoringService _dbMonitor = DatabaseMonitoringService.instance;

  // Default pagination settings
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Calculate pagination range from page and pageSize
  /// Returns (from, to) for use with .range(from, to)
  static (int, int) calculateRange({
    int page = 1,
    int pageSize = defaultPageSize,
  }) {
    final actualPageSize = _clampPageSize(pageSize);
    final actualPage = page < 1 ? 1 : page;
    final from = (actualPage - 1) * actualPageSize;
    final to = from + actualPageSize - 1;
    return (from, to);
  }

  /// Execute a count query (for pagination metadata)
  /// Example usage:
  /// ```dart
  /// final count = await QueryOptimizer.instance.executeCountQuery(
  ///   client: _supabase,
  ///   table: 'tournaments',
  ///   filters: {'status': 'open'},
  /// );
  /// ```
  /// 
  /// Note: For complex filters, build the query manually and use this as a helper
  Future<int> executeCountQuery({
    required SupabaseClient client,
    required String table,
    Map<String, String>? filters,
    String? queryName,
  }) async {
    final queryName_ = queryName ?? 'count_query_$table';
    
    return await _dbMonitor.trackQuery(
      queryName_,
      () async {
        // Build query with filters before count
        var query = client.from(table).select();
        
        // Apply simple filters (eq only for count queries)
        if (filters != null) {
          for (final entry in filters.entries) {
            query = query.eq(entry.key, entry.value);
          }
        }
        
        // Apply count after filters
        final response = await query.count(CountOption.exact);
        return response.count;
      },
      metadata: {
        'table': table,
        'filters': filters?.keys.toList() ?? [],
      },
    );
  }

  /// Batch execute multiple queries with concurrency control
  /// Example usage:
  /// ```dart
  /// final results = await QueryOptimizer.instance.executeBatchQueries(
  ///   queries: [
  ///     () => _supabase.from('tournaments').select().limit(10),
  ///     () => _supabase.from('clubs').select().limit(10),
  ///   ],
  ///   maxConcurrency: 3,
  /// );
  /// ```
  Future<List<T>> executeBatchQueries<T>({
    required List<Future<T> Function()> queries,
    int? maxConcurrency,
  }) async {
    final concurrency = maxConcurrency ?? 5;
    final results = <T>[];

    for (int i = 0; i < queries.length; i += concurrency) {
      final batch = queries.sublist(
        i,
        i + concurrency > queries.length ? queries.length : i + concurrency,
      );

      final batchResults = await Future.wait(
        batch.map((query) => query()),
      );

      results.addAll(batchResults);
    }

    return results;
  }

  /// Detect N+1 query patterns (for development/debugging)
  /// Call this after executing queries to detect potential issues
  void detectNPlusOne({
    required String operation,
    required int expectedQueries,
    required int actualQueries,
  }) {
    if (actualQueries > expectedQueries * 2) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  static int _clampPageSize(int pageSize) {
    if (pageSize < 1) return 1;
    if (pageSize > maxPageSize) return maxPageSize;
    return pageSize;
  }
}

/// Paginated result with metadata
class PaginatedResult {
  final List<Map<String, dynamic>> data;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResult({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'page': page,
      'pageSize': pageSize,
      'totalCount': totalCount,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }
}


