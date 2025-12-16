import 'package:flutter/material.dart';
import 'dart:math' as math;

class LogoLoadingWidget extends StatefulWidget {
  final double? size;
  final Color? backgroundColor;
  final bool showBackground;
  final EdgeInsets? padding;
  final bool animate;

  const LogoLoadingWidget({
    super.key,
    this.size,
    this.backgroundColor,
    this.showBackground = false,
    this.padding,
    this.animate = true,
  });

  @override
  State<LogoLoadingWidget> createState() => _LogoLoadingWidgetState();
}

class _LogoLoadingWidgetState extends State<LogoLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat();
    } else {
      _controller = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.size ?? 50.0;
    final defaultPadding = widget.padding ?? const EdgeInsets.all(8.0);

    Widget logoImage = ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color(0xFF0D5C4C), // Màu xanh lá đậm và tối
        BlendMode.srcATop,
      ),
      child: Image.asset(
        'assets/images/logoxoaphong.png',
        width: logoSize * 0.7,
        height: logoSize * 0.7,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/logo.png',
            width: logoSize * 0.7,
            height: logoSize * 0.7,
            fit: BoxFit.contain,
          );
        },
      ),
    );

    Widget animatedLogo = widget.animate
        ? AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: child,
              );
            },
            child: logoImage,
          )
        : logoImage;

    Widget logoWidget = Container(
      width: logoSize,
      height: logoSize,
      padding: defaultPadding,
      decoration: widget.showBackground
          ? BoxDecoration(
              color: widget.backgroundColor ?? Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: animatedLogo,
    );

    return Center(child: logoWidget);
  }
}

// Small version for inline loading
class SmallLogoLoadingWidget extends StatelessWidget {
  const SmallLogoLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const LogoLoadingWidget(size: 24, padding: EdgeInsets.all(4.0));
  }
}

// Medium version for cards/modals
class MediumLogoLoadingWidget extends StatelessWidget {
  const MediumLogoLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const LogoLoadingWidget(size: 40, showBackground: true);
  }
}

// Large version for main loading screens
class LargeLogoLoadingWidget extends StatelessWidget {
  const LargeLogoLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const LogoLoadingWidget(size: 80, showBackground: true);
  }
}
