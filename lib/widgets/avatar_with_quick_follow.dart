import 'dart:async';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../presentation/other_user_profile_screen/other_user_profile_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart';
import 'user/user_avatar_widget.dart';

/// Global stream to broadcast follow/unfollow events
class FollowEventBroadcaster {
  static final _controller = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get stream => _controller.stream;

  static void notifyFollowChanged(String userId, bool isFollowing) {
    _controller.add({'userId': userId, 'isFollowing': isFollowing});
  }
}

/// Avatar widget with quick follow button
/// Shows a small "+" button on avatar for users you haven't followed yet
class AvatarWithQuickFollow extends StatefulWidget {
  final String userId;
  final String? avatarUrl;
  final double size;
  final bool isFollowing;
  final VoidCallback? onFollowChanged;
  final bool showQuickFollow;

  const AvatarWithQuickFollow({
    Key? key,
    required this.userId,
    this.avatarUrl,
    this.size = 40.0,
    this.isFollowing = false,
    this.onFollowChanged,
    this.showQuickFollow = true,
  }) : super(key: key);

  @override
  State<AvatarWithQuickFollow> createState() => _AvatarWithQuickFollowState();
}

class _AvatarWithQuickFollowState extends State<AvatarWithQuickFollow>
    with WidgetsBindingObserver {
  final UserService _userService = UserService.instance;
  bool _isFollowing = false;
  bool _isProcessing = false;
  bool _showCheckmark = false;
  bool _isCurrentUser = false; // NEW: Track if this is current user
  DateTime? _lastChecked;
  StreamSubscription? _followEventSubscription;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
    _checkCurrentUserAndFollowStatus();
    // Listen to app lifecycle to refresh when returning to screen
    WidgetsBinding.instance.addObserver(this);

    // Listen to global follow/unfollow events
    _followEventSubscription = FollowEventBroadcaster.stream.listen((event) {
      if (event['userId'] == widget.userId && mounted) {
        setState(() {
          _isFollowing = event['isFollowing'] as bool;
        });
      }
    });
  }

  @override
  void dispose() {
    _followEventSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh follow status when app becomes active again
    if (state == AppLifecycleState.resumed) {
      // Only check if more than 2 seconds have passed since last check
      final now = DateTime.now();
      if (_lastChecked == null || now.difference(_lastChecked!).inSeconds > 2) {
        _checkCurrentUserAndFollowStatus();
      }
    }
  }

  @override
  void didUpdateWidget(AvatarWithQuickFollow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      setState(() => _isFollowing = widget.isFollowing);
    }
    // Also check if userId changed - need to recheck follow status
    if (oldWidget.userId != widget.userId) {
      _checkCurrentUserAndFollowStatus();
    }

    // Refresh if cache is stale (more than 3 seconds old)
    final now = DateTime.now();
    if (_lastChecked != null && now.difference(_lastChecked!).inSeconds > 3) {
      _checkCurrentUserAndFollowStatus();
    }
  }

  Future<void> _checkCurrentUserAndFollowStatus() async {
    try {
      _lastChecked = DateTime.now();

      // Check if this is current user's own profile
      final currentUserProfile = await _userService.getCurrentUserProfile();
      if (currentUserProfile?.id == widget.userId) {
        // Don't show follow button for own profile
        if (mounted) {
          setState(() => _isCurrentUser = true);
        }
        return;
      }

      // Not current user, check actual follow status from server
      final isFollowing = await _userService.isFollowingUser(widget.userId);
      if (mounted) {
        setState(() {
          _isCurrentUser = false;
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      ProductionLogger.error('Error checking follow status: $e', error: e);
    }
  }

  Future<void> _handleQuickFollow() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _userService.followUser(widget.userId);

      if (mounted) {
        setState(() {
          _isFollowing = true;
          _showCheckmark = true;
          _isProcessing = false;
        });

        // Broadcast follow event globally
        FollowEventBroadcaster.notifyFollowChanged(widget.userId, true);

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã theo dõi'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // Hide checkmark after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _showCheckmark = false);
          }
        });

        // Notify parent widget
        widget.onFollowChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể theo dõi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUnfollow() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _userService.unfollowUser(widget.userId);

      if (mounted) {
        setState(() {
          _isFollowing = false;
          _isProcessing = false;
        });

        // Broadcast unfollow event globally
        FollowEventBroadcaster.notifyFollowChanged(widget.userId, false);

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.person_remove, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã bỏ theo dõi'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );

        // Notify parent widget
        widget.onFollowChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể bỏ theo dõi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _shouldShowQuickFollowButton {
    // Don't show if:
    // - Quick follow is disabled
    // - This is current user (can't follow yourself)
    // - Already following
    // - Processing
    // - Showing checkmark
    return widget.showQuickFollow &&
        !_isCurrentUser && // NEW: Don't show for current user
        !_isFollowing &&
        !_isProcessing &&
        !_showCheckmark;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate to user profile on avatar tap
        final currentUserProfile = await _userService.getCurrentUserProfile();
        if (currentUserProfile?.id != widget.userId) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OtherUserProfileScreen(userId: widget.userId),
              ),
            );
          }
        }
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            // Avatar
            UserAvatarWidget(
              avatarUrl: widget.avatarUrl,
              size: widget.size,
            ),

            // Quick follow button (bottom right corner) - when NOT following
            if (_shouldShowQuickFollowButton)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _handleQuickFollow,
                  child: Container(
                    width: widget.size * 0.35,
                    height: widget.size * 0.35,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: widget.size * 0.2,
                    ),
                  ),
                ),
              ),

            // Following badge - when ALREADY following (tap to unfollow)
            if (_isFollowing &&
                !_isProcessing &&
                !_showCheckmark &&
                widget.showQuickFollow)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _handleUnfollow,
                  child: Container(
                    width: widget.size * 0.35,
                    height: widget.size * 0.35,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: widget.size * 0.2,
                    ),
                  ),
                ),
              ),

            // Checkmark after successful follow (temporary - 2 seconds)
            if (_showCheckmark)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: widget.size * 0.35,
                  height: widget.size * 0.35,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: widget.size * 0.2,
                  ),
                ),
              ),

            // Loading indicator
            if (_isProcessing)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: widget.size * 0.35,
                  height: widget.size * 0.35,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(widget.size * 0.08),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
