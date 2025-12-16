import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 🔔 Auto Notification Hooks System
/// Tự động gửi thông báo cho các sự kiện quan trọng trong hệ thống
///
/// Sử dụng:
/// ```dart
/// // Trong auth_service.dart sau khi signUp thành công:
/// await AutoNotificationHooks.onUserRegistered(userId: newUser.id, userName: fullName);
///
/// // Trong club_service.dart sau khi createClub:
/// await AutoNotificationHooks.onClubCreated(clubId: club.id, ownerId: userId);
/// ```
class AutoNotificationHooks {
  static final NotificationService _notificationService =
      NotificationService.instance;

  // =============================================================================
  // 👤 USER EVENTS
  // =============================================================================

  /// Thông báo chào mừng user mới đăng ký
  static Future<void> onUserRegistered({
    required String userId,
    required String userName,
    String?
    registrationMethod, // 'email', 'phone', 'google', 'apple', 'facebook'
  }) async {
    try {
      final methodText = registrationMethod != null
          ? _getRegistrationMethodText(registrationMethod)
          : '';

      await _notificationService.sendNotification(
        userId: userId,
        type: 'system',
        title: '🎉 Chào mừng bạn đến với Sabo Arena!',
        message:
            'Xin chào $userName! Tài khoản của bạn đã được tạo thành công$methodText. Hãy khám phá các câu lạc bộ billiards gần bạn!',
        data: {
          'screen': 'home',
          'action': 'welcome',
          'registration_method': registrationMethod,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi profile được cập nhật
  static Future<void> onProfileUpdated({
    required String userId,
    required String userName,
    List<String>? updatedFields,
  }) async {
    try {
      final fieldsText = updatedFields?.join(', ') ?? 'thông tin';

      await _notificationService.sendNotification(
        userId: userId,
        type: 'system',
        title: '✅ Cập nhật hồ sơ thành công',
        message: 'Hồ sơ của bạn đã được cập nhật: $fieldsText',
        data: {
          'screen': 'profile',
          'action': 'view_profile',
          'updated_fields': updatedFields,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // 🏢 CLUB EVENTS
  // =============================================================================

  /// Thông báo khi user tạo CLB mới (pending approval)
  static Future<void> onClubCreated({
    required String clubId,
    required String ownerId,
    required String clubName,
  }) async {
    try {
      await _notificationService.sendNotification(
        userId: ownerId,
        type: 'club',
        title: '🏢 CLB đã được tạo thành công!',
        message:
            'CLB "$clubName" của bạn đã được tạo và đang chờ quản trị viên xét duyệt. Chúng tôi sẽ thông báo khi CLB được phê duyệt.',
        data: {
          'screen': 'club_detail',
          'club_id': clubId,
          'action': 'view_club',
          'status': 'pending',
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi CLB được admin phê duyệt
  static Future<void> onClubApproved({
    required String clubId,
    required String ownerId,
    required String clubName,
    String? approvedBy,
  }) async {
    try {
      await _notificationService.sendNotification(
        userId: ownerId,
        type: 'club',
        title: '✅ CLB đã được phê duyệt!',
        message:
            'Chúc mừng! CLB "$clubName" của bạn đã được phê duyệt. Giờ đây CLB của bạn đã hiển thị trên hệ thống!',
        data: {
          'screen': 'club_detail',
          'club_id': clubId,
          'action': 'view_club',
          'status': 'approved',
          'approved_by': approvedBy,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi CLB bị từ chối
  static Future<void> onClubRejected({
    required String clubId,
    required String ownerId,
    required String clubName,
    String? reason,
    String? rejectedBy,
  }) async {
    try {
      final reasonText = reason != null ? '\n\nLý do: $reason' : '';

      await _notificationService.sendNotification(
        userId: ownerId,
        type: 'club',
        title: '❌ CLB không được phê duyệt',
        message:
            'Rất tiếc, CLB "$clubName" của bạn chưa được phê duyệt.$reasonText\n\nVui lòng kiểm tra lại thông tin hoặc liên hệ với quản trị viên.',
        data: {
          'screen': 'club_detail',
          'club_id': clubId,
          'action': 'edit_club',
          'status': 'rejected',
          'reason': reason,
          'rejected_by': rejectedBy,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // 👥 MEMBERSHIP EVENTS
  // =============================================================================

  /// Thông báo khi user gửi yêu cầu gia nhập CLB
  static Future<void> onMembershipRequested({
    required String requestId,
    required String clubId,
    required String userId,
    required String userName,
    required List<String> adminIds, // IDs của các admin/owner nhận thông báo
  }) async {
    try {
      // Gửi thông báo cho user
      await _notificationService.sendNotification(
        userId: userId,
        type: 'club',
        title: '📝 Đã gửi yêu cầu gia nhập CLB',
        message:
            'Yêu cầu gia nhập CLB của bạn đã được gửi. Chúng tôi sẽ thông báo khi CLB phản hồi.',
        data: {
          'screen': 'club_detail',
          'club_id': clubId,
          'request_id': requestId,
          'action': 'view_request',
        },
      );

      // Gửi thông báo cho các admin
      for (String adminId in adminIds) {
        await _notificationService.sendNotification(
          userId: adminId,
          type: 'club',
          title: '👤 Yêu cầu gia nhập CLB mới',
          message: '$userName đã gửi yêu cầu gia nhập CLB của bạn.',
          data: {
            'screen': 'member_requests',
            'club_id': clubId,
            'request_id': requestId,
            'user_id': userId,
            'action': 'review_request',
          },
        );
      }

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi yêu cầu gia nhập CLB được chấp nhận
  static Future<void> onMembershipApproved({
    required String requestId,
    required String clubId,
    required String userId,
    required String clubName,
    String? approvedBy,
  }) async {
    try {
      await _notificationService.sendNotification(
        userId: userId,
        type: 'club',
        title: '🎉 Yêu cầu gia nhập CLB được chấp nhận!',
        message: 'Chúc mừng! Bạn đã trở thành thành viên của CLB "$clubName".',
        data: {
          'screen': 'club_detail',
          'club_id': clubId,
          'request_id': requestId,
          'action': 'view_club',
          'approved_by': approvedBy,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi yêu cầu gia nhập CLB bị từ chối
  static Future<void> onMembershipRejected({
    required String requestId,
    required String clubId,
    required String userId,
    required String clubName,
    String? reason,
    String? rejectedBy,
  }) async {
    try {
      final reasonText = reason != null ? '\n\nLý do: $reason' : '';

      await _notificationService.sendNotification(
        userId: userId,
        type: 'club',
        title: '❌ Yêu cầu gia nhập CLB không được chấp nhận',
        message:
            'Rất tiếc, yêu cầu gia nhập CLB "$clubName" của bạn chưa được chấp nhận.$reasonText',
        data: {
          'screen': 'club_detail',
          'club_id': clubId,
          'request_id': requestId,
          'action': 'view_club',
          'reason': reason,
          'rejected_by': rejectedBy,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi user được thêm trực tiếp vào CLB (không qua request)
  static Future<void> onMemberAdded({
    required String clubId,
    required String userId,
    required String clubName,
    String? addedBy,
  }) async {
    try {
      await _notificationService.sendNotification(
        userId: userId,
        type: 'club',
        title: '🎉 Bạn đã được thêm vào CLB!',
        message: 'Bạn đã trở thành thành viên của CLB "$clubName".',
        data: {
          'screen': 'club_detail',
          'club_id': clubId,
          'action': 'view_club',
          'added_by': addedBy,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi user bị xóa khỏi CLB
  static Future<void> onMemberRemoved({
    required String clubId,
    required String userId,
    required String clubName,
    String? reason,
    String? removedBy,
  }) async {
    try {
      final reasonText = reason != null ? '\n\nLý do: $reason' : '';

      await _notificationService.sendNotification(
        userId: userId,
        type: 'club',
        title: '👋 Bạn đã bị xóa khỏi CLB',
        message: 'Bạn không còn là thành viên của CLB "$clubName".$reasonText',
        data: {
          'screen': 'home',
          'club_id': clubId,
          'action': 'view_clubs',
          'reason': reason,
          'removed_by': removedBy,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // 🏆 TOURNAMENT EVENTS (Already partially implemented, but can add more)
  // =============================================================================

  /// Thông báo khi user đăng ký giải đấu
  static Future<void> onTournamentRegistered({
    required String tournamentId,
    required String userId,
    required String tournamentName,
  }) async {
    try {
      await _notificationService.sendNotification(
        userId: userId,
        type: 'tournament',
        title: '✅ Đăng ký giải đấu thành công',
        message: 'Bạn đã đăng ký tham gia giải đấu "$tournamentName".',
        data: {
          'screen': 'tournament_detail',
          'tournament_id': tournamentId,
          'action': 'view_tournament',
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi giải đấu sắp bắt đầu (1 ngày trước)
  static Future<void> onTournamentStartingSoon({
    required String tournamentId,
    required List<String> participantIds,
    required String tournamentName,
    required DateTime startTime,
  }) async {
    try {
      final timeText = _formatDateTime(startTime);

      for (String userId in participantIds) {
        await _notificationService.sendNotification(
          userId: userId,
          type: 'tournament',
          title: '⏰ Giải đấu sắp bắt đầu',
          message:
              'Giải đấu "$tournamentName" sẽ bắt đầu vào $timeText. Hãy chuẩn bị sẵn sàng!',
          data: {
            'screen': 'tournament_detail',
            'tournament_id': tournamentId,
            'action': 'view_tournament',
            'start_time': startTime.toIso8601String(),
          },
        );
      }

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // ⚽ MATCH EVENTS (Already implemented in UniversalMatchProgressionService)
  // =============================================================================

  /// Thông báo khi trận đấu tournament có đủ 2 người chơi và sẵn sàng thi đấu
  static Future<void> onTournamentMatchReady({
    required String matchId,
    required String tournamentId,
    required String player1Id,
    required String player2Id,
    required String tournamentName,
    required String matchName, // e.g., "Vòng 1 - Trận 3" or "Group A - R1M3"
  }) async {
    try {
      // Send notification to both players
      final participantIds = [player1Id, player2Id];
      
      for (String userId in participantIds) {
        await _notificationService.sendNotification(
          userId: userId,
          type: 'tournament_match',
          title: '🏆 Trận đấu tournament đã sẵn sàng!',
          message: 'Đối thủ đã được xác định cho $matchName trong giải "$tournamentName". Hãy chuẩn bị thi đấu!',
          data: {
            'screen': 'tournament_detail',
            'tournament_id': tournamentId,
            'match_id': matchId,
            'action': 'view_tournament_match',
            'opponent_id': participantIds.firstWhere((id) => id != userId),
          },
        );
      }

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi trận đấu sắp bắt đầu
  static Future<void> onMatchStartingSoon({
    required String matchId,
    required List<String> participantIds,
    required String matchName,
    required DateTime startTime,
  }) async {
    try {
      final timeText = _formatDateTime(startTime);

      for (String userId in participantIds) {
        await _notificationService.sendNotification(
          userId: userId,
          type: 'match',
          title: '⏰ Trận đấu sắp bắt đầu',
          message: 'Trận đấu "$matchName" sẽ bắt đầu vào $timeText.',
          data: {
            'screen': 'match_detail',
            'match_id': matchId,
            'action': 'view_match',
            'start_time': startTime.toIso8601String(),
          },
        );
      }

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // 📊 RANK EVENTS
  // =============================================================================

  /// Thông báo khi user lên rank
  static Future<void> onRankUp({
    required String userId,
    required String oldRank,
    required String newRank,
  }) async {
    try {
      await _notificationService.sendNotification(
        userId: userId,
        type: 'rank',
        title: '🎉 Chúc mừng! Bạn đã lên hạng!',
        message: 'Bạn đã thăng từ $oldRank lên $newRank. Tiếp tục phát huy!',
        data: {
          'screen': 'profile',
          'action': 'view_rank',
          'old_rank': oldRank,
          'new_rank': newRank,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi user xuống rank
  static Future<void> onRankDown({
    required String userId,
    required String oldRank,
    required String newRank,
  }) async {
    try {
      await _notificationService.sendNotification(
        userId: userId,
        type: 'rank',
        title: '📉 Hạng của bạn đã giảm',
        message: 'Bạn đã giảm từ $oldRank xuống $newRank. Cố gắng lên nhé!',
        data: {
          'screen': 'profile',
          'action': 'view_rank',
          'old_rank': oldRank,
          'new_rank': newRank,
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // 👥 SOCIAL EVENTS
  // =============================================================================

  /// Thông báo khi có người follow
  static Future<void> onUserFollowed({
    required String userId,
    required String followerId,
    required String followerName,
  }) async {
    try {
      await _notificationService.sendNotification(
        userId: userId,
        type: 'follow',
        title: '👤 Bạn có người theo dõi mới',
        message: '$followerName đã bắt đầu theo dõi bạn.',
        data: {
          'screen': 'user_profile',
          'user_id': followerId,
          'action': 'view_profile',
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // 💬 POST/COMMENT EVENTS
  // =============================================================================

  /// Thông báo khi có người react vào post
  static Future<void> onPostReacted({
    required String postId,
    required String postOwnerId,
    required String reactorId,
    required String reactorName,
    required String reactionType, // 'like', 'love', 'wow', etc.
  }) async {
    try {
      final reactionEmoji = _getReactionEmoji(reactionType);

      await _notificationService.sendNotification(
        userId: postOwnerId,
        type: 'reaction',
        title: '$reactionEmoji Ai đó đã thả cảm xúc vào bài viết',
        message: '$reactorName đã thả $reactionEmoji vào bài viết của bạn.',
        data: {
          'screen': 'post_detail',
          'post_id': postId,
          'reactor_id': reactorId,
          'reaction_type': reactionType,
          'action': 'view_post',
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  /// Thông báo khi có người comment vào post
  static Future<void> onPostCommented({
    required String postId,
    required String postOwnerId,
    required String commenterId,
    required String commenterName,
    required String commentText,
  }) async {
    try {
      final previewText = commentText.length > 50
          ? '${commentText.substring(0, 50)}...'
          : commentText;

      await _notificationService.sendNotification(
        userId: postOwnerId,
        type: 'comment',
        title: '💬 Có bình luận mới',
        message: '$commenterName: $previewText',
        data: {
          'screen': 'post_detail',
          'post_id': postId,
          'commenter_id': commenterId,
          'action': 'view_comments',
        },
      );

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // 🔧 SYSTEM EVENTS
  // =============================================================================

  /// Thông báo bảo trì hệ thống
  static Future<void> onSystemMaintenance({
    required List<String> allUserIds,
    required DateTime maintenanceTime,
    required Duration estimatedDuration,
  }) async {
    try {
      final timeText = _formatDateTime(maintenanceTime);
      final durationText = _formatDuration(estimatedDuration);

      for (String userId in allUserIds) {
        await _notificationService.sendNotification(
          userId: userId,
          type: 'system',
          title: '🔧 Thông báo bảo trì hệ thống',
          message:
              'Hệ thống sẽ bảo trì vào $timeText, dự kiến trong $durationText. Xin lỗi vì sự bất tiện này.',
          data: {
            'screen': 'home',
            'action': 'none',
            'maintenance_time': maintenanceTime.toIso8601String(),
            'estimated_duration': estimatedDuration.inMinutes,
          },
        );
      }

      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    }
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  static String _getRegistrationMethodText(String method) {
    switch (method) {
      case 'email':
        return ' qua email';
      case 'phone':
        return ' qua số điện thoại';
      case 'google':
        return ' qua Google';
      case 'apple':
        return ' qua Apple';
      case 'facebook':
        return ' qua Facebook';
      default:
        return '';
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateText;
    if (date == today) {
      dateText = 'hôm nay';
    } else if (date == tomorrow) {
      dateText = 'ngày mai';
    } else {
      dateText = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$dateText lúc $hour:$minute';
  }

  static String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} giờ';
    } else {
      return '${duration.inMinutes} phút';
    }
  }

  static String _getReactionEmoji(String reactionType) {
    switch (reactionType) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'haha':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return '👍';
    }
  }
}

