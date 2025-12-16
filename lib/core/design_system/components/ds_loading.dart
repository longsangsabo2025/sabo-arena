import 'package:flutter/material.dart';
import '../design_tokens.dart';
import '../app_colors.dart';

/// Loading spinner sizes for DSLoading
enum DSLoadingSize {
  /// Small loading indicator
  small,

  /// Medium loading indicator
  medium,

  /// Large loading indicator
  large,
}

/// Design System Loading Component
class DSLoading extends StatelessWidget {
  /// Loading size
  final DSLoadingSize size;

  const DSLoading({Key? key, this.size = DSLoadingSize.medium})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    double loadingSize = switch (size) {
      DSLoadingSize.small => 20,
      DSLoadingSize.medium => 40,
      DSLoadingSize.large => 60,
    };

    return SizedBox(
      width: loadingSize,
      height: loadingSize,
      child: const CircularProgressIndicator(),
    );
  }
}

///
/// Instagram/Facebook quality loading indicators:
/// - DSSpinner: Circular progress indicator
/// - DSSkeletonLoader: Shimmer loading placeholders
/// - DSProgressBar: Linear progress indicator
/// - DSPulseLoader: Pulse/bounce animation
///
/// Usage:
/// ```dart
/// DSSpinner.primary()
/// DSSkeletonLoader.list(itemCount: 5)
/// DSProgressBar(value: 0.6)
/// ```

/// Loading spinner sizes
enum DSSpinnerSize {
  /// Extra small (16px)
  xs,

  /// Small (20px)
  small,

  /// Medium (24px)
  medium,

  /// Large (32px)
  large,

  /// Extra large (48px)
  xl,
}

/// Circular loading spinner
class DSSpinner extends StatelessWidget {
  /// Spinner size
  final DSSpinnerSize size;

  /// Spinner color
  final Color? color;

  /// Stroke width
  final double? strokeWidth;

  /// Background color (for contained spinner)
  final Color? backgroundColor;

  /// Show background container
  final bool showBackground;

  const DSSpinner({
    super.key,
    this.size = DSSpinnerSize.medium,
    this.color,
    this.strokeWidth,
    this.backgroundColor,
    this.showBackground = false,
  });

  /// Primary colored spinner
  factory DSSpinner.primary({
    DSSpinnerSize size = DSSpinnerSize.medium,
    bool showBackground = false,
  }) {
    return DSSpinner(
      size: size,
      color: AppColors.primary,
      showBackground: showBackground,
    );
  }

  /// White spinner (for dark backgrounds)
  factory DSSpinner.white({
    DSSpinnerSize size = DSSpinnerSize.medium,
    bool showBackground = false,
  }) {
    return DSSpinner(
      size: size,
      color: AppColors.surface,
      showBackground: showBackground,
    );
  }

  /// Secondary colored spinner
  factory DSSpinner.secondary({
    DSSpinnerSize size = DSSpinnerSize.medium,
    bool showBackground = false,
  }) {
    return DSSpinner(
      size: size,
      color: AppColors.textSecondary,
      showBackground: showBackground,
    );
  }

  double get _size {
    switch (size) {
      case DSSpinnerSize.xs:
        return 16.0;
      case DSSpinnerSize.small:
        return 20.0;
      case DSSpinnerSize.medium:
        return 24.0;
      case DSSpinnerSize.large:
        return 32.0;
      case DSSpinnerSize.xl:
        return 48.0;
    }
  }

  double get _strokeWidth {
    if (strokeWidth != null) return strokeWidth!;
    switch (size) {
      case DSSpinnerSize.xs:
      case DSSpinnerSize.small:
        return 2.0;
      case DSSpinnerSize.medium:
        return 2.5;
      case DSSpinnerSize.large:
        return 3.0;
      case DSSpinnerSize.xl:
        return 3.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget spinner = SizedBox(
      width: _size,
      height: _size,
      child: CircularProgressIndicator(
        strokeWidth: _strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
      ),
    );

    if (showBackground) {
      final containerSize = _size + DesignTokens.space24;
      spinner = Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: DesignTokens.radius(DesignTokens.radiusMD),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: spinner),
      );
    }

    return spinner;
  }
}

/// Full screen loading overlay
class DSLoadingOverlay extends StatelessWidget {
  /// Loading message
  final String? message;

  /// Show background blur
  final bool blur;

  /// Background color
  final Color? backgroundColor;

  /// Spinner size
  final DSSpinnerSize spinnerSize;

  const DSLoadingOverlay({
    super.key,
    this.message,
    this.blur = true,
    this.backgroundColor,
    this.spinnerSize = DSSpinnerSize.large,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.shadow.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DSSpinner(
              size: spinnerSize,
              color: AppColors.surface,
              showBackground: true,
            ),
            if (message != null) ...[
              SizedBox(height: DesignTokens.space16),
              Container(
                padding: DesignTokens.only(
                  left: DesignTokens.space24,
                  right: DesignTokens.space24,
                  top: DesignTokens.space12,
                  bottom: DesignTokens.space12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: DesignTokens.radius(DesignTokens.radiusSM),
                ),
                child: Text(
                  message!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader placeholder
class DSSkeletonLoader extends StatefulWidget {
  /// Width
  final double? width;

  /// Height
  final double? height;

  /// Border radius
  final double? borderRadius;

  /// Shape (box or circle)
  final BoxShape shape;

  /// Base color
  final Color? baseColor;

  /// Highlight color
  final Color? highlightColor;

  const DSSkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.baseColor,
    this.highlightColor,
  });

  /// Circle skeleton (for avatars)
  factory DSSkeletonLoader.circle({
    required double size,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return DSSkeletonLoader(
      width: size,
      height: size,
      shape: BoxShape.circle,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Text line skeleton
  factory DSSkeletonLoader.text({
    double? width,
    double height = 16,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return DSSkeletonLoader(
      width: width,
      height: height,
      borderRadius: DesignTokens.radiusXS,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Card skeleton
  factory DSSkeletonLoader.card({
    double? width,
    double height = 200,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return DSSkeletonLoader(
      width: width,
      height: height,
      borderRadius: DesignTokens.radiusMD,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// List item skeleton
  static Widget listItem({bool showAvatar = true, int lineCount = 2}) {
    return Padding(
      padding: DesignTokens.only(
        left: DesignTokens.space16,
        right: DesignTokens.space16,
        top: DesignTokens.space12,
        bottom: DesignTokens.space12,
      ),
      child: Row(
        children: [
          if (showAvatar) ...[
            DSSkeletonLoader.circle(size: 48),
            SizedBox(width: DesignTokens.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSSkeletonLoader.text(width: double.infinity, height: 14),
                if (lineCount > 1) ...[
                  SizedBox(height: DesignTokens.space8),
                  DSSkeletonLoader.text(width: 200, height: 12),
                ],
                if (lineCount > 2) ...[
                  SizedBox(height: DesignTokens.space8),
                  DSSkeletonLoader.text(width: 150, height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// List of skeleton items
  static Widget list({
    int itemCount = 5,
    bool showAvatar = true,
    int lineCount = 2,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          listItem(showAvatar: showAvatar, lineCount: lineCount),
    );
  }

  @override
  State<DSSkeletonLoader> createState() => _DSSkeletonLoaderState();
}

class _DSSkeletonLoaderState extends State<DSSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? AppColors.gray100;
    final highlightColor = widget.highlightColor ?? AppColors.gray50;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : DesignTokens.radius(
                    widget.borderRadius ?? DesignTokens.radiusXS,
                  ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Linear progress bar
class DSProgressBar extends StatelessWidget {
  /// Progress value (0.0 to 1.0)
  final double? value;

  /// Bar height
  final double height;

  /// Bar color
  final Color? color;

  /// Background color
  final Color? backgroundColor;

  /// Border radius
  final double? borderRadius;

  /// Show percentage text
  final bool showPercentage;

  const DSProgressBar({
    super.key,
    this.value,
    this.height = 4,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppColors.primary;
    final bgColor = backgroundColor ?? AppColors.gray200;
    final radius = borderRadius ?? DesignTokens.radiusFull;

    Widget progressBar = ClipRRect(
      borderRadius: DesignTokens.radius(radius),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: bgColor,
        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
      ),
    );

    if (showPercentage && value != null) {
      return Row(
        children: [
          Expanded(child: progressBar),
          SizedBox(width: DesignTokens.space12),
          Text(
            '${(value! * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return progressBar;
  }
}

/// Pulse loader (bouncing dots)
class DSPulseLoader extends StatefulWidget {
  /// Dot count
  final int dotCount;

  /// Dot size
  final double dotSize;

  /// Dot color
  final Color? color;

  /// Space between dots
  final double spacing;

  const DSPulseLoader({
    super.key,
    this.dotCount = 3,
    this.dotSize = 8,
    this.color,
    this.spacing = 8,
  });

  @override
  State<DSPulseLoader> createState() => _DSPulseLoaderState();
}

class _DSPulseLoaderState extends State<DSPulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return Padding(
          padding: EdgeInsets.only(
            right: index < widget.dotCount - 1 ? widget.spacing : 0,
          ),
          child: _PulseDot(
            size: widget.dotSize,
            color: dotColor,
            delay: index * 0.15,
            controller: _controller,
          ),
        );
      }),
    );
  }
}

class _PulseDot extends StatelessWidget {
  final double size;
  final Color color;
  final double delay;
  final AnimationController controller;

  const _PulseDot({
    required this.size,
    required this.color,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = (controller.value - delay) % 1.0;
        final scale = 1.0 + (0.5 * (1 - (value * 2 - 1).abs()));

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5 + (0.5 * scale)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// Refresh indicator wrapper
class DSRefreshIndicator extends StatelessWidget {
  /// Child widget
  final Widget child;

  /// Refresh callback
  final Future<void> Function() onRefresh;

  /// Indicator color
  final Color? color;

  /// Background color
  final Color? backgroundColor;

  const DSRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor: backgroundColor ?? AppColors.surface,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
