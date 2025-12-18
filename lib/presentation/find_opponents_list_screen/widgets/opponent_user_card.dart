import 'package:flutter/material.dart';
import 'dart:io';
import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../../utils/profile_navigation_utils.dart';
import '../../../widgets/avatar_with_quick_follow.dart'; // Import FollowEventBroadcaster
import '../../../widgets/user/user_widgets.dart';
import '../../find_opponents_screen/widgets/modern_challenge_modal.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Facebook-style user card với Follow button và action buttons
class OpponentUserCard extends StatefulWidget {
  final UserProfile user;
  final VoidCallback? onRefresh; // 🚀 MUSK: Make optional to reduce coupling
  final VoidCallback? onFollowChanged; // 🚀 MUSK: Better callback for follow status changes

  const OpponentUserCard({
    super.key,
    required this.user,
    this.onRefresh,
    this.onFollowChanged,
  });

  @override
  State<OpponentUserCard> createState() => _OpponentUserCardState();
}

class _OpponentUserCardState extends State<OpponentUserCard> {
  final UserService _userService = UserService.instance;
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  /// 🚀 MUSK OPTIMIZATION: Smart follow status với caching
  Future<void> _checkFollowStatus() async {
    try {
      // Check cache first to avoid redundant API calls
      final cachedStatus = _userService.getCachedFollowStatus(widget.user.id);
      if (cachedStatus != null) {
        if (mounted) {
          setState(() {
            _isFollowing = cachedStatus;
            _isLoading = false;
          });
        }
        return;
      }
      
      final isFollowing = await _userService.isFollowingUser(widget.user.id);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      ProductionLogger.error('👥 Follow status check failed: $e', tag: 'opponent_card');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (_isFollowing) {
        await _userService.unfollowUser(widget.user.id);
        if (mounted) {
          setState(() => _isFollowing = false);
          // Broadcast unfollow event to sync other screens
          FollowEventBroadcaster.notifyFollowChanged(widget.user.id, false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.person_remove,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đã bỏ theo dõi ${widget.user.displayName}',
                    style: TextStyle(fontFamily: _getSystemFont()),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.black87,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        await _userService.followUser(widget.user.id);
        if (mounted) {
          setState(() => _isFollowing = true);
          // Broadcast follow event to sync other screens
          FollowEventBroadcaster.notifyFollowChanged(widget.user.id, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF42B72A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đã theo dõi ${widget.user.displayName}',
                    style: TextStyle(fontFamily: _getSystemFont()),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.black87,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
      // ❌ REMOVED: widget.onRefresh();
      // ✅ Không reload page, chỉ update state local để tăng trải nghiệm
    } catch (e) {
      ProductionLogger.error('👥 Follow toggle failed: $e', tag: 'opponent_card');
      if (mounted) {
        _showErrorSnackbar('Không thể ${_isFollowing ? "bỏ theo dõi" : "theo dõi"} ${widget.user.displayName}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  
  /// Show follow success snackbar
  // void _showFollowSuccessSnackbar() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Row(
  //         children: [
  //           const Icon(
  //             Icons.check_circle,
  //             color: Color(0xFF42B72A),
  //             size: 20,
  //           ),
  //           const SizedBox(width: 8),
  //           Text(
  //             '✅ Đã theo dõi ${widget.user.displayName}',
  //             style: TextStyle(fontFamily: _getSystemFont()),
  //           ),
  //         ],
  //       ),
  //       duration: const Duration(milliseconds: 2000),
  //       behavior: SnackBarBehavior.floating,
  //       backgroundColor: Colors.black87,
  //       margin: const EdgeInsets.all(16),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //     ),
  //   );
  // }
  
  /// Show error snackbar với context-aware message
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontFamily: _getSystemFont()),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: _toggleFollow,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug log để kiểm tra avatar URL
    ProductionLogger.info('👤 User: ${widget.user.displayName}, Avatar: ${widget.user.avatarUrl}', tag: 'opponent_user_card');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Info + Follow button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Follow button overlay
                _buildAvatarWithFollow(),
                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        widget.user.displayName,
                        style: TextStyle(
                          fontFamily: _getSystemFont(),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF050505),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Rank & Stats
                      Row(
                        children: [
                          UserRankBadgeWidget(
                            rankCode: widget.user.rank,
                            style: RankBadgeStyle.compact,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.user.totalWins}W - ${widget.user.totalLosses}L',
                            style: TextStyle(
                              fontFamily: _getSystemFont(),
                              fontSize: 13,
                              color: const Color(0xFF65676B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // ELO & Distance
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            'ELO: ${widget.user.eloRating}',
                            style: TextStyle(
                              fontFamily: _getSystemFont(),
                              fontSize: 13,
                              color: const Color(0xFF65676B),
                            ),
                          ),
                          
                          // 🚀 MUSK: Smart distance/activity indicator
                          const SizedBox(width: 12),
                          _buildActivityIndicator(),
                          //       fontSize: 13,
                          //       color: const Color(0xFF65676B),
                          //     ),
                          //   ),
                          // ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFCED0D4)),
            const SizedBox(height: 12),

            // Action buttons: Thách đấu & Giao lưu
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Thách đấu',
                    icon: Icons.emoji_events,
                    color: const Color(0xFFFF9800),
                    onTap: () => _showChallengeModal('thach_dau'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    label: 'Giao lưu',
                    icon: Icons.groups,
                    color: const Color(0xFF0866FF),
                    onTap: () => _showChallengeModal('giao_luu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithFollow() {
    return Stack(
      children: [
        // Avatar với navigation
        GestureDetector(
          onTap: () {
            // Navigate to user profile using ProfileNavigationUtils
            ProfileNavigationUtils.navigateToUserProfile(context, widget.user);
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCED0D4), width: 2),
            ),
            child: UserAvatarWidget(
              avatarUrl: widget.user.avatarUrl,
              userName: widget.user.displayName,
              size: 76, // Slightly smaller than container (80-4 for border)
            ),
          ),
        ),

        // Follow button overlay (bottom right) với animation
        if (!_isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isProcessing ? null : _toggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isProcessing
                      ? Colors.grey
                      : (_isFollowing
                            ? const Color(0xFF42B72A)
                            : const Color(0xFF0866FF)),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isFollowing
                                  ? const Color(0xFF42B72A)
                                  : const Color(0xFF0866FF))
                              .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                        child: Icon(
                          _isFollowing ? Icons.check : Icons.person_add,
                          key: ValueKey<bool>(_isFollowing),
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  // Widget _buildDefaultAvatar() {
  //   // Tạo avatar từ chữ cái đầu của tên
  //   String initials = _getInitials(widget.user.displayName);
  //   Color backgroundColor = _getAvatarColor(widget.user.displayName);
  //   
  //   return Container(
  //     color: backgroundColor,
  //     child: Center(
  //       child: Text(
  //         initials,
  //         style: const TextStyle(
  //           fontSize: 28,
  //           fontWeight: FontWeight.w600,
  //           color: Colors.white,
  //           letterSpacing: -0.5,
  //         ),
  //       ),
  //     ),
  //   );
  // }
  
  // String _getInitials(String name) {
  //   List<String> nameParts = name.trim().split(' ');
  //   if (nameParts.length >= 2) {
  //     return '${nameParts[0][0].toUpperCase()}${nameParts[1][0].toUpperCase()}';
  //   } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
  //     return nameParts[0][0].toUpperCase();
  //   }
  //   return '?';
  // }
  
  // Color _getAvatarColor(String name) {
  //   // Tạo màu consistent dựa trên tên
  //   final colors = [
  //     const Color(0xFF1877F2), // Facebook Blue
  //     const Color(0xFF42B883), // Green
  //     const Color(0xFFE1306C), // Instagram Pink  
  //     const Color(0xFF1DA1F2), // Twitter Blue
  //     const Color(0xFFFF6B6B), // Coral Red
  //     const Color(0xFF4ECDC4), // Turquoise
  //     const Color(0xFF45B7D1), // Sky Blue
  //     const Color(0xFF96CEB4), // Mint Green
  //     const Color(0xFFFECEB7), // Peach
  //     const Color(0xFFE17055), // Orange Red
  //   ];
    
  //   int hash = name.hashCode.abs();
  //   return colors[hash % colors.length];
  // }

  /// 🚀 MUSK: Smart activity indicator
  Widget _buildActivityIndicator() {
    final lastSeen = DateTime.now().difference(widget.user.updatedAt).inDays;
    
    if (lastSeen == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF42B72A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Hoạt động',
            style: TextStyle(
              fontFamily: _getSystemFont(),
              fontSize: 11,
              color: const Color(0xFF42B72A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (lastSeen <= 7) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 12, color: Color(0xFFFF9800)),
          const SizedBox(width: 4),
          Text(
            '$lastSeen ngày trước',
            style: TextStyle(
              fontFamily: _getSystemFont(),
              fontSize: 11,
              color: const Color(0xFFFF9800),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 12, color: Color(0xFF9E9E9E)),
          const SizedBox(width: 4),
          Text(
            'Lâu rồi',
            style: TextStyle(
              fontFamily: _getSystemFont(),
              fontSize: 11,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: _getSystemFont(),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChallengeModal(String challengeType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernChallengeModal(
        player: {
          'id': widget.user.id,
          'display_name': widget.user.displayName,
          'avatar_url': widget.user.avatarUrl,
          'rank': widget.user.rank,
          'elo_rating': widget.user.eloRating,
          'total_wins': widget.user.totalWins,
          'total_losses': widget.user.totalLosses,
        },
        challengeType: challengeType,
      ),
    ).then((_) {
      // 🚀 MUSK: Smart callback - only refresh if really needed
      widget.onRefresh?.call(); // Make onRefresh optional
    });
  }

  String _getSystemFont() {
    try {
      if (Platform.isIOS) {
        return '.SF Pro Display';
      } else {
        return 'Roboto';
      }
    } catch (e) {
      return 'Roboto';
    }
  }
}
