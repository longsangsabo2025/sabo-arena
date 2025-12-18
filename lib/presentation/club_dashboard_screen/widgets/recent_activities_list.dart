import 'package:flutter/material.dart';
// Temporarily removed AppLocalizations import
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/models/club_activity.dart';

class RecentActivitiesList extends StatelessWidget {
  final List<ClubActivity> activities;
  final bool showAnimation;

  const RecentActivitiesList({
    super.key,
    required this.activities,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;

    if (activities.isEmpty) {
      return DSEmptyState(
        icon: AppIcons.event,
        title: "Chưa có hoạt động",
        description: "Các hoạt động mới của CLB sẽ hiển thị tại đây",
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length > 5 ? 5 : activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityItem(context, activity, index);
      },
    );
  }

  Widget _buildActivityItem(BuildContext context, ClubActivity activity, int index) {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    String title = '';
    String subtitle = '';

    switch (activity.type) {
      case 'member_join':
        title = "Thành viên mới";
        subtitle = '${activity.data['userName']} đã tham gia CLB';
        break;
      case 'tournament_start':
        title = "Giải đấu bắt đầu";
        subtitle = '${activity.data['tournamentName']} đã bắt đầu';
        break;
      case 'tournament_end':
        title = "Giải đấu kết thúc";
        subtitle = '${activity.data['tournamentName']} đã kết thúc';
        break;
      default:
        title = 'Hoạt động';
        subtitle = '';
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: DesignTokens.curveStandard,
      tween: Tween(begin: 0.0, end: showAnimation ? 1.0 : 0.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue,
            child: DSCard.outlined(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space12,
                  vertical: DesignTokens.space12,
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.add,
                            color: AppColors.success,
                            size: AppIcons.sizeMD,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getActivityColor(activity.type),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              _getActivityIcon(activity.type),
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: DesignTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: DesignTokens.space4),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: DesignTokens.space8),
                    Text(
                      _formatTimeAgo(activity.timestamp),
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'member_join':
        return AppColors.success;
      case 'tournament_end':
        return AppColors.info;
      case 'tournament_start':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'member_join':
        return AppIcons.add;
      case 'tournament_end':
        return AppIcons.trophy;
      case 'tournament_start':
        return Icons.play_arrow;
      default:
        return AppIcons.info;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}p';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
