/// DSBadge - Design System Badge Component
///
/// Instagram/Facebook quality badge with:
/// - Multiple variants (dot, count, text)
/// - Multiple colors (primary, error, success, warning)
/// - Position control (top-right, top-left, etc.)
/// - Flexible positioning on any widget
/// - Pulse animation option
///
/// Usage:
/// ```dart
/// DSBadge.count(
///   count: 5,
///   child: Icon(AppIcons.notifications),
/// )
///
/// DSBadge.dot(
///   color: AppColors.success,
///   child: DSAvatar(imageUrl: user.avatar),
/// )
/// ```

import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Badge variants
enum DSBadgeVariant {
  /// Small dot indicator
  dot,

  /// Numeric count
  count,

  /// Text label
  text,
}

/// Badge position
enum DSBadgePosition {
  /// Top right corner
  topRight,

  /// Top left corner
  topLeft,

  /// Bottom right corner
  bottomRight,

  /// Bottom left corner
  bottomLeft,
}

/// Badge colors
enum DSBadgeColor {
  /// Primary color
  primary,

  /// Error/notification color
  error,

  /// Success color
  success,

  /// Warning color
  warning,

  /// Info color
  info,

  /// Neutral/gray color
  neutral,
}

/// Design System Badge Component
class DSBadge extends StatelessWidget {
  /// Child widget to place badge on
  final Widget child;

  /// Badge variant
  final DSBadgeVariant variant;

  /// Badge position
  final DSBadgePosition position;

  /// Badge color scheme
  final DSBadgeColor color;

  /// Count value (for count variant)
  final int? count;

  /// Text label (for text variant)
  final String? label;

  /// Show badge (can be used to hide/show)
  final bool show;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom text color
  final Color? textColor;

  /// Custom size for dot
  final double? dotSize;

  /// Enable pulse animation
  final bool pulse;

  /// Offset from edge
  final Offset? offset;

  const DSBadge({
    super.key,
    required this.child,
    this.variant = DSBadgeVariant.count,
    this.position = DSBadgePosition.topRight,
    this.color = DSBadgeColor.error,
    this.count,
    this.label,
    this.show = true,
    this.backgroundColor,
    this.textColor,
    this.dotSize,
    this.pulse = false,
    this.offset,
  });

  /// Dot badge factory
  factory DSBadge.dot({
    required Widget child,
    DSBadgePosition position = DSBadgePosition.topRight,
    DSBadgeColor color = DSBadgeColor.success,
    bool show = true,
    double? dotSize,
    bool pulse = false,
    Offset? offset,
  }) {
    return DSBadge(
      variant: DSBadgeVariant.dot,
      position: position,
      color: color,
      show: show,
      dotSize: dotSize,
      pulse: pulse,
      offset: offset,
      child: child,
    );
  }

  /// Count badge factory
  factory DSBadge.count({
    required Widget child,
    required int count,
    DSBadgePosition position = DSBadgePosition.topRight,
    DSBadgeColor color = DSBadgeColor.error,
    bool show = true,
    int maxCount = 99,
    Offset? offset,
  }) {
    return DSBadge(
      variant: DSBadgeVariant.count,
      position: position,
      color: color,
      count: count > maxCount ? maxCount : count,
      show: show && count > 0,
      offset: offset,
      child: child,
    );
  }

  /// Text badge factory
  factory DSBadge.text({
    required Widget child,
    required String label,
    DSBadgePosition position = DSBadgePosition.topRight,
    DSBadgeColor color = DSBadgeColor.primary,
    bool show = true,
    Offset? offset,
  }) {
    return DSBadge(
      variant: DSBadgeVariant.text,
      position: position,
      color: color,
      label: label,
      show: show,
      offset: offset,
      child: child,
    );
  }

  /// Online indicator badge (green dot)
  factory DSBadge.online({
    required Widget child,
    bool isOnline = true,
    DSBadgePosition position = DSBadgePosition.bottomRight,
  }) {
    return DSBadge.dot(
      color: DSBadgeColor.success,
      position: position,
      show: isOnline,
      dotSize: 12,
      child: child,
    );
  }

  /// New badge (red dot with pulse)
  factory DSBadge.newIndicator({
    required Widget child,
    bool show = true,
    DSBadgePosition position = DSBadgePosition.topRight,
  }) {
    return DSBadge.dot(
      color: DSBadgeColor.error,
      position: position,
      show: show,
      pulse: true,
      child: child,
    );
  }

  Color get _backgroundColor {
    if (backgroundColor != null) return backgroundColor!;

    switch (color) {
      case DSBadgeColor.primary:
        return AppColors.primary;
      case DSBadgeColor.error:
        return AppColors.error;
      case DSBadgeColor.success:
        return AppColors.success;
      case DSBadgeColor.warning:
        return AppColors.warning;
      case DSBadgeColor.info:
        return AppColors.info;
      case DSBadgeColor.neutral:
        return AppColors.gray600;
    }
  }

  Color get _textColor {
    if (textColor != null) return textColor!;
    return AppColors.surface;
  }

  double get _dotSize {
    return dotSize ?? 8.0;
  }

  Alignment get _alignment {
    switch (position) {
      case DSBadgePosition.topRight:
        return Alignment.topRight;
      case DSBadgePosition.topLeft:
        return Alignment.topLeft;
      case DSBadgePosition.bottomRight:
        return Alignment.bottomRight;
      case DSBadgePosition.bottomLeft:
        return Alignment.bottomLeft;
    }
  }

  Offset get _offset {
    if (offset != null) return offset!;

    final offsetValue = variant == DSBadgeVariant.dot ? 2.0 : 4.0;

    switch (position) {
      case DSBadgePosition.topRight:
        return Offset(offsetValue, -offsetValue);
      case DSBadgePosition.topLeft:
        return Offset(-offsetValue, -offsetValue);
      case DSBadgePosition.bottomRight:
        return Offset(offsetValue, offsetValue);
      case DSBadgePosition.bottomLeft:
        return Offset(-offsetValue, offsetValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: _alignment,
            child: Transform.translate(offset: _offset, child: _buildBadge()),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    Widget badge;

    switch (variant) {
      case DSBadgeVariant.dot:
        badge = _buildDotBadge();
        break;
      case DSBadgeVariant.count:
        badge = _buildCountBadge();
        break;
      case DSBadgeVariant.text:
        badge = _buildTextBadge();
        break;
    }

    if (pulse) {
      return _PulsatingBadge(child: badge);
    }

    return badge;
  }

  Widget _buildDotBadge() {
    return Container(
      width: _dotSize,
      height: _dotSize,
      decoration: BoxDecoration(
        color: _backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
    );
  }

  Widget _buildCountBadge() {
    final displayCount = count ?? 0;
    final displayText = displayCount > 99 ? '99+' : displayCount.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _textColor,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTextBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: DesignTokens.radius(DesignTokens.radiusXS),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Text(
        label ?? '',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _textColor,
          height: 1,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Pulsating animation for badge
class _PulsatingBadge extends StatefulWidget {
  final Widget child;

  const _PulsatingBadge({required this.child});

  @override
  State<_PulsatingBadge> createState() => _PulsatingBadgeState();
}

class _PulsatingBadgeState extends State<_PulsatingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// Badge standalone (without child)
class DSBadgeStandalone extends StatelessWidget {
  /// Badge text
  final String text;

  /// Badge color
  final DSBadgeColor color;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom text color
  final Color? textColor;

  /// Tap callback
  final VoidCallback? onTap;

  const DSBadgeStandalone({
    super.key,
    required this.text,
    this.color = DSBadgeColor.primary,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  Color get _backgroundColor {
    if (backgroundColor != null) return backgroundColor!;

    switch (color) {
      case DSBadgeColor.primary:
        return AppColors.primary100;
      case DSBadgeColor.error:
        return AppColors.error100;
      case DSBadgeColor.success:
        return AppColors.success100;
      case DSBadgeColor.warning:
        return AppColors.warning100;
      case DSBadgeColor.info:
        return AppColors.info100;
      case DSBadgeColor.neutral:
        return AppColors.gray200;
    }
  }

  Color get _textColor {
    if (textColor != null) return textColor!;

    switch (color) {
      case DSBadgeColor.primary:
        return AppColors.primary;
      case DSBadgeColor.error:
        return AppColors.error;
      case DSBadgeColor.success:
        return AppColors.success;
      case DSBadgeColor.warning:
        return AppColors.warning;
      case DSBadgeColor.info:
        return AppColors.info;
      case DSBadgeColor.neutral:
        return AppColors.gray700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textColor,
          height: 1,
          letterSpacing: 0.2,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.radius(DesignTokens.radiusFull),
        child: badge,
      );
    }

    return badge;
  }
}
