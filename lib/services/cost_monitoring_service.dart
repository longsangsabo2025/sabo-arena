import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Cost Monitoring Service
/// Tracks resource usage to estimate costs and set up alerts
/// 
/// Tracks:
/// - Database queries (cost per query)
/// - Storage usage (cost per GB)
/// - Bandwidth usage (cost per GB)
/// - Real-time subscriptions (cost per subscription)
class CostMonitoringService {
  static CostMonitoringService? _instance;
  static CostMonitoringService get instance =>
      _instance ??= CostMonitoringService._();

  CostMonitoringService._();

  // Cost estimates (Supabase pricing - adjust based on your plan)
  static const double _costPerQuery = 0.000001; // $0.000001 per query (example)
  static const double _costPerGBStorage = 0.021; // $0.021 per GB/month
  static const double _costPerGBBandwidth = 0.09; // $0.09 per GB
  static const double _costPerSubscription = 0.0001; // $0.0001 per subscription/hour

  // Usage tracking
  int _totalQueries = 0;
  double _estimatedStorageGB = 0.0;
  double _estimatedBandwidthGB = 0.0;
  int _totalSubscriptionHours = 0;

  // Daily tracking
  final Map<DateTime, DailyUsage> _dailyUsage = {};
  Timer? _dailyResetTimer;

  /// Initialize cost monitoring
  void initialize() {
    // Reset daily usage at midnight
    _scheduleDailyReset();
    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Schedule daily reset
  void _scheduleDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    _dailyResetTimer?.cancel();
    _dailyResetTimer = Timer(durationUntilMidnight, () {
      _resetDailyUsage();
      _scheduleDailyReset(); // Schedule next reset
    });
  }

  /// Reset daily usage
  void _resetDailyUsage() {
    final today = DateTime.now();
    _dailyUsage[today] = DailyUsage(
      date: today,
      queries: 0,
      storageGB: 0.0,
      bandwidthGB: 0.0,
      subscriptionHours: 0,
    );
  }

  /// Record database query
  void recordQuery() {
    _totalQueries++;
    _getTodayUsage().queries++;
  }

  /// Record storage usage
  void recordStorage(double gb) {
    _estimatedStorageGB = gb;
    _getTodayUsage().storageGB = gb;
  }

  /// Record bandwidth usage
  void recordBandwidth(double gb) {
    _estimatedBandwidthGB += gb;
    _getTodayUsage().bandwidthGB += gb;
  }

  /// Record subscription usage
  void recordSubscription(int hours) {
    _totalSubscriptionHours += hours;
    _getTodayUsage().subscriptionHours += hours;
  }

  /// Get today's usage
  DailyUsage _getTodayUsage() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    if (!_dailyUsage.containsKey(todayKey)) {
      _dailyUsage[todayKey] = DailyUsage(
        date: todayKey,
        queries: 0,
        storageGB: 0.0,
        bandwidthGB: 0.0,
        subscriptionHours: 0,
      );
    }

    return _dailyUsage[todayKey]!;
  }

  /// Calculate estimated monthly cost
  double calculateEstimatedMonthlyCost() {
    // Database queries cost
    final queryCost = _totalQueries * _costPerQuery;

    // Storage cost (monthly)
    final storageCost = _estimatedStorageGB * _costPerGBStorage;

    // Bandwidth cost
    final bandwidthCost = _estimatedBandwidthGB * _costPerGBBandwidth;

    // Subscription cost
    final subscriptionCost = _totalSubscriptionHours * _costPerSubscription;

    return queryCost + storageCost + bandwidthCost + subscriptionCost;
  }

  /// Calculate estimated daily cost
  double calculateEstimatedDailyCost() {
    final today = _getTodayUsage();

    final queryCost = today.queries * _costPerQuery;
    final storageCost = (today.storageGB / 30) * _costPerGBStorage; // Daily portion
    final bandwidthCost = today.bandwidthGB * _costPerGBBandwidth;
    final subscriptionCost = today.subscriptionHours * _costPerSubscription;

    return queryCost + storageCost + bandwidthCost + subscriptionCost;
  }

  /// Get cost breakdown
  Map<String, dynamic> getCostBreakdown() {
    final monthlyCost = calculateEstimatedMonthlyCost();
    final dailyCost = calculateEstimatedDailyCost();

    return {
      'monthly_estimated_cost': monthlyCost,
      'daily_estimated_cost': dailyCost,
      'breakdown': {
        'database_queries': {
          'count': _totalQueries,
          'cost': _totalQueries * _costPerQuery,
          'cost_per_query': _costPerQuery,
        },
        'storage': {
          'gb': _estimatedStorageGB,
          'cost': _estimatedStorageGB * _costPerGBStorage,
          'cost_per_gb_month': _costPerGBStorage,
        },
        'bandwidth': {
          'gb': _estimatedBandwidthGB,
          'cost': _estimatedBandwidthGB * _costPerGBBandwidth,
          'cost_per_gb': _costPerGBBandwidth,
        },
        'subscriptions': {
          'hours': _totalSubscriptionHours,
          'cost': _totalSubscriptionHours * _costPerSubscription,
          'cost_per_hour': _costPerSubscription,
        },
      },
    };
  }

  /// Get usage statistics
  Map<String, dynamic> getUsageStatistics() {
    final today = _getTodayUsage();

    return {
      'total_queries': _totalQueries,
      'today_queries': today.queries,
      'estimated_storage_gb': _estimatedStorageGB,
      'estimated_bandwidth_gb': _estimatedBandwidthGB,
      'today_bandwidth_gb': today.bandwidthGB,
      'total_subscription_hours': _totalSubscriptionHours,
      'today_subscription_hours': today.subscriptionHours,
    };
  }

  /// Check if cost threshold exceeded
  bool checkCostThreshold(double monthlyThreshold) {
    final estimatedCost = calculateEstimatedMonthlyCost();
    return estimatedCost > monthlyThreshold;
  }

  /// Get cost alerts
  List<String> getCostAlerts(double monthlyThreshold) {
    final alerts = <String>[];
    final estimatedCost = calculateEstimatedMonthlyCost();

    if (estimatedCost > monthlyThreshold) {
      alerts.add(
        '⚠️ Estimated monthly cost (\$${estimatedCost.toStringAsFixed(2)}) exceeds threshold (\$${monthlyThreshold.toStringAsFixed(2)})',
      );
    }

    final today = _getTodayUsage();
    final dailyCost = calculateEstimatedDailyCost();
    final dailyThreshold = monthlyThreshold / 30;

    if (dailyCost > dailyThreshold * 1.5) {
      alerts.add(
        '⚠️ Today\'s estimated cost (\$${dailyCost.toStringAsFixed(2)}) is 50% above daily average',
      );
    }

    // Check for unusual query patterns
    if (today.queries > 10000) {
      alerts.add('⚠️ High query count today: ${today.queries} queries');
    }

    // Check for high bandwidth usage
    if (today.bandwidthGB > 10) {
      alerts.add('⚠️ High bandwidth usage today: ${today.bandwidthGB.toStringAsFixed(2)}GB');
    }

    return alerts;
  }

  /// Print cost report
  void printCostReport() {
    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final breakdown = getCostBreakdown();
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // costBreakdown and usage variables removed - only used in debug logs
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

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
  }

  /// Dispose resources
  void dispose() {
    _dailyResetTimer?.cancel();
  }
}

/// Daily usage tracking
class DailyUsage {
  DateTime date;
  int queries;
  double storageGB;
  double bandwidthGB;
  int subscriptionHours;

  DailyUsage({
    required this.date,
    required this.queries,
    required this.storageGB,
    required this.bandwidthGB,
    required this.subscriptionHours,
  });
}


