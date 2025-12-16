/// App Card Widget
///
/// Standardized card component with consistent styling
/// Supports tap interactions, custom padding, and elevation levels

import 'package:flutter/material.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
        boxShadow: elevation ?? AppElevation.level2,
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.card),
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
