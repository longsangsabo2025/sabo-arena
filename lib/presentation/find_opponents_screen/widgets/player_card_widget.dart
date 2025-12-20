import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../services/opponent_club_service.dart';
import '../../../services/user_service.dart';
import '../../../services/challenge_rules_service.dart'; // ✅ Import for rank validation
import '../../../routes/app_routes.dart';
// import '../../../services/challenge_service.dart';
import './modern_challenge_modal.dart';
import './schedule_match_modal.dart';
import '../../../widgets/avatar_with_quick_follow.dart';
import '../../../widgets/user/user_widgets.dart';
import '../../../widgets/common/common_widgets.dart';
// ELON_MODE_AUTO_FIX // Phase 4: AppButton & AppSnackbar

class PlayerCardWidget extends StatelessWidget {
  final UserProfile player;
  final String mode; // 'giao_luu' or 'thach_dau'
  final Map<String, dynamic>? challengeInfo;

  const PlayerCardWidget({
    super.key,
    required this.player,
    this.mode = 'giao_luu', // Default to friendly mode
    this.challengeInfo,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // iOS Facebook style border - more prominent
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.25),
          width: 1.5,
        ),
        // Enhanced shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 18),
          child: Column(
            children: [
              Row(
                children: [
                  // Player Avatar with Quick Follow
                  Hero(
                    tag: 'opponent_avatar_${player.id}',
                    child: AvatarWithQuickFollow(
                      userId: player.id,
                      avatarUrl: player.avatarUrl,
                      size: isTablet ? 60 : 50,
                      showQuickFollow: true,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),

                  // Player Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserDisplayNameText(
                          userData: {
                            'display_name': player.displayName,
                            'full_name': player.fullName,
                          },
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Club name from real Supabase data
                        FutureBuilder<String>(
                          future:
                              OpponentClubService.instance.getRandomClubName(),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'CLB SABO ARENA',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),

                        // Rank Badge with unified component
                        UserRankBadgeWidget(
                          rankCode: player.displayRank,
                          style: RankBadgeStyle.standard,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Player Stats - similar to the image design
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '${player.totalWins}',
                      'Thắng',
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '${player.totalLosses}',
                      'Thua',
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '${player.winRate.toStringAsFixed(1)}%',
                      'Tỷ lệ',
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '${player.eloRating}',
                      'Điểm',
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              // Challenge Mode Extra Info
              if (mode == 'thach_dau') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.08),
                        Colors.blue.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Challenge Info Row 1: SPA Bonus & Race To
                      Row(
                        children: [
                          Expanded(
                            child: _buildChallengeInfoItem(
                              Icons.monetization_on,
                              'SPA Bonus',
                              '${challengeInfo?['spaBonus'] ?? 300}',
                              Colors.amber,
                            ),
                          ),
                          Expanded(
                            child: _buildChallengeInfoItem(
                              Icons.flag,
                              'Race to',
                              '${challengeInfo?['raceTo'] ?? 14}',
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Challenge Info Row 2: User Details
                      Row(
                        children: [
                          Expanded(
                            child: _buildChallengeInfoItem(
                              Icons.calendar_today,
                              'Tham gia',
                              challengeInfo?['joinedDate'] ?? 'N/A',
                              Colors.purple,
                            ),
                          ),
                          Expanded(
                            child: _buildChallengeInfoItem(
                              Icons.location_on,
                              'Vị trí',
                              challengeInfo?['location'] ?? 'Chưa cập nhật',
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Action Buttons Row - Challenge Mode
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Thách đấu ngay',
                        type: AppButtonType.primary,
                        size: AppButtonSize.medium,
                        icon: Icons.sports,
                        iconTrailing: false,
                        customColor:
                            const Color(0xFFE53935), // Red for challenge
                        customTextColor: Colors.white,
                        fullWidth: true,
                        onPressed: () =>
                            _showChallengeModal(context, 'thach_dau'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: AppButton(
                        label: 'Hẹn lịch',
                        type: AppButtonType.primary,
                        size: AppButtonSize.medium,
                        icon: Icons.calendar_today,
                        iconTrailing: false,
                        customColor:
                            const Color(0xFF1E88E5), // Blue for schedule
                        customTextColor: Colors.white,
                        fullWidth: true,
                        onPressed: () => _showScheduleModal(context),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                // Friendly Mode Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Giao lưu',
                        type: AppButtonType.primary,
                        size: AppButtonSize.medium,
                        icon: Icons.sports,
                        iconTrailing: false,
                        customColor:
                            const Color(0xFF43A047), // Green for social
                        customTextColor: Colors.white,
                        fullWidth: true,
                        onPressed: () =>
                            _showChallengeModal(context, 'giao_luu'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: AppButton(
                        label: 'Hẹn lịch',
                        type: AppButtonType.primary,
                        size: AppButtonSize.medium,
                        icon: Icons.calendar_today,
                        iconTrailing: false,
                        customColor:
                            const Color(0xFF1E88E5), // Blue for schedule
                        customTextColor: Colors.white,
                        fullWidth: true,
                        onPressed: () => _showScheduleModal(context),
                      ),
                    ),
                  ],
                ),
              ],

              if (player.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        player.location!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Note: Old _getRankColor method removed - now using SaboRankSystem.getRankColor()

  Widget _buildChallengeInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChallengeModal(BuildContext context, String challengeType) async {
    // Check if user has rank for competitive play
    if (challengeType == 'thach_dau') {
      final hasRank = await _checkUserRank(context);
      if (!context.mounted) return;
      if (!hasRank) {
        _showRegistrationRequiredDialog(context, 'thách đấu cược SPA');
        return;
      }

      // ✅ Check rank eligibility (only for competitive challenges)
      final canChallenge = await _checkRankEligibility(context);
      if (!context.mounted) return;
      if (!canChallenge) {
        return; // Error message already shown in _checkRankEligibility
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernChallengeModal(
        player: {
          'id': player.id,
          'fullName': player.fullName,
          'username': player.username,
          'club': 'CLB SABO ARENA',
          'rank': player.displayRank,
          'elo': player.eloRating,
          'avatarUrl': player.avatarUrl,
        },
        challengeType: challengeType,
      ),
    );
  }

  void _showScheduleModal(BuildContext context) async {
    // Check if user has rank for competitive scheduling
    if (mode == 'thach_dau') {
      final hasRank = await _checkUserRank(context);
      if (!context.mounted) return;
      if (!hasRank) {
        _showRegistrationRequiredDialog(context, 'hẹn lịch thách đấu cược SPA');
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleMatchModal(
        targetUserId: player.id,
        targetUserName: player.fullName,
      ),
    );
  }

  Future<bool> _checkUserRank(BuildContext context) async {
    try {
      final userService = UserService.instance;
      final currentUser = await userService.getCurrentUserProfile();

      if (currentUser == null) return false;

      final userRank = currentUser.rank;
      return userRank != null && userRank.isNotEmpty && userRank != 'unranked';
    } catch (e) {
      return false;
    }
  }

  // ✅ NEW: Check if current user can challenge this opponent based on rank
  Future<bool> _checkRankEligibility(BuildContext context) async {
    try {
      final userService = UserService.instance;
      final currentUser = await userService.getCurrentUserProfile();

      if (currentUser == null) return false;

      final currentUserRank = currentUser.rank;
      final opponentRank = player.rank;

      // If either has no rank, allow (will be caught by _checkUserRank)
      if (currentUserRank == null || opponentRank == null) {
        return true;
      }

      // Check rank eligibility using ChallengeRulesService
      final rulesService = ChallengeRulesService.instance;
      final canChallenge =
          rulesService.canChallenge(currentUserRank, opponentRank);

      if (!canChallenge) {
        // Show error with eligible ranks
        final eligibleRanks = rulesService.getEligibleRanks(currentUserRank);

        if (!context.mounted) return false;

        AppSnackbar.error(
          context: context,
          message: '❌ Không thể thách đấu!\n'
              'Hạng của bạn ($currentUserRank) không thể thách đấu với hạng $opponentRank.\n\n'
              'Bạn chỉ có thể thách đấu với các hạng:\n${eligibleRanks.join(", ")}',
          duration: const Duration(seconds: 5),
        );

        return false;
      }

      return true;
    } catch (e) {
      return true; // Allow by default if error
    }
  }

  void _showRegistrationRequiredDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600, size: 28),
              const SizedBox(width: 12),
              const Text('Cần đăng ký hạng'),
            ],
          ),
          content: Text(
            'Bạn cần đăng ký hạng trước khi có thể $action.\n\nĐăng ký hạng giúp hệ thống tìm đối thủ phù hợp với trình độ của bạn.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            AppButton(
              label: 'Để sau',
              type: AppButtonType.text,
              customColor: Colors.grey.shade600,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AppButton(
              label: 'Đăng ký ngay',
              customColor: Colors.orange.shade600,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
              },
            ),
          ],
        );
      },
    );
  }
}
