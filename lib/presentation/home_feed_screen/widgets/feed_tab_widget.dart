import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FeedTabWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const FeedTabWidget({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              context,
              title: 'Gần đây',
              icon: 'location_on',
              index: 0,
              isSelected: selectedIndex == 0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              context,
              title: 'Đang theo dõi',
              icon: 'people',
              index: 1,
              isSelected: selectedIndex == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String title,
    required String icon,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => onTabChanged(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 16,
            ),
            SizedBox(width: 1.5.w),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
