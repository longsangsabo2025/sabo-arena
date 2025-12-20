import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../core/design_system.dart' hide AppTypography;
import '../../core/design_system/typography.dart';
import '../../widgets/common/app_button.dart';
import '../../core/app_export.dart' hide AppColors, AppTypography;

class RankManagementScreen extends StatefulWidget {
  const RankManagementScreen({super.key});

  @override
  State<RankManagementScreen> createState() => _RankManagementScreenState();
}

class _RankManagementScreenState extends State<RankManagementScreen> {
  final UserService _userService = UserService.instance;
  UserProfile? _currentUser;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = await _userService.getCurrentUserProfile();

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Quản lý hạng',
          overflow: TextOverflow.ellipsis,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontFamily: '.SF Pro Display',
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi tải thông tin',
                          style: AppTypography.headingSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Thử lại',
                          type: AppButtonType.primary,
                          size: AppButtonSize.medium,
                          onPressed: _loadUserProfile,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Rank Status
                      _buildCurrentRankCard(),

                      const SizedBox(height: 16),

                      // Quick Actions
                      _buildQuickActions(),

                      const SizedBox(height: 16),

                      // My Clubs Section
                      _buildMyClubsSection(),

                      const SizedBox(height: 16),

                      // Rank History
                      _buildRankHistorySection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentRankCard() {
    final hasRank = _currentUser?.rank != null &&
        _currentUser!.rank!.isNotEmpty &&
        _currentUser!.rank != 'unranked';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasRank
              ? [AppColors.success, AppColors.successDark]
              : [AppColors.warning, AppColors.warningDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppElevation.level2,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasRank ? Icons.emoji_events : Icons.help_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasRank ? 'Hạng hiện tại' : 'Chưa có hạng',
                  style: AppTypography.bodyMediumMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasRank ? _currentUser!.rank! : 'Chưa đăng ký hạng thi đấu',
                  style: AppTypography.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final hasRank = _currentUser?.rank != null &&
        _currentUser!.rank!.isNotEmpty &&
        _currentUser!.rank != 'unranked';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tính năng hạng',
          style: AppTypography.headingSmall,
        ),
        const SizedBox(height: 12),
        // Action Cards Grid
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: hasRank ? Icons.edit : Icons.add_circle,
                title: hasRank ? 'Thay đổi hạng' : 'Đăng ký hạng',
                subtitle:
                    hasRank ? 'Yêu cầu thay đổi hạng' : 'Đăng ký hạng mới',
                color: hasRank ? AppColors.primary : AppColors.success,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'Thống kê hạng',
                subtitle: 'Xem lịch sử & thống kê',
                color: AppColors.categoryAnalytics,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.rankStatisticsScreen);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.leaderboard,
                title: 'Bảng xếp hạng',
                subtitle: 'Xem vị trí của bạn',
                color: AppColors.categoryTournament,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.leaderboardScreen);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                icon: Icons.help_outline,
                title: 'Hướng dẫn',
                subtitle: 'Tìm hiểu về hệ thống hạng',
                color: AppColors.info,
                onTap: () {
                  _showRankingSystemInfo();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          boxShadow: AppElevation.level1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.bodyMediumMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
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

  Widget _buildMyClubsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Câu lạc bộ của tôi',
              style: AppTypography.headingSmall,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/my_clubs');
              },
              child: Text(
                'Xem tất cả',
                style: AppTypography.bodyMediumMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/my_clubs');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border,
              ),
              boxShadow: AppElevation.level1,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.store,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý câu lạc bộ',
                        style: AppTypography.bodyMediumMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Xem danh sách CLB đã tham gia và quản lý',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử hạng',
          style: AppTypography.headingSmall,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: AppElevation.level1,
          ),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                color: AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có lịch sử',
                style: AppTypography.bodyMediumMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lịch sử thay đổi hạng sẽ hiển thị tại đây',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRankingSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Hệ thống xếp hạng',
              style: AppTypography.headingSmall,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hệ thống xếp hạng Sabo Arena giúp bạn:',
                style: AppTypography.bodyMediumMedium,
              ),
              const SizedBox(height: 12),
              _buildInfoItem('🎯', 'Xác định trình độ chính xác'),
              _buildInfoItem('⚔️', 'Tìm đối thủ cùng trình độ'),
              _buildInfoItem('🏆', 'Tham gia giải đấu ranked'),
              _buildInfoItem('📊', 'Theo dõi tiến bộ của bản thân'),
              _buildInfoItem('💎', 'Nhận phần thưởng xứng đáng'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Hạng của bạn được đánh giá bởi club owner hoặc admin dựa trên kỹ năng thực tế.',
                  style: AppTypography.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: 'Đóng',
            type: AppButtonType.secondary,
            size: AppButtonSize.medium,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            label: 'Đăng ký hạng',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
