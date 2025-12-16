import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

/// Profile Stats Compact Widget - Facebook 2025 Style
/// Displays user statistics in a 2-column grid format
/// Positioned below SPA Points in ProfileHeaderWidget
class ProfileStatsCompactWidget extends StatelessWidget {
  final int wins;
  final int losses;
  final int tournaments;
  final int ranking;
  final int eloRating;
  final int winStreak;

  const ProfileStatsCompactWidget({
    super.key,
    required this.wins,
    required this.losses,
    required this.tournaments,
    required this.ranking,
    required this.eloRating,
    required this.winStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thống kê',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to full stats screen
                },
                child: Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Grid - 2 columns, 3 rows
          Column(
            children: [
              // Row 1: Wins & Losses
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.emoji_events,
                      iconColor: const Color(0xFF45BD62), // Green
                      label: 'Thắng',
                      value: wins.toString(),
                      subtitle: 'trận',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: 'trending_down',
                      iconColor: const Color(0xFFF3425F), // Red
                      label: 'Thua',
                      value: losses.toString(),
                      subtitle: '5 trận',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Row 2: Tournaments & Ranking
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: 'emoji_events',
                      iconColor: const Color(0xFFF7B928), // Yellow
                      label: 'Giải đấu',
                      value: tournaments.toString(),
                      subtitle: '0 chiến thắng',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: 'bar_chart',
                      iconColor: const Color(0xFF9B51E0), // Purple
                      label: 'Xếp hạng',
                      value: '#$ranking',
                      subtitle: '1735 điểm',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Row 3: ELO & Win Streak
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: 'trending_up',
                      iconColor: const Color(0xFF0866FF), // Blue
                      label: 'ELO Rating',
                      value: eloRating.toString(),
                      subtitle: 'Ranking Points',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: 'local_fire_department',
                      iconColor: const Color(0xFFF7B928), // Yellow/Orange
                      label: 'Win Streak',
                      value: winStreak.toString(),
                      subtitle: 'Liên tiếp',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Label row
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: icon,
                    color: iconColor,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 2),
          
          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
