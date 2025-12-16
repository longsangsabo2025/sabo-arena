import '../services/notification_service.dart';
import '../models/notification_models.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Smart notification batching service for optimized delivery
class SmartNotificationBatchingService {
  static final SmartNotificationBatchingService _instance =
      SmartNotificationBatchingService._internal();
  factory SmartNotificationBatchingService() => _instance;
  SmartNotificationBatchingService._internal();

  static SmartNotificationBatchingService get instance => _instance;

  final NotificationService _notificationService = NotificationService.instance;
  final List<PendingNotification> _pendingNotifications = [];
  final Map<String, List<PendingNotification>> _userBatches = {};

  // Configuration
  static const int _maxBatchSize = 50;
  static const Duration _batchTimeout = Duration(minutes: 5);

  /// Add notification to smart batching queue
  Future<void> queueNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final notification = PendingNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
      priority: priority,
      queuedAt: DateTime.now(),
    );

    // High priority notifications bypass batching
    if (priority == NotificationPriority.urgent) {
      await _notificationService.sendNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        data: data,
      );
      return;
    }

    // Add to batching queue
    _pendingNotifications.add(notification);

    // Group by user for smart batching
    _userBatches.putIfAbsent(userId, () => []).add(notification);

    // Trigger batching logic
    await _processBatching();
  }

  /// Process batching logic with smart timing
  Future<void> _processBatching() async {
    final now = DateTime.now();

    // Process each user's batch
    for (final entry in _userBatches.entries) {
      final userId = entry.key;
      final userNotifications = entry.value;

      if (userNotifications.isEmpty) continue;

      // Check if batch should be sent
      final shouldSend = await _shouldSendBatch(userId, userNotifications, now);

      if (shouldSend) {
        await _sendBatch(userId, userNotifications);
        _userBatches[userId]?.clear();
      }
    }

    // Remove processed notifications
    _pendingNotifications.removeWhere(
      (notification) =>
          !_userBatches.values.any((batch) => batch.contains(notification)),
    );
  }

  /// Determine if batch should be sent based on smart rules
  Future<bool> _shouldSendBatch(
    String userId,
    List<PendingNotification> notifications,
    DateTime now,
  ) async {
    if (notifications.isEmpty) return false;

    // Rule 1: Batch size threshold
    if (notifications.length >= _maxBatchSize) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    }

    // Rule 2: Time threshold
    final oldestNotification = notifications.reduce(
      (a, b) => a.queuedAt.isBefore(b.queuedAt) ? a : b,
    );
    if (now.difference(oldestNotification.queuedAt) >= _batchTimeout) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    }

    // Rule 3: High priority notifications in batch
    if (notifications.any((n) => n.priority == NotificationPriority.high)) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    }

    // Rule 4: Optimal delivery time (not in quiet hours)
    if (!_isInQuietHours(now)) {
      // Send if we have accumulated enough diverse notifications
      if (notifications.length >= 3 && _hasDiverseTypes(notifications)) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return true;
      }
    }

    // Rule 5: Force send if batch is very old (prevent indefinite queuing)
    if (now.difference(oldestNotification.queuedAt) >=
        const Duration(hours: 2)) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    }

    return false;
  }

  /// Send batch with smart grouping
  Future<void> _sendBatch(
    String userId,
    List<PendingNotification> notifications,
  ) async {
    if (notifications.isEmpty) return;

    // Group similar notifications
    final grouped = _groupSimilarNotifications(notifications);

    for (final group in grouped) {
      if (group.length == 1) {
        // Send individual notification
        final notification = group.first;
        await _notificationService.sendNotification(
          userId: notification.userId,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          data: notification.data,
        );
      } else {
        // Send grouped notification
        await _sendGroupedNotification(userId, group);
      }
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Group similar notifications together
  List<List<PendingNotification>> _groupSimilarNotifications(
    List<PendingNotification> notifications,
  ) {
    final Map<String, List<PendingNotification>> groups = {};

    for (final notification in notifications) {
      final groupKey = _getGroupKey(notification);
      groups.putIfAbsent(groupKey, () => []).add(notification);
    }

    return groups.values.toList();
  }

  /// Generate group key for similar notifications
  String _getGroupKey(PendingNotification notification) {
    // Group by type and source
    final tournamentId = notification.data?['tournament_id'];
    final clubId = notification.data?['club_id'];

    if (tournamentId != null) {
      return '${notification.type}_tournament_$tournamentId';
    } else if (clubId != null) {
      return '${notification.type}_club_$clubId';
    } else {
      return notification.type;
    }
  }

  /// Send grouped notification with summary
  Future<void> _sendGroupedNotification(
    String userId,
    List<PendingNotification> group,
  ) async {
    final firstNotification = group.first;
    final count = group.length;

    String title;
    String message;

    switch (firstNotification.type) {
      case 'tournament_completion':
      case 'tournament_champion':
      case 'tournament_runner_up':
      case 'tournament_podium':
        title = '🏆 Tournament Updates ($count)';
        message =
            'You have $count tournament result notifications waiting for you!';
        break;

      case 'challenge_request':
        title = '⚔️ Challenge Requests ($count)';
        message = 'You have $count new challenge requests!';
        break;

      case 'club_announcement':
        title = '📢 Club Updates ($count)';
        message = 'Your clubs have $count new announcements';
        break;

      case 'membership_request':
        title = '👥 Membership Requests ($count)';
        message = 'You have $count new membership requests to review';
        break;

      default:
        title = '🔔 Notifications ($count)';
        message = 'You have $count new notifications';
    }

    // Aggregate data from all notifications in group
    final aggregatedData = <String, dynamic>{
      'batch_count': count,
      'notification_ids': group
          .map((n) => n.data?['notification_id'])
          .where((id) => id != null)
          .toList(),
      'types': group.map((n) => n.type).toSet().toList(),
    };

    // Add specific data based on type
    if (firstNotification.data?['tournament_id'] != null) {
      aggregatedData['tournament_id'] =
          firstNotification.data!['tournament_id'];
    }
    if (firstNotification.data?['club_id'] != null) {
      aggregatedData['club_id'] = firstNotification.data!['club_id'];
    }

    await _notificationService.sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'batch_notification',
      data: aggregatedData,
    );
  }

  /// Check if notifications have diverse types
  bool _hasDiverseTypes(List<PendingNotification> notifications) {
    final types = notifications.map((n) => n.type).toSet();
    return types.length >= 2; // At least 2 different types
  }

  /// Check if current time is in quiet hours (10 PM - 8 AM)
  bool _isInQuietHours(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= 22 || hour < 8;
  }

  /// Force flush all pending notifications (useful for app shutdown)
  Future<void> flushAllPending() async {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    for (final entry in _userBatches.entries) {
      if (entry.value.isNotEmpty) {
        await _sendBatch(entry.key, entry.value);
      }
    }

    _userBatches.clear();
    _pendingNotifications.clear();
  }

  /// Get pending notification stats for monitoring
  Map<String, dynamic> getPendingStats() {
    final totalPending = _pendingNotifications.length;
    final userBatchCounts = _userBatches.map(
      (key, value) => MapEntry(key, value.length),
    );
    final typeDistribution = <String, int>{};

    for (final notification in _pendingNotifications) {
      typeDistribution[notification.type] =
          (typeDistribution[notification.type] ?? 0) + 1;
    }

    return {
      'total_pending': totalPending,
      'users_with_pending': _userBatches.keys.length,
      'user_batch_counts': userBatchCounts,
      'type_distribution': typeDistribution,
      'oldest_pending': _pendingNotifications.isEmpty
          ? null
          : _pendingNotifications
                .map((n) => n.queuedAt)
                .reduce((a, b) => a.isBefore(b) ? a : b)
                .toIso8601String(),
    };
  }
}

/// Pending notification model for batching queue
class PendingNotification {
  final String userId;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? data;
  final NotificationPriority priority;
  final DateTime queuedAt;

  PendingNotification({
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.priority,
    required this.queuedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingNotification &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          title == other.title &&
          message == other.message &&
          type == other.type &&
          queuedAt == other.queuedAt;

  @override
  int get hashCode =>
      userId.hashCode ^
      title.hashCode ^
      message.hashCode ^
      type.hashCode ^
      queuedAt.hashCode;
}

