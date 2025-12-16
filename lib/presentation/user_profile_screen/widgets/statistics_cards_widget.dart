import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../widgets/rank_change_request_dialog.dart';
import '../../../core/utils/rank_migration_helper.dart';
import '../../../core/app_export.dart' hide AppColors;
import '../../../core/design_system/design_system.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class StatisticsCardsWidget extends StatefulWidget {
  final String userId;

  const StatisticsCardsWidget({super.key, required this.userId});

  @override
  State<StatisticsCardsWidget> createState() => _StatisticsCardsWidgetState();
}

class _StatisticsCardsWidgetState extends State<StatisticsCardsWidget> {
  bool _isLoading = true;
  UserProfile? _userProfile;
  Map<String, int> _userStats = {};
  int _userRanking = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userProfile = await UserService.instance.getUserProfileById(
        widget.userId,
      );
      final userStats = await UserService.instance.getUserStats(widget.userId);
      final ranking = await UserService.instance.getUserRanking(widget.userId);

      setState(() {
        _userProfile = userProfile;
        _userStats = userStats;
        _userRanking = ranking;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.info600, // Facebook blue
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Không thể tải thống kê',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.error, // Facebook red
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface, // White background
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, // Facebook black
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Thắng',
                  value: '${_userProfile!.totalWins}',
                  subtitle:
                      '${_userProfile!.winRate.toStringAsFixed(1)}% tỷ lệ',
                  color: AppColors.success, // Facebook green
                  icon: 'emoji_events',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Thua',
                  value: '${_userProfile!.totalLosses}',
                  subtitle: '${_userStats['total_matches'] ?? 0} trận',
                  color: AppColors.error, // Facebook red
                  icon: 'trending_down',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Giải đấu',
                  value: '${_userProfile!.totalTournaments}',
                  subtitle: '0 chiến thắng',
                  color: AppColors.warning, // Facebook yellow
                  icon: 'military_tech',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildRankingCard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'ELO Rating',
                  value: '${_userProfile!.rankingPoints}',
                  subtitle: 'Ranking Points',
                  color: AppColors.info600, // Facebook blue
                  icon: 'trending_up',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Win Streak',
                  value: '${_userStats['win_streak'] ?? 0}',
                  subtitle: 'Liên tiếp',
                  color: AppColors.warning, // Facebook yellow
                  icon: 'local_fire_department',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard() {
    // Kiểm tra xem user có rank từ database hay không
    final userRank = _userProfile?.rank;
    final hasRank =
        userRank != null && userRank.isNotEmpty && userRank != 'unranked';

    if (!hasRank) {
      // User chưa có rank - hiển thị card đăng ký rank
      return GestureDetector(
        onTap: () => _showRankRegistrationDialog(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning50, // Light orange background
            border: Border.all(
              color: AppColors.warning, // Facebook yellow/orange
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Xếp hạng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary, // Facebook gray
                    ),
                  ),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'leaderboard',
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.priority_high,
                          color: AppColors.textOnPrimary,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Chưa đăng ký',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nhấn để đăng ký',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User có rank - hiển thị card với option thay đổi rank
    return GestureDetector(
      onTap: () => _showRankChangeDialog(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surface, // White background
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
            bottom: BorderSide(color: AppColors.border, width: 0.5),
            left: BorderSide(color: AppColors.border, width: 0.5),
            right: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Xếp hạng',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary, // Facebook gray
                  ),
                ),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'leaderboard',
                      color: AppColors.premium, // Purple
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.swap_vert,
                      color: AppColors.info600, // Facebook blue
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${_userRanking > 0 ? _userRanking : 'N/A'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.premium, // Purple
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_userProfile!.rankingPoints} điểm',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info50, // Light blue background
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.info600.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Hạng: ${RankMigrationHelper.getNewDisplayName(userRank)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Text(
                    'Nhấn để thay đổi',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.info600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRankRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
          title: const Text(
            'Đăng ký Rank',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn chưa có rank chính thức. Để xem thống kê xếp hạng chính xác và tham gia các trận đấu ranked, hãy đăng ký rank ngay!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning50, // Light orange
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sau khi đăng ký, bạn sẽ có thể theo dõi xếp hạng chính xác của mình.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Để sau',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToRankRegistration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info600,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text(
              'Đăng ký ngay',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRankRegistration() {
    // Since this is user profile, we need to show club selection first
    // For now show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vui lòng vào trang club cụ thể để đăng ký rank'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surface, // White background
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
          left: BorderSide(color: AppColors.border, width: 0.5),
          right: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary, // Facebook gray
                ),
              ),
              CustomIconWidget(iconName: icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRankChangeDialog() {
    if (_userProfile == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RankChangeRequestDialog(
          userProfile: _userProfile!,
          onRequestSubmitted: () {
            // Optional: Refresh data
            _loadStatistics();
          },
        );
      },
    );
  }
}

