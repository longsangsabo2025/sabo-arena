import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Notification Badge Widget with Real-time Unread Count
///
/// Displays a red badge with unread notification count on top of the notification icon.
/// Uses StreamBuilder for real-time updates via Supabase Realtime.
class NotificationBadge extends StatelessWidget {
  final Widget child;

  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.instance.unreadCountStream,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count == 0) {
          return child;
        }

        return Badge(
          label: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          textColor: Colors.white,
          child: child,
        );
      },
    );
  }
}
