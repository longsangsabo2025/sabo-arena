/// DSCard - Design System Card Component
///
/// Instagram/Facebook quality card with:
/// - 3 variants (elevated, outlined, filled)
/// - Tap callback with scale animation
/// - Custom padding and border radius
/// - Hover effects
/// - Optional header/footer sections
/// - Hero animation support
///
/// Usage:
/// ```dart
/// DSCard.elevated(
///   child: Text('Post content'),
///   onTap: () => viewPost(),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Card variants
enum DSCardVariant {
  /// Elevated card with shadow
  elevated,

  /// Outlined card with border
  outlined,

  /// Filled card with background color
  filled,
}

/// Design System Card Component
class DSCard extends StatefulWidget {
  /// Card content
  final Widget child;

  /// Tap callback
  final VoidCallback? onTap;

  /// Long press callback
  final VoidCallback? onLongPress;

  /// Card variant
  final DSCardVariant variant;

  /// Custom padding
  final EdgeInsetsGeometry? padding;

  /// Custom margin
  final EdgeInsetsGeometry? margin;

  /// Border radius
  final double? borderRadius;

  /// Background color (overrides variant)
  final Color? backgroundColor;

  /// Border color (for outlined variant)
  final Color? borderColor;

  /// Border width (for outlined variant)
  final double? borderWidth;

  /// Elevation (for elevated variant)
  final double? elevation;

  /// Enable hover effect
  final bool enableHover;

  /// Enable haptic feedback
  final bool enableHaptic;

  /// Hero tag for hero animation
  final String? heroTag;

  /// Width
  final double? width;

  /// Height
  final double? height;

  /// Clip behavior
  final Clip clipBehavior;

  const DSCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.variant = DSCardVariant.elevated,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.elevation,
    this.enableHover = true,
    this.enableHaptic = true,
    this.heroTag,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Elevated card factory
  factory DSCard.elevated({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    Color? backgroundColor,
    double? elevation,
    bool enableHover = true,
    String? heroTag,
  }) {
    return DSCard(
      onTap: onTap,
      variant: DSCardVariant.elevated,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      elevation: elevation,
      enableHover: enableHover,
      heroTag: heroTag,
      child: child,
    );
  }

  /// Outlined card factory
  factory DSCard.outlined({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    bool enableHover = true,
    String? heroTag,
  }) {
    return DSCard(
      onTap: onTap,
      variant: DSCardVariant.outlined,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      enableHover: enableHover,
      heroTag: heroTag,
      child: child,
    );
  }

  /// Filled card factory
  factory DSCard.filled({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? borderRadius,
    Color? backgroundColor,
    bool enableHover = true,
    String? heroTag,
  }) {
    return DSCard(
      onTap: onTap,
      variant: DSCardVariant.filled,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      enableHover: enableHover,
      heroTag: heroTag,
      child: child,
    );
  }

  @override
  State<DSCard> createState() => _DSCardState();
}

class _DSCardState extends State<DSCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  bool get _isInteractive => widget.onTap != null || widget.onLongPress != null;

  Color get _backgroundColor {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.variant) {
      case DSCardVariant.elevated:
      case DSCardVariant.outlined:
        return AppColors.surface;
      case DSCardVariant.filled:
        return AppColors.gray100;
    }
  }

  double get _elevation {
    if (widget.elevation != null) return widget.elevation!;

    if (widget.variant != DSCardVariant.elevated) return 0;

    if (_isPressed) return DesignTokens.elevation1;
    if (_isHovered && _isInteractive) return DesignTokens.elevation4;
    return DesignTokens.elevation2;
  }

  BorderSide? get _borderSide {
    if (widget.variant == DSCardVariant.outlined) {
      return BorderSide(
        color: widget.borderColor ?? AppColors.border,
        width: widget.borderWidth ?? 1,
      );
    }
    return null;
  }

  void _handleTap() {
    if (widget.onTap == null) return;

    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }

    widget.onTap!();
  }

  void _handleLongPress() {
    if (widget.onLongPress == null) return;

    if (widget.enableHaptic) {
      HapticFeedback.mediumImpact();
    }

    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    Widget card = GestureDetector(
      onTapDown: _isInteractive
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: _isInteractive
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: _isInteractive
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: _handleTap,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: MouseRegion(
        onEnter: widget.enableHover && _isInteractive
            ? (_) => setState(() => _isHovered = true)
            : null,
        onExit: widget.enableHover && _isInteractive
            ? (_) => setState(() => _isHovered = false)
            : null,
        cursor: _isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: DesignTokens.durationFast,
          curve: DesignTokens.curveStandard,
          child: AnimatedContainer(
            duration: DesignTokens.durationNormal,
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            padding: widget.padding ?? DesignTokens.all(DesignTokens.space16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: DesignTokens.radius(
                widget.borderRadius ?? DesignTokens.radiusMD,
              ),
              border: _borderSide != null
                  ? Border.fromBorderSide(_borderSide!)
                  : null,
              boxShadow: _elevation > 0
                  ? [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.08),
                        blurRadius: _elevation,
                        offset: Offset(0, _elevation / 2),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: widget.clipBehavior,
            child: widget.child,
          ),
        ),
      ),
    );

    // Add hero animation if heroTag provided
    if (widget.heroTag != null) {
      card = Hero(tag: widget.heroTag!, child: card);
    }

    return card;
  }
}

/// Card with header and footer sections
class DSCardWithHeader extends StatelessWidget {
  /// Card header
  final Widget? header;

  /// Card content
  final Widget child;

  /// Card footer
  final Widget? footer;

  /// Tap callback
  final VoidCallback? onTap;

  /// Card variant
  final DSCardVariant variant;

  /// Custom padding for content
  final EdgeInsetsGeometry? contentPadding;

  /// Custom padding for header
  final EdgeInsetsGeometry? headerPadding;

  /// Custom padding for footer
  final EdgeInsetsGeometry? footerPadding;

  /// Border radius
  final double? borderRadius;

  /// Background color
  final Color? backgroundColor;

  /// Show divider between sections
  final bool showDividers;

  /// Hero tag
  final String? heroTag;

  const DSCardWithHeader({
    super.key,
    this.header,
    required this.child,
    this.footer,
    this.onTap,
    this.variant = DSCardVariant.elevated,
    this.contentPadding,
    this.headerPadding,
    this.footerPadding,
    this.borderRadius,
    this.backgroundColor,
    this.showDividers = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return DSCard(
      onTap: onTap,
      variant: variant,
      padding: EdgeInsets.zero,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      heroTag: heroTag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            Padding(
              padding:
                  headerPadding ??
                  DesignTokens.only(
                    left: DesignTokens.space16,
                    right: DesignTokens.space16,
                    top: DesignTokens.space16,
                    bottom: DesignTokens.space12,
                  ),
              child: header!,
            ),
            if (showDividers)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
          ],
          Padding(
            padding: contentPadding ?? DesignTokens.all(DesignTokens.space16),
            child: child,
          ),
          if (footer != null) ...[
            if (showDividers)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            Padding(
              padding:
                  footerPadding ??
                  DesignTokens.only(
                    left: DesignTokens.space16,
                    right: DesignTokens.space16,
                    top: DesignTokens.space12,
                    bottom: DesignTokens.space16,
                  ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact card for list items
class DSListCard extends StatelessWidget {
  /// Leading widget (usually avatar or icon)
  final Widget? leading;

  /// Title text
  final String title;

  /// Subtitle text
  final String? subtitle;

  /// Trailing widget (usually icon or action)
  final Widget? trailing;

  /// Tap callback
  final VoidCallback? onTap;

  /// Long press callback
  final VoidCallback? onLongPress;

  /// Custom padding
  final EdgeInsetsGeometry? padding;

  /// Background color
  final Color? backgroundColor;

  /// Enable hover effect
  final bool enableHover;

  const DSListCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.backgroundColor,
    this.enableHover = true,
  });

  @override
  Widget build(BuildContext context) {
    return DSCard(
      onTap: onTap,
      onLongPress: onLongPress,
      variant: DSCardVariant.filled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      padding:
          padding ??
          DesignTokens.only(
            left: DesignTokens.space16,
            right: DesignTokens.space16,
            top: DesignTokens.space12,
            bottom: DesignTokens.space12,
          ),
      enableHover: enableHover,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: DesignTokens.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: DesignTokens.space4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: DesignTokens.space12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Image card with overlay
class DSImageCard extends StatelessWidget {
  /// Image widget
  final Widget image;

  /// Overlay widget (usually text or actions)
  final Widget? overlay;

  /// Overlay alignment
  final AlignmentGeometry overlayAlignment;

  /// Overlay gradient
  final Gradient? overlayGradient;

  /// Tap callback
  final VoidCallback? onTap;

  /// Border radius
  final double? borderRadius;

  /// Width
  final double? width;

  /// Height
  final double? height;

  /// Aspect ratio (if width/height not provided)
  final double? aspectRatio;

  /// Hero tag
  final String? heroTag;

  const DSImageCard({
    super.key,
    required this.image,
    this.overlay,
    this.overlayAlignment = Alignment.bottomLeft,
    this.overlayGradient,
    this.onTap,
    this.borderRadius,
    this.width,
    this.height,
    this.aspectRatio,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = image;

    // Wrap with AspectRatio if provided
    if (aspectRatio != null && width == null && height == null) {
      imageWidget = AspectRatio(aspectRatio: aspectRatio!, child: imageWidget);
    }

    // Add overlay if provided
    if (overlay != null || overlayGradient != null) {
      imageWidget = Stack(
        children: [
          imageWidget,
          if (overlayGradient != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(gradient: overlayGradient),
              ),
            ),
          if (overlay != null)
            Positioned.fill(
              child: Align(alignment: overlayAlignment, child: overlay!),
            ),
        ],
      );
    }

    return DSCard(
      onTap: onTap,
      variant: DSCardVariant.elevated,
      padding: EdgeInsets.zero,
      borderRadius: borderRadius,
      width: width,
      height: height,
      heroTag: heroTag,
      child: imageWidget,
    );
  }
}
