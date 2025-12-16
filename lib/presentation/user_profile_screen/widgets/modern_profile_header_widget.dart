import 'package:flutter/material.dart';

import '../../../core/app_export.dart' hide AppColors;
import '../../../core/design_system/design_system.dart';
import '../../../core/performance/performance_widgets.dart';
import '../../../core/utils/sabo_rank_system.dart';
import '../../../widgets/user/user_widgets.dart';
import '../../../widgets/common/common_widgets.dart'; // Phase 4: AppButton & AppSnackbar
import '../elo_history_screen.dart';
import '../match_history_screen.dart';
import '../rank_history_screen.dart';
import '../spa_history_screen.dart';
import 'package:sabo_arena/widgets/common/universal_image_widget.dart';

/// Modern Profile Header Widget - Thiết kế giống ảnh tham khảo
/// Features:
/// - Cover photo với text overlay
/// - Rank badge shield style
/// - 4 metric cards (ELO, SPA, XH, TRẬN) trong 1 row
class ModernProfileHeaderWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onEditProfile;
  final VoidCallback? onCoverPhotoTap;
  final Function(int)? onTabChanged; // 0: Giải Đấu, 1: Trận Đấu, 2: Kết quả

  // Platform primary color - Teal Green (same as splash screen)
  static const Color primaryGreen = Color(0xFF00695C); // Teal Green

  const ModernProfileHeaderWidget({
    super.key,
    required this.userData,
    this.onEditProfile,
    this.onCoverPhotoTap,
    this.onTabChanged,
  });

  @override
  State<ModernProfileHeaderWidget> createState() =>
      _ModernProfileHeaderWidgetState();
}

class _ModernProfileHeaderWidgetState extends State<ModernProfileHeaderWidget> {
  // Tab state - 0: Giải Đấu, 1: Trận Đấu, 2: Kết quả
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface, // Clean white background like Facebook
      child: Column(
        children: [
          const SizedBox(height: 12), // Compact top spacing
          // Hero Section - Avatar Centered (includes social stats)
          _buildHeroSection(context),

          const SizedBox(height: 12), // Spacing before buttons
          // Action Buttons Row
          _buildActionButtons(context),

          const SizedBox(height: 12), // Spacing before stats
          // Stats Row with Icons
          _buildStatsRow(context),

          const SizedBox(height: 8), // Reduced spacing before tabs
          // Tournament/Match Tabs (moved below stats)
          _buildMainTabs(context),

          const SizedBox(height: 4), // Compact bottom spacing
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final bio =
        widget.userData["bio"] as String? ?? "🎱 Professional Pool Player";
    final currentRankCode = widget.userData["currentRankCode"] as String?;
    final bool hasRank = currentRankCode != null && currentRankCode.isNotEmpty;

    return Column(
      children: [
        // Avatar with gradient border and edit icon
        Stack(
          children: [
            UserAvatarWidget(
              avatarUrl: widget.userData["avatar"] as String?,
              rankCode: currentRankCode,
              size: 90,
              showRankBorder: hasRank,
            ),
            // Edit icon ở góc phải dưới avatar
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: widget.onEditProfile,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ModernProfileHeaderWidget.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.edit, size: 16, color: AppColors.textOnPrimary),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Name + Verified Badge
        UserDisplayNameText(
          userData: widget.userData,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          showVerifiedBadge: true,
        ),

        const SizedBox(height: 4),

        // Rank Badge (compact) - clickable button if no rank
        UserRankBadgeWidget(
          rankCode: currentRankCode,
          style: RankBadgeStyle.compact,
          onTap: hasRank ? null : () => _showRankRegistrationSheet(context),
        ),

        // Rank Progress Indicator (only show if user has rank)
        if (hasRank) _buildRankProgressIndicator(currentRankCode),

        const SizedBox(height: 8),

        // Bio
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary, // Facebook gray text
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 8), // Compact spacing
        // Followers, Following, Likes Row (Instagram style)
        _buildSocialStatsRow(context),
      ],
    );
  }

  Widget _buildSocialStatsRow(BuildContext context) {
    final followersCount = widget.userData["followersCount"] as int? ?? 1245;
    final followingCount = widget.userData["followingCount"] as int? ?? 328;
    final likesCount = widget.userData["likesCount"] as int? ?? 8560;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSocialStatItem(
            value: _formatNumber(followersCount),
            label: 'Followers',
            onTap: () {
              // TODO: Navigate to followers list
            },
          ),
          Container(
            width: 1,
            height: 30,
            color: AppColors.border, // Facebook divider
          ),
          _buildSocialStatItem(
            value: _formatNumber(followingCount),
            label: 'Following',
            onTap: () {
              // TODO: Navigate to following list
            },
          ),
          Container(
            width: 1,
            height: 30,
            color: AppColors.border, // Facebook divider
          ),
          _buildSocialStatItem(
            value: _formatNumber(likesCount),
            label: 'Likes',
            onTap: () {
              // TODO: Navigate to likes list
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialStatItem({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, // Facebook black
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary, // Facebook gray
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildStatsRow(BuildContext context) {
    final eloRating = widget.userData["eloRating"] as int?;
    final spaPoints = widget.userData["spaPoints"] as int? ?? 0;
    final ranking = widget.userData["ranking"] as int? ?? 0;
    final totalMatches = widget.userData["totalMatches"] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.emoji_events,
            value: eloRating != null ? eloRating.toString() : 'UnElo',
            label: 'ELO',
            color: ModernProfileHeaderWidget.primaryGreen, // Platform green
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.star,
            value: spaPoints.toString(),
            label: 'SPA',
            color: ModernProfileHeaderWidget.primaryGreen, // Platform green
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.trending_up,
            value: '#$ranking',
            label: 'Rank',
            color: ModernProfileHeaderWidget.primaryGreen, // Platform green
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.sports_esports,
            value: totalMatches.toString(),
            label: 'Matches',
            color: ModernProfileHeaderWidget.primaryGreen, // Platform green
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Builder(
        builder: (context) => Column(
          children: [
            // Icon + Value (clickable - navigate to history)
            InkWell(
              onTap: () {
                _navigateToHistoryScreen(context, label);
              },
              child: Column(
                children: [
                  // Icon with glow
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                    shadows: [
                      Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8)
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Value
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Label with info icon (clickable - show explanation)
            InkWell(
              onTap: () {
                _showStatExplanation(context, label);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ModernProfileHeaderWidget
                          .primaryGreen, // Platform green
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.error, // Red for visibility
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppColors.border, // Facebook divider
    );
  }

  Widget _buildMainTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Bài đăng Tab
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
                widget.onTabChanged?.call(0);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Icon(
                      Icons.article_outlined,
                      color: _selectedTabIndex == 0
                          ? ModernProfileHeaderWidget.primaryGreen
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  // Underline chỉ vừa với icon
                  Container(
                    height: 3,
                    width: 28, // Vừa với icon 20px + padding
                    color: _selectedTabIndex == 0
                        ? ModernProfileHeaderWidget.primaryGreen
                        : AppColors.border,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Giải Đấu Tab
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
                widget.onTabChanged?.call(1);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: _selectedTabIndex == 1
                          ? ModernProfileHeaderWidget.primaryGreen
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  // Underline chỉ vừa với icon
                  Container(
                    height: 3,
                    width: 28,
                    color: _selectedTabIndex == 1
                        ? ModernProfileHeaderWidget.primaryGreen
                        : AppColors.border,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Trận Đấu Tab
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 2;
                });
                widget.onTabChanged?.call(2);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Icon(
                      Icons.sports_esports_outlined,
                      color: _selectedTabIndex == 2
                          ? ModernProfileHeaderWidget.primaryGreen
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  // Underline chỉ vừa với icon
                  Container(
                    height: 3,
                    width: 28,
                    color: _selectedTabIndex == 2
                        ? ModernProfileHeaderWidget.primaryGreen
                        : AppColors.border,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Kết Quả Tab
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 3;
                });
                widget.onTabChanged?.call(3);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Icon(
                      Icons.leaderboard_outlined,
                      color: _selectedTabIndex == 3
                          ? ModernProfileHeaderWidget.primaryGreen
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  // Underline chỉ vừa với icon
                  Container(
                    height: 3,
                    width: 28,
                    color: _selectedTabIndex == 3
                        ? ModernProfileHeaderWidget.primaryGreen
                        : AppColors.border,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Action buttons đã được thay thế bằng edit icon ở avatar
    return const SizedBox.shrink();
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          // Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to appropriate history screen based on stat label
  void _navigateToHistoryScreen(BuildContext context, String label) {
    final userId = widget.userData['id'] as String?;
    // Display name is handled consistently by UserDisplayNameText
    final userName = widget.userData['displayName'] as String? ?? 'Player';

    if (userId == null) {
      AppSnackbar.error(
        context: context,
        message: 'Không tìm thấy thông tin người dùng',
      );
      return;
    }

    switch (label) {
      case 'ELO':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EloHistoryScreen(
              userId: userId,
              userName: userName,
            ),
          ),
        );
        break;
      case 'SPA':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SpaHistoryScreen(
              userId: userId,
              userName: userName,
            ),
          ),
        );
        break;
      case 'Rank':
        // For Rank, show rank history (promotions/demotions)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RankHistoryScreen(
              userId: userId,
              userName: userName,
            ),
          ),
        );
        break;
      case 'Matches':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MatchHistoryScreen(
              userId: userId,
              userName: userName,
            ),
          ),
        );
        break;
      default:
        _showStatExplanation(context, label);
    }
  }

  // Show explanation bottom sheet for stats - iOS Facebook 2025 Style
  void _showStatExplanation(BuildContext context, String label) {
    String title;
    String description;
    Widget? customContent;
    List<String> details = [];
    IconData icon;
    Color iconColor;

    switch (label) {
      case 'ELO':
        title = 'ELO Rating System';
        icon = Icons.emoji_events;
        iconColor = AppColors.warning;
        description = 'Điểm ELO đánh giá trình độ chơi bida của bạn.';
        customContent = _buildEloRankingTable();
        break;

      case 'SPA':
        title = 'SPA Points System';
        icon = Icons.star;
        iconColor = AppColors.warning;
        description =
            'SPA Points là điểm thưởng tích lũy từ các hoạt động trên SABO Arena.';
        details = [
          '🎯 Cách kiếm SPA Points:',
          '',
          '• Referral Code',
          '  → Người giới thiệu: +100 SPA',
          '  → Người được giới thiệu: +50 SPA',
          '',
          '• Tournament Position Bonus',
          '  → 1st Place: +1,000 SPA',
          '  → 2nd Place: +800 SPA',
          '  → 3rd/4th Place: +550 SPA',
          '  → Top 25%: +400 SPA',
          '  → Top 50%: +300 SPA',
          '  → Top 75%: +200 SPA',
          '  → Bottom 25%: +100 SPA',
          '',
          '• Daily challenges & achievements',
          '  → Hoàn thành nhiệm vụ hàng ngày',
          '',
          '💰 Sử dụng SPA Points:',
          '',
          '• SPA Shop: Đổi quà tặng và items',
          '• Premium features & benefits',
          '• Tournament entry fees (tùy chọn)',
        ];
        break;

      case 'Rank':
        title = 'Vietnamese Billiards Ranking';
        icon = Icons.trending_up;
        iconColor = AppColors.info600;
        description = 'Hệ thống rank bida Việt Nam dựa trên điểm ELO.';
        details = [
          '🎱 Rank được tính tự động từ điểm ELO:',
          '',
          '• Xem chi tiết 12 hạng từ K → C tại tab ELO',
          '• Mỗi hạng tương ứng với kỹ năng đánh bi khác nhau',
          '• Range: 1000 ELO (K) → 2199 ELO (C)',
          '',
          '📈 Cách thăng/giáng hạng:',
          '',
          '• Rank UP (Thăng hạng)',
          '  → Tăng ELO qua Tournament',
          '  → CẦN xác thực (verification) bởi Admin',
          '  → Đảm bảo trình độ thật sự đạt yêu cầu',
          '',
          '• Rank DOWN (Giáng hạng)',
          '  → TỰ ĐỘNG khi ELO giảm xuống',
          '  → Không cần xác thực',
          '  → Có grace period để bảo vệ rank',
          '',
          '💡 Lưu ý quan trọng:',
          '',
          '• Rank dựa trên kỹ thuật bida Việt Nam thực tế',
          '• Thăng hạng khó hơn giáng hạng (đảm bảo chất lượng)',
          '• Tham gia nhiều tournament để cải thiện ELO & Rank',
        ];
        break;

      case 'Matches':
        title = 'Total Tournaments';
        icon = Icons.sports_esports;
        iconColor = AppColors.success;
        description = 'Tổng số tournament bạn đã tham gia trên SABO Arena.';
        details = [
          '🎮 Các loại trận đấu:',
          '',
          '1️⃣ Trận giải đấu (Tournament)',
          '  → Trận chính thức trong giải',
          '  → Ảnh hưởng: ELO ✅, Rank ✅',
          '  → Nhận thưởng: SPA Points',
          '',
          '2️⃣ Trận thách đấu (Challenge)',
          '  → Thách đấu giữa 2 người chơi',
          '  → Yêu cầu: Đã xác thực rank',
          '  → Có thể: Cược SPA, Có chấp Handicap',
          '  → Nhận thưởng: SPA Points',
          '',
          '3️⃣ Trận giao lưu (Friendly)',
          '  → Chơi thân thiện, không rank',
          '  → Không ảnh hưởng: ELO ❌, Rank ❌',
          '  → Không có: Cược, Có chấp Handicap',
          '',
          '� Format giải đấu:',
          '',
          '• Single Elimination: Đấu loại trực tiếp',
          '• Double Elimination: Nhánh thua phục hồi',
          '• Round Robin: Vòng tròn tính điểm',
          '• Swiss System: Đấu theo điểm tương đồng',
        ];
        break;

      default:
        return;
    }

    // Show modern bottom sheet - iOS Facebook style
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.gray50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Custom content or Details
                    if (customContent != null)
                      customContent
                    else
                      ...details.map((detail) {
                        final isHeader =
                            detail.startsWith('🏆') ||
                            detail.startsWith('🎯') ||
                            detail.startsWith('💰') ||
                            detail.startsWith('🎱') ||
                            detail.startsWith('🎮') ||
                            detail.startsWith('📊');
                        final isEmpty = detail.trim().isEmpty;

                        if (isEmpty) {
                          return const SizedBox(height: 12);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: isHeader ? 16 : 15,
                              fontWeight: isHeader
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              letterSpacing: isHeader ? -0.3 : -0.2,
                              color: isHeader
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Footer button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: AppButton(
                label: 'Đóng',
                fullWidth: true,
                size: AppButtonSize.large,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build ELO Ranking Table with colors
  Widget _buildEloRankingTable() {
    final ranks = [
      {
        'rank': 'K',
        'elo': '1000-1099',
        'role': 'Người mới',
        'skill': '2-4 bi khi hình dễ',
        'color': const Color(0xFF8B4513),
      },
      {
        'rank': 'K+',
        'elo': '1100-1199',
        'role': 'Học việc',
        'skill': 'Đã quen cơ bida',
        'color': const Color(0xFFA0522D),
      },
      {
        'rank': 'I',
        'elo': '1200-1299',
        'role': 'Thợ 3',
        'skill': '3-5 bi; chưa điều chấm',
        'color': const Color(0xFFCD853F),
      },
      {
        'rank': 'I+',
        'elo': '1300-1399',
        'role': 'Thợ 2',
        'skill': 'Kỹ thuật I ổn định',
        'color': const Color(0xFFDEB887),
      },
      {
        'rank': 'H',
        'elo': '1400-1499',
        'role': 'Thợ 1',
        'skill': '5-8 bi; rùa 1 chấm dễ',
        'color': const Color(0xFFC0C0C0),
      },
      {
        'rank': 'H+',
        'elo': '1500-1599',
        'role': 'Thợ chính',
        'skill': 'Trình H chắc chắn',
        'color': const Color(0xFFB0B0B0),
      },
      {
        'rank': 'G',
        'elo': '1600-1699',
        'role': 'Thợ giỏi',
        'skill': 'Clear 1 chấm + 3-7 bi',
        'color': const Color(0xFFFFD700),
      },
      {
        'rank': 'G+',
        'elo': '1700-1799',
        'role': 'Cao thủ',
        'skill': 'Trình phong trào ngon',
        'color': const Color(0xFFFFA500),
      },
      {
        'rank': 'F',
        'elo': '1800-1899',
        'role': 'Chuyên gia',
        'skill': '60-80% clear 1 chấm',
        'color': const Color(0xFFFF6347),
      },
      {
        'rank': 'F+',
        'elo': '1900-1999',
        'role': 'Đại cao thủ',
        'skill': 'Safety & spin tốt',
        'color': const Color(0xFFFF4500),
      },
      {
        'rank': 'E',
        'elo': '2000-2099',
        'role': 'Huyền thoại',
        'skill': '90-100% clear 1 chấm',
        'color': const Color(0xFFDC143C),
      },
      {
        'rank': 'D',
        'elo': '2000-2099',
        'role': 'Huyền Thoại',
        'skill': 'Master cơ hội',
        'color': const Color(0xFFDC143C),
      },
      {
        'rank': 'C',
        'elo': '2100-2199',
        'role': 'Vô Địch',
        'skill': 'Điều bi phức tạp',
        'color': const Color(0xFFFFD700),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          '📊 Bảng xếp hạng ELO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: ranks.asMap().entries.map((entry) {
              final index = entry.key;
              final rank = entry.value;
              final isLast = index == ranks.length - 1;

              return Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank with color
                    Container(
                      width: 40,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (rank['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (rank['color'] as Color).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        rank['rank'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: rank['color'] as Color,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ELO & Role
                          Row(
                            children: [
                              Text(
                                rank['elo'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                rank['role'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Skill
                          Text(
                            rank['skill'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Tournament rewards section
        const Text(
          '🏆 Cách tăng ELO - Thi đấu Tournament',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        _buildRewardItem('🥇 1st Place', '+75 ELO', const Color(0xFFFFD700)),
        _buildRewardItem('🥈 2nd Place', '+60 ELO', const Color(0xFFC0C0C0)),
        _buildRewardItem('🥉 3rd Place', '+45 ELO', const Color(0xFFCD7F32)),
        _buildRewardItem('4th Place', '+35 ELO', AppColors.textSecondary),
        _buildRewardItem('Top 25%', '+25 ELO', AppColors.textSecondary),
        _buildRewardItem('Top 50%', '+15 ELO', AppColors.textSecondary),
        _buildRewardItem('Top 75%', '+10 ELO', AppColors.textSecondary),
        _buildRewardItem('Bottom 25%', '-5 ELO', AppColors.error),
      ],
    );
  }

  Widget _buildRewardItem(String position, String reward, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              position,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            reward,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Show rank registration options bottom sheet
  void _showRankRegistrationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child:               Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: ModernProfileHeaderWidget.primaryGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng ký xác minh hạng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Chọn câu lạc bộ để xác minh trình độ của bạn',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Option 1: Register at specific club
            _buildRegistrationOption(
              context,
              icon: Icons.location_on,
              title: 'Đăng ký tại câu lạc bộ',
              description: 'Chọn CLB bạn muốn xác minh hạng',
              color: ModernProfileHeaderWidget.primaryGreen,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
              },
            ),

            const SizedBox(height: 12),

            // Option 2: Learn about ranking system
            _buildRegistrationOption(
              context,
              icon: Icons.help_outline,
              title: 'Tìm hiểu về hệ thống hạng',
              description: 'Xem quy định và yêu cầu xác minh',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                _showRankingSystemInfo(context);
              },
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  /// Show ranking system information dialog
  void _showRankingSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.shield,
              color: ModernProfileHeaderWidget.primaryGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hệ thống xếp hạng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection(
                title: '📋 Quy trình xác minh',
                items: [
                  '1. Chọn câu lạc bộ muốn xác minh',
                  '2. Gửi yêu cầu kèm video/ảnh chứng minh',
                  '3. Chủ CLB/Admin review và phê duyệt',
                  '4. Nhận hạng chính thức sau khi được duyệt',
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                title: '🎯 Yêu cầu',
                items: [
                  'Video đánh bida rõ nét (nếu có)',
                  'Chứng chỉ/Giải thưởng (nếu có)',
                  'Lịch sử thi đấu (nếu có)',
                  'Xác nhận từ người chơi khác',
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                title: '⚡ Lưu ý',
                items: [
                  'Mỗi CLB có thể có tiêu chí khác nhau',
                  'Hạng sẽ được cập nhật theo thành tích',
                  'Chỉ Admin/Chủ CLB mới duyệt được',
                  'Có thể đăng ký tại nhiều CLB',
                ],
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: 'Đóng',
            type: AppButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            label: 'Đăng ký ngay',
            customColor: ModernProfileHeaderWidget.primaryGreen,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(fontSize: 14, color: AppColors.textTertiary, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankProgressIndicator(String currentRankCode) {
    // Get current rank info
    final currentRankInfo = SaboRankSystem.rankEloMapping[currentRankCode];
    if (currentRankInfo == null) return Container();

    final currentElo = currentRankInfo['elo'] as int;
    final currentRankColor = currentRankInfo['color'] as Color;

    // Find next rank
    final allRanks = SaboRankSystem.rankEloMapping.entries
        .toList()
        ..sort((a, b) => (a.value['elo'] as int).compareTo(b.value['elo'] as int));

    final currentRankIndex = allRanks.indexWhere((rank) => rank.key == currentRankCode);
    if (currentRankIndex == -1 || currentRankIndex >= allRanks.length - 1) {
      // Max rank reached
      return Container();
    }

    final nextRank = allRanks[currentRankIndex + 1];
    final nextRankElo = nextRank.value['elo'] as int;
    final nextRankCode = nextRank.key;

    // Calculate progress using eloRating from userData
    final userElo = widget.userData['eloRating'] as int? ?? currentElo;
    final progressInCurrentRank = userElo - currentElo;
    final totalRankRange = nextRankElo - currentElo;
    final progressPercentage = (progressInCurrentRank / totalRankRange).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rank $currentRankCode',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: currentRankColor,
                ),
              ),
              Text(
                'Next: $nextRankCode',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(currentRankColor),
            minHeight: 4,
          ),
          const SizedBox(height: 2),
          Text(
            '${(progressPercentage * 100).toInt()}% to next rank',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
