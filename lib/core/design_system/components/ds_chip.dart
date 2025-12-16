/// DSChip - Design System Chip Component
///
/// Instagram/Facebook quality chip with:
/// - 3 variants (filled, outlined, tonal)
/// - 3 sizes (small, medium, large)
/// - Optional leading/trailing icons
/// - Delete button support
/// - Selected state
/// - Tap callback
///
/// Usage:
/// ```dart
/// DSChip(
///   label: 'Flutter',
///   onTap: () => filterByTag('Flutter'),
///   leadingIcon: AppIcons.tag,
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';
import '../app_colors.dart';
import '../app_icons.dart';

/// Chip variants
enum DSChipVariant {
  /// Filled background with primary color
  filled,

  /// Outlined with border
  outlined,

  /// Tonal background (subtle)
  tonal,
}

/// Chip sizes
enum DSChipSize {
  /// Small chip (24px height)
  small,

  /// Medium chip (32px height) - default
  medium,

  /// Large chip (40px height)
  large,
}

/// Design System Chip Component
class DSChip extends StatelessWidget {
  /// Chip label text
  final String label;

  /// Tap callback
  final VoidCallback? onTap;

  /// Delete callback (shows delete button)
  final VoidCallback? onDelete;

  /// Chip variant
  final DSChipVariant variant;

  /// Chip size
  final DSChipSize size;

  /// Leading icon
  final IconData? leadingIcon;

  /// Trailing icon (ignored if onDelete is provided)
  final IconData? trailingIcon;

  /// Selected state
  final bool isSelected;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom text color
  final Color? textColor;

  /// Custom border color
  final Color? borderColor;

  /// Enable haptic feedback
  final bool enableHaptic;

  /// Avatar widget (overrides leadingIcon)
  final Widget? avatar;

  const DSChip({
    super.key,
    required this.label,
    this.onTap,
    this.onDelete,
    this.variant = DSChipVariant.filled,
    this.size = DSChipSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.enableHaptic = true,
    this.avatar,
  });

  /// Filled chip factory
  factory DSChip.filled({
    required String label,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    DSChipSize size = DSChipSize.medium,
    IconData? leadingIcon,
    bool isSelected = false,
  }) {
    return DSChip(
      label: label,
      onTap: onTap,
      onDelete: onDelete,
      variant: DSChipVariant.filled,
      size: size,
      leadingIcon: leadingIcon,
      isSelected: isSelected,
    );
  }

  /// Outlined chip factory
  factory DSChip.outlined({
    required String label,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    DSChipSize size = DSChipSize.medium,
    IconData? leadingIcon,
    bool isSelected = false,
  }) {
    return DSChip(
      label: label,
      onTap: onTap,
      onDelete: onDelete,
      variant: DSChipVariant.outlined,
      size: size,
      leadingIcon: leadingIcon,
      isSelected: isSelected,
    );
  }

  /// Tonal chip factory
  factory DSChip.tonal({
    required String label,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    DSChipSize size = DSChipSize.medium,
    IconData? leadingIcon,
    bool isSelected = false,
  }) {
    return DSChip(
      label: label,
      onTap: onTap,
      onDelete: onDelete,
      variant: DSChipVariant.tonal,
      size: size,
      leadingIcon: leadingIcon,
      isSelected: isSelected,
    );
  }

  /// Filter chip factory (with selection)
  factory DSChip.filter({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    DSChipSize size = DSChipSize.medium,
    IconData? leadingIcon,
  }) {
    return DSChip(
      label: label,
      onTap: onTap,
      variant: DSChipVariant.outlined,
      size: size,
      leadingIcon: leadingIcon,
      isSelected: isSelected,
    );
  }

  /// Choice chip factory (radio-like)
  factory DSChip.choice({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    DSChipSize size = DSChipSize.medium,
  }) {
    return DSChip(
      label: label,
      onTap: onTap,
      variant: DSChipVariant.tonal,
      size: size,
      isSelected: isSelected,
    );
  }

  /// Input chip factory (with delete)
  factory DSChip.input({
    required String label,
    required VoidCallback onDelete,
    DSChipSize size = DSChipSize.medium,
    IconData? leadingIcon,
    Widget? avatar,
  }) {
    return DSChip(
      label: label,
      onDelete: onDelete,
      variant: DSChipVariant.filled,
      size: size,
      leadingIcon: leadingIcon,
      avatar: avatar,
    );
  }

  double get _height {
    switch (size) {
      case DSChipSize.small:
        return 24;
      case DSChipSize.medium:
        return 32;
      case DSChipSize.large:
        return 40;
    }
  }

  double get _fontSize {
    switch (size) {
      case DSChipSize.small:
        return 12;
      case DSChipSize.medium:
        return 13;
      case DSChipSize.large:
        return 14;
    }
  }

  double get _iconSize {
    switch (size) {
      case DSChipSize.small:
        return 14;
      case DSChipSize.medium:
        return 16;
      case DSChipSize.large:
        return 18;
    }
  }

  double get _horizontalPadding {
    switch (size) {
      case DSChipSize.small:
        return DesignTokens.space8;
      case DSChipSize.medium:
        return DesignTokens.space12;
      case DSChipSize.large:
        return DesignTokens.space16;
    }
  }

  Color get _backgroundColor {
    if (backgroundColor != null) return backgroundColor!;

    if (isSelected) {
      return variant == DSChipVariant.outlined
          ? AppColors.primary100
          : AppColors.primary;
    }

    switch (variant) {
      case DSChipVariant.filled:
        return AppColors.gray200;
      case DSChipVariant.outlined:
        return Colors.transparent;
      case DSChipVariant.tonal:
        return AppColors.gray100;
    }
  }

  Color get _textColor {
    if (textColor != null) return textColor!;

    if (isSelected) {
      return variant == DSChipVariant.outlined
          ? AppColors.primary
          : AppColors.surface;
    }

    switch (variant) {
      case DSChipVariant.filled:
        return AppColors.textPrimary;
      case DSChipVariant.outlined:
        return AppColors.textPrimary;
      case DSChipVariant.tonal:
        return AppColors.textPrimary;
    }
  }

  Color? get _borderColor {
    if (variant != DSChipVariant.outlined) return null;

    if (borderColor != null) return borderColor;

    return isSelected ? AppColors.primary : AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = onTap != null || onDelete != null;

    Widget chip = Container(
      height: _height,
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: _borderColor != null
            ? Border.all(color: _borderColor!, width: 1)
            : null,
        borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
      ),
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Leading avatar or icon
          if (avatar != null) ...[
            avatar!,
            SizedBox(width: DesignTokens.space4),
          ] else if (leadingIcon != null) ...[
            Icon(leadingIcon, size: _iconSize, color: _textColor),
            SizedBox(width: DesignTokens.space4),
          ],

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
              color: _textColor,
              height: 1,
            ),
          ),

          // Trailing icon or delete button
          if (onDelete != null) ...[
            SizedBox(width: DesignTokens.space4),
            GestureDetector(
              onTap: () {
                if (enableHaptic) {
                  HapticFeedback.lightImpact();
                }
                onDelete?.call();
              },
              child: Icon(
                AppIcons.close,
                size: _iconSize,
                color: _textColor.withValues(alpha: 0.7),
              ),
            ),
          ] else if (trailingIcon != null) ...[
            SizedBox(width: DesignTokens.space4),
            Icon(trailingIcon, size: _iconSize, color: _textColor),
          ],
        ],
      ),
    );

    if (hasAction) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
          onTapDown: enableHaptic ? (_) => HapticFeedback.lightImpact() : null,
          child: chip,
        ),
      );
    }

    return chip;
  }
}

/// Chip group for multiple chips
class DSChipGroup extends StatelessWidget {
  /// List of chips
  final List<Widget> chips;

  /// Spacing between chips
  final double spacing;

  /// Run spacing (vertical spacing between rows)
  final double runSpacing;

  /// Alignment
  final WrapAlignment alignment;

  /// Scroll direction (if scrollable)
  final Axis? scrollDirection;

  const DSChipGroup({
    super.key,
    required this.chips,
    this.spacing = DesignTokens.space8,
    this.runSpacing = DesignTokens.space8,
    this.alignment = WrapAlignment.start,
    this.scrollDirection,
  });

  /// Horizontal scrollable chip group
  factory DSChipGroup.horizontal({
    required List<Widget> chips,
    double spacing = DesignTokens.space8,
  }) {
    return DSChipGroup(
      chips: chips,
      spacing: spacing,
      scrollDirection: Axis.horizontal,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (scrollDirection == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              chips[i],
              if (i < chips.length - 1) SizedBox(width: spacing),
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: chips,
    );
  }
}
