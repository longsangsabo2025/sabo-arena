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
        color: const Color(0xFFFFFFFF), // White
        border: Border(
          top: BorderSide(color: const Color(0xFFE4E6EB), width: 0.5),
          bottom: BorderSide(color: const Color(0xFFE4E6EB), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thống kê',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF050505),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to full stats screen
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0866FF),
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
                      icon: 'emoji_events',
                      iconColor: const Color(0xFF45BD62), // Green
                      label: 'Thắng',
                      value: wins.toString(),
                      subtitle: '60.0% tỷ lệ',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
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

  Widget _buildStatCard({
    required String icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5), // Light gray background
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF65676B), // Gray
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF050505), // Black
            ),
          ),

          const SizedBox(height: 2),

          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF65676B), // Gray
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
