import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/user_achievement.dart';
import '../../../theme/app_theme.dart';

class AchievementCardWidget extends StatelessWidget {
  final UserAchievement achievement;
  final VoidCallback? onTap;

  const AchievementCardWidget({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = achievement.isCompleted;
    final double progress = achievement.progressPercentage;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.sp),
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.amber[50]!, Colors.orange[50]!]
              : [Colors.grey[50]!, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isCompleted ? Colors.amber[200]! : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.sp),
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Achievement Icon with animation-ready styling
                    Container(
                      width: 48.sp,
                      height: 48.sp,
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  Colors.amber[400]!,
                                  Colors.orange[400]!
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.grey[300]!, Colors.grey[200]!],
                              ),
                        borderRadius: BorderRadius.circular(12.sp),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.emoji_events_rounded
                            : Icons.emoji_events_outlined,
                        color: isCompleted ? Colors.white : Colors.grey[500],
                        size: 24.sp,
                      ),
                    ),

                    SizedBox(width: 12.sp),

                    // Achievement Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryLight,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondaryLight,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.sp),

                    // Status Badge
                    if (isCompleted)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.sp,
                          vertical: 5.sp,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.teal[400]!],
                          ),
                          borderRadius: BorderRadius.circular(16.sp),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4.sp),
                            Text(
                              'Hoàn thành',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 16.sp),

                // Progress Section with better styling
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.sp),
                    border: Border.all(
                      color:
                          isCompleted ? Colors.green[200]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiến độ hoàn thành',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.sp,
                              vertical: 4.sp,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6.sp),
                            ),
                            child: Text(
                              '${achievement.progressCurrent}/${achievement.progressRequired}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? Colors.green[700]
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8.sp),

                      // Styled progress bar
                      Stack(
                        children: [
                          Container(
                            height: 8.sp,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4.sp),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 8.sp,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isCompleted
                                      ? [Colors.green[400]!, Colors.teal[400]!]
                                      : [
                                          AppTheme.primaryLight,
                                          AppTheme.primaryLight
                                              .withValues(alpha: 0.7),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(4.sp),
                                boxShadow: [
                                  BoxShadow(
                                    color: isCompleted
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : AppTheme.primaryLight
                                            .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 6.sp),

                      // Progress percentage
                      Text(
                        '${(progress * 100).toInt()}% hoàn thành',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                // Achievement Type & Rewards in one row
                if (achievement.isCompleted) ...[
                  SizedBox(height: 12.sp),
                  Container(
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.teal[50]!],
                      ),
                      borderRadius: BorderRadius.circular(10.sp),
                      border: Border.all(
                        color: Colors.green[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.card_giftcard_rounded,
                          size: 24.sp,
                          color: Colors.green[600],
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phần thưởng đã nhận',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              SizedBox(height: 2.sp),
                              Text(
                                '${achievement.rewardVoucherIds?.length ?? 0} voucher khuyến mãi',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (achievement.completedAt != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.sp,
                              vertical: 4.sp,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.sp),
                            ),
                            child: Text(
                              '${achievement.completedAt!.day}/${achievement.completedAt!.month}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 12.sp),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.sp,
                          vertical: 6.sp,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getTypeColor().withValues(alpha: 0.2),
                              _getTypeColor().withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.sp),
                          border: Border.all(
                            color: _getTypeColor().withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTypeIcon(),
                              size: 14.sp,
                              color: _getTypeColor(),
                            ),
                            SizedBox(width: 4.sp),
                            Text(
                              _getTypeText(),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: _getTypeColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Tiếp tục phấn đấu!',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ], // Closes Column children
            ), // Closes Column
          ), // Closes Padding
        ), // Closes InkWell
      ), // Closes Material
    ); // Closes Container
  }

  Color _getTypeColor() {
    switch (achievement.type) {
      case AchievementType.matchesPlayed:
      case AchievementType.matchesWon:
        return Colors.blue[600]!;
      case AchievementType.tournamentsJoined:
      case AchievementType.tournamentsWon:
        return Colors.purple[600]!;
      case AchievementType.clubVisits:
        return Colors.orange[600]!;
      case AchievementType.consecutiveDays:
        return Colors.green[600]!;
      case AchievementType.spendingMilestone:
        return Colors.amber[700]!;
      case AchievementType.socialEngagement:
        return Colors.pink[600]!;
      case AchievementType.referralSuccess:
        return Colors.teal[600]!;
      case AchievementType.skillImprovement:
        return Colors.indigo[600]!;
    }
  }

  IconData _getTypeIcon() {
    switch (achievement.type) {
      case AchievementType.matchesPlayed:
        return Icons.sports_esports_rounded;
      case AchievementType.matchesWon:
        return Icons.emoji_events_rounded;
      case AchievementType.tournamentsJoined:
        return Icons.event_rounded;
      case AchievementType.tournamentsWon:
        return Icons.military_tech_rounded;
      case AchievementType.clubVisits:
        return Icons.store_rounded;
      case AchievementType.consecutiveDays:
        return Icons.calendar_today_rounded;
      case AchievementType.spendingMilestone:
        return Icons.savings_rounded;
      case AchievementType.socialEngagement:
        return Icons.people_rounded;
      case AchievementType.referralSuccess:
        return Icons.share_rounded;
      case AchievementType.skillImprovement:
        return Icons.trending_up_rounded;
    }
  }

  String _getTypeText() {
    switch (achievement.type) {
      case AchievementType.matchesPlayed:
        return 'Trận đấu';
      case AchievementType.matchesWon:
        return 'Chiến thắng';
      case AchievementType.tournamentsJoined:
        return 'Giải đấu';
      case AchievementType.tournamentsWon:
        return 'Vô địch';
      case AchievementType.clubVisits:
        return 'Ghé thăm CLB';
      case AchievementType.consecutiveDays:
        return 'Liên tiếp';
      case AchievementType.spendingMilestone:
        return 'Chi tiêu';
      case AchievementType.socialEngagement:
        return 'Tương tác';
      case AchievementType.referralSuccess:
        return 'Giới thiệu';
      case AchievementType.skillImprovement:
        return 'Kỹ năng';
    }
  }
}
