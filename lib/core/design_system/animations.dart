/// Animation System - Smooth Transitions & Micro-interactions
///
/// Provides pre-built animations following Instagram/Facebook standards:
/// - Fade, scale, slide transitions
/// - Page route builders
/// - Micro-interaction widgets
/// - Hero animations support
///
/// All animations use design tokens for consistency

import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Animation utilities for smooth, consistent transitions
class AppAnimations {
  AppAnimations._(); // Private constructor

  // ============================================================================
  // FADE ANIMATIONS
  // ============================================================================

  /// Fade in animation
  ///
  /// Usage:
  /// ```dart
  /// AppAnimations.fadeIn(child: YourWidget())
  /// ```
  static Widget fadeIn({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveStandard,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        if (delay > Duration.zero &&
            value <
                delay.inMilliseconds /
                    (duration.inMilliseconds + delay.inMilliseconds)) {
          return Opacity(opacity: 0.0, child: child);
        }
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  /// Fade out animation
  static Widget fadeOut({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveStandard,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  // ============================================================================
  // SCALE ANIMATIONS
  // ============================================================================

  /// Scale in animation (from 0 to 1)
  static Widget scaleIn({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    Alignment alignment = Alignment.center,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        if (delay > Duration.zero &&
            value <
                delay.inMilliseconds /
                    (duration.inMilliseconds + delay.inMilliseconds)) {
          return Transform.scale(
            scale: 0.0,
            alignment: alignment,
            child: child,
          );
        }
        return Transform.scale(
          scale: value,
          alignment: alignment,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale out animation (from 1 to 0)
  static Widget scaleOut({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveAccelerate,
    Alignment alignment = Alignment.center,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: alignment,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale on tap animation (button press effect)
  static Widget scaleTap({
    required Widget child,
    required VoidCallback onTap,
    double scaleDown = 0.95,
    Duration duration = DesignTokens.durationFast,
  }) {
    return _ScaleTapWidget(
      onTap: onTap,
      scaleDown: scaleDown,
      duration: duration,
      child: child,
    );
  }

  // ============================================================================
  // SLIDE ANIMATIONS
  // ============================================================================

  /// Slide in from left
  static Widget slideInFromLeft({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    double offset = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -offset, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * MediaQuery.of(context).size.width, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in from right
  static Widget slideInFromRight({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    double offset = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * MediaQuery.of(context).size.width, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in from bottom
  static Widget slideInFromBottom({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    double offset = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value * MediaQuery.of(context).size.height),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in from top
  static Widget slideInFromTop({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    double offset = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -offset, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value * MediaQuery.of(context).size.height),
          child: child,
        );
      },
      child: child,
    );
  }

  // ============================================================================
  // COMBINED ANIMATIONS
  // ============================================================================

  /// Fade + Scale in (Instagram/Facebook style)
  static Widget fadeScaleIn({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    Alignment alignment = Alignment.center,
    double beginScale = 0.8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        final scale = beginScale + (1.0 - beginScale) * value;
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: scale,
            alignment: alignment,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Fade + Slide up (for bottom sheets, modals)
  static Widget fadeSlideUp({
    required Widget child,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    double slideOffset = 50.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, slideOffset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ============================================================================
  // PAGE TRANSITIONS
  // ============================================================================

  /// Fade page transition
  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget page,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveStandard,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: curve)),
          child: child,
        );
      },
    );
  }

  /// Slide page transition (left to right)
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget page,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    RouteSettings? settings,
    SlideDirection direction = SlideDirection.right,
  }) {
    Offset beginOffset;
    switch (direction) {
      case SlideDirection.right:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.left:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, 1.0);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, -1.0);
        break;
    }

    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(
              begin: beginOffset,
              end: Offset.zero,
            ).chain(CurveTween(curve: curve)),
          ),
          child: child,
        );
      },
    );
  }

  /// Scale page transition (for modals)
  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget page,
    Duration duration = DesignTokens.durationNormal,
    Curve curve = DesignTokens.curveEmphasized,
    RouteSettings? settings,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: curve)),
          ),
          alignment: alignment,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  /// iOS-style cupertino page transition
  static PageRouteBuilder<T> cupertinoTransition<T>({
    required Widget page,
    Duration duration = DesignTokens.durationMedium,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  // ============================================================================
  // SHIMMER / SKELETON LOADER
  // ============================================================================

  /// Shimmer effect for skeleton loading
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return _ShimmerWidget(
      duration: duration,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

// ============================================================================
// HELPER ENUMS
// ============================================================================

/// Slide direction for page transitions
enum SlideDirection { left, right, up, down }

// ============================================================================
// INTERNAL WIDGETS
// ============================================================================

/// Scale on tap widget (internal)
class _ScaleTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;
  final Duration duration;

  const _ScaleTapWidget({
    required this.child,
    required this.onTap,
    this.scaleDown = 0.95,
    this.duration = DesignTokens.durationFast,
  });

  @override
  State<_ScaleTapWidget> createState() => _ScaleTapWidgetState();
}

class _ScaleTapWidgetState extends State<_ScaleTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: DesignTokens.curveStandard),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Shimmer widget (internal)
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerWidget({
    required this.child,
    required this.duration,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ============================================================================
// ANIMATION PRESETS
// ============================================================================

/// Pre-configured animation presets for common use cases
class AnimationPresets {
  AnimationPresets._();

  /// Instagram-style like animation
  static Widget likeAnimation({required Widget child}) {
    return AppAnimations.scaleIn(
      duration: DesignTokens.durationFast,
      curve: DesignTokens.curveBounce,
      child: child,
    );
  }

  /// Facebook-style notification animation
  static Widget notificationAnimation({required Widget child}) {
    return AppAnimations.fadeSlideUp(
      duration: DesignTokens.durationNormal,
      slideOffset: 20.0,
      child: child,
    );
  }

  /// Bottom sheet slide up animation
  static Widget bottomSheetAnimation({required Widget child}) {
    return AppAnimations.slideInFromBottom(
      duration: DesignTokens.durationMedium,
      curve: DesignTokens.curveEmphasized,
      child: child,
    );
  }

  /// Modal fade scale animation
  static Widget modalAnimation({required Widget child}) {
    return AppAnimations.fadeScaleIn(
      duration: DesignTokens.durationNormal,
      beginScale: 0.9,
      child: child,
    );
  }

  /// List item stagger animation
  static Widget listItemAnimation({
    required Widget child,
    required int index,
    int itemsPerScreen = 10,
  }) {
    // Calculate stagger delay based on index
    final delayMs = (index * 50).clamp(0, itemsPerScreen * 50);
    final adjustedDuration =
        DesignTokens.durationNormal + Duration(milliseconds: delayMs);

    return AppAnimations.fadeSlideUp(
      duration: adjustedDuration,
      slideOffset: 30.0,
      child: child,
    );
  }
}
