import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to monitor SPA economy health and prevent inflation/deflation
class EconomyMonitoringService {
  static EconomyMonitoringService? _instance;
  static EconomyMonitoringService get instance =>
      _instance ??= EconomyMonitoringService._();
  EconomyMonitoringService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive economy statistics
  Future<Map<String, dynamic>> getEconomyStats() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get total SPA in circulation
      final spaCirculation = await _getTotalSPACirculation();

      // Get SPA distribution by source
      final spaBySource = await _getSPABySource();

      // Get SPA transaction velocity
      final transactionStats = await _getTransactionStats();

      // Get user wealth distribution
      final wealthDistribution = await _getWealthDistribution();

      // Calculate health metrics
      final healthMetrics = _calculateHealthMetrics(
        spaCirculation,
        spaBySource,
        transactionStats,
      );

      return {
        'total_spa_circulation': spaCirculation,
        'spa_by_source': spaBySource,
        'transaction_stats': transactionStats,
        'wealth_distribution': wealthDistribution,
        'health_metrics': healthMetrics,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Get total SPA points in circulation
  Future<Map<String, dynamic>> _getTotalSPACirculation() async {
    // Total SPA owned by all users
    final userSPA = await _supabase
        .from('users')
        .select('spa_points')
        .then(
          (data) => data.fold<int>(
            0,
            (sum, user) => sum + ((user['spa_points'] as int?) ?? 0),
          ),
        );

    // SPA in pending transactions
    final pendingSPA = await _supabase
        .from('spa_transactions')
        .select('amount')
        .eq('status', 'pending')
        .then(
          (data) => data.fold<int>(
            0,
            (sum, txn) => sum + ((txn['amount'] as int?) ?? 0).abs(),
          ),
        );

    // SPA in active challenges
    final challengeSPA = await _supabase
        .from('challenges')
        .select('spa_points')
        .eq('status', 'accepted')
        .then(
          (data) => data.fold<int>(
            0,
            (sum, challenge) =>
                sum + ((challenge['spa_points'] as int?) ?? 0) * 2,
          ),
        ); // Both players stake

    return {
      'user_spa': userSPA,
      'pending_spa': pendingSPA,
      'challenge_spa': challengeSPA,
      'total_spa': userSPA + pendingSPA + challengeSPA,
    };
  }

  /// Get SPA distribution by earning source
  Future<Map<String, int>> _getSPABySource() async {
    final transactions = await _supabase
        .from('spa_transactions')
        .select('transaction_type, amount')
        .gte('amount', 0); // Only credits

    final Map<String, int> distribution = {};

    for (final txn in transactions) {
      final type = txn['transaction_type'] as String;
      final amount = (txn['amount'] as int?) ?? 0;
      distribution[type] = (distribution[type] ?? 0) + amount;
    }

    return distribution;
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> _getTransactionStats() async {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7days = now.subtract(const Duration(days: 7));

    // Transactions in last 24h
    final txn24h = await _supabase
        .from('spa_transactions')
        .select('amount')
        .gte('created_at', last24h.toIso8601String());

    // Transactions in last 7 days
    final txn7days = await _supabase
        .from('spa_transactions')
        .select('amount')
        .gte('created_at', last7days.toIso8601String());

    final volume24h = txn24h.fold<int>(
      0,
      (sum, txn) => sum + ((txn['amount'] as int?) ?? 0).abs(),
    );
    final volume7days = txn7days.fold<int>(
      0,
      (sum, txn) => sum + ((txn['amount'] as int?) ?? 0).abs(),
    );

    return {
      'transactions_24h': txn24h.length,
      'transactions_7days': txn7days.length,
      'volume_24h': volume24h,
      'volume_7days': volume7days,
      'avg_transaction_24h': txn24h.isNotEmpty ? volume24h / txn24h.length : 0,
      'daily_velocity': txn24h.isNotEmpty ? volume24h / txn24h.length : 0,
    };
  }

  /// Get wealth distribution (Gini-like analysis)
  Future<Map<String, dynamic>> _getWealthDistribution() async {
    final users = await _supabase
        .from('users')
        .select('spa_points')
        .order('spa_points', ascending: false);

    final spaList = users
        .map((u) => (u['spa_points'] as int?) ?? 0)
        .where((spa) => spa > 0)
        .toList();

    if (spaList.isEmpty) {
      return {
        'top_1_percent': 0,
        'top_10_percent': 0,
        'median': 0,
        'average': 0,
        'total_users': 0,
      };
    }

    final totalUsers = spaList.length;
    final totalSPA = spaList.fold<int>(0, (sum, spa) => sum + spa);

    // Top 1% and 10%
    final top1Count = (totalUsers * 0.01).ceil();
    final top10Count = (totalUsers * 0.10).ceil();

    final top1SPA = spaList
        .take(top1Count)
        .fold<int>(0, (sum, spa) => sum + spa);
    final top10SPA = spaList
        .take(top10Count)
        .fold<int>(0, (sum, spa) => sum + spa);

    // Median
    final median = spaList[totalUsers ~/ 2];

    return {
      'top_1_percent': ((top1SPA / totalSPA) * 100).toStringAsFixed(1),
      'top_10_percent': ((top10SPA / totalSPA) * 100).toStringAsFixed(1),
      'median': median,
      'average': (totalSPA / totalUsers).round(),
      'total_users': totalUsers,
      'total_spa': totalSPA,
    };
  }

  /// Calculate economy health metrics
  Map<String, dynamic> _calculateHealthMetrics(
    Map<String, dynamic> circulation,
    Map<String, int> bySource,
    Map<String, dynamic> transactionStats,
  ) {
    final totalSPA = circulation['total_spa'] as int;
    final userSPA = circulation['user_spa'] as int;
    final dailyVolume = transactionStats['volume_24h'] as int;

    // Velocity = daily transaction volume / total circulation
    final velocity = totalSPA > 0 ? (dailyVolume / totalSPA) : 0;

    // Concentration ratio (should be < 0.5 for healthy economy)
    final concentration = userSPA > 0 ? (totalSPA / userSPA) : 1.0;

    // Determine health status
    String status;
    if (velocity > 0.3 && concentration < 1.5) {
      status = 'healthy'; // Good circulation, low concentration
    } else if (velocity > 0.15 || concentration < 2.0) {
      status = 'moderate'; // Acceptable levels
    } else {
      status = 'warning'; // Low velocity or high concentration
    }

    return {
      'status': status,
      'velocity': velocity.toStringAsFixed(3),
      'concentration': concentration.toStringAsFixed(2),
      'inflation_risk': velocity > 0.5
          ? 'high'
          : (velocity > 0.3 ? 'medium' : 'low'),
      'recommendation': _getRecommendation(
        status,
        velocity.toDouble(),
        concentration.toDouble(),
      ),
    };
  }

  /// Get recommendation based on health metrics
  String _getRecommendation(
    String status,
    double velocity,
    double concentration,
  ) {
    if (status == 'healthy') {
      return 'Economy is healthy. Continue monitoring.';
    } else if (velocity < 0.1) {
      return 'Low transaction velocity. Consider adding more SPA earning opportunities.';
    } else if (concentration > 2.0) {
      return 'High SPA concentration. Encourage distribution through events.';
    } else {
      return 'Monitor economy closely and adjust reward rates if needed.';
    }
  }

  /// Get SPA sources and sinks summary
  Future<Map<String, dynamic>> getSPAFlowAnalysis() async {
    final now = DateTime.now();
    final last30days = now.subtract(const Duration(days: 30));

    final transactions = await _supabase
        .from('spa_transactions')
        .select('transaction_type, amount')
        .gte('created_at', last30days.toIso8601String());

    final Map<String, int> sources = {}; // Positive amounts (earning)
    final Map<String, int> sinks = {}; // Negative amounts (spending)

    for (final txn in transactions) {
      final type = txn['transaction_type'] as String;
      final amount = (txn['amount'] as int?) ?? 0;

      if (amount > 0) {
        sources[type] = (sources[type] ?? 0) + amount;
      } else {
        sinks[type] = (sinks[type] ?? 0) + amount.abs();
      }
    }

    final totalEarned = sources.values.fold<int>(0, (sum, val) => sum + val);
    final totalSpent = sinks.values.fold<int>(0, (sum, val) => sum + val);

    return {
      'sources': sources,
      'sinks': sinks,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      'net_flow': totalEarned - totalSpent,
      'balance_ratio': totalSpent > 0
          ? (totalEarned / totalSpent).toStringAsFixed(2)
          : 'N/A',
    };
  }

  /// Get alert if economy needs attention
  Future<List<Map<String, String>>> getEconomyAlerts() async {
    final stats = await getEconomyStats();
    final healthMetrics = stats['health_metrics'] as Map<String, dynamic>;
    final flowAnalysis = await getSPAFlowAnalysis();

    final List<Map<String, String>> alerts = [];

    // Check health status
    if (healthMetrics['status'] == 'warning') {
      alerts.add({
        'level': 'warning',
        'message': healthMetrics['recommendation'] as String,
      });
    }

    // Check inflation risk
    if (healthMetrics['inflation_risk'] == 'high') {
      alerts.add({
        'level': 'critical',
        'message': 'High inflation risk detected. Review SPA reward rates.',
      });
    }

    // Check net flow
    final netFlow = flowAnalysis['net_flow'] as int;
    if (netFlow > 100000) {
      alerts.add({
        'level': 'warning',
        'message':
            'SPA supply increasing rapidly (+$netFlow in 30 days). Monitor inflation.',
      });
    } else if (netFlow < -50000) {
      alerts.add({
        'level': 'info',
        'message':
            'SPA being burned faster than earned. Consider adding earning opportunities.',
      });
    }

    return alerts;
  }
}

