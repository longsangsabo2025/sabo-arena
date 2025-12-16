import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';

/// Widget hiển thị 3 sub-tabs cho phần "Bài đăng" trong Profile
/// - Bài viết: Tất cả posts (có/không có ảnh)
/// - Hình ảnh: Chỉ posts có ảnh
/// - Highlight: Videos (YouTube links)
class PostsSubTabNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const PostsSubTabNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(
            context,
            index: 0,
            icon: Icons.article_outlined,
            label: 'Bài viết',
            isSelected: currentIndex == 0,
          ),
          _buildTabItem(
            context,
            index: 1,
            icon: Icons.image_outlined,
            label: 'Hình ảnh',
            isSelected: currentIndex == 1,
          ),
          _buildTabItem(
            context,
            index: 2,
            icon: Icons.play_circle_outline,
            label: 'Highlight',
            isSelected: currentIndex == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onTabChanged(index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
