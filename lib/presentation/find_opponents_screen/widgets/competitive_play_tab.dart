import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../../core/app_export.dart' hide AppColors;
import '../../../core/design_system/design_system.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_state_widget.dart';
import './player_card_widget.dart';
import './create_spa_challenge_modal.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class CompetitivePlayTab extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<UserProfile> players;
  final bool isMapView;
  final VoidCallback onRefresh;

  const CompetitivePlayTab({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.players,
    required this.isMapView,
    required this.onRefresh,
  });

  @override
  State<CompetitivePlayTab> createState() => _CompetitivePlayTabState();
}

class _CompetitivePlayTabState extends State<CompetitivePlayTab> {
  final UserService _userService = UserService.instance;
  UserProfile? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userProfile = await _userService.getCurrentUserProfile();
        if (mounted) {
          setState(() {
            _currentUser = userProfile;
            _isLoadingUser = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  bool get _hasRank {
    if (_currentUser == null) return false;
    final userRank = _currentUser!.rank;
    return userRank != null && userRank.isNotEmpty && userRank != 'unranked';
  }

  Widget _buildRankStatusBanner(BuildContext context) {
    if (_currentUser == null) {
      return _buildCompactBanner(
        context,
        icon: Icons.info_outline,
        iconColor: AppColors.textTertiary, // Muted gray-green
        backgroundColor: AppColors.gray50, // Very light gray-green
        borderColor: AppColors.border, // Light gray-green border
        text: 'Đăng ký hạng để tham gia thách đấu có bonus điểm SPA',
        showInfoButton: true,
      );
    }

    if (_hasRank) {
      return _buildCompactBanner(
        context,
        icon: Icons.check_circle,
        iconColor: AppColors.success900, // Dark forest green
        backgroundColor: AppColors.success50, // Very light green
        borderColor: AppColors.success200, // Light green border
        text:
            'Hạng hiện tại: ${_currentUser!.rank} - Có thể thách đấu cược SPA',
        textColor: AppColors.success800,
        fontWeight: FontWeight.w600,
        showInfoButton: true,
      );
    }

    return _buildCompactBanner(
      context,
      icon: Icons.info_outline,
      iconColor: AppColors.warning600,
      backgroundColor: AppColors.warning50,
      borderColor: AppColors.warning200,
      text: 'Đăng ký hạng để tham gia thách đấu cược SPA',
      showInfoButton: true,
    );
  }

  void _navigateToRankRegistration(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
  }

  void _showCreateChallengeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CreateSpaChallengeModal(
          currentUser: _currentUser,
          opponents: widget.players,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Info banner - always show rank status
          if (!_isLoadingUser) _buildRankStatusBanner(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => widget.onRefresh(),
              child: _buildBody(context),
            ),
          ),
        ],
      ),
      // Dynamic button based on rank status
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // Compact banner with info icon
  Widget _buildCompactBanner(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String text,
    Color? textColor,
    FontWeight? fontWeight,
    bool showInfoButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: fontWeight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showInfoButton) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showSPAChallengeInfo(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, size: 18, color: iconColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Show detailed explanation dialog - iOS Facebook 2025 Style
  void _showSPAChallengeInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.gray50, // Facebook background
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.warning500, AppColors.warning700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: AppColors.textOnPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thách đấu có cược SPA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Chế độ thi đấu chính thức',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // What is SPA Challenge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thách đấu cược SPA là gì?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chế độ thi đấu chính thức với cược điểm SPA (Sabo Points Arena). Cả 2 người đặt cược, người thắng nhận toàn bộ.',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Stakes & Rules
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('💰', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                'Mức cược & Điều kiện',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildModernInfoRow(
                            '💎',
                            '100-600 SPA',
                            '6 mức cược khác nhau',
                          ),
                          _buildModernInfoRow(
                            '🎯',
                            'Race-to: 8-22',
                            'Tùy mức cược',
                          ),
                          _buildModernInfoRow(
                            '🏆',
                            'Thắng',
                            'Nhận toàn bộ 2× cược',
                          ),
                          _buildModernInfoRow(
                            '❌',
                            'Thua',
                            'Mất số SPA đã cược',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Handicap System
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.info600.withValues(alpha: 0.08),
                            AppColors.info600.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info600.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('⚖️', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                'Hệ thống Handicap SABO',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildHandicapPoint(
                            'Áp dụng handicap theo chênh lệch hạng',
                          ),
                          _buildHandicapPoint(
                            'Người yếu hơn được cộng điểm ban đầu',
                          ),
                          _buildHandicapPoint(
                            'Đảm bảo tính công bằng trong trận đấu',
                          ),
                          _buildHandicapPoint(
                            'VD: K vs H (chênh 4 hạng) → K +4 điểm',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Requirements
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warning500.withValues(alpha: 0.08),
                            AppColors.warning700.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning500.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('📋', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                'Yêu cầu tham gia',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRequirementPoint('Đã đăng ký hạng chính thức'),
                          _buildRequirementPoint(
                            'Đủ SPA để đặt cược (tối thiểu 100 SPA)',
                          ),
                          _buildRequirementPoint(
                            'Chênh lệch tối đa ±2 hạng chính (±4 phụ hạng)',
                          ),
                          _buildRequirementPoint(
                            'Kết quả xác nhận bởi cả 2 người chơi',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Important Notice about SPA
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning50, // Light orange background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning500,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.warning500,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: AppColors.textOnPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lưu ý quan trọng',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'SPA là điểm thưởng do CLB phát hành, không phải tiền và không có giá trị quy đổi ra tiền. Chỉ có thể dùng để đổi quà, voucher, phần thưởng do CLB phân phối quy định từ trước.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Action
            if (!_hasRank)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToRankRegistration(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info600,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Đăng ký hạng ngay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(
    String emoji,
    String title,
    String subtitle, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandicapPoint(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppColors.info600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementPoint(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppColors.warning500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (_isLoadingUser) {
      return FloatingActionButton(
        heroTag: 'competitive_play_loading',
        onPressed: null,
        backgroundColor: AppColors.textTertiary, // Muted gray-green
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textOnPrimary,
        ),
      );
    }

    if (_hasRank) {
      // User has rank - show create challenge button
      return FloatingActionButton.extended(
        heroTag: 'competitive_play_create_challenge',
        onPressed: () => _showCreateChallengeModal(context),
        backgroundColor: AppColors.success900, // Dark forest green
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.sports_martial_arts),
        label: const Text('Tạo thách đấu'),
      );
    } else {
      // User doesn't have rank - show register rank button
      return FloatingActionButton.extended(
        heroTag: 'competitive_play_register_rank',
        onPressed: () => _navigateToRankRegistration(context),
        backgroundColor: AppColors.success800, // Darker muted green
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.emoji_events),
        label: const Text('Đăng ký hạng'),
      );
    }
  }

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return const LoadingStateWidget(
        message: 'Đang tìm đối thủ để thách đấu cược SPA...',
      );
    }

    if (widget.errorMessage != null) {
      return RefreshableErrorStateWidget(
        errorMessage: widget.errorMessage,
        onRefresh: () async => widget.onRefresh(),
        title: 'Không thể tìm đối thủ',
        description: 'Đã xảy ra lỗi khi tìm kiếm đối thủ gần bạn',
        showErrorDetails: true,
      );
    }

    if (widget.players.isEmpty) {
      return RefreshableEmptyStateWidget(
        message: 'Không có đối thủ nào ở gần',
        subtitle: 'Thử mở rộng khoảng cách hoặc thay đổi bộ lọc',
        icon: Icons.sports_esports,
        onRefresh: () async => widget.onRefresh(),
      );
    }

    return Column(
      children: [
        // Ranking filters - HIDDEN for cleaner billiards UI
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 16),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: _buildRankingFilter('Tương đương', Icons.balance, Colors.green),
        //       ),
        //       const SizedBox(width: 8),
        //       Expanded(
        //         child: _buildRankingFilter('Cao hơn', Icons.trending_up, Colors.red),
        //       ),
        //       const SizedBox(width: 8),
        //       Expanded(
        //         child: _buildRankingFilter('Thấp hơn', Icons.trending_down, Colors.blue),
        //       ),
        //     ],
        //   ),
        // ),
        // const SizedBox(height: 16),
        // Players list (map view disabled for privacy)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            itemCount: widget.players.length,
            itemBuilder: (context, index) {
              return PlayerCardWidget(
                player: widget.players[index],
                mode: 'thach_dau',
                challengeInfo: _getChallengeInfo(widget.players[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankingFilter(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getChallengeInfo(UserProfile player) {
    // Use actual player data for accurate display
    return {
      'spaBonus': 300, // Default SPA bonus for challenges
      'raceTo': 14, // Default race to value
      'playTime': '19:00-21:00', // Default play time
      'availability': player.isActive ? 'Rảnh' : 'Bận',
      'rank': player.rank ?? 'Chưa xếp hạng',
      'displayName': player.displayName,
      'joinedDate': player.createdAt.toString().split(' ')[0],
      'location': player.location ?? 'Chưa cập nhật',
      'skillLevel': player.skillLevel,
      'eloRating': player.eloRating,
      'totalWins': player.totalWins,
      'totalLosses': player.totalLosses,
    };
  }
}

