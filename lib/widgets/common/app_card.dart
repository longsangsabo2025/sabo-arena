/// App Card Widget
///
/// Standardized card component with consistent styling
/// Supports tap interactions, custom padding, and elevation levels
/// iOS Support: Automatically applies iOS-style (16px radius, subtle shadow) on iOS devices

import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/design_system.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double? borderRadius;
  final List<BoxShadow>? elevation;
  final Border? border;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius,
    this.elevation,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && Platform.isIOS;
    final defaultRadius =
        isIOS ? 16.0 : AppRadius.card; // iOS: 16px, Android: 12px
    final cardRadius = borderRadius ?? defaultRadius;

    // iOS: subtle shadow, Android: Material elevation
    final cardShadow = elevation ??
        (isIOS
            ? [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: 0.05), // Subtle iOS shadow
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  // No spread radius (iOS style)
                ),
              ]
            : AppElevation.level2);

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: cardShadow,
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(cardRadius),
          child: Padding(
            padding: padding ?? EdgeInsets.all(AppSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Compact Card variant for list items
class AppCardCompact extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AppCardCompact({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.md),
      elevation: AppElevation.level1,
      onTap: onTap,
      child: child,
    );
  }
}

/// Elevated Card variant for prominent content
class AppCardElevated extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AppCardElevated({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(elevation: AppElevation.level4, onTap: onTap, child: child);
  }
}

/// Outlined Card variant with border
class AppCardOutlined extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCardOutlined({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: AppElevation.none,
      border: Border.all(color: borderColor ?? AppColors.border, width: 1.5),
      onTap: onTap,
      child: child,
    );
  }
}
