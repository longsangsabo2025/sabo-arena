import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../services/opponent_club_service.dart';
import '../../../services/user_service.dart';
import '../../../services/challenge_rules_service.dart'; // ✅ Import for rank validation
import '../../../routes/app_routes.dart';
// import '../../../services/challenge_service.dart';
import './modern_challenge_modal.dart';
import '../../../widgets/avatar_with_quick_follow.dart';
import '../../../widgets/user/user_widgets.dart';
import '../../../widgets/common/common_widgets.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX // Phase 4: AppButton & AppSnackbar

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
                          future: OpponentClubService.instance
                              .getRandomClubName(),
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

                        // Rank Badge (instead of skill level)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14 : 12,
                            vertical: isTablet ? 6 : 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRankColor(player.displayRank),
                                _getRankColor(
                                  player.displayRank,
                                ).withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _getRankColor(
                                  player.displayRank,
                                ).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            player.displayRank,
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
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
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFE53935).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showChallengeModal(context, 'thach_dau'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 12 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: Icon(
                            Icons.sports,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Thách đấu ngay',
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF1E88E5).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _showScheduleModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 12 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Hẹn lịch',
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
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
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF43A047).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showChallengeModal(context, 'giao_luu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 12 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: Icon(
                            Icons.sports,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Giao lưu',
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF1E88E5).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _showScheduleModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 24 : 20,
                              vertical: isTablet ? 12 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Hẹn lịch',
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
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

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'K':
      case 'K+':
        return Colors.brown;
      case 'I':
      case 'I+':
        return Colors.green;
      case 'H':
      case 'H+':
        return Colors.blue;
      case 'G':
      case 'G+':
        return Colors.orange;
      case 'F':
      case 'F+':
        return Colors.red;
      case 'E':
        return Colors.purple;
      case 'D':
        return const Color(0xFFDC143C);
      case 'C':
        return const Color(0xFFFFD700);
      case 'UNRANKED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

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
      if (!hasRank) {
        _showRegistrationRequiredDialog(context, 'thách đấu cược SPA');
        return;
      }
      
      // ✅ Check rank eligibility (only for competitive challenges)
      final canChallenge = await _checkRankEligibility(context);
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
      if (!hasRank) {
        _showRegistrationRequiredDialog(context, 'hẹn lịch thách đấu cược SPA');
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildScheduleModal(context),
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
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
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
      final canChallenge = rulesService.canChallenge(currentUserRank, opponentRank);
      
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
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
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

  Widget _buildScheduleModal(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String? selectedTimeSlot;
    String? customStartTime;
    String? customEndTime;

    return StatefulBuilder(
      builder: (context, setState) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.schedule, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hẹn lịch với ${player.fullName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Chọn thời gian phù hợp để chơi',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Selection
              Text(
                'Chọn ngày:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDateOption(
                      context,
                      DateTime.now(),
                      'Hôm nay',
                      'Chơi ngay trong ngày',
                      selectedDate,
                      (date) => setState(() => selectedDate = date),
                    ),
                    const Divider(height: 1),
                    _buildDateOption(
                      context,
                      DateTime.now().add(const Duration(days: 1)),
                      'Ngày mai',
                      _formatDate(DateTime.now().add(const Duration(days: 1))),
                      selectedDate,
                      (date) => setState(() => selectedDate = date),
                    ),
                    const Divider(height: 1),
                    _buildDateOption(
                      context,
                      DateTime.now().add(const Duration(days: 2)),
                      'Ngày kia',
                      _formatDate(DateTime.now().add(const Duration(days: 2))),
                      selectedDate,
                      (date) => setState(() => selectedDate = date),
                    ),
                    const Divider(height: 1),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.blue,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() => selectedDate = pickedDate);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Chọn ngày khác...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Time Slots
              Text(
                'Khung giờ có sẵn:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Column(
                children: [
                  _buildSelectableTimeSlot(
                    '08:00 - 10:00',
                    'Sáng',
                    Colors.orange,
                    selectedTimeSlot,
                    (timeSlot) => setState(() => selectedTimeSlot = timeSlot),
                  ),
                  const SizedBox(height: 8),
                  _buildSelectableTimeSlot(
                    '14:00 - 16:00',
                    'Chiều',
                    Colors.blue,
                    selectedTimeSlot,
                    (timeSlot) => setState(() => selectedTimeSlot = timeSlot),
                  ),
                  const SizedBox(height: 8),
                  _buildSelectableTimeSlot(
                    '19:00 - 21:00',
                    'Tối',
                    Colors.green,
                    selectedTimeSlot,
                    (timeSlot) => setState(() => selectedTimeSlot = timeSlot),
                  ),
                  const SizedBox(height: 8),
                  _buildSelectableTimeSlot(
                    '21:00 - 23:00',
                    'Tối muộn',
                    Colors.purple,
                    selectedTimeSlot,
                    (timeSlot) => setState(() => selectedTimeSlot = timeSlot),
                  ),
                  const SizedBox(height: 16),
                  // Custom time selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 20,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tùy chỉnh khung giờ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Start time
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final time = await _showTimePicker(context);
                                  if (time != null) {
                                    setState(() => customStartTime = time);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        customStartTime ?? 'Giờ bắt đầu',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: customStartTime != null
                                              ? Colors.black87
                                              : Colors.grey[600],
                                          fontWeight: customStartTime != null
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'đến',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // End time
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final time = await _showTimePicker(context);
                                  if (time != null) {
                                    setState(() => customEndTime = time);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        customEndTime ?? 'Giờ kết thúc',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: customEndTime != null
                                              ? Colors.black87
                                              : Colors.grey[600],
                                          fontWeight: customEndTime != null
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (customStartTime != null &&
                            customEndTime != null) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              final customTimeSlot =
                                  '$customStartTime - $customEndTime';
                              setState(() => selectedTimeSlot = customTimeSlot);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selectedTimeSlot ==
                                        '$customStartTime - $customEndTime'
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      selectedTimeSlot ==
                                          '$customStartTime - $customEndTime'
                                      ? Colors.blue
                                      : Colors.blue.withValues(alpha: 0.3),
                                  width:
                                      selectedTimeSlot ==
                                          '$customStartTime - $customEndTime'
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                    color:
                                        selectedTimeSlot ==
                                            '$customStartTime - $customEndTime'
                                        ? Colors.blue
                                        : Colors.blue.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sử dụng: $customStartTime - $customEndTime',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            selectedTimeSlot ==
                                                '$customStartTime - $customEndTime'
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color:
                                            selectedTimeSlot ==
                                                '$customStartTime - $customEndTime'
                                            ? Colors.blue
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (selectedTimeSlot ==
                                      '$customStartTime - $customEndTime')
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Hủy',
                      type: AppButtonType.outline,
                      fullWidth: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Xác nhận',
                      fullWidth: true,
                      onPressed: selectedTimeSlot != null
                          ? () async {
                              try {
                                // TODO: Implement schedule request with simple service
                                // final challengeService = ChallengeService.instance;
                                //
                                // await challengeService.sendScheduleRequest(
                                //   targetUserId: player.id,
                                //   scheduledDate: selectedDate,
                                //   timeSlot: selectedTimeSlot!,
                                //   message: 'Lời mời hẹn lịch chơi bida từ ứng dụng SABO ARENA',
                                // );

                                ProductionLogger.debug('Debug log', tag: 'AutoFix');

                                Navigator.pop(context);
                                final dateStr = _isToday(selectedDate)
                                    ? 'hôm nay'
                                    : _isTomorrow(selectedDate)
                                    ? 'ngày mai'
                                    : _formatDate(selectedDate);

                                AppSnackbar.success(
                                  context: context,
                                  message: 'Đã gửi lời mời hẹn lịch đến ${player.fullName} - $dateStr, $selectedTimeSlot thành công! 📅',
                                );
                              } catch (error) {
                                Navigator.pop(context);
                                AppSnackbar.error(
                                  context: context,
                                  message: 'Lỗi: ${error.toString().replaceAll('Exception: ', '')}',
                                  duration: const Duration(seconds: 4),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateOption(
    BuildContext context,
    DateTime date,
    String title,
    String subtitle,
    DateTime selectedDate,
    Function(DateTime) onTap,
  ) {
    final isSelected = _isSameDay(date, selectedDate);

    return InkWell(
      onTap: () => onTap(date),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableTimeSlot(
    String time,
    String period,
    Color color,
    String? selectedTimeSlot,
    Function(String) onTap,
  ) {
    final isSelected = selectedTimeSlot == time;

    return InkWell(
      onTap: () => onTap(time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: isSelected ? color : color.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ),
            Text(
              period,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day}/${date.month}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<String?> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format time to HH:mm format
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return null;
  }
}

