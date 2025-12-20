import 'package:flutter/material.dart';

/// 🎯 **AppSnackbar** - Unified Snackbar Service
///
/// **Purpose**: Replace 100+ inconsistent ScaffoldMessenger.showSnackBar implementations
/// with a single, consistent, and accessible snackbar service across the entire app.
///
/// **Features**:
/// - 4 snackbar types: success, error, warning, info
/// - Consistent icons and colors
/// - Optional action button
/// - Customizable duration
/// - Automatic icon based on type
/// - Consistent styling and animations
///
/// **Usage**:
/// ```dart
/// // Success message
/// AppSnackbar.success(
///   context: context,
///   message: 'Cập nhật thành công!',
/// );
///
/// // Error message
/// AppSnackbar.error(
///   context: context,
///   message: 'Không thể tải dữ liệu',
/// );
///
/// // Warning with action
/// AppSnackbar.warning(
///   context: context,
///   message: 'Kết nối không ổn định',
///   actionLabel: 'Thử lại',
///   onActionPressed: () => retry(),
/// );
///
/// // Info message (short duration)
/// AppSnackbar.info(
///   context: context,
///   message: 'Đang xử lý...',
///   duration: Duration(seconds: 2),
/// );
/// ```

enum AppSnackbarType {
  success,
  error,
  warning,
  info,
}

class AppSnackbar {
  // 🎨 Static color configurations
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _warningColor = Color(0xFFFFA726);
  static const Color _infoColor = Color(0xFF1976D2);

  // ✅ Success Snackbar
  static void success({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      type: AppSnackbarType.success,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  // ❌ Error Snackbar
  static void error({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      message: message,
      type: AppSnackbarType.error,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  // ⚠️ Warning Snackbar
  static void warning({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      type: AppSnackbarType.warning,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  // ℹ️ Info Snackbar
  static void info({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      type: AppSnackbarType.info,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  // 🎯 Core show method (private)
  static void _show({
    required BuildContext context,
    required String message,
    required AppSnackbarType type,
    String? actionLabel,
    VoidCallback? onActionPressed,
    required Duration duration,
  }) {
    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Icon
            Icon(
              _getIcon(type),
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            // Message
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _getColor(type),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        action: (actionLabel != null && onActionPressed != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed,
              )
            : null,
      ),
    );
  }

  // 🎨 Get color based on type
  static Color _getColor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return _successColor;
      case AppSnackbarType.error:
        return _errorColor;
      case AppSnackbarType.warning:
        return _warningColor;
      case AppSnackbarType.info:
        return _infoColor;
    }
  }

  // 🎯 Get icon based on type
  static IconData _getIcon(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_outline;
      case AppSnackbarType.error:
        return Icons.error_outline;
      case AppSnackbarType.warning:
        return Icons.warning_amber_outlined;
      case AppSnackbarType.info:
        return Icons.info_outline;
    }
  }

  // 🔧 Custom Snackbar (for advanced use cases)
  static void custom({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
    Color? textColor,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? _infoColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        action: (actionLabel != null && onActionPressed != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: textColor ?? Colors.white,
                onPressed: onActionPressed,
              )
            : null,
      ),
    );
  }
}

/// 🎯 **AppSnackbarHelper** - Extension methods for easier access
///
/// **Usage**:
/// ```dart
/// context.showSuccess('Cập nhật thành công!');
/// context.showError('Có lỗi xảy ra');
/// context.showWarning('Cảnh báo');
/// context.showInfo('Thông tin');
/// ```
extension AppSnackbarExtension on BuildContext {
  void showSuccess(String message,
      {String? actionLabel, VoidCallback? onActionPressed}) {
    AppSnackbar.success(
      context: this,
      message: message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  void showError(String message,
      {String? actionLabel, VoidCallback? onActionPressed}) {
    AppSnackbar.error(
      context: this,
      message: message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  void showWarning(String message,
      {String? actionLabel, VoidCallback? onActionPressed}) {
    AppSnackbar.warning(
      context: this,
      message: message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  void showInfo(String message,
      {String? actionLabel, VoidCallback? onActionPressed}) {
    AppSnackbar.info(
      context: this,
      message: message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }
}
