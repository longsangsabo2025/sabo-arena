import 'package:flutter/material.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'dart:math' as math;

/// Widget hiển thị trạng thái đang tải chuyên nghiệp với logo xanh lá
class LoadingStateWidget extends StatefulWidget {
  final String? message;
  final Color? color;
  final double? size;
  final bool useLogo;

  const LoadingStateWidget({
    Key? key,
    this.message,
    this.color,
    this.size,
    this.useLogo = true, // Mặc định dùng logo
  }) : super(key: key);

  @override
  State<LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<LoadingStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.useLogo) {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.useLogo)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                );
              },
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0D5C4C), // Màu xanh lá đậm và tối
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/images/logoxoaphong.png',
                  width: widget.size ?? 50,
                  height: widget.size ?? 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/logo.png',
                      width: widget.size ?? 50,
                      height: widget.size ?? 50,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            )
          else
            SizedBox(
              width: widget.size ?? 40,
              height: widget.size ?? 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.color ?? AppColors.primary,
                ),
                strokeWidth: 3,
              ),
            ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget shimmer loading (skeleton screen)
class ShimmerLoadingWidget extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const ShimmerLoadingWidget({
    Key? key,
    required this.height,
    required this.width,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<ShimmerLoadingWidget> createState() => _ShimmerLoadingWidgetState();
}

class _ShimmerLoadingWidgetState extends State<ShimmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}
