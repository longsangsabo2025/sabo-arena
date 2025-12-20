/// DSButton - Design System Button Component
///
/// Instagram/Facebook quality button with:
/// - 4 variants (primary, secondary, tertiary, ghost)
/// - 3 sizes (small, medium, large)
/// - Loading state with spinner
/// - Leading/trailing icons
/// - Full-width option
/// - Disabled state
/// - Haptic feedback
/// - Scale animation on tap
///
/// Usage:
/// ```dart
/// DSButton(
///   text: 'Follow',
///   variant: DSButtonVariant.primary,
///   onPressed: () => followUser(),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Button variants
enum DSButtonVariant {
  /// Solid primary color background
  primary,

  /// Outlined with primary color
  secondary,

  /// Text only with primary color
  tertiary,

  /// Text only with subtle background on hover
  ghost,
}

/// Button sizes
enum DSButtonSize {
  /// Small button (32px height)
  small,

  /// Medium button (40px height) - default
  medium,

  /// Large button (48px height)
  large,
}

/// Design System Button Component
class DSButton extends StatefulWidget {
  /// Button text
  final String text;

  /// Tap callback
  final VoidCallback? onPressed;

  /// Long press callback
  final VoidCallback? onLongPress;

  /// Button variant
  final DSButtonVariant variant;

  /// Button size
  final DSButtonSize size;

  /// Leading icon
  final IconData? leadingIcon;

  /// Trailing icon
  final IconData? trailingIcon;

  /// Loading state
  final bool isLoading;

  /// Disabled state (overrides onPressed null check)
  final bool isDisabled;

  /// Full width button
  final bool fullWidth;

  /// Custom background color (overrides variant)
  final Color? backgroundColor;

  /// Custom text color (overrides variant)
  final Color? textColor;

  /// Border radius (overrides default)
  final double? borderRadius;

  /// Enable haptic feedback
  final bool enableHaptic;

  /// Custom padding
  final EdgeInsetsGeometry? padding;

  const DSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.onLongPress,
    this.variant = DSButtonVariant.primary,
    this.size = DSButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.enableHaptic = true,
    this.padding,
  });

  /// Primary button factory
  factory DSButton.primary({
    required String text,
    required VoidCallback? onPressed,
    DSButtonSize size = DSButtonSize.medium,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.primary,
      size: size,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  /// Secondary button factory
  factory DSButton.secondary({
    required String text,
    required VoidCallback? onPressed,
    DSButtonSize size = DSButtonSize.medium,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.secondary,
      size: size,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  /// Tertiary button factory
  factory DSButton.tertiary({
    required String text,
    required VoidCallback? onPressed,
    DSButtonSize size = DSButtonSize.medium,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool isLoading = false,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.tertiary,
      size: size,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
    );
  }

  /// Ghost button factory
  factory DSButton.ghost({
    required String text,
    required VoidCallback? onPressed,
    DSButtonSize size = DSButtonSize.medium,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool isLoading = false,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.ghost,
      size: size,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
    );
  }

  /// Outlined button factory (secondary variant)
  factory DSButton.outlined({
    required String text,
    required VoidCallback? onPressed,
    DSButtonSize size = DSButtonSize.medium,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.secondary,
      size: size,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  @override
  State<DSButton> createState() => _DSButtonState();
}

class _DSButtonState extends State<DSButton> {
  bool _isPressed = false;

  bool get _isDisabled =>
      widget.isDisabled || widget.onPressed == null || widget.isLoading;

  double get _height {
    switch (widget.size) {
      case DSButtonSize.small:
        return DesignTokens.buttonHeightSM;
      case DSButtonSize.medium:
        return DesignTokens.buttonHeightMD;
      case DSButtonSize.large:
        return DesignTokens.buttonHeightLG;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case DSButtonSize.small:
        return 14;
      case DSButtonSize.medium:
        return 15;
      case DSButtonSize.large:
        return 16;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case DSButtonSize.small:
        return DesignTokens.iconSM;
      case DSButtonSize.medium:
        return DesignTokens.iconSM;
      case DSButtonSize.large:
        return DesignTokens.iconMD;
    }
  }

  EdgeInsetsGeometry get _padding {
    if (widget.padding != null) return widget.padding!;

    switch (widget.size) {
      case DSButtonSize.small:
        return DesignTokens.only(
          left: DesignTokens.space16,
          right: DesignTokens.space16,
          top: DesignTokens.space8,
          bottom: DesignTokens.space8,
        );
      case DSButtonSize.medium:
        return DesignTokens.only(
          left: DesignTokens.space20,
          right: DesignTokens.space20,
          top: DesignTokens.space12,
          bottom: DesignTokens.space12,
        );
      case DSButtonSize.large:
        return DesignTokens.only(
          left: DesignTokens.space24,
          right: DesignTokens.space24,
          top: DesignTokens.space12,
          bottom: DesignTokens.space12,
        );
    }
  }

  Color get _backgroundColor {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    if (_isDisabled) {
      return AppColors.gray300;
    }

    switch (widget.variant) {
      case DSButtonVariant.primary:
        return AppColors.primary;
      case DSButtonVariant.secondary:
        return Colors.transparent;
      case DSButtonVariant.tertiary:
        return Colors.transparent;
      case DSButtonVariant.ghost:
        return _isPressed ? AppColors.gray100 : Colors.transparent;
    }
  }

  Color get _textColor {
    if (widget.textColor != null) return widget.textColor!;

    if (_isDisabled) {
      return AppColors.gray500;
    }

    switch (widget.variant) {
      case DSButtonVariant.primary:
        return AppColors.textOnPrimary;
      case DSButtonVariant.secondary:
      case DSButtonVariant.tertiary:
      case DSButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  BorderSide? get _borderSide {
    if (widget.variant == DSButtonVariant.secondary) {
      return BorderSide(
        color: _isDisabled ? AppColors.gray300 : AppColors.primary,
        width: 1,
      );
    }
    return null;
  }

  void _handleTap() {
    if (_isDisabled) return;

    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }

    widget.onPressed?.call();
  }

  void _handleLongPress() {
    if (_isDisabled) return;

    if (widget.enableHaptic) {
      HapticFeedback.mediumImpact();
    }

    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: _isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel:
          _isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: _handleTap,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: DesignTokens.durationFast,
        curve: DesignTokens.curveStandard,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          height: _height,
          width: widget.fullWidth ? double.infinity : null,
          padding: _padding,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: DesignTokens.radius(
              widget.borderRadius ?? DesignTokens.radiusSM,
            ),
            border: _borderSide != null
                ? Border.fromBorderSide(_borderSide!)
                : null,
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: _iconSize,
          height: _iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_textColor),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: _iconSize, color: _textColor),
          SizedBox(width: DesignTokens.space8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: _textColor,
            letterSpacing: DesignTokens.letterSpacingRelaxed,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          SizedBox(width: DesignTokens.space8),
          Icon(widget.trailingIcon, size: _iconSize, color: _textColor),
        ],
      ],
    );
  }
}

/// Icon-only button variant
class DSIconButton extends StatefulWidget {
  /// Icon to display
  final IconData icon;

  /// Tap callback
  final VoidCallback? onPressed;

  /// Button variant
  final DSButtonVariant variant;

  /// Button size
  final DSButtonSize size;

  /// Loading state
  final bool isLoading;

  /// Badge text (e.g., notification count)
  final String? badgeText;

  /// Tooltip text
  final String? tooltip;

  /// Enable haptic feedback
  final bool enableHaptic;

  const DSIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = DSButtonVariant.ghost,
    this.size = DSButtonSize.medium,
    this.isLoading = false,
    this.badgeText,
    this.tooltip,
    this.enableHaptic = true,
  });

  @override
  State<DSIconButton> createState() => _DSIconButtonState();
}

class _DSIconButtonState extends State<DSIconButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  double get _size {
    switch (widget.size) {
      case DSButtonSize.small:
        return DesignTokens.tapTargetMin - 8;
      case DSButtonSize.medium:
        return DesignTokens.tapTargetMin;
      case DSButtonSize.large:
        return DesignTokens.tapTargetRecommended;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case DSButtonSize.small:
        return DesignTokens.iconSM;
      case DSButtonSize.medium:
        return DesignTokens.iconMD;
      case DSButtonSize.large:
        return DesignTokens.iconLG;
    }
  }

  Color get _backgroundColor {
    if (_isDisabled) {
      return AppColors.gray200;
    }

    switch (widget.variant) {
      case DSButtonVariant.primary:
        return AppColors.primary;
      case DSButtonVariant.secondary:
        return AppColors.primary100;
      case DSButtonVariant.tertiary:
      case DSButtonVariant.ghost:
        return _isPressed ? AppColors.gray100 : Colors.transparent;
    }
  }

  Color get _iconColor {
    if (_isDisabled) {
      return AppColors.gray500;
    }

    switch (widget.variant) {
      case DSButtonVariant.primary:
        return AppColors.textOnPrimary;
      case DSButtonVariant.secondary:
      case DSButtonVariant.tertiary:
      case DSButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  void _handleTap() {
    if (_isDisabled) return;

    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTapDown: _isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: _isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel:
          _isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: DesignTokens.durationFast,
        curve: DesignTokens.curveStandard,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: _backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: _iconSize * 0.8,
                    height: _iconSize * 0.8,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_iconColor),
                    ),
                  )
                : Icon(widget.icon, size: _iconSize, color: _iconColor),
          ),
        ),
      ),
    );

    // Add badge if provided
    if (widget.badgeText != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: DesignTokens.only(
                left: DesignTokens.space4,
                right: DesignTokens.space4,
                top: 2,
                bottom: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Text(
                widget.badgeText!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Add tooltip if provided
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
