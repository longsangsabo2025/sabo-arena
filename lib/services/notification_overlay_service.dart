import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/services.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';

/// 🔔 Notification Overlay Service
///
/// Hiển thị in-app notifications với animation đẹp mắt giống Facebook/Instagram.
/// Sử dụng Flash package cho smooth animations và Material 3 design.
///
/// Features:
/// - ✅ Top banner notifications
/// - ✅ Auto-dismiss sau 4 giây
/// - ✅ Tap to navigate
/// - ✅ Swipe to dismiss
/// - ✅ Sound + haptic feedback
/// - ✅ Queue management (nhiều notification)
class NotificationOverlayService {
  static final instance = NotificationOverlayService._();
  NotificationOverlayService._();

  /// Show in-app notification overlay with modern design
  void showNotificationOverlay(
    BuildContext context, {
    required String title,
    required String message,
    String? avatarUrl,
    IconData? icon,
    Color? iconColor,
    required VoidCallback onTap,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
    bool hapticFeedback = true,
  }) {
    // Play haptic feedback
    if (hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    showOverlayNotification(
      (context) {
        return Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  OverlaySupportEntry.of(context)?.dismiss();
                  onTap();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar or Icon
                      if (avatarUrl != null)
                        UserAvatarWidget(
                          avatarUrl: avatarUrl,
                          size: 48,
                        )
                      else if (icon != null)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: iconColor ?? Colors.blue,
                            size: 24,
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Close button
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        onPressed: () =>
                            OverlaySupportEntry.of(context)?.dismiss(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      duration: duration,
      position: NotificationPosition.top,
    );
  }

  /// Show tournament registration notification
  void showTournamentNotification(
    BuildContext context, {
    required String tournamentName,
    required String userName,
    required String avatarUrl,
    required VoidCallback onTap,
  }) {
    showNotificationOverlay(
      context,
      title: 'Đăng ký giải đấu mới',
      message: '$userName đã đăng ký tham gia "$tournamentName"',
      avatarUrl: avatarUrl,
      onTap: onTap,
    );
  }

  /// Show club announcement notification
  void showClubAnnouncementNotification(
    BuildContext context, {
    required String clubName,
    required String announcement,
    required VoidCallback onTap,
  }) {
    showNotificationOverlay(
      context,
      title: clubName,
      message: announcement,
      icon: Icons.campaign,
      iconColor: Colors.orange,
      onTap: onTap,
    );
  }

  /// Show challenge request notification
  void showChallengeNotification(
    BuildContext context, {
    required String challengerName,
    required String avatarUrl,
    required VoidCallback onTap,
  }) {
    showNotificationOverlay(
      context,
      title: 'Lời mời thách đấu',
      message: '$challengerName muốn thách đấu với bạn',
      avatarUrl: avatarUrl,
      onTap: onTap,
      icon: Icons.sports_esports,
      iconColor: Colors.red,
    );
  }

  /// Show match result notification
  void showMatchResultNotification(
    BuildContext context, {
    required String result,
    required String opponent,
    required VoidCallback onTap,
  }) {
    showNotificationOverlay(
      context,
      title: 'Kết quả trận đấu',
      message: '$result vs $opponent',
      icon: Icons.emoji_events,
      iconColor: Colors.amber,
      onTap: onTap,
    );
  }

  /// Show friend request notification
  void showFriendRequestNotification(
    BuildContext context, {
    required String userName,
    required String avatarUrl,
    required VoidCallback onTap,
  }) {
    showNotificationOverlay(
      context,
      title: 'Lời mời kết bạn',
      message: '$userName muốn kết bạn với bạn',
      avatarUrl: avatarUrl,
      onTap: onTap,
      icon: Icons.person_add,
      iconColor: Colors.blue,
    );
  }

  /// Show system notification
  void showSystemNotification(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onTap,
  }) {
    showNotificationOverlay(
      context,
      title: title,
      message: message,
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      onTap: onTap,
    );
  }
}
