/// DSEmptyState - Design System Empty State Component
///
/// Instagram/Facebook quality empty state with:
/// - Icon or illustration
/// - Title and description
/// - Optional action button
/// - Custom styling
///
/// Usage:
/// ```dart
/// DSEmptyState(
///   icon: Icons.inbox,
///   title: 'No Messages',
///   description: 'Start a conversation',
///   actionButton: DSButton(...),
/// )
/// ```

import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Design System Empty State Component
class DSEmptyState extends StatelessWidget {
  /// Icon to display
  final IconData? icon;

  /// Custom icon widget (overrides icon)
  final Widget? iconWidget;

  /// Title text
  final String title;

  /// Description text
  final String? description;

  /// Action button
  final Widget? actionButton;

  /// Icon size
  final double? iconSize;

  /// Icon color
  final Color? iconColor;

  /// Title color
  final Color? titleColor;

  /// Description color
  final Color? descriptionColor;

  /// Padding
  final EdgeInsetsGeometry? padding;

  /// Max width
  final double? maxWidth;

  const DSEmptyState({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.description,
    this.actionButton,
    this.iconSize,
    this.iconColor,
    this.titleColor,
    this.descriptionColor,
    this.padding,
    this.maxWidth,
  });

  /// Empty inbox state
  factory DSEmptyState.inbox({
    String? title,
    String? description,
    Widget? actionButton,
  }) {
    return DSEmptyState(
      icon: Icons.inbox,
      title: title ?? 'No Messages',
      description: description ?? 'Your inbox is empty',
      actionButton: actionButton,
    );
  }

  /// Empty search results state
  factory DSEmptyState.search({
    String? title,
    String? description,
    Widget? actionButton,
  }) {
    return DSEmptyState(
      icon: Icons.search_off,
      title: title ?? 'No Results Found',
      description: description ?? 'Try different keywords',
      actionButton: actionButton,
    );
  }

  /// Empty notifications state
  factory DSEmptyState.notifications({
    String? title,
    String? description,
    Widget? actionButton,
  }) {
    return DSEmptyState(
      icon: Icons.notifications_none,
      title: title ?? 'No Notifications',
      description: description ?? 'You\'re all caught up',
      actionButton: actionButton,
    );
  }

  /// Empty favorites state
  factory DSEmptyState.favorites({
    String? title,
    String? description,
    Widget? actionButton,
  }) {
    return DSEmptyState(
      icon: Icons.favorite_border,
      title: title ?? 'No Favorites',
      description: description ?? 'Save your favorites here',
      actionButton: actionButton,
    );
  }

  /// Network error state
  factory DSEmptyState.networkError({
    String? title,
    String? description,
    Widget? actionButton,
  }) {
    return DSEmptyState(
      icon: Icons.wifi_off,
      title: title ?? 'No Connection',
      description: description ?? 'Check your internet connection',
      iconColor: AppColors.error,
      actionButton: actionButton,
    );
  }

  /// Server error state
  factory DSEmptyState.serverError({
    String? title,
    String? description,
    Widget? actionButton,
  }) {
    return DSEmptyState(
      icon: Icons.cloud_off,
      title: title ?? 'Something Went Wrong',
      description: description ?? 'Please try again later',
      iconColor: AppColors.error,
      actionButton: actionButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: maxWidth != null
            ? BoxConstraints(maxWidth: maxWidth!)
            : const BoxConstraints(maxWidth: 400),
        padding:
            padding ??
            DesignTokens.only(
              left: DesignTokens.space32,
              right: DesignTokens.space32,
              top: DesignTokens.space48,
              bottom: DesignTokens.space48,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            if (iconWidget != null)
              iconWidget!
            else if (icon != null)
              Container(
                width: iconSize ?? 80,
                height: iconSize ?? 80,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.textSecondary).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: (iconSize ?? 80) * 0.5,
                  color: iconColor ?? AppColors.textSecondary,
                ),
              ),

            SizedBox(height: DesignTokens.space24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null) ...[
              SizedBox(height: DesignTokens.space12),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 15,
                  color: descriptionColor ?? AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action Button
            if (actionButton != null) ...[
              SizedBox(height: DesignTokens.space24),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for lists
class DSListEmptyState extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Message text
  final String message;

  /// Action button
  final Widget? actionButton;

  const DSListEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DesignTokens.all(DesignTokens.space32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          SizedBox(height: DesignTokens.space16),
          Text(
            message,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionButton != null) ...[
            SizedBox(height: DesignTokens.space16),
            actionButton!,
          ],
        ],
      ),
    );
  }
}
