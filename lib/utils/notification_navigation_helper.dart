import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

/// Helper để navigate tới notification list screen
/// Dùng cho các AppBar muốn hiển thị notification badge
class NotificationNavigationHelper {
  static void navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.notificationListScreen);
  }
}
