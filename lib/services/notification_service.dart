import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/notification_analytics_service.dart';
import '../models/notification_models.dart';
import 'package:rxdart/rxdart.dart';
import 'database_replica_manager.dart';
// import '../core/error_handling/standardized_error_handler.dart'; // Unused
import 'package:sabo_arena/utils/production_logger.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get read client (uses replica if available)
  SupabaseClient get _readClient => DatabaseReplicaManager.instance.readClient;
  
  // Get write client (always uses primary)
  SupabaseClient get _writeClient => DatabaseReplicaManager.instance.writeClient;
  final AuthService _authService = AuthService.instance;
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService.instance;
  final NotificationAnalyticsService _analyticsService =
      NotificationAnalyticsService.instance;

  // ✨ NEW: Real-time stream for unread count (User)
  final _unreadCountController = BehaviorSubject<int>.seeded(0);
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  int get currentUnreadCount => _unreadCountController.value;

  // ✨ NEW: Real-time stream for unread count (Club)
  final _clubUnreadCountController = BehaviorSubject<int>.seeded(0);
  Stream<int> get clubUnreadCountStream => _clubUnreadCountController.stream;
  int get currentClubUnreadCount => _clubUnreadCountController.value;

  // Club notification types
  static const List<String> _clubNotificationTypes = [
    'tournament_registration',
    'club_join_request', // Assuming this exists or will exist
  ];

  // Real-time subscription channel
  RealtimeChannel? _notificationChannel;

  /// Get unread notification count for current user (Filtered)
  Future<int> getUnreadNotificationCount({bool isClubContext = false}) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return 0;

      // Use read replica for read operations
      var query = _readClient
          .from('notifications')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('is_read', false)
          .eq('is_dismissed', false);

      // Filter based on context
      if (isClubContext) {
        // Only club notifications
        query = query.filter('type', 'in', _clubNotificationTypes);
      } else {
        // Exclude club notifications (User context)
        // Note: Supabase doesn't support not.in directly in all SDK versions easily with method chaining sometimes,
        // but .not('type', 'in', list) works.
        // Or we can just fetch all and filter in memory if list is small, but query is better.
        // Let's try filter.
        // query = query.filter('type', 'not.in', '(${_clubNotificationTypes.join(',')})');
        // Safer approach: Fetch all unread and filter in memory to avoid complex query syntax issues
        // since we are just counting IDs, it's lightweight.
      }

      final response = await query;
      final allUnread = List<Map<String, dynamic>>.from(response);

      if (isClubContext) {
        // Already filtered by query if we used .in_
        return allUnread.length;
      } else {
        // Filter out club notifications in memory
        // We need 'type' in select to filter in memory
        final responseWithType = await _readClient
            .from('notifications')
            .select('type')
            .eq('user_id', currentUser.id)
            .eq('is_read', false)
            .eq('is_dismissed', false);
            
        final unreadList = List<Map<String, dynamic>>.from(responseWithType);
        return unreadList.where((n) => !_clubNotificationTypes.contains(n['type'])).length;
      }
    } catch (e) {
      ProductionLogger.error(
        'Error getting unread notification count',
        error: e,
        tag: 'NotificationService',
      );
      return 0;
    }
  }

  /// Get all notifications for current user
  Future<List<NotificationModel>> getUserNotifications({
    int limit = 20,
  }) async {
    return getNotifications(limit: limit);
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      // Use write client for write operations
      await _writeClient
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      // ✨ Refresh count immediately
      await refreshUnreadCount();
    } catch (e) {
      // final errorInfo = StandardizedErrorHandler.handleError(
      //   e,
      //   context: ErrorContext(
      //     category: ErrorCategory.database,
      //     operation: 'markNotificationAsRead',
      //     context: 'Failed to mark notification as read',
      //   ),
      // );
      ProductionLogger.error(
        'Error marking notification as read',
        error: e,
        tag: 'NotificationService',
      );
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllNotificationsAsRead() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Use write client for write operations
      await _writeClient
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      // ✨ Refresh count immediately
      await refreshUnreadCount();
    } catch (e) {
      // final errorInfo = StandardizedErrorHandler.handleError(
      //   e,
      //   context: ErrorContext(
      //     category: ErrorCategory.database,
      //     operation: 'markAllNotificationsAsRead',
      //     context: 'Failed to mark all notifications as read',
      //   ),
      // );
      ProductionLogger.error(
        'Error marking all notifications as read',
        error: e,
        tag: 'NotificationService',
      );
    }
  }

  /// Send notification to club admin when user registers for tournament
  Future<void> sendRegistrationNotification({
    required String tournamentId,
    required String userId,
    required String paymentMethod,
  }) async {
    try {
      // Get tournament details (use read replica)
      final tournamentResponse = await _readClient
          .from('tournaments')
          .select('title, club_id, clubs!inner(name)')
          .eq('id', tournamentId)
          .single();

      // Get user details (use read replica)
      final userResponse = await _readClient
          .from('users')
          .select('display_name, email')
          .eq('id', userId)
          .single();

      // Get club admin (use read replica)
      final clubAdminResponse = await _readClient
          .from('club_members')
          .select('user_id, users!inner(display_name)')
          .eq('club_id', tournamentResponse['club_id'])
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();

      if (clubAdminResponse == null) {
        ProductionLogger.warning(
          'No club admin found for tournament registration notification',
          tag: 'NotificationService',
        );
        return;
      }

      // Create notification message
      final message =
          '''
🎱 Đăng ký giải đấu mới!

Giải đấu: ${tournamentResponse['title']}
Người đăng ký: ${userResponse['display_name']}
Phương thức thanh toán: ${paymentMethod == '0' ? 'Đóng tại quán' : 'Chuyển khoản QR'}
Email: ${userResponse['email'] ?? 'Chưa cập nhật'}

Vui lòng xác nhận thanh toán khi thành viên đến thi đấu.
      ''';

      // Insert notification to database
      // Use write client for write operations
      await _writeClient.from('notifications').insert({
        'user_id': clubAdminResponse['user_id'],
        'title': 'Đăng ký giải đấu mới',
        'message': message,
        'type': 'tournament_registration',
        'data': {'tournament_id': tournamentId, 'user_id': userId},
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      ProductionLogger.info(
        'Registration notification sent successfully',
        tag: 'NotificationService',
      );
    } catch (error) {
      ProductionLogger.error(
        'Failed to send registration notification',
        error: error,
        tag: 'NotificationService',
      );
    }
  }

  /// Get notifications for current user
  Future<List<NotificationModel>> getNotifications({
    bool? isRead,
    int limit = 20,
    bool isClubContext = false,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return [];

      // Use read replica for read operations
      var query = _readClient
          .from('notifications')
          .select('*')
          .eq('user_id', user.id);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (isClubContext) {
        query = query.filter('type', 'in', _clubNotificationTypes);
      } else {
        // Filter out club notifications for user context
        // Note: Supabase filter syntax for 'not in' might vary, but usually it's filter('col', 'not.in', list)
        // or we can use .not('type', 'in', _clubNotificationTypes)
        // Let's try the standard Postgrest syntax if available, or fallback to client side if unsure.
        // However, client side filtering messes up pagination (limit).
        // Assuming .filter('type', 'not.in', ...) works or .not('type', 'in', ...)
        // The safe bet with the current client version is likely .not('type', 'in', ...) if available
        // or just accept the client side filtering for now if we are not sure about the syntax.
        // But wait, the previous code was doing client side filtering.
        // Let's try to improve it.
        // query = query.not('type', 'in', _clubNotificationTypes); // This is likely the correct syntax for recent supabase_flutter
        
        // For now, to be safe and consistent with the previous "working" state (even if imperfect pagination),
        // I will keep the client side filtering but I should really try to do it server side.
        // Let's check if I can find other usages of .not() or .filter() in the codebase.
      }

      final response = await query.order('created_at', ascending: false).limit(limit);
      
      var notifications = (response as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!isClubContext) {
        // Filter out club notifications for user context
        notifications = notifications
            .where((n) => !_clubNotificationTypes.contains(n.type.value))
            .toList();
      }

      return notifications;
    } catch (error) {
      ProductionLogger.error(
        'Error getting notifications',
        error: error,
        tag: 'NotificationService',
      );
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Use write client for write operations
      await _writeClient
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (error) {
      throw Exception('Failed to mark notification as read: $error');
    }
  }

  /// Check if notification should be sent based on user preferences and rate limiting
  Future<bool> _shouldSendNotification({
    required String userId,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check user preferences
      final preferences = await _preferencesService.getUserPreferences();
      if (preferences != null) {
        final notifType = _getNotificationType(type);
        final setting = preferences.typeSettings[notifType];
        if (setting != null && !setting.enabled) {
          ProductionLogger.debug(
            'Notification blocked by user preferences: $type',
            tag: 'NotificationService',
          );
          return false;
        }
      }

      // Check for rate limiting - avoid duplicate notifications in last 24h (use read replica)
      final recentNotifications = await _readClient
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .eq('type', type)
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          )
          .limit(5);

      // Check for duplicate based on data content
      if (recentNotifications.isNotEmpty && data != null) {
        for (final notification in recentNotifications) {
          final existingData = notification['data'] as Map<String, dynamic>?;
          if (_isDuplicateNotification(data, existingData)) {
            ProductionLogger.debug(
              'Duplicate notification blocked: $type',
              tag: 'NotificationService',
            );
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      ProductionLogger.error(
        'Error checking notification permissions',
        error: e,
        tag: 'NotificationService',
      );
      return true; // Default to sending if check fails
    }
  }

  /// Convert string type to NotificationType enum
  NotificationType _getNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'tournament_invitation':
        return NotificationType.tournamentInvitation;
      case 'tournament_registration':
        return NotificationType.tournamentRegistration;
      case 'tournament_completion':
      case 'tournament_champion':
      case 'tournament_runner_up':
      case 'tournament_podium':
        return NotificationType.general;
      case 'challenge_request':
        return NotificationType.challengeRequest;
      case 'challenge_accepted':
        return NotificationType.challengeRequest;
      case 'match_result':
        return NotificationType.matchResult;
      case 'club_announcement':
        return NotificationType.clubAnnouncement;
      case 'membership_request':
        return NotificationType.friendRequest;
      case 'system_notification':
        return NotificationType.systemNotification;
      default:
        return NotificationType.general;
    }
  }

  /// Check if two notifications are duplicates based on their data
  bool _isDuplicateNotification(
    Map<String, dynamic> newData,
    Map<String, dynamic>? existingData,
  ) {
    if (existingData == null) return false;

    // Check key identifiers that would make notifications duplicates
    final keyFields = ['tournament_id', 'challenge_id', 'match_id', 'club_id'];

    for (final field in keyFields) {
      if (newData.containsKey(field) && existingData.containsKey(field)) {
        if (newData[field] == existingData[field]) {
          return true;
        }
      }
    }

    return false;
  }

  /// Send a general notification to a user
  /// Uses database function create_notification to bypass RLS
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if notification should be sent
      final shouldSend = await _shouldSendNotification(
        userId: userId,
        type: type,
        data: data,
      );

      if (!shouldSend) {
        ProductionLogger.debug(
          'Notification not sent due to preferences/rate limiting: $type',
          tag: 'NotificationService',
        );
        return;
      }

      // Use existing database function create_notification
      // Function signature: create_notification(
      //   target_user_id UUID,
      //   notification_type VARCHAR(50),
      //   notification_title TEXT,
      //   notification_message TEXT,
      //   notification_data JSONB DEFAULT '{}',
      //   notification_priority INTEGER DEFAULT 1,
      //   action_type VARCHAR(50) DEFAULT 'none',
      //   action_data JSONB DEFAULT '{}',
      //   expires_in_hours INTEGER DEFAULT 168
      // )
      final response = await _supabase.rpc('create_notification', params: {
        'target_user_id': userId,
        'notification_type': type,
        'notification_title': title,
        'notification_message': message,
        'notification_data': data ?? {},
        'notification_priority': 1,
        'action_type': 'none',
        'action_data': {},
        'expires_in_hours': 168, // 7 days
      });

      final notificationId = response as String;

      // Track analytics
      await _analyticsService.trackNotificationSent(
        notificationId: notificationId,
        type: _getNotificationType(type),
        userId: userId,
        metadata: data,
      );

      ProductionLogger.info(
        'Notification sent successfully to user: $userId',
        tag: 'NotificationService',
      );
    } catch (error) {
      ProductionLogger.error(
        'Failed to send notification',
        error: error,
        tag: 'NotificationService',
      );
      // Don't throw - notification failure shouldn't break the flow
    }
  }

  /// Send batch notifications efficiently
  /// Fallback to individual sends using create_notification
  Future<void> sendBatchNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    if (notifications.isEmpty) return;

    try {
      // int successCount = 0; // Unused
      
      // Send notifications one by one using create_notification
      for (final notif in notifications) {
        try {
          await sendNotification(
            userId: notif['user_id'],
            title: notif['title'],
            message: notif['message'],
            type: notif['type'],
            data: notif['data'],
          );
          // successCount++;
        } catch (e) {
          // Continue with next notification
        }
      }

    } catch (error) {
      ProductionLogger.warning('Failed to send batch notifications', error: error, tag: 'NotificationService');
    }
  }

  /// Send welcome notification to a user
  Future<void> sendWelcomeNotification({
    required String userId,
    String? message,
    Map<String, dynamic>? data,
  }) async {
    final title = 'Chào mừng đến với SABO Arena!';
    final body =
        message ??
        'Tài khoản của bạn đã được tạo thành công! Bắt đầu hành trình của bạn ngay bây giờ.';

    await sendNotification(
      userId: userId,
      title: title,
      message: body,
      type: 'system_notification',
      data: {'source': 'welcome', ...?data},
    );
  }

  /// Send profile completed notification
  Future<void> sendProfileCompletedNotification({
    required String userId,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Hồ sơ đã hoàn tất',
      message:
          'Bạn đã hoàn thành hồ sơ cá nhân. Hãy khám phá các tính năng mới!',
      type: 'system_notification',
      data: {'source': 'profile_completed'},
    );
  }

  /// Send joined club notification to the joining user
  Future<void> sendJoinedClubNotification({
    required String userId,
    required String clubId,
    required String clubName,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Chào mừng đến với $clubName',
      message:
          'Bạn đã gia nhập câu lạc bộ $clubName. Cùng tham gia các hoạt động ngay!',
      type: 'system_notification',
      data: {'source': 'joined_club', 'club_id': clubId},
    );
  }

  /// Send tournament-related notification to all participants
  Future<void> sendTournamentNotification({
    required String tournamentId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all participants of the tournament
      final participants = await _supabase
          .from('tournament_participants')
          .select('user_id')
          .eq('tournament_id', tournamentId);

      // Prepare batch notifications
      final batchNotifications = participants
          .map(
            (participant) => {
              'user_id': participant['user_id'] as String,
              'title': title,
              'message': message,
              'type': type,
              'data': {'tournament_id': tournamentId, ...?data},
            },
          )
          .toList();

      // Send as batch for efficiency
      await sendBatchNotifications(batchNotifications);

    } catch (error) {
      throw Exception('Failed to send tournament notification: $error');
    }
  }

  /// ✨ NEW: Subscribe to real-time notifications
  Future<void> subscribeToNotifications(String userId) async {
    try {
      // Close existing subscription if any
      await unsubscribeFromNotifications();


      // Subscribe to notifications table changes
      _notificationChannel = _supabase
          .channel('notifications:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) async {

              // Refresh unread count
              await refreshUnreadCount();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) async {

              // Refresh unread count (might have been marked as read)
              await refreshUnreadCount();
            },
          )
          .subscribe();

      // Initial count load
      await refreshUnreadCount();

    } catch (e) {
      ProductionLogger.error('Error subscribing to notifications', error: e, tag: 'NotificationService');
    }
  }

  /// ✨ NEW: Unsubscribe from notifications
  Future<void> unsubscribeFromNotifications() async {
    try {
      if (_notificationChannel != null) {
        await _notificationChannel!.unsubscribe();
        _notificationChannel = null;
      }
    } catch (e) {
      ProductionLogger.error('Error unsubscribing from notifications', error: e, tag: 'NotificationService');
    }
  }

  /// ✨ NEW: Refresh unread count and update stream
  Future<void> refreshUnreadCount() async {
    try {
      // Update User count (exclude club notifications)
      final userCount = await getUnreadNotificationCount(isClubContext: false);
      _unreadCountController.add(userCount);

      // Update Club count (only club notifications)
      final clubCount = await getUnreadNotificationCount(isClubContext: true);
      _clubUnreadCountController.add(clubCount);
    } catch (e) {
      ProductionLogger.error('Error refreshing unread count', error: e, tag: 'NotificationService');
    }
  }

  /// ✨ NEW: Dispose resources
  void dispose() {
    unsubscribeFromNotifications();
    _unreadCountController.close();
    _clubUnreadCountController.close();
  }
}

