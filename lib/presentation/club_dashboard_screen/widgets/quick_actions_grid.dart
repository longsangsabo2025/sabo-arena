import 'package:flutter/material.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/core/design_system/responsive_grid.dart';

class QuickActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;

  QuickActionItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });
}

class QuickActionsGrid extends StatelessWidget {
  final List<QuickActionItem> actions;

  const QuickActionsGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      items: actions,
      itemBuilder: (context, action, index) {
        return _buildQuickActionItem(action);
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      spacing: DesignTokens.space12,
      runSpacing: DesignTokens.space12,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActionItem(QuickActionItem action) {
    return DSCard.elevated(
      onTap: action.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
              ),
              child: Icon(
                action.icon,
                color: action.iconColor,
                size: AppIcons.sizeMD,
              ),
            ),
            SizedBox(width: DesignTokens.space12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (action.badge != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space8,
                  vertical: DesignTokens.space4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                ),
                child: Text(
                  action.badge!,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
