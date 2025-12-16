/// DSSnackbar - Design System Snackbar Component
///
/// Instagram/Facebook quality snackbar with:
/// - 4 types (success, error, warning, info)
/// - Action button
/// - Custom duration
/// - Dismiss callback
/// - Icon support
///
/// Usage:
/// ```dart
/// DSSnackbar.success(
///   context: context,
///   message: 'Post published!',
/// )
/// ```

import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Snackbar types
enum DSSnackbarType {
  /// Success message
  success,

  /// Error message
  error,

  /// Warning message
  warning,

  /// Info message
  info,

  /// Default message
  neutral,
}

/// Design System Snackbar
class DSSnackbar {
  /// Show snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show({
    required BuildContext context,
    required String message,
    DSSnackbarType type = DSSnackbarType.neutral,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    bool showCloseButton = false,
    IconData? icon,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    // Clear any existing snackbars
    messenger.clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null || _getIcon(type) != null) ...[
            Icon(
              icon ?? _getIcon(type),
              color: AppColors.surface,
              size: DesignTokens.iconMD,
            ),
            SizedBox(width: DesignTokens.space12),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _getColor(type),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.radius(DesignTokens.radiusSM),
      ),
      margin: DesignTokens.all(DesignTokens.space16),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.surface,
              onPressed: onActionPressed ?? () {},
            )
          : showCloseButton
          ? SnackBarAction(
              label: '',
              textColor: AppColors.surface,
              onPressed: () => messenger.hideCurrentSnackBar(),
            )
          : null,
    );

    return messenger.showSnackBar(snackBar);
  }

  /// Show success snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> success({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    return show(
      context: context,
      message: message,
      type: DSSnackbarType.success,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  /// Show error snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> error({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 5),
  }) {
    return show(
      context: context,
      message: message,
      type: DSSnackbarType.error,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  /// Show warning snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> warning({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    return show(
      context: context,
      message: message,
      type: DSSnackbarType.warning,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  /// Show info snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> info({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    return show(
      context: context,
      message: message,
      type: DSSnackbarType.info,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  static Color _getColor(DSSnackbarType type) {
    switch (type) {
      case DSSnackbarType.success:
        return AppColors.success;
      case DSSnackbarType.error:
        return AppColors.error;
      case DSSnackbarType.warning:
        return AppColors.warning;
      case DSSnackbarType.info:
        return AppColors.info;
      case DSSnackbarType.neutral:
        return AppColors.textPrimary;
    }
  }

  static IconData? _getIcon(DSSnackbarType type) {
    switch (type) {
      case DSSnackbarType.success:
        return Icons.check_circle;
      case DSSnackbarType.error:
        return Icons.error;
      case DSSnackbarType.warning:
        return Icons.warning;
      case DSSnackbarType.info:
        return Icons.info;
      case DSSnackbarType.neutral:
        return null;
    }
  }
}
