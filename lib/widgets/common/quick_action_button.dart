/// Quick Action Button Widget
///
/// Standardized button for quick actions in dashboard
/// Supports icons, labels, badges, and color customization

import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import 'app_card.dart';

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final bool showBorder;
  final double? width;
  final double? height;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
    this.showBorder = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final buttonHeight =
        height ?? (isMobile ? 110.0 : 130.0); // Increased from 100/120

    return SizedBox(
      width: width,
      height: buttonHeight,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.all(AppSpacing.sm), // Reduced from md to sm
        border: showBorder
            ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 24 : 28),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.caption(
                          color: Colors.white,
                        ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: AppSpacing.sm),

            // Label
            Text(
              label,
              style: AppTypography.labelMedium().copyWith(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal Quick Action Button
class QuickActionButtonHorizontal extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const QuickActionButtonHorizontal({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: AppIconSize.md),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(width: AppSpacing.md),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelLarge(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Arrow
          Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: AppIconSize.sm,
          ),
        ],
      ),
    );
  }
}

/// Quick Action Category Section
class QuickActionCategory extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final VoidCallback? onSeeAll;

  const QuickActionCategory({
    super.key,
    required this.title,
    required this.actions,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.h6()),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  'Xem tất cả',
                  style: AppTypography.labelMedium(color: AppColors.primary),
                ),
              ),
          ],
        ),

        SizedBox(height: AppSpacing.md),

        // Actions
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: actions,
        ),
      ],
    );
  }
}
