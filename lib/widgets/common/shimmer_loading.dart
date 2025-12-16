/// Shimmer Loading Effect Widget
///
/// Creates animated shimmer effect for skeleton screens
/// Used during data loading to improve perceived performance

import 'package:flutter/material.dart';
import '../../core/design_system.dart' as ds;

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration? duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.duration,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? ds.AppDuration.shimmer,
    );

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor ?? ds.AppColors.grey300,
                widget.highlightColor ?? ds.AppColors.grey100,
                widget.baseColor ?? ds.AppColors.grey300,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Skeleton Box - Building block for skeleton screens
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ds.AppColors.grey300,
        borderRadius: borderRadius ?? BorderRadius.circular(ds.AppRadius.sm),
      ),
    );
  }
}

/// Skeleton Line - For text placeholders
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonLine({super.key, this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}

/// Skeleton Circle - For avatars
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ds.AppColors.grey300,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton Stat Card - For dashboard stats loading
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(ds.AppSpacing.md),
      decoration: BoxDecoration(
        color: ds.AppColors.surface,
        borderRadius: BorderRadius.circular(ds.AppRadius.card),
        border: Border.all(color: ds.AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(ds.AppRadius.sm),
              ),
              const Spacer(),
              const SkeletonLine(width: 40, height: 16),
            ],
          ),
          const SizedBox(height: ds.AppSpacing.md),
          const SkeletonLine(width: 60, height: 28),
          const SizedBox(height: ds.AppSpacing.xs),
          const SkeletonLine(width: 80, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton Quick Action Button
class SkeletonQuickAction extends StatelessWidget {
  const SkeletonQuickAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110, // Increased from 100 to match QuickActionButton
      padding: const EdgeInsets.all(ds.AppSpacing.sm), // Reduced from md to sm
      decoration: BoxDecoration(
        color: ds.AppColors.surface,
        borderRadius: BorderRadius.circular(ds.AppRadius.card),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(ds.AppRadius.md),
          ),
          const SizedBox(height: ds.AppSpacing.sm),
          const SkeletonLine(width: 50, height: 10),
        ],
      ),
    );
  }
}

/// Skeleton Activity Item
class SkeletonActivityItem extends StatelessWidget {
  const SkeletonActivityItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ds.AppSpacing.md),
      decoration: BoxDecoration(
        color: ds.AppColors.surface,
        borderRadius: BorderRadius.circular(ds.AppRadius.md),
      ),
      child: Row(
        children: [
          SkeletonBox(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(ds.AppRadius.sm),
          ),
          const SizedBox(width: ds.AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLine(width: 150, height: 14),
                const SizedBox(height: 4),
                SkeletonLine(width: 100, height: 12),
              ],
            ),
          ),
          const SkeletonLine(width: 40, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton Member Card
class SkeletonMemberCard extends StatelessWidget {
  const SkeletonMemberCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ds.AppSpacing.md),
      decoration: BoxDecoration(
        color: ds.AppColors.surface,
        borderRadius: BorderRadius.circular(ds.AppRadius.md),
        border: Border.all(color: ds.AppColors.border),
      ),
      child: Row(
        children: [
          const SkeletonCircle(size: 56),
          const SizedBox(width: ds.AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLine(width: 120, height: 16),
                const SizedBox(height: 4),
                const SkeletonLine(width: 80, height: 12),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SkeletonLine(width: 60, height: 12),
                    const SizedBox(width: ds.AppSpacing.sm),
                    const SkeletonLine(width: 60, height: 12),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              const SkeletonBox(width: 32, height: 32),
              const SizedBox(height: ds.AppSpacing.xs),
              const SkeletonBox(width: 32, height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashboard Skeleton Screen - Complete loading state
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ds.AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      right: index < 3 ? ds.AppSpacing.md : 0,
                    ),
                    child: const SkeletonStatCard(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: ds.AppSpacing.lg),

            // Section Title
            const SkeletonLine(width: 150, height: 20),

            const SizedBox(height: ds.AppSpacing.md),

            // Quick Actions
            Wrap(
              spacing: ds.AppSpacing.md,
              runSpacing: ds.AppSpacing.md,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: MediaQuery.of(context).size.width * 0.28,
                  child: const SkeletonQuickAction(),
                ),
              ),
            ),

            const SizedBox(height: ds.AppSpacing.lg),

            // Section Title
            const SkeletonLine(width: 180, height: 20),

            const SizedBox(height: ds.AppSpacing.md),

            // Activities
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: ds.AppSpacing.sm),
                child: const SkeletonActivityItem(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
