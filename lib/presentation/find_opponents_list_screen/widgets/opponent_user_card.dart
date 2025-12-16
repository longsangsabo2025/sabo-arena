import 'package:flutter/material.dart';
import 'dart:io';
import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../../utils/profile_navigation_utils.dart';
import '../../../widgets/avatar_with_quick_follow.dart'; // Import FollowEventBroadcaster
import '../../find_opponents_screen/widgets/modern_challenge_modal.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Facebook-style user card với Follow button và action buttons
class OpponentUserCard extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onRefresh;

  const OpponentUserCard({
    super.key,
    required this.user,
    required this.onRefresh,
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

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await _userService.isFollowingUser(widget.user.id);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Có lỗi xảy ra: $e',
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
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
                          _buildRankBadge(),
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
                          // TODO: Re-enable when distance feature is implemented
                          // if (widget.user.distance != null) ...[
                          //   const SizedBox(width: 12),
                          //   const Icon(Icons.location_on, size: 14, color: Color(0xFF65676B)),
                          //   const SizedBox(width: 4),
                          //   Text(
                          //     '${widget.user.distance!.toStringAsFixed(1)} km',
                          //     style: TextStyle(
                          //       fontFamily: _getSystemFont(),
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
            child: ClipOval(
              child: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                  ? Image.network(
                      widget.user.avatarUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildDefaultAvatar();
                      },
                      errorBuilder: (_, __, ___) {
                        ProductionLogger.info('🖼️ Failed to load avatar: ${widget.user.avatarUrl}', tag: 'opponent_user_card');
                        return _buildDefaultAvatar();
                      },
                    )
                  : _buildDefaultAvatar(),
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

  Widget _buildDefaultAvatar() {
    // Tạo avatar từ chữ cái đầu của tên
    String initials = _getInitials(widget.user.displayName);
    Color backgroundColor = _getAvatarColor(widget.user.displayName);
    
    return Container(
      color: backgroundColor,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
  
  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0].toUpperCase()}${nameParts[1][0].toUpperCase()}';
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return '?';
  }
  
  Color _getAvatarColor(String name) {
    // Tạo màu consistent dựa trên tên
    final colors = [
      const Color(0xFF1877F2), // Facebook Blue
      const Color(0xFF42B883), // Green
      const Color(0xFFE1306C), // Instagram Pink  
      const Color(0xFF1DA1F2), // Twitter Blue
      const Color(0xFFFF6B6B), // Coral Red
      const Color(0xFF4ECDC4), // Turquoise
      const Color(0xFF45B7D1), // Sky Blue
      const Color(0xFF96CEB4), // Mint Green
      const Color(0xFFFECEB7), // Peach
      const Color(0xFFE17055), // Orange Red
    ];
    
    int hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _buildRankBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getRankColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.user.rank ?? 'Chưa xếp hạng',
        style: TextStyle(
          fontFamily: _getSystemFont(),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getRankColor(),
        ),
      ),
    );
  }

  Color _getRankColor() {
    switch (widget.user.rank) {
      case 'Cao cấp':
        return const Color(0xFFD32F2F);
      case 'Trung cấp':
        return const Color(0xFFFF9800);
      case 'Sơ cấp':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF65676B);
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
    ).then((_) => widget.onRefresh());
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
