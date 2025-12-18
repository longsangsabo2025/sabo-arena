import 'package:flutter/material.dart';
// Temporarily removed AppLocalizations import
import 'package:intl/intl.dart';
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/core/device/device_info.dart';
import 'package:sabo_arena/models/club_dashboard_stats.dart';

class DashboardStatsWidget extends StatelessWidget {
  final ClubDashboardStats stats;
  final int activityCount;
  final bool showAnimation;

  const DashboardStatsWidget({
    super.key,
    required this.stats,
    required this.activityCount,
    this.showAnimation = true,
  });

  String _formatRevenue(double revenue) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return currencyFormat.format(revenue);
  }

  @override
  Widget build(BuildContext context) {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    final isMobile = !DeviceInfo.isIPad(context);

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Thành viên",
                  '${stats.activeMembers}',
                  icon: Icons.people,
                  color: AppColors.primary,
                  index: 0,
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _buildStatCard(
                  "Giải đấu",
                  '${stats.totalTournaments}',
                  icon: AppIcons.trophy,
                  color: AppColors.secondary,
                  index: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Doanh thu",
                  _formatRevenue(stats.monthlyRevenue),
                  icon: Icons.attach_money,
                  color: AppColors.success,
                  index: 2,
                ),
              ),
              SizedBox(width: DesignTokens.space12),
              Expanded(
                child: _buildStatCard(
                  "Hoạt động",
                  '$activityCount',
                  icon: Icons.history,
                  color: AppColors.info,
                  index: 3,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Thành viên",
            '${stats.activeMembers}',
            icon: Icons.people,
            color: AppColors.primary,
            index: 0,
          ),
        ),
        SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildStatCard(
            "Giải đấu",
            '${stats.totalTournaments}',
            icon: AppIcons.trophy,
            color: AppColors.secondary,
            index: 1,
          ),
        ),
        SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildStatCard(
            "Doanh thu",
            _formatRevenue(stats.monthlyRevenue),
            icon: Icons.attach_money,
            color: AppColors.success,
            index: 2,
          ),
        ),
        SizedBox(width: DesignTokens.space12),
        Expanded(
          child: _buildStatCard(
            "Hoạt động",
            '$activityCount',
            icon: Icons.history,
            color: AppColors.info,
            index: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {required IconData icon, required Color color, int index = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: DesignTokens.curveEmphasized,
      tween: Tween(begin: 0.0, end: showAnimation ? 1.0 : 0.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: DSCard.elevated(
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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSM,
                        ),
                      ),
                      child: Icon(icon, color: color, size: AppIcons.sizeMD),
                    ),
                    SizedBox(width: DesignTokens.space12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: AppTypography.headingMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: DesignTokens.space4),
                          Text(
                            label,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
}
