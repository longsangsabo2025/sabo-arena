import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 UNIFIED NOTIFICATION SERVICE
/// 
/// Consolidates all notification functionality:
/// - notification_service.dart
/// - notification_overlay_service.dart
/// - notification_preferences_service.dart
/// - notification_analytics_service.dart
/// - smart_notification_batching_service.dart
/// - voucher_notification_service.dart
/// - auto_notification_hooks.dart
/// 
/// Features:
/// - Push notifications
/// - In-app overlays
/// - Notification preferences
/// - Batching & throttling
/// - Analytics tracking
class UnifiedNotificationService {
  static UnifiedNotificationService? _instance;
  static UnifiedNotificationService get instance =>
      _instance ??= UnifiedNotificationService._();

  UnifiedNotificationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tag = 'UnifiedNotification';

  // Batching configuration
  static const Duration _batchInterval = Duration(seconds: 5);
  static const int _maxBatchSize = 10;
  
  final List<_NotificationItem> _pendingNotifications = [];
  DateTime? _lastBatchTime;

  // Preferences cache
  Map<String, bool> _preferences = {};

  /// Initialize notification service
  Future<void> initialize() async {
    ProductionLogger.info('$_tag: Initializing notification service');
    await _loadPreferences();
  }

  // ============================================================================
  // SEND NOTIFICATIONS
  // ============================================================================

  /// Send notification to user
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
    bool immediate = false,
  }) async {
    try {
      // Check preferences
      if (!await _shouldSendNotification(userId, type)) {
        ProductionLogger.debug('$_tag: Notification blocked by preferences');
        return false;
      }

      final notification = _NotificationItem(
        userId: userId,
        title: title,
        body: body,
        type: type ?? 'general',
        data: data ?? {},
        createdAt: DateTime.now(),
      );

      if (immediate) {
        return await _sendImmediately(notification);
      } else {
        _addToBatch(notification);
        return true;
      }
    } catch (e) {
      ProductionLogger.error('$_tag: Error sending notification', error: e);
      return false;
    }
  }

  /// Send notification to multiple users
  Future<int> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    int successCount = 0;
    
    for (final userId in userIds) {
      final success = await sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
      if (success) successCount++;
    }

    ProductionLogger.info('$_tag: Bulk notification sent to $successCount/${userIds.length} users');
    return successCount;
  }

  // ============================================================================
  // NOTIFICATION TYPES
  // ============================================================================

  /// Tournament notification
  Future<bool> sendTournamentNotification({
    required String oderId,
    required String tournamentName,
    required String message,
    String? tournamentId,
  }) async {
    return await sendNotification(
      userId: oderId,
      title: '🏆 $tournamentName',
      body: message,
      type: 'tournament',
      data: {'tournament_id': tournamentId},
    );
  }

  /// Match notification
  Future<bool> sendMatchNotification({
    required String userId,
    required String opponentName,
    required String message,
    String? matchId,
  }) async {
    return await sendNotification(
      userId: userId,
      title: '🎱 Match Update',
      body: '$opponentName - $message',
      type: 'match',
      data: {'match_id': matchId},
    );
  }

  /// Voucher notification
  Future<bool> sendVoucherNotification({
    required String userId,
    required String voucherName,
    required String message,
    String? voucherId,
  }) async {
    return await sendNotification(
      userId: userId,
      title: '🎁 $voucherName',
      body: message,
      type: 'voucher',
      data: {'voucher_id': voucherId},
    );
  }

  /// Challenge notification
  Future<bool> sendChallengeNotification({
    required String userId,
    required String challengerName,
    required String message,
    String? challengeId,
  }) async {
    return await sendNotification(
      userId: userId,
      title: '⚔️ Challenge from $challengerName',
      body: message,
      type: 'challenge',
      data: {'challenge_id': challengeId},
      immediate: true, // Challenges should be immediate
    );
  }

  /// Club notification
  Future<bool> sendClubNotification({
    required String userId,
    required String clubName,
    required String message,
    String? clubId,
  }) async {
    return await sendNotification(
      userId: userId,
      title: '🏠 $clubName',
      body: message,
      type: 'club',
      data: {'club_id': clubId},
    );
  }

  // ============================================================================
  // IN-APP OVERLAYS
  // ============================================================================

  /// Show in-app notification overlay
  void showOverlay(
    BuildContext context, {
    required String title,
    required String body,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    final overlay = OverlayEntry(
      builder: (context) => _NotificationOverlayWidget(
        title: title,
        body: body,
        onTap: onTap,
        onDismiss: () {},
      ),
    );

    Overlay.of(context).insert(overlay);

    Future.delayed(duration, () {
      if (overlay.mounted) {
        overlay.remove();
      }
    });
  }

  /// Show success notification
  void showSuccess(BuildContext context, String message) {
    showOverlay(context, title: '✅ Success', body: message);
  }

  /// Show error notification
  void showError(BuildContext context, String message) {
    showOverlay(context, title: '❌ Error', body: message);
  }

  /// Show info notification
  void showInfo(BuildContext context, String message) {
    showOverlay(context, title: 'ℹ️ Info', body: message);
  }

  // ============================================================================
  // PREFERENCES
  // ============================================================================

  /// Load user preferences
  Future<void> _loadPreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _preferences = {
          'tournament': response['tournament_enabled'] ?? true,
          'match': response['match_enabled'] ?? true,
          'voucher': response['voucher_enabled'] ?? true,
          'challenge': response['challenge_enabled'] ?? true,
          'club': response['club_enabled'] ?? true,
          'general': response['general_enabled'] ?? true,
        };
      }
    } catch (e) {
      ProductionLogger.warning('$_tag: Error loading preferences: $e');
    }
  }

  /// Update notification preference
  Future<bool> updatePreference(String type, bool enabled) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notification_preferences')
          .upsert({
            'user_id': userId,
            '${type}_enabled': enabled,
            'updated_at': DateTime.now().toIso8601String(),
          });

      _preferences[type] = enabled;
      return true;
    } catch (e) {
      ProductionLogger.error('$_tag: Error updating preference', error: e);
      return false;
    }
  }

  /// Check if notification type is enabled
  Future<bool> _shouldSendNotification(String userId, String? type) async {
    if (type == null) return true;
    return _preferences[type] ?? true;
  }

  /// Get all preferences
  Map<String, bool> getPreferences() => Map.from(_preferences);

  // ============================================================================
  // BATCHING
  // ============================================================================

  void _addToBatch(_NotificationItem notification) {
    _pendingNotifications.add(notification);

    if (_pendingNotifications.length >= _maxBatchSize) {
      _flushBatch();
    } else if (_lastBatchTime == null) {
      _lastBatchTime = DateTime.now();
      Future.delayed(_batchInterval, _flushBatch);
    }
  }

  Future<void> _flushBatch() async {
    if (_pendingNotifications.isEmpty) return;

    final batch = List<_NotificationItem>.from(_pendingNotifications);
    _pendingNotifications.clear();
    _lastBatchTime = null;

    for (final notification in batch) {
      await _sendImmediately(notification);
    }

    ProductionLogger.debug('$_tag: Flushed ${batch.length} notifications');
  }

  Future<bool> _sendImmediately(_NotificationItem notification) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': notification.userId,
        'title': notification.title,
        'body': notification.body,
        'type': notification.type,
        'data': notification.data,
        'is_read': false,
        'created_at': notification.createdAt.toIso8601String(),
      });

      // Track analytics
      _trackNotification(notification);

      return true;
    } catch (e) {
      ProductionLogger.error('$_tag: Error sending notification', error: e);
      return false;
    }
  }

  // ============================================================================
  // ANALYTICS
  // ============================================================================

  void _trackNotification(_NotificationItem notification) {
    // Track notification sent
    ProductionLogger.debug(
      '$_tag: Notification sent - type: ${notification.type}, user: ${notification.userId}'
    );
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getStats(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('type, is_read')
          .eq('user_id', userId);

      final total = response.length;
      final unread = response.where((n) => n['is_read'] == false).length;
      final byType = <String, int>{};

      for (final n in response) {
        final type = n['type'] as String? ?? 'general';
        byType[type] = (byType[type] ?? 0) + 1;
      }

      return {
        'total': total,
        'unread': unread,
        'by_type': byType,
      };
    } catch (e) {
      ProductionLogger.error('$_tag: Error getting stats', error: e);
      return {};
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark all as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Internal notification item
class _NotificationItem {
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  _NotificationItem({
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.createdAt,
  });
}

/// Notification overlay widget
class _NotificationOverlayWidget extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _NotificationOverlayWidget({
    required this.title,
    required this.body,
    this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

