/// DSDialog - Design System Dialog Component
///
/// Instagram/Facebook quality dialog with:
/// - Title and content
/// - Action buttons
/// - Custom width
/// - Dismissible options
/// - Confirmation dialogs
///
/// Usage:
/// ```dart
/// DSDialog.show(
///   context: context,
///   title: 'Delete Post',
///   content: 'Are you sure?',
///   actions: [confirmButton, cancelButton],
/// )
/// ```

import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../app_colors.dart';
import 'ds_button.dart';

/// Design System Dialog
class DSDialog {
  /// Show dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    String? content,
    Widget? contentWidget,
    List<Widget>? actions,
    bool isDismissible = true,
    double? width,
    EdgeInsetsGeometry? contentPadding,
    Color? backgroundColor,
    double? borderRadius,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: width ?? 320,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            borderRadius: DesignTokens.radius(
              borderRadius ?? DesignTokens.radiusLG,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null || titleWidget != null) ...[
                Padding(
                  padding: DesignTokens.only(
                    left: DesignTokens.space24,
                    right: DesignTokens.space24,
                    top: DesignTokens.space24,
                    bottom: DesignTokens.space12,
                  ),
                  child: titleWidget ??
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                ),
              ],
              if (content != null || contentWidget != null) ...[
                Padding(
                  padding: contentPadding ??
                      DesignTokens.only(
                        left: DesignTokens.space24,
                        right: DesignTokens.space24,
                        top: DesignTokens.space8,
                        bottom: DesignTokens.space24,
                      ),
                  child: contentWidget ??
                      Text(
                        content!,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                ),
              ],
              if (actions != null && actions.isNotEmpty) ...[
                Padding(
                  padding: DesignTokens.only(
                    left: DesignTokens.space16,
                    right: DesignTokens.space16,
                    bottom: DesignTokens.space16,
                  ),
                  child: actions.length == 1
                      ? actions.first
                      : Row(
                          children: actions
                              .map(
                                (action) => Expanded(
                                  child: Padding(
                                    padding: DesignTokens.only(
                                      left: DesignTokens.space4,
                                      right: DesignTokens.space4,
                                    ),
                                    child: action,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDismissible = true,
    bool isDestructive = false,
  }) async {
    final result = await show<bool>(
      context: context,
      title: title,
      content: content,
      isDismissible: isDismissible,
      actions: [
        DSButton(
          text: cancelText,
          variant: DSButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DSButton(
          text: confirmText,
          variant: DSButtonVariant.primary,
          backgroundColor: isDestructive ? AppColors.error : null,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    return result ?? false;
  }

  /// Show alert dialog
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'OK',
    bool isDismissible = true,
  }) {
    return show(
      context: context,
      title: title,
      content: content,
      isDismissible: isDismissible,
      actions: [
        DSButton(
          text: buttonText,
          variant: DSButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: true,
        ),
      ],
    );
  }

  /// Show loading dialog
  static void showLoading({required BuildContext context, String? message}) {
    show(
      context: context,
      isDismissible: false,
      contentWidget: Padding(
        padding: DesignTokens.all(DesignTokens.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              SizedBox(height: DesignTokens.space16),
              Text(
                message,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
