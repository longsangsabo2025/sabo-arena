import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base Skeleton Widget with shimmer animation
class SkeletonWidget extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonWidget({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Tournament Card Skeleton
class TournamentCardSkeleton extends StatelessWidget {
  const TournamentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Tournament Logo/Avatar Skeleton
            const SkeletonWidget(width: 80, height: 80, borderRadius: 8),
            const SizedBox(width: 16),

            // Tournament Info Skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament Name
                  const SkeletonWidget(
                    width: double.infinity,
                    height: 20,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),

                  // Tournament Description
                  const SkeletonWidget(width: 200, height: 16, borderRadius: 4),
                  const Spacer(),

                  // Tournament Details Row
                  Row(
                    children: [
                      // Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonWidget(
                              width: 60,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 4),
                            const SkeletonWidget(
                              width: 80,
                              height: 14,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      // Participants
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SkeletonWidget(
                              width: 40,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 4),
                            const SkeletonWidget(
                              width: 60,
                              height: 14,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      // Prize Pool
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SkeletonWidget(
                              width: 50,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 4),
                            const SkeletonWidget(
                              width: 70,
                              height: 14,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// User Profile Card Skeleton
class UserProfileCardSkeleton extends StatelessWidget {
  const UserProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User Avatar Skeleton
            const SkeletonWidget(width: 60, height: 60, borderRadius: 30),
            const SizedBox(width: 16),

            // User Info Skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Name
                  const SkeletonWidget(width: 150, height: 18, borderRadius: 4),
                  const SizedBox(height: 8),

                  // User Rank
                  const SkeletonWidget(width: 100, height: 14, borderRadius: 4),
                  const Spacer(),

                  // User Stats Row
                  Row(
                    children: [
                      // Wins
                      Expanded(
                        child: Row(
                          children: [
                            const SkeletonWidget(
                              width: 16,
                              height: 16,
                              borderRadius: 8,
                            ),
                            const SizedBox(width: 4),
                            const SkeletonWidget(
                              width: 30,
                              height: 12,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      // Tournaments
                      Expanded(
                        child: Row(
                          children: [
                            const SkeletonWidget(
                              width: 16,
                              height: 16,
                              borderRadius: 8,
                            ),
                            const SizedBox(width: 4),
                            const SkeletonWidget(
                              width: 30,
                              height: 12,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      // ELO Rating
                      Expanded(
                        child: Row(
                          children: [
                            const SkeletonWidget(
                              width: 16,
                              height: 16,
                              borderRadius: 8,
                            ),
                            const SizedBox(width: 4),
                            const SkeletonWidget(
                              width: 40,
                              height: 12,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Club Card Skeleton
class ClubCardSkeleton extends StatelessWidget {
  const ClubCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Club Logo Skeleton
            const SkeletonWidget(width: 80, height: 80, borderRadius: 8),
            const SizedBox(width: 16),

            // Club Info Skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Club Name
                  const SkeletonWidget(width: 180, height: 20, borderRadius: 4),
                  const SizedBox(height: 8),

                  // Club Location
                  const SkeletonWidget(width: 120, height: 16, borderRadius: 4),
                  const Spacer(),

                  // Club Stats Row
                  Row(
                    children: [
                      // Tables
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonWidget(
                              width: 50,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 4),
                            const SkeletonWidget(
                              width: 60,
                              height: 14,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),

                      // Rating
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SkeletonWidget(
                              width: 40,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SkeletonWidget(
                                  width: 12,
                                  height: 12,
                                  borderRadius: 6,
                                ),
                                const SizedBox(width: 4),
                                const SkeletonWidget(
                                  width: 30,
                                  height: 14,
                                  borderRadius: 4,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Members
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SkeletonWidget(
                              width: 50,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 4),
                            const SkeletonWidget(
                              width: 60,
                              height: 14,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List Skeleton for showing multiple skeleton items
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final Widget Function(int) itemBuilder;
  final EdgeInsetsGeometry? padding;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(index),
    );
  }
}

/// Tournament List Skeleton
class TournamentListSkeleton extends StatelessWidget {
  const TournamentListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListSkeleton(
      itemCount: 5,
      itemBuilder: (index) => const TournamentCardSkeleton(),
    );
  }
}

/// Club List Skeleton
class ClubListSkeleton extends StatelessWidget {
  const ClubListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListSkeleton(
      itemCount: 6,
      itemBuilder: (index) => const ClubCardSkeleton(),
    );
  }
}

/// Shimmer Loading Widget
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: duration,
      child: child,
    );
  }
}

/// Form Skeleton for registration/login forms
class FormSkeleton extends StatelessWidget {
  final int fieldCount;

  const FormSkeleton({super.key, this.fieldCount = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        fieldCount,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: const SkeletonWidget(height: 50, borderRadius: 12),
        ),
      ),
    );
  }
}

/// Button Skeleton
class ButtonSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const ButtonSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonWidget(width: width, height: height, borderRadius: 8);
  }
}
