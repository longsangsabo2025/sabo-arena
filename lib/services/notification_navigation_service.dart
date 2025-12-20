import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_routes.dart';
// ELON_MODE_AUTO_FIX

/// Service to handle navigation from notifications
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._();
  static NotificationNavigationService get instance => _instance;
  NotificationNavigationService._();

  /// Navigate to the appropriate screen based on notification type and data
  void navigateFromNotification({
    required BuildContext context,
    required String type,
    Map<String, dynamic>? data,
  }) {
    try {
      switch (type) {
        // Tournament related notifications
        case 'tournament_invitation':
        case 'tournament_registration':
        case 'tournament_start':
        case 'tournament_completion':
        case 'tournament_champion':
        case 'tournament_runner_up':
        case 'tournament_podium':
          _navigateToTournament(context, data);
          break;

        // Match related notifications
        case 'match_result':
        case 'match_scheduled':
        case 'match_reminder':
          _navigateToMatch(context, data);
          break;

        // Challenge related notifications
        case 'challenge_request':
        case 'challenge_accepted':
        case 'challenge_declined':
        case 'challenge_completed':
          _navigateToChallenge(context, data);
          break;

        // Club related notifications
        case 'club_announcement':
        case 'club_invitation':
        case 'membership_request':
        case 'membership_approved':
        case 'membership_rejected':
          _navigateToClub(context, data);
          break;

        // Social notifications
        case 'friend_request':
        case 'friend_accepted':
        case 'follower_new':
          _navigateToProfile(context, data);
          break;

        // Rank/Achievement notifications
        case 'rank_update':
        case 'achievement_unlocked':
        case 'level_up':
          _navigateToUserProfile(context);
          break;

        // Post/Feed notifications
        case 'post_like':
        case 'post_comment':
        case 'post_mention':
        case 'post_share':
          _navigateToPost(context, data);
          break;

        // SPA/Voucher notifications
        case 'spa_earned':
        case 'spa_spent':
        case 'voucher_issued':
        case 'voucher_expiring':
          _navigateToWallet(context);
          break;

        // System notifications
        case 'system_notification':
        case 'maintenance':
        case 'update_available':
          _showSystemNotificationDialog(context, data);
          break;

        default:
          // Navigate to notification detail screen as fallback
          _navigateToNotificationDetail(context, data);
      }
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở thông báo này'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== NAVIGATION HELPERS ====================

  void _navigateToTournament(BuildContext context, Map<String, dynamic>? data) {
    final tournamentId = data?['tournament_id'] as String?;
    if (tournamentId == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.tournamentDetailScreen,
      arguments: tournamentId,
    );
  }

  void _navigateToMatch(BuildContext context, Map<String, dynamic>? data) {
    final matchId = data?['match_id'] as String?;
    final tournamentId = data?['tournament_id'] as String?;

    if (matchId == null && tournamentId == null) {
      return;
    }

    // For now, navigate to tournament detail since we don't have match detail screen
    // TODO: Add match detail screen
    if (tournamentId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.tournamentDetailScreen,
        arguments: {
          'tournamentId': tournamentId,
          'tab': 'matches',
        },
      );
    }
  }

  void _navigateToChallenge(BuildContext context, Map<String, dynamic>? data) {
    final challengeId = data?['challenge_id'] as String?;
    if (challengeId == null) {
      return;
    }

    // TODO: Add challenge detail screen
    // For now, show in bottom sheet
    _navigateToNotificationDetail(context, data);
  }

  void _navigateToClub(BuildContext context, Map<String, dynamic>? data) {
    final clubId = data?['club_id'] as String?;
    if (clubId == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.clubProfileScreen,
      arguments: clubId,
    );
  }

  void _navigateToProfile(BuildContext context, Map<String, dynamic>? data) {
    final userId = data?['user_id'] as String?;
    if (userId == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.userProfileScreen,
      arguments: userId,
    );
  }

  void _navigateToUserProfile(BuildContext context) {
    // Navigate to current user's profile
    Navigator.pushNamed(context, AppRoutes.userProfileScreen);
  }

  void _navigateToPost(BuildContext context, Map<String, dynamic>? data) {
    final postId = data?['post_id'] as String?;
    if (postId == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.postDetailScreen,
      arguments: {'postId': postId},
    );
  }

  void _navigateToWallet(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.userVoucherScreen,
      arguments: userId,
    );
  }

  void _navigateToNotificationDetail(
    BuildContext context,
    Map<String, dynamic>? data,
  ) {
    // Fallback: show notification details in a dialog or bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 32,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🔔 Thông Báo Mới',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF050505),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE4E6EB),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data != null) ...[
                    if (data['action'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Color(0xFF65676B)),
                          const SizedBox(width: 8),
                          const Text(
                            'Loại:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF65676B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getActionLabel(data['action'] as String?),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF050505),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (data['screen'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.screen_share_outlined,
                              size: 16, color: Color(0xFF65676B)),
                          const SizedBox(width: 8),
                          const Text(
                            'Màn hình:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF65676B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getScreenLabel(data['screen'] as String?),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF050505),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else
                    const Text(
                      'Bạn đã nhận được một thông báo mới từ SABO Arena!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF65676B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons Row
            Row(
              children: [
                // Close Button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF65676B),
                      side: const BorderSide(
                        color: Color(0xFFE4E6EB),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // View Detail Button (if has navigation data)
                if (data != null &&
                    (data['tournament_id'] != null ||
                        data['match_id'] != null ||
                        data['challenge_id'] != null ||
                        data['club_id'] != null)) ...[
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close dialog first
                        // Navigate based on data
                        if (data['tournament_id'] != null) {
                          _navigateToTournament(context, data);
                        } else if (data['match_id'] != null) {
                          _navigateToMatch(context, data);
                        } else if (data['challenge_id'] != null) {
                          _navigateToChallenge(context, data);
                        } else if (data['club_id'] != null) {
                          _navigateToClub(context, data);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Xem Chi Tiết',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Convert technical action name to friendly Vietnamese label
  String _getActionLabel(String? action) {
    if (action == null) return 'Thông báo';

    switch (action.toLowerCase()) {
      case 'view_tournament':
        return '🏆 Xem Giải Đấu';
      case 'view_match':
        return '🎱 Xem Trận Đấu';
      case 'view_challenge':
        return '⚔️ Xem Thách Đấu';
      case 'view_club':
        return '🏛️ Xem CLB';
      case 'view_profile':
        return '👤 Xem Hồ Sơ';
      case 'view_notification':
        return '🔔 Xem Thông Báo';
      case 'view_leaderboard':
        return '🏅 Xem Bảng Xếp Hạng';
      default:
        return '📱 ${action.replaceAll('_', ' ')}';
    }
  }

  /// Convert technical screen name to friendly Vietnamese label
  String _getScreenLabel(String? screen) {
    if (screen == null) return 'Màn hình chính';

    switch (screen.toLowerCase()) {
      case 'tournament_detail':
        return 'Chi Tiết Giải Đấu';
      case 'match_detail':
        return 'Chi Tiết Trận Đấu';
      case 'challenge_detail':
        return 'Chi Tiết Thách Đấu';
      case 'club_detail':
        return 'Chi Tiết CLB';
      case 'user_profile':
        return 'Trang Cá Nhân';
      case 'notifications':
        return 'Thông Báo';
      case 'leaderboard':
        return 'Bảng Xếp Hạng';
      case 'home':
        return 'Trang Chủ';
      default:
        return screen
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  void _showSystemNotificationDialog(
    BuildContext context,
    Map<String, dynamic>? data,
  ) {
    final message = data?['message'] as String? ?? 'Thông báo hệ thống';
    final actionUrl = data?['action_url'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo hệ thống'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (actionUrl != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle action URL if needed
              },
              child: const Text('Xem chi tiết'),
            ),
        ],
      ),
    );
  }

  // ==================== QUICK ACTIONS ====================

  /// Navigate to specific tournament by ID
  void navigateToTournamentById(BuildContext context, String tournamentId) {
    Navigator.pushNamed(
      context,
      AppRoutes.tournamentDetailScreen,
      arguments: tournamentId,
    );
  }

  /// Navigate to specific club by ID
  void navigateToClubById(BuildContext context, String clubId) {
    Navigator.pushNamed(
      context,
      AppRoutes.clubProfileScreen,
      arguments: clubId,
    );
  }

  /// Navigate to specific user profile by ID
  void navigateToUserProfileById(BuildContext context, String userId) {
    Navigator.pushNamed(
      context,
      AppRoutes.userProfileScreen,
      arguments: userId,
    );
  }
}
