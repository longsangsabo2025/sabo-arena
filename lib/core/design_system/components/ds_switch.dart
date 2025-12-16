/// DSSwitch - Design System Switch Component
///
/// Instagram/Facebook quality toggle switch with:
/// - Smooth animation
/// - Custom colors
/// - Disabled state
/// - Haptic feedback
/// - Label support
///
/// Usage:
/// ```dart
/// DSSwitch(
///   value: isEnabled,
///   onChanged: (value) => setState(() => isEnabled = value),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';
import '../app_colors.dart';
import '../typography.dart';

/// Design System Switch Component
class DSSwitch extends StatelessWidget {
  /// Current value
  final bool value;

  /// Change callback
  final void Function(bool)? onChanged;

  /// Active color (when ON)
  final Color? activeColor;

  /// Inactive color (when OFF)
  final Color? inactiveColor;

  /// Track color when active
  final Color? activeTrackColor;

  /// Track color when inactive
  final Color? inactiveTrackColor;

  /// Enable haptic feedback
  final bool enableHaptic;

  const DSSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged != null
          ? (newValue) {
              if (enableHaptic) {
                HapticFeedback.lightImpact();
              }
              onChanged?.call(newValue);
            }
          : null,
      activeThumbColor: activeColor ?? AppColors.surface,
      inactiveThumbColor: inactiveColor ?? AppColors.surface,
      activeTrackColor: activeTrackColor ?? AppColors.primary,
      inactiveTrackColor: inactiveTrackColor ?? AppColors.gray300,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Switch with label
class DSSwitchTile extends StatelessWidget {
  /// Title text
  final String title;

  /// Subtitle text (optional)
  final String? subtitle;

  /// Current value
  final bool value;

  /// Change callback
  final void Function(bool)? onChanged;

  /// Leading icon (optional)
  final IconData? leadingIcon;

  /// Active color
  final Color? activeColor;

  /// Content padding
  final EdgeInsetsGeometry? contentPadding;

  /// Enable haptic feedback
  final bool enableHaptic;

  const DSSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.leadingIcon,
    this.activeColor,
    this.contentPadding,
    this.enableHaptic = true,
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
                onChanged?.call(!value);
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

              // Switch
              DSSwitch(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor,
                enableHaptic: false, // Handled by InkWell
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact switch list item
class DSSwitchListTile extends StatelessWidget {
  /// Title text
  final String title;

  /// Current value
  final bool value;

  /// Change callback
  final void Function(bool)? onChanged;

  /// Leading widget
  final Widget? leading;

  /// Subtitle text
  final String? subtitle;

  /// Dense layout
  final bool dense;

  const DSSwitchListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.leading,
    this.subtitle,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
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
      secondary: leading,
      dense: dense,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: dense ? 0 : DesignTokens.space4,
      ),
    );
  }
}
