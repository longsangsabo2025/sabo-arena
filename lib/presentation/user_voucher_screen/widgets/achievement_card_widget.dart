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
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.sp),
        child: Container(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Achievement Icon
                  Container(
                    width: 48.sp,
                    height: 48.sp,
                    decoration: BoxDecoration(
                      color: achievement.isCompleted
                          ? const Color(0xFFFFD700).withValues(
                              alpha: 0.2,
                            ) // Gold color
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Icon(
                      achievement.isCompleted
                          ? Icons.emoji_events
                          : Icons.emoji_events_outlined,
                      color: achievement.isCompleted
                          ? const Color(0xFFFFD700) // Gold color
                          : Colors.grey,
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
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          achievement.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  if (achievement.isCompleted)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.sp,
                        vertical: 4.sp,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.sp),
                      ),
                      child: Text(
                        'Hoàn thành',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 12.sp),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '${achievement.progressCurrent}/${achievement.progressRequired}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: achievement.isCompleted
                              ? Colors.green
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.sp),

                  LinearProgressIndicator(
                    value: achievement.progressPercentage,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievement.isCompleted
                          ? Colors.green
                          : AppTheme.primaryLight,
                    ),
                    minHeight: 6.sp,
                  ),
                ],
              ),

              // Achievement Type & Completion Date
              SizedBox(height: 8.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.sp,
                      vertical: 2.sp,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    child: Text(
                      _getTypeText(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _getTypeColor(),
                      ),
                    ),
                  ),

                  if (achievement.isCompleted &&
                      achievement.completedAt != null)
                    Text(
                      'Hoàn thành: ${achievement.completedAt!.day}/${achievement.completedAt!.month}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                ],
              ),

              // Rewards Info
              if (achievement.isCompleted &&
                  achievement.rewardVoucherIds?.isNotEmpty == true)
                Container(
                  margin: EdgeInsets.only(top: 8.sp),
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.sp),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer, size: 16.sp, color: Colors.green),
                      SizedBox(width: 6.sp),
                      Text(
                        'Đã nhận ${achievement.rewardVoucherIds!.length} voucher',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (achievement.type) {
      case AchievementType.matchesPlayed:
      case AchievementType.matchesWon:
        return Colors.blue;
      case AchievementType.tournamentsJoined:
      case AchievementType.tournamentsWon:
        return Colors.purple;
      case AchievementType.clubVisits:
        return Colors.orange;
      case AchievementType.consecutiveDays:
        return Colors.green;
      case AchievementType.spendingMilestone:
        return Colors.amber;
      case AchievementType.socialEngagement:
        return Colors.pink;
      case AchievementType.referralSuccess:
        return Colors.teal;
      case AchievementType.skillImprovement:
        return Colors.indigo;
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
