import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_models.dart';
import 'package:sabo_arena/utils/production_logger.dart';
// ELON_MODE_AUTO_FIX

/// Advanced analytics service for notification system monitoring
class NotificationAnalyticsService {
  static final NotificationAnalyticsService _instance =
      NotificationAnalyticsService._internal();
  factory NotificationAnalyticsService() => _instance;
  NotificationAnalyticsService._internal();

  static NotificationAnalyticsService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive notification statistics for admin dashboard
  Future<NotificationAnalytics> getNotificationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get total notification stats
      final totalStats = await _getTotalNotificationStats(start, end);

      // Get delivery rates by type
      final deliveryRates = await _getDeliveryRatesByType(start, end);

      // Get user engagement metrics
      final engagementMetrics = await _getUserEngagementMetrics(start, end);

      // Get hourly distribution
      final hourlyDistribution = await _getHourlyDistribution(start, end);

      // Get daily trends
      final dailyTrends = await _getDailyTrends(start, end);

      return NotificationAnalytics(
        totalSent: totalStats['total_sent'] ?? 0,
        totalDelivered: totalStats['total_delivered'] ?? 0,
        totalRead: totalStats['total_read'] ?? 0,
        totalClicked: totalStats['total_clicked'] ?? 0,
        deliveryRate: _calculateRate(
          totalStats['total_delivered'],
          totalStats['total_sent'],
        ),
        readRate: _calculateRate(
          totalStats['total_read'],
          totalStats['total_delivered'],
        ),
        clickRate: _calculateRate(
          totalStats['total_clicked'],
          totalStats['total_read'],
        ),
        deliveryRatesByType: deliveryRates,
        engagementMetrics: engagementMetrics,
        hourlyDistribution: hourlyDistribution,
        dailyTrends: dailyTrends,
        periodStart: start,
        periodEnd: end,
      );
    } catch (e) {
      return NotificationAnalytics.empty();
    }
  }

  /// Get detailed stats for specific notification type
  Future<NotificationTypeAnalytics> getTypeAnalytics(
    NotificationType type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('type', type.value)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final notifications = response as List<dynamic>;

      final totalSent = notifications.length;
      final totalRead = notifications.where((n) => n['is_read'] == true).length;
      final totalClicked = notifications
          .where((n) => n['clicked_at'] != null)
          .length;

      return NotificationTypeAnalytics(
        type: type,
        totalSent: totalSent,
        totalRead: totalRead,
        totalClicked: totalClicked,
        readRate: _calculateRate(totalRead, totalSent),
        clickRate: _calculateRate(totalClicked, totalRead),
        averageTimeToRead: await _getAverageTimeToRead(type, start, end),
        peakHours: await _getPeakHoursForType(type, start, end),
      );
    } catch (e) {
      return NotificationTypeAnalytics.empty(type);
    }
  }

  /// Track notification delivery (called when notification is sent)
  Future<void> trackNotificationSent({
    required String notificationId,
    required NotificationType type,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('notification_analytics').insert({
        'notification_id': notificationId,
        'type': type.value,
        'user_id': userId,
        'event_type': 'sent',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata,
      });
    } catch (e) {
      ProductionLogger.warning('Failed to track notification sent', error: e, tag: 'NotificationAnalyticsService');
    }
  }

  /// Track notification read (called when user views notification)
  Future<void> trackNotificationRead(String notificationId) async {
    try {
      await _supabase.from('notification_analytics').insert({
        'notification_id': notificationId,
        'event_type': 'read',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ProductionLogger.warning('Failed to track notification read', error: e, tag: 'NotificationAnalyticsService');
    }
  }

  /// Track notification click (called when user taps notification)
  Future<void> trackNotificationClick({
    required String notificationId,
    String? actionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('notification_analytics').insert({
        'notification_id': notificationId,
        'event_type': 'clicked',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {'action_id': actionId, ...?metadata},
      });
    } catch (e) {
      ProductionLogger.warning('Failed to track notification click', error: e, tag: 'NotificationAnalyticsService');
    }
  }

  /// Get real-time notification metrics for dashboard
  Future<Map<String, dynamic>> getRealTimeMetrics() async {
    try {
      final now = DateTime.now();
      final last24h = now.subtract(const Duration(hours: 24));

      final metrics = await _supabase.rpc(
        'get_realtime_notification_metrics',
        params: {
          'start_time': last24h.toIso8601String(),
          'end_time': now.toIso8601String(),
        },
      );

      return {
        'notifications_sent_24h': metrics['sent_24h'] ?? 0,
        'notifications_read_24h': metrics['read_24h'] ?? 0,
        'active_users_24h': metrics['active_users_24h'] ?? 0,
        'avg_read_time_minutes': metrics['avg_read_time_minutes'] ?? 0,
        'most_engaged_type': metrics['most_engaged_type'] ?? 'general',
        'current_hour_activity': metrics['current_hour_activity'] ?? 0,
      };
    } catch (e) {
      return {};
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>> _getTotalNotificationStats(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_notification_stats',
        params: {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<Map<NotificationType, double>> _getDeliveryRatesByType(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_delivery_rates_by_type',
        params: {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );

      final Map<NotificationType, double> rates = {};
      for (final item in response as List<dynamic>) {
        final type = NotificationType.fromString(item['type']);
        rates[type] = (item['delivery_rate'] as num).toDouble();
      }
      return rates;
    } catch (e) {
      return {};
    }
  }

  Future<UserEngagementMetrics> _getUserEngagementMetrics(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_user_engagement_metrics',
        params: {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );

      return UserEngagementMetrics.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return UserEngagementMetrics.empty();
    }
  }

  Future<List<HourlyActivity>> _getHourlyDistribution(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_hourly_notification_distribution',
        params: {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );

      return (response as List<dynamic>)
          .map((item) => HourlyActivity.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DailyTrend>> _getDailyTrends(DateTime start, DateTime end) async {
    try {
      final response = await _supabase.rpc(
        'get_daily_notification_trends',
        params: {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );

      return (response as List<dynamic>)
          .map((item) => DailyTrend.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Duration> _getAverageTimeToRead(
    NotificationType type,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_average_time_to_read',
        params: {
          'notification_type': type.value,
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );

      final minutes = (response as num).toDouble();
      return Duration(minutes: minutes.round());
    } catch (e) {
      return const Duration(minutes: 0);
    }
  }

  Future<List<int>> _getPeakHoursForType(
    NotificationType type,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_peak_hours_for_type',
        params: {
          'notification_type': type.value,
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
      );

      return (response as List<dynamic>).cast<int>();
    } catch (e) {
      return [];
    }
  }

  double _calculateRate(int numerator, int denominator) {
    if (denominator == 0) return 0.0;
    return (numerator / denominator) * 100.0;
  }
}

/// Main analytics data model
class NotificationAnalytics {
  final int totalSent;
  final int totalDelivered;
  final int totalRead;
  final int totalClicked;
  final double deliveryRate;
  final double readRate;
  final double clickRate;
  final Map<NotificationType, double> deliveryRatesByType;
  final UserEngagementMetrics engagementMetrics;
  final List<HourlyActivity> hourlyDistribution;
  final List<DailyTrend> dailyTrends;
  final DateTime periodStart;
  final DateTime periodEnd;

  NotificationAnalytics({
    required this.totalSent,
    required this.totalDelivered,
    required this.totalRead,
    required this.totalClicked,
    required this.deliveryRate,
    required this.readRate,
    required this.clickRate,
    required this.deliveryRatesByType,
    required this.engagementMetrics,
    required this.hourlyDistribution,
    required this.dailyTrends,
    required this.periodStart,
    required this.periodEnd,
  });

  factory NotificationAnalytics.empty() {
    return NotificationAnalytics(
      totalSent: 0,
      totalDelivered: 0,
      totalRead: 0,
      totalClicked: 0,
      deliveryRate: 0.0,
      readRate: 0.0,
      clickRate: 0.0,
      deliveryRatesByType: {},
      engagementMetrics: UserEngagementMetrics.empty(),
      hourlyDistribution: [],
      dailyTrends: [],
      periodStart: DateTime.now(),
      periodEnd: DateTime.now(),
    );
  }
}

/// Analytics for specific notification type
class NotificationTypeAnalytics {
  final NotificationType type;
  final int totalSent;
  final int totalRead;
  final int totalClicked;
  final double readRate;
  final double clickRate;
  final Duration averageTimeToRead;
  final List<int> peakHours;

  NotificationTypeAnalytics({
    required this.type,
    required this.totalSent,
    required this.totalRead,
    required this.totalClicked,
    required this.readRate,
    required this.clickRate,
    required this.averageTimeToRead,
    required this.peakHours,
  });

  factory NotificationTypeAnalytics.empty(NotificationType type) {
    return NotificationTypeAnalytics(
      type: type,
      totalSent: 0,
      totalRead: 0,
      totalClicked: 0,
      readRate: 0.0,
      clickRate: 0.0,
      averageTimeToRead: const Duration(minutes: 0),
      peakHours: [],
    );
  }
}

/// User engagement metrics
class UserEngagementMetrics {
  final int totalActiveUsers;
  final int highlyEngagedUsers;
  final int lowEngagedUsers;
  final double averageEngagementScore;
  final Map<String, int> engagementDistribution;

  UserEngagementMetrics({
    required this.totalActiveUsers,
    required this.highlyEngagedUsers,
    required this.lowEngagedUsers,
    required this.averageEngagementScore,
    required this.engagementDistribution,
  });

  factory UserEngagementMetrics.fromJson(Map<String, dynamic> json) {
    return UserEngagementMetrics(
      totalActiveUsers: json['total_active_users'] ?? 0,
      highlyEngagedUsers: json['highly_engaged_users'] ?? 0,
      lowEngagedUsers: json['low_engaged_users'] ?? 0,
      averageEngagementScore:
          (json['average_engagement_score'] as num?)?.toDouble() ?? 0.0,
      engagementDistribution: Map<String, int>.from(
        json['engagement_distribution'] ?? {},
      ),
    );
  }

  factory UserEngagementMetrics.empty() {
    return UserEngagementMetrics(
      totalActiveUsers: 0,
      highlyEngagedUsers: 0,
      lowEngagedUsers: 0,
      averageEngagementScore: 0.0,
      engagementDistribution: {},
    );
  }
}

/// Hourly activity data
class HourlyActivity {
  final int hour;
  final int notificationsSent;
  final int notificationsRead;
  final double engagementRate;

  HourlyActivity({
    required this.hour,
    required this.notificationsSent,
    required this.notificationsRead,
    required this.engagementRate,
  });

  factory HourlyActivity.fromJson(Map<String, dynamic> json) {
    return HourlyActivity(
      hour: json['hour'] ?? 0,
      notificationsSent: json['notifications_sent'] ?? 0,
      notificationsRead: json['notifications_read'] ?? 0,
      engagementRate: (json['engagement_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Daily trend data
class DailyTrend {
  final DateTime date;
  final int notificationsSent;
  final int notificationsRead;
  final int activeUsers;
  final double engagementRate;

  DailyTrend({
    required this.date,
    required this.notificationsSent,
    required this.notificationsRead,
    required this.activeUsers,
    required this.engagementRate,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: DateTime.parse(json['date']),
      notificationsSent: json['notifications_sent'] ?? 0,
      notificationsRead: json['notifications_read'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      engagementRate: (json['engagement_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

