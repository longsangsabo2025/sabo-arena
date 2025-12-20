/// DSCheckbox - Design System Checkbox Component
///
/// Instagram/Facebook quality checkbox with:
/// - Custom colors
/// - Smooth animation
/// - Disabled state
/// - Indeterminate state
/// - Label support
/// - Haptic feedback
///
/// Usage:
/// ```dart
/// DSCheckbox(
///   value: isChecked,
///   onChanged: (value) => setState(() => isChecked = value ?? false),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';
import '../app_colors.dart';
import '../typography.dart';

/// Design System Checkbox Component
class DSCheckbox extends StatelessWidget {
  /// Current value
  final bool? value;

  /// Change callback
  final void Function(bool?)? onChanged;

  /// Active color (when checked)
  final Color? activeColor;

  /// Check color
  final Color? checkColor;

  /// Enable haptic feedback
  final bool enableHaptic;

  /// Tristate (allows null value)
  final bool tristate;

  const DSCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.checkColor,
    this.enableHaptic = true,
    this.tristate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged != null
          ? (newValue) {
              if (enableHaptic) {
                HapticFeedback.lightImpact();
              }
              onChanged?.call(newValue);
            }
          : null,
      activeColor: activeColor ?? AppColors.primary,
      checkColor: checkColor ?? AppColors.surface,
      tristate: tristate,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: DesignTokens.radius(4)),
    );
  }
}

/// Checkbox with label
class DSCheckboxTile extends StatelessWidget {
  /// Title text
  final String title;

  /// Subtitle text (optional)
  final String? subtitle;

  /// Current value
  final bool? value;

  /// Change callback
  final void Function(bool?)? onChanged;

  /// Leading icon (optional)
  final IconData? leadingIcon;

  /// Active color
  final Color? activeColor;

  /// Content padding
  final EdgeInsetsGeometry? contentPadding;

  /// Enable haptic feedback
  final bool enableHaptic;

  /// Tristate
  final bool tristate;

  /// Control affinity (where checkbox is placed)
  final ListTileControlAffinity controlAffinity;

  const DSCheckboxTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.leadingIcon,
    this.activeColor,
    this.contentPadding,
    this.enableHaptic = true,
    this.tristate = false,
    this.controlAffinity = ListTileControlAffinity.leading,
  });

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

                if (tristate) {
                  // Cycle through: false -> true -> null -> false
                  if (value == false) {
                    onChanged?.call(true);
                  } else if (value == true) {
                    onChanged?.call(null);
                  } else {
                    onChanged?.call(false);
                  }
                } else {
                  onChanged?.call(!(value ?? false));
                }
              }
            : null,
        child: Padding(
          padding: contentPadding ??
              EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space12,
              ),
          child: Row(
            children: [
              // Checkbox on left
              if (controlAffinity == ListTileControlAffinity.leading) ...[
                DSCheckbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: activeColor,
                  enableHaptic: false, // Handled by InkWell
                  tristate: tristate,
                ),
                SizedBox(width: DesignTokens.space12),
              ],

              // Leading icon
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 24, color: AppColors.textSecondary),
                SizedBox(width: DesignTokens.space12),
              ],

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTypography.bodyMedium),
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

              // Checkbox on right
              if (controlAffinity == ListTileControlAffinity.trailing) ...[
                SizedBox(width: DesignTokens.space12),
                DSCheckbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: activeColor,
                  enableHaptic: false, // Handled by InkWell
                  tristate: tristate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact checkbox list item
class DSCheckboxListTile extends StatelessWidget {
  /// Title text
  final String title;

  /// Current value
  final bool? value;

  /// Change callback
  final void Function(bool?)? onChanged;

  /// Leading widget
  final Widget? secondary;

  /// Subtitle text
  final String? subtitle;

  /// Control affinity
  final ListTileControlAffinity controlAffinity;

  /// Dense layout
  final bool dense;

  /// Tristate
  final bool tristate;

  const DSCheckboxListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.secondary,
    this.subtitle,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.dense = false,
    this.tristate = false,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
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
      tristate: tristate,
      activeColor: AppColors.primary,
      checkColor: AppColors.surface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: dense ? 0 : DesignTokens.space4,
      ),
      shape: RoundedRectangleBorder(borderRadius: DesignTokens.radius(4)),
    );
  }
}

/// Checkbox group for multiple selections
class DSCheckboxGroup extends StatelessWidget {
  /// List of options
  final List<String> options;

  /// Selected values
  final List<String> selectedValues;

  /// Selection change callback
  final void Function(List<String>) onChanged;

  /// Leading icons for each option
  final List<IconData?>? leadingIcons;

  /// Spacing between checkboxes
  final double spacing;

  /// Enable dividers
  final bool showDividers;

  const DSCheckboxGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.leadingIcons,
    this.spacing = 0,
    this.showDividers = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = selectedValues.contains(option);
        final leadingIcon = leadingIcons != null && index < leadingIcons!.length
            ? leadingIcons![index]
            : null;

        return Column(
          children: [
            DSCheckboxTile(
              title: option,
              value: isSelected,
              onChanged: (value) {
                final newValues = List<String>.from(selectedValues);
                if (value == true) {
                  newValues.add(option);
                } else {
                  newValues.remove(option);
                }
                onChanged(newValues);
              },
              leadingIcon: leadingIcon,
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
