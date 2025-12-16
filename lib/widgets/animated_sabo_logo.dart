import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../core/design_system/design_system.dart';

// Helper để lấy font family phù hợp
String _getSystemFont() {
  try {
    if (Platform.isIOS) {
      return '.SF Pro Display'; // SF Pro Display - iOS
    } else {
      return 'Roboto'; // Roboto - Android
    }
  } catch (e) {
    return 'Roboto'; // Fallback
  }
}

/// Animated SABO ARENA logo với hiệu ứng chuyên nghiệp
class AnimatedSaboLogo extends StatefulWidget {
  final String text;
  final double fontSize;

  const AnimatedSaboLogo({
    super.key,
    this.text = 'SABO ARENA',
    this.fontSize = 20,
  });

  @override
  State<AnimatedSaboLogo> createState() => _AnimatedSaboLogoState();
}

class _AnimatedSaboLogoState extends State<AnimatedSaboLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -2,
      end: 2,
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
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Shadow layer (blur effect)
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.primary700.withValues(alpha: 0.3),
                  AppColors.primary500.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontFamily: _getSystemFont(),
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5, // Tighter cho system font
                  height: 1.2,
                ),
              ),
            ),
            // Main text với gradient và shimmer effect
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.primary800,
                  AppColors.primary600,
                  AppColors.primary500,
                  AppColors.primary600,
                  AppColors.primary800,
                ],
                stops: [
                  0.0,
                  0.3 + (_shimmerAnimation.value * 0.1),
                  0.5 + (_shimmerAnimation.value * 0.1),
                  0.7 + (_shimmerAnimation.value * 0.1),
                  1.0,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontFamily: _getSystemFont(),
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5, // Tighter cho system font
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: AppColors.primary700.withValues(alpha: 0.4),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Static version (không animation) cho performance
class StaticSaboLogo extends StatelessWidget {
  final String text;
  final double fontSize;

  const StaticSaboLogo({
    super.key,
    this.text = 'SABO ARENA',
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Shadow layer (blur effect)
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.primary700.withValues(alpha: 0.3),
              AppColors.primary500.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: _getSystemFont(),
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
        ),
        // Main text với gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              AppColors.primary800, // Xanh đậm nhất
              AppColors.primary600, // Xanh vừa
              AppColors.primary500, // Xanh chuẩn
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: _getSystemFont(),
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.2,
              shadows: [
                Shadow(
                  color: AppColors.primary700.withValues(alpha: 0.4),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
