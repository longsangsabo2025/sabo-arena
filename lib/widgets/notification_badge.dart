import 'package:flutter/material.dart';
import '../services/notification_service.dart';

enum NotificationContext {
  user,
  club,
}

/// Notification Badge Widget with Real-time Unread Count
///
/// Displays a red badge with unread notification count on top of the notification icon.
/// Uses StreamBuilder for real-time updates via Supabase Realtime.
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final NotificationContext contextType;

  const NotificationBadge({
    super.key,
    required this.child,
    this.contextType = NotificationContext.user,
  });

  @override
  Widget build(BuildContext context) {
    final stream = contextType == NotificationContext.club
        ? NotificationService.instance.clubUnreadCountStream
        : NotificationService.instance.unreadCountStream;

    return StreamBuilder<int>(
      stream: stream,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count == 0) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
