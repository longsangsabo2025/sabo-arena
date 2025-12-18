import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;
import '../../../widgets/common/app_button.dart';

class EmptyFeedWidget extends StatefulWidget {
  final bool isNearbyTab;
  final VoidCallback? onCreatePost;
  final VoidCallback? onFindFriends;

  const EmptyFeedWidget({
    super.key,
    required this.isNearbyTab,
    this.onCreatePost,
    this.onFindFriends,
  });

  @override
  State<EmptyFeedWidget> createState() => _EmptyFeedWidgetState();
}

class _EmptyFeedWidgetState extends State<EmptyFeedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo xoay 2D với màu xanh lá brand
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
                  width: 9.3.w,
                  height: 9.3.w,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to original logo if not found
                    return Image.asset(
                      'assets/images/logo.png',
                      width: 9.3.w,
                      height: 9.3.w,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 2.h),

            // Title
            Text(
              widget.isNearbyTab
                  ? 'Chưa có bài viết gần đây'
                  : 'Chưa có bài viết từ bạn bè',
              style: const TextStyle(
                fontFamily: '.SF Pro Display',
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
                fontSize: 20,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 0.8.h),

            // Description - iOS Style
            // Description
            Text(
              widget.isNearbyTab
                  ? 'Hãy là người đầu tiên chia sẻ trải nghiệm billiards!'
                  : 'Kết nối với những người chơi billiards khác.',
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
                fontSize: 15,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 3.h),

            // Action buttons - iOS style với AppButton
            Column(
              children: [
                AppButton(
                  label: 'Tạo bài viết đầu tiên',
                  type: AppButtonType.primary,
                  size: AppButtonSize.large,
                  icon: Icons.add,
                  iconTrailing: false,
                  fullWidth: true,
                  onPressed: widget.onCreatePost,
                ),
                if (!widget.isNearbyTab) ...[
                  SizedBox(height: 2.h),
                  AppButton(
                    label: 'Tìm bạn bè',
                    type: AppButtonType.outline,
                    size: AppButtonSize.large,
                    icon: Icons.people,
                    iconTrailing: false,
                    fullWidth: true,
                    onPressed: widget.onFindFriends,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
