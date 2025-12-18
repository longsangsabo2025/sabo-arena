/// DSRadio - Design System Radio Button Component
///
/// Instagram/Facebook quality radio button with:
/// - Custom colors
/// - Smooth animation
/// - Disabled state
/// - Label support
/// - Haptic feedback
///
/// Usage:
/// ```dart
/// DSRadio<String>(
///   value: 'option1',
///   groupValue: selectedOption,
///   onChanged: (value) => setState(() => selectedOption = value),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';
import '../app_colors.dart';
import '../typography.dart';

/// Design System Radio Button Component
class DSRadio<T> extends StatelessWidget {
  /// Value represented by this radio
  final T value;

  /// Currently selected value in group
  final T? groupValue;

  /// Change callback
  final void Function(T?)? onChanged;

  /// Active color (when selected)
  final Color? activeColor;

  /// Enable haptic feedback
  final bool enableHaptic;

  const DSRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.activeColor,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: (newValue) {
        if (onChanged != null) {
          if (enableHaptic) {
            HapticFeedback.lightImpact();
          }
          onChanged!(newValue);
        }
      },
      child: Radio<T>(
        value: value,
        activeColor: activeColor ?? AppColors.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Radio button with label
class DSRadioTile<T> extends StatelessWidget {
  /// Value represented by this radio
  final T value;

  /// Currently selected value in group
  final T? groupValue;

  /// Change callback
  final void Function(T?)? onChanged;

  /// Title text
  final String title;

  /// Subtitle text (optional)
  final String? subtitle;

  /// Leading icon (optional)
  final IconData? leadingIcon;

  /// Active color
  final Color? activeColor;

  /// Content padding
  final EdgeInsetsGeometry? contentPadding;

  /// Enable haptic feedback
  final bool enableHaptic;

  /// Control affinity (where radio is placed)
  final ListTileControlAffinity controlAffinity;

  const DSRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.activeColor,
    this.contentPadding,
    this.enableHaptic = true,
    this.controlAffinity = ListTileControlAffinity.leading,
  });

  bool get isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null
            ? () {
                if (enableHaptic) {
                  HapticFeedback.lightImpact();
                }
                onChanged?.call(value);
              }
            : null,
        child: Padding(
          padding:
              contentPadding ??
              EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space12,
              ),
          child: Row(
            children: [
              // Radio on left
              if (controlAffinity == ListTileControlAffinity.leading) ...[
                DSRadio<T>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: activeColor,
                  enableHaptic: false, // Handled by InkWell
                ),
                SizedBox(width: DesignTokens.space12),
              ],

              // Leading icon
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 24,
                  color: isSelected
                      ? (activeColor ?? AppColors.primary)
                      : AppColors.textSecondary,
                ),
                SizedBox(width: DesignTokens.space12),
              ],

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: DesignTokens.space4),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Radio on right
              if (controlAffinity == ListTileControlAffinity.trailing) ...[
                SizedBox(width: DesignTokens.space12),
                DSRadio<T>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: activeColor,
                  enableHaptic: false, // Handled by InkWell
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact radio list item
class DSRadioListTile<T> extends StatelessWidget {
  /// Value represented by this radio
  final T value;

  /// Currently selected value in group
  final T? groupValue;

  /// Change callback
  final void Function(T?)? onChanged;

  /// Title text
  final String title;

  /// Subtitle text
  final String? subtitle;

  /// Leading widget
  final Widget? secondary;

  /// Control affinity
  final ListTileControlAffinity controlAffinity;

  /// Dense layout
  final bool dense;

  const DSRadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.secondary,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: (val) => onChanged?.call(val),
      child: RadioListTile<T>(
        value: value,
        title: Text(title, style: AppTypography.bodyMedium),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        secondary: secondary,
        controlAffinity: controlAffinity,
        dense: dense,
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: dense ? 0 : DesignTokens.space4,
        ),
      ),
    );
  }
}

/// Radio group for single selection
class DSRadioGroup<T> extends StatelessWidget {
  /// List of options
  final List<DSRadioOption<T>> options;

  /// Currently selected value
  final T? selectedValue;

  /// Selection change callback
  final void Function(T?) onChanged;

  /// Spacing between radios
  final double spacing;

  /// Enable dividers
  final bool showDividers;

  /// Control affinity
  final ListTileControlAffinity controlAffinity;

  const DSRadioGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.spacing = 0,
    this.showDividers = false,
    this.controlAffinity = ListTileControlAffinity.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];

        return Column(
          children: [
            DSRadioTile<T>(
              value: option.value,
              groupValue: selectedValue,
              onChanged: onChanged,
              title: option.title,
              subtitle: option.subtitle,
              leadingIcon: option.leadingIcon,
              controlAffinity: controlAffinity,
            ),
            if (spacing > 0) SizedBox(height: spacing),
            if (showDividers && index < options.length - 1)
              const Divider(height: 1),
          ],
        );
      }),
    );
  }
}

/// Radio option data class
class DSRadioOption<T> {
  /// Option value
  final T value;

  /// Option title
  final String title;

  /// Option subtitle
  final String? subtitle;

  /// Option leading icon
  final IconData? leadingIcon;

  const DSRadioOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leadingIcon,
  });
}

/// Horizontal radio group (chip-like)
class DSRadioChipGroup<T> extends StatelessWidget {
  /// List of options
  final List<DSRadioOption<T>> options;

  /// Currently selected value
  final T? selectedValue;

  /// Selection change callback
  final void Function(T?) onChanged;

  /// Spacing between chips
  final double spacing;

  /// Scroll direction
  final Axis scrollDirection;

  const DSRadioChipGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.spacing = DesignTokens.space8,
    this.scrollDirection = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final chips = options.map((option) {
      final isSelected = option.value == selectedValue;

      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(option.value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space16,
            vertical: DesignTokens.space8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.gray100,
            borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.leadingIcon != null) ...[
                Icon(
                  option.leadingIcon,
                  size: 16,
                  color: isSelected ? AppColors.surface : AppColors.textPrimary,
                ),
                SizedBox(width: DesignTokens.space4),
              ],
              Text(
                option.title,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

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

    return Wrap(spacing: spacing, runSpacing: spacing, children: chips);
  }
}
