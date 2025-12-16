import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';

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
          'Quản lý hạng', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Lỗi tải thông tin', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.headlineSmall
                        ?.copyWith(fontFamily: '.SF Pro Display'),
                  ),
                  SizedBox(height: 1.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center, style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    child: const Text(
                      'Thử lại', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: '.SF Pro Text'),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Rank Status
                  _buildCurrentRankCard(),

                  SizedBox(height: 3.h),

                  // Quick Actions
                  _buildQuickActions(),

                  SizedBox(height: 3.h),

                  // My Clubs Section (giữ lại từ tính năng cũ)
                  _buildMyClubsSection(),

                  SizedBox(height: 3.h),

                  // Rank History (nếu có)
                  _buildRankHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentRankCard() {
    final hasRank =
        _currentUser?.rank != null &&
        _currentUser!.rank!.isNotEmpty &&
        _currentUser!.rank != 'unranked';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasRank
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (hasRank ? Colors.green : Colors.orange).withValues(
              alpha: 0.3,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasRank ? Icons.emoji_events : Icons.help_outline,
                  color: Colors.white,
                  size: 8.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasRank ? 'Hạng hiện tại' : 'Chưa có hạng', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: '.SF Pro Display',
                          ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      hasRank
                          ? _currentUser!.rank!
                          : 'Chưa đăng ký hạng thi đấu', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: '.SF Pro Display',
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!hasRank) ...[
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Đăng ký hạng để tham gia các trận đấu ranked và được xếp hạng chính xác', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontFamily: '.SF Pro Text',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final hasRank =
        _currentUser?.rank != null &&
        _currentUser!.rank!.isNotEmpty &&
        _currentUser!.rank != 'unranked';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tính năng hạng', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: '.SF Pro Display',
          ),
        ),

        SizedBox(height: 2.h),

        // Action Cards Grid
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: hasRank ? Icons.edit : Icons.add_circle,
                title: hasRank ? 'Thay đổi hạng' : 'Đăng ký hạng',
                subtitle: hasRank
                    ? 'Yêu cầu thay đổi hạng'
                    : 'Đăng ký hạng mới',
                color: hasRank ? Colors.blue : Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
                },
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'Thống kê hạng',
                subtitle: 'Xem lịch sử & thống kê',
                color: Colors.purple,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.rankStatisticsScreen);
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.leaderboard,
                title: 'Bảng xếp hạng',
                subtitle: 'Xem vị trí của bạn',
                color: Colors.amber,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.leaderboardScreen);
                },
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.help_outline,
                title: 'Hướng dẫn',
                subtitle: 'Tìm hiểu về hệ thống hạng',
                color: Colors.teal,
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
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 6.w),
            ),
            SizedBox(height: 1.5.h),
            Text(
              title, style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Display',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Text(
              subtitle, style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                fontFamily: '.SF Pro Text',
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
              'Câu lạc bộ của tôi', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: '.SF Pro Display',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/my_clubs');
              },
              child: const Text(
                'Xem tất cả', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: '.SF Pro Text'),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.store,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý câu lạc bộ', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: '.SF Pro Display',
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Xem danh sách CLB đã tham gia và quản lý', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
                size: 4.w,
              ),
            ],
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
          'Lịch sử hạng', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: '.SF Pro Display',
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
                size: 8.w,
              ),
              SizedBox(height: 1.h),
              Text(
                'Chưa có lịch sử', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                  fontFamily: '.SF Pro Display',
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Lịch sử thay đổi hạng sẽ hiển thị tại đây', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
                  fontFamily: '.SF Pro Text',
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
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(width: 2.w),
            const Text(
              'Hệ thống xếp hạng', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: '.SF Pro Display'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hệ thống xếp hạng Sabo Arena giúp bạn:', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Display',
                ),
              ),
              SizedBox(height: 1.h),
              _buildInfoItem('🎯', 'Xác định trình độ chính xác'),
              _buildInfoItem('⚔️', 'Tìm đối thủ cùng trình độ'),
              _buildInfoItem('🏆', 'Tham gia giải đấu ranked'),
              _buildInfoItem('📊', 'Theo dõi tiến bộ của bản thân'),
              _buildInfoItem('💎', 'Nhận phần thưởng xứng đáng'),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hạng của bạn được đánh giá bởi club owner hoặc admin dựa trên kỹ năng thực tế.', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đóng', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: '.SF Pro Text'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
            },
            child: const Text(
              'Đăng ký hạng', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: '.SF Pro Text'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text, style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
