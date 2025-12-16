import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';

class BulkActionBar extends StatelessWidget {
  final int selectedCount;
  final Function(String) onAction;
  final VoidCallback onClear;

  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.onAction,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selection count with icon
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$selectedCount',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'đã chọn',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            Spacer(),

            // Action buttons - horizontal scroll for small screens
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DSButton.secondary(
                      text: 'Nhắn tin',
                      onPressed: () => onAction('message'),
                      size: DSButtonSize.small,
                      leadingIcon: Icons.chat_bubble_outline,
                    ),

                    SizedBox(width: 8),

                    DSButton.secondary(
                      text: 'Thăng cấp',
                      onPressed: () => onAction('promote'),
                      size: DSButtonSize.small,
                      leadingIcon: Icons.trending_up,
                    ),

                    SizedBox(width: 8),

                    DSButton.secondary(
                      text: 'Xuất',
                      onPressed: () => onAction('export'),
                      size: DSButtonSize.small,
                      leadingIcon: Icons.file_download_outlined,
                    ),

                    SizedBox(width: 8),

                    // More actions menu
                    _buildMoreMenu(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
      onSelected: onAction,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: Offset(0, 8),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'change-membership',
          child: Row(
            children: [
              Icon(
                Icons.card_membership,
                size: 18,
                color: AppColors.textPrimary,
              ),
              SizedBox(width: 12),
              Text(
                'Thay đổi loại thành viên',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'suspend',
          child: Row(
            children: [
              Icon(Icons.block, size: 18, color: AppColors.warning),
              SizedBox(width: 12),
              Text(
                'Tạm khóa',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: 12),
              Text(
                'Xóa khỏi CLB',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
      tooltip: 'Thêm hành động',
    );
  }
}
