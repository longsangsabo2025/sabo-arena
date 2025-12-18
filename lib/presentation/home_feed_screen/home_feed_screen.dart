import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart' hide AppColors;
import '../../core/design_system/design_system.dart';
import '../../core/design_system/typography_ipad.dart';
import '../../core/device/device_info.dart';
import '../../core/utils/user_friendly_messages.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/common/app_button.dart';

import '../../models/post_model.dart';
import '../../services/post_repository.dart';
import '../../services/auth_service.dart';
import '../../services/club_service.dart';
import '../../services/app_cache_service.dart';
import '../club_registration_screen/club_registration_screen.dart';
import '../other_user_profile_screen/other_user_profile_screen.dart';
import '../../widgets/comments_modal.dart';
import '../../widgets/share_bottom_sheet.dart';
import './widgets/create_post_modal_widget.dart';
import './widgets/create_post_hint_widget.dart';
import './widgets/empty_feed_widget.dart';
import './widgets/feed_tab_widget.dart';
import './widgets/feed_post_card_widget.dart';
import '../search_screen/simple_modern_search_screen.dart';

// 🎯 Coach Marks Tutorial
import '../../widgets/app_coach_marks.dart';
// ELON_MODE_AUTO_FIX

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  // bool _isPlayer = true;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late AnimationController _logoRotationController;
  late Animation<double> _logoRotationAnimation;

  // Real Supabase data
  final PostRepository _postRepository = PostRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<PostModel> _nearbyPosts = [];
  List<PostModel> _followingPosts = [];
  String? _errorMessage;

  // 🎯 iPad: Selected post for master-detail layout
  Map<String, dynamic>? _selectedPost;

  // 🎯 Coach Marks Keys
  final GlobalKey _homeFeedKey = GlobalKey();
  final GlobalKey _createPostKey = GlobalKey();
  final GlobalKey _tournamentsKey = GlobalKey();
  final GlobalKey _clubsKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  // 🎯 FACEBOOK APPROACH: Debounce like actions to prevent duplicate API calls
  final Map<String, Future<void>?> _pendingLikeRequests = {};

  // Club owner status
  bool _isClubOwner = false;
  bool _hasClub = false;

  // 🎯 Phase 3: CLB Registration Reminder
  bool _showClubReminderBanner = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers FIRST
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // Logo rotation animation for loading
    _logoRotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _logoRotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _logoRotationController, curve: Curves.linear),
    );

    _fabAnimationController.forward();

    // Setup scroll listener
    _scrollController.addListener(_onScroll);

    // Load posts AFTER animation controllers are initialized
    _loadPosts();
    // Check club owner status
    _checkClubOwnerStatus();

    // 🎯 Show coach marks after first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  /// 🎯 Show tutorial if user hasn't seen it yet
  Future<void> _showTutorialIfNeeded() async {
    final hasSeen = await CoachMarksController.hasSeenTutorial();

    if (!hasSeen && mounted) {
      // Đợi layout render xong
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      await AppCoachMarks.show(
        context: context,
        steps: [
          // Step 1: Home Feed
          CoachMarkStep(
            targetKey: _homeFeedKey,
            title: 'Trang Chủ',
            description:
                'Nơi để bạn khám phá các bài viết mới nhất từ cộng đồng Bida, '
                'theo dõi hoạt động và kết nối với người chơi khác.',
            icon: Icons.home_rounded, // 🏠 Icon trang chủ
          ),

          // Step 2: Create Post Button
          CoachMarkStep(
            targetKey: _createPostKey,
            title: 'Tạo Bài Viết',
            description:
                'Nhấn vào đây để chia sẻ khoảnh khắc, ảnh trận đấu, '
                'hoặc trải nghiệm của bạn với cộng đồng.',
            icon: Icons.add_photo_alternate_rounded, // 📸 Icon tạo bài viết
          ),

          // Step 3: Clubs Tab
          CoachMarkStep(
            targetKey: _clubsKey,
            title: 'Câu Lạc Bộ',
            description:
                'Khám phá và tham gia các câu lạc bộ Bida. '
                'Kết nối với đội nhóm và tham gia hoạt động thường xuyên.',
            icon: Icons.groups_rounded, // 👥 Icon câu lạc bộ
          ),

          // Step 4: Tournaments Tab
          CoachMarkStep(
            targetKey: _tournamentsKey,
            title: 'Giải Đấu',
            description:
                'Xem lịch thi đấu, đăng ký tham gia và theo dõi kết quả. '
                'Nâng cao kỹ năng và tranh tài với các cao thủ.',
            icon: Icons.emoji_events_rounded, // 🏆 Icon giải đấu
          ),

          // Step 5: Profile Tab
          CoachMarkStep(
            targetKey: _profileKey,
            title: 'Trang Cá Nhân',
            description:
                'Quản lý hồ sơ, xem thống kê và hạng của bạn. '
                'Đăng ký xác minh hạng để tham gia giải đấu chính thức.',
            icon: Icons.person_rounded, // 👤 Icon profile
          ),
        ],
        onComplete: () async {
          await CoachMarksController.markTutorialAsSeen();
        },
        onSkip: () async {
          await CoachMarksController.markTutorialAsSeen();
        },
      );
    }
  }

  Future<void> _loadPosts() async {
    try {
      // 🚀 PHASE 2: Load from cache first for instant display
      final cachedNearby = await AppCacheService.instance.getCache('home_feed_nearby');
      final cachedFollowing = await AppCacheService.instance.getCache('home_feed_following');
      
      if (cachedNearby != null && cachedFollowing != null) {
        if (mounted) {
          setState(() {
            _nearbyPosts = (cachedNearby as List).map((json) => PostModel.fromJson(json)).toList();
            _followingPosts = (cachedFollowing as List).map((json) => PostModel.fromJson(json)).toList();
            _isLoading = false; // No spinner, show cached data immediately
          });
        }
      } else {
        // No cache, show loading spinner
        if (mounted) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
          _logoRotationController.repeat();
        }
      }

      // 📡 Then fetch fresh data in background (Facebook approach)
      final nearbyFuture = _postRepository.getNearbyFeed(limit: 20);
      final followingFuture = _postRepository.getFollowingFeed(limit: 20);

      // Wait for both to complete in parallel
      final results = await Future.wait([nearbyFuture, followingFuture]);

      if (mounted) {
        setState(() {
          _nearbyPosts = results[0]; // Nearby/All posts
          _followingPosts = results[1]; // Posts from followed users
          _isLoading = false;
        });
        _logoRotationController.stop();
        
        // 💾 Save fresh data to cache for next time
        await AppCacheService.instance.setCache(
          key: 'home_feed_nearby',
          data: results[0].map((post) => post.toJson()).toList(),
          ttl: const Duration(minutes: 5), // Cache for 5 minutes
        );
        await AppCacheService.instance.setCache(
          key: 'home_feed_following',
          data: results[1].map((post) => post.toJson()).toList(),
          ttl: const Duration(minutes: 5),
        );
        
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi tải bài đăng: $e';
        });
        _logoRotationController.stop();
      }
    }
  }

  // Convert PostModel to Map for backwards compatibility
  Map<String, dynamic> _postToMap(PostModel post) {
    return {
      'id': post.id,
      'userId': post.authorId, // Add userId for navigation
      'userName': post
          .authorName, // Use authorName from PostModel (already prioritizes display_name)
      'userAvatar':
          post.authorAvatarUrl ??
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'userRank': null, // TODO: Get user rank
      'content': post.content,
      'imageUrl': post.imageUrl, // Use imageUrl from PostModel
      'location': '', // PostModel doesn't have location
      'hashtags': post.tags ?? [], // Use tags from PostModel
      'timestamp': post.createdAt,
      'likeCount': post.likeCount,
      'commentCount': post.commentCount,
      'shareCount': post.shareCount,
      'isLiked': post.isLiked, // Use isLiked from PostModel
      'isSaved': post.isSaved, // Use isSaved from PostModel
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _logoRotationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      // Load more posts based on current tab with separate feeds
      final currentList = _selectedTabIndex == 0
          ? _nearbyPosts
          : _followingPosts;

      final morePosts = _selectedTabIndex == 0
          ? await _postRepository.getNearbyFeed(
              offset: currentList.length,
              limit: 10,
            )
          : await _postRepository.getFollowingFeed(
              offset: currentList.length,
              limit: 10,
            );

      if (mounted) {
        setState(() {
          if (_selectedTabIndex == 0) {
            _nearbyPosts.addAll(morePosts);
          } else {
            _followingPosts.addAll(morePosts);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyMessages.getErrorMessage(e, context: 'Tải bài đăng'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFeed() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      await _loadPosts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật bảng tin'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostModalWidget(
        onPostCreated: () {
          _refreshFeed();
        },
      ),
    );
  }

  Future<void> _handlePostAction(
    String action,
    dynamic post, // Can be PostModel or Map
  ) async {
    switch (action) {
      case 'like':
        await _handleLikeToggle(post);
        break;
      case 'comment':
        _showCommentsModal(post);
        break;
      case 'share':
        await _handleSharePost(post);
        break;
    }
  }

  Future<void> _handleLikeToggle(dynamic postData) async {
    // Extract post ID
    final postId = postData is PostModel ? postData.id : postData['id'];

    // 🎯 FACEBOOK APPROACH: Cancel previous request if user clicks again
    if (_pendingLikeRequests.containsKey(postId)) {
      // Already processing - ignore duplicate clicks
      return;
    }

    // Get current like status (save for error message)
    final currentlyLiked = postData is PostModel 
        ? postData.isLiked 
        : (postData['isLiked'] ?? false);

    try {

      // 🎯 Optimistic UI update - update the PostModel in list
      final targetList = _selectedTabIndex == 0 ? _nearbyPosts : _followingPosts;
      final index = targetList.indexWhere((p) => p.id == postId);
      
      if (index != -1 && mounted) {
        setState(() {
          targetList[index] = PostModel(
            id: targetList[index].id,
            title: targetList[index].title,
            content: targetList[index].content,
            authorId: targetList[index].authorId,
            authorName: targetList[index].authorName,
            authorAvatarUrl: targetList[index].authorAvatarUrl,
            imageUrl: targetList[index].imageUrl,
            createdAt: targetList[index].createdAt,
            tags: targetList[index].tags,
            commentCount: targetList[index].commentCount,
            shareCount: targetList[index].shareCount,
            // Toggle like
            isLiked: !currentlyLiked,
            likeCount: targetList[index].likeCount + (!currentlyLiked ? 1 : -1),
          );
        });
      }

      // Mark as pending and execute API call
      final request = _executeLikeRequest(postId, !currentlyLiked);
      _pendingLikeRequests[postId] = request;

      await request;
      
      // � PHASE 2: Invalidate cache after like/unlike to ensure fresh data next time
      await AppCacheService.instance.removeCache('home_feed_nearby');
      await AppCacheService.instance.removeCache('home_feed_following');
      
      // �🔄 Sync isLiked from DB sau khi API thành công
      await _reloadPost(postId);
    } catch (e) {
      
      // ✅ Revert on error
      final targetList = _selectedTabIndex == 0 ? _nearbyPosts : _followingPosts;
      final index = targetList.indexWhere((p) => p.id == postId);
      
      if (index != -1 && mounted) {
        setState(() {
          targetList[index] = PostModel(
            id: targetList[index].id,
            title: targetList[index].title,
            content: targetList[index].content,
            authorId: targetList[index].authorId,
            authorName: targetList[index].authorName,
            authorAvatarUrl: targetList[index].authorAvatarUrl,
            imageUrl: targetList[index].imageUrl,
            createdAt: targetList[index].createdAt,
            tags: targetList[index].tags,
            commentCount: targetList[index].commentCount,
            shareCount: targetList[index].shareCount,
            // Revert toggle
            isLiked: !targetList[index].isLiked,
            likeCount: targetList[index].likeCount + (targetList[index].isLiked ? -1 : 1),
          );
        });
      }

      // 🎯 User-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Không thể ${currentlyLiked ? 'bỏ thích' : 'thích'} bài viết. Vui lòng thử lại.',
            ),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // Clean up pending request
      _pendingLikeRequests.remove(postId);
    }
  }

  Future<void> _executeLikeRequest(String postId, bool shouldLike) async {
    try {
      if (shouldLike) {
        await _postRepository.likePost(postId);
      } else {
        await _postRepository.unlikePost(postId);
      }
    } catch (e) {
      rethrow;
    }
  }

  void _showCommentsModal(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(
        postId: post['id'],
        postTitle: post['content'] ?? 'Bài viết',
        onCommentAdded: () async {
          // Update comment count when new comment is added
          if (mounted) {
            setState(() {
              post['commentCount'] = (post['commentCount'] ?? 0) + 1;
            });
          }
          // 🔄 Sync from database to ensure accuracy
          await _reloadPost(post['id']);
        },
        onCommentDeleted: () async {
          // Update comment count when comment is deleted
          if (mounted) {
            setState(() {
              final currentCount = post['commentCount'] ?? 0;
              post['commentCount'] = (currentCount - 1).clamp(0, currentCount);
            });
          }
          // 🔄 Sync from database to ensure accuracy
          await _reloadPost(post['id']);
        },
      ),
    );
  }

  // 🔄 PHASE 2: Reload single post from database to sync counts
  Future<void> _reloadPost(String postId) async {
    try {
      // Determine which list to update
      final targetList = _selectedTabIndex == 0
          ? _nearbyPosts
          : _followingPosts;

      // Find the post in the list
      final index = targetList.indexWhere((p) => p.id == postId);
      if (index == -1) return;

      // Fetch fresh data from database (counts + isLiked)
      final response = await Supabase.instance.client
          .from('posts')
          .select('comment_count, share_count, like_count')
          .eq('id', postId)
          .single();
      
      // 🔄 Re-check if user has liked this post
      final isLiked = await _postRepository.hasUserLikedPost(postId);

      if (mounted) {
        setState(() {
          targetList[index] = PostModel(
            id: targetList[index].id,
            title: targetList[index].title,
            content: targetList[index].content,
            authorId: targetList[index].authorId,
            authorName: targetList[index].authorName,
            authorAvatarUrl: targetList[index].authorAvatarUrl,
            imageUrl: targetList[index].imageUrl,
            createdAt: targetList[index].createdAt,
            tags: targetList[index].tags,
            // 🔄 Update counts and isLiked from database
            commentCount: response['comment_count'] ?? 0,
            shareCount: response['share_count'] ?? 0,
            likeCount: response['like_count'] ?? 0,
            isLiked: isLiked, // ✅ Sync from database
          );
        });
      }
    } catch (e) {
      // Silent fail - counts will sync on next refresh
    }
  }

  Future<void> _handleSharePost(Map<String, dynamic> post) async {
    // Optimistic update: increment share count immediately
    final targetList = _selectedTabIndex == 0 ? _nearbyPosts : _followingPosts;
    final index = targetList.indexWhere((p) => p.id == post['id']);

    if (index != -1 && mounted) {
      setState(() {
        targetList[index] = PostModel(
          id: targetList[index].id,
          title: targetList[index].title,
          content: targetList[index].content,
          authorId: targetList[index].authorId,
          authorName: targetList[index].authorName,
          authorAvatarUrl: targetList[index].authorAvatarUrl,
          imageUrl: targetList[index].imageUrl,
          createdAt: targetList[index].createdAt,
          tags: targetList[index].tags,
          commentCount: targetList[index].commentCount,
          likeCount: targetList[index].likeCount,
          isLiked: targetList[index].isLiked,
          // 🚀 Increment share count optimistically
          shareCount: targetList[index].shareCount + 1,
        );
      });
    }

    // Show share modal with full post data
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        postId: post['id'],
        postTitle: post['content'] ?? 'Bài viết',
        postContent: post['content'],
        postImageUrl: post['imageUrl'],
        authorName: post['authorName'] ?? post['author_name'] ?? 'Không xác định',
        authorAvatar: post['authorAvatarUrl'] ?? post['author_avatar_url'],
        likeCount: post['likeCount'] ?? post['like_count'] ?? 0,
        commentCount: post['commentCount'] ?? post['comment_count'] ?? 0,
        shareCount: post['shareCount'] ?? post['share_count'] ?? 0,
        createdAt: DateTime.tryParse(post['createdAt']?.toString() ?? post['created_at']?.toString() ?? '') ?? DateTime.now(),
      ),
    );

    // Reload from database to sync count (whether shared or canceled)
    if (result == true || result == null) {
      await _reloadPost(post['id']);
    }
  }

  Future<void> _handleSavePost(Map<String, dynamic> post) async {
    try {
      final postId = post['id'];
      final success = await _postRepository.savePost(postId);

      if (mounted && success) {
        // ✅ Update isSaved state in PostModel
        final targetList = _selectedTabIndex == 0
            ? _nearbyPosts
            : _followingPosts;
        final index = targetList.indexWhere((p) => p.id == postId);

        if (index != -1) {
          setState(() {
            targetList[index] = PostModel(
              id: targetList[index].id,
              title: targetList[index].title,
              content: targetList[index].content,
              authorId: targetList[index].authorId,
              authorName: targetList[index].authorName,
              authorAvatarUrl: targetList[index].authorAvatarUrl,
              imageUrl: targetList[index].imageUrl,
              createdAt: targetList[index].createdAt,
              tags: targetList[index].tags,
              commentCount: targetList[index].commentCount,
              shareCount: targetList[index].shareCount,
              likeCount: targetList[index].likeCount,
              isLiked: targetList[index].isLiked,
              // 🔖 Mark as saved
              isSaved: true,
            );
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã lưu bài viết'),
            action: SnackBarAction(
              label: 'Xem',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.userProfileScreen);
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Lỗi lưu bài viết')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyMessages.getErrorMessage(e, context: 'Thao tác'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleHidePost(Map<String, dynamic> post) async {
    try {
      final postId = post['id'];
      final success = await _postRepository.hidePost(postId);

      if (mounted && success) {
        // Remove post from current list
        setState(() {
          if (_selectedTabIndex == 0) {
            _nearbyPosts.removeWhere((p) => p.id == postId);
          } else {
            _followingPosts.removeWhere((p) => p.id == postId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã ẩn bài viết'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Lỗi ẩn bài viết')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyMessages.getErrorMessage(e, context: 'Thao tác'),
            ),
          ),
        );
      }
    }
  }

  void _handleUserTap(Map<String, dynamic> post) {
    final userId = post['userId'];
    final currentUserId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xem profile người dùng')),
      );
      return;
    }

    // If it's current user, go to own profile
    if (userId == currentUserId) {
      Navigator.pushNamed(
        context,
        AppRoutes.userProfileScreen,
        arguments: {'userId': userId, 'isCurrentUser': true},
      );
    } else {
      // If it's another user, go to OtherUserProfileScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtherUserProfileScreen(
            userId: userId,
            userName: post['userName'],
          ),
        ),
      );
    }
  }

  // 🚀 MUSK: Old search methods removed - using ModernSearchScreen now

  // void _handleNavigation(String route) {
  //   if (route != AppRoutes.homeFeedScreen) {
  //     Navigator.pushReplacementNamed(context, route);
  //   }
  // }

  List<Map<String, dynamic>> get _currentPosts {
    final postModels = _selectedTabIndex == 0 ? _nearbyPosts : _followingPosts;
    return postModels.map((post) => _postToMap(post)).toList();
  }

  bool get _isEmpty {
    return _currentPosts.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 iPad detection
    final isIPad = DeviceInfo.isIPad(context);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final showMasterDetail = isIPad && isLandscape;

    return Scaffold(
      backgroundColor: AppColors.surface, // White background
      appBar: CustomAppBar.homeFeed(
        onNotificationTap: () {
          Navigator.pushNamed(context, AppRoutes.notificationListScreen);
        },
        onSearchTap: () {
          // 🚀 MUSK: Navigate to modern search screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernSearchScreen(),
            ),
          );
        },
      ),
      body: SafeArea(
        child: showMasterDetail
            ? _buildMasterDetailLayout()
            : _buildSingleColumnLayout(),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale:
                _fabAnimation.value *
                (1 + 0.1 * (1 - _fabAnimation.value)), // Zoom effect
            child: Container(
              key: _createPostKey, // 🎯 Coach mark target
              child: FloatingActionButton(
                heroTag: 'home_feed_create_post',
                onPressed: _showCreatePostModal,
                tooltip: 'Tạo bài viết',
                backgroundColor: AppColors.primary,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.textOnPrimary,
                  size: 32, // Large icon size
                ),
              ),
            ),
          );
        },
      ),
      // 🎯 PHASE 1: Bottom navigation moved to PersistentTabScaffold
      // No bottomNavigationBar here to prevent duplicate navigation bars
    );
  }

  // 🎯 iPad Master-Detail Layout
  Widget _buildMasterDetailLayout() {
    return Row(
      children: [
        // Master Panel (40% - Feed list)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
            ),
            child: _buildSingleColumnLayout(),
          ),
        ),

        // Detail Panel (60% - Post detail)
        Expanded(
          child: _selectedPost != null
              ? _buildPostDetailPanel(_selectedPost!)
              : _buildEmptyDetailPanel(),
        ),
      ],
    );
  }

  // 🎯 Empty state for detail panel
  Widget _buildEmptyDetailPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 24),
          Text(
            'Chọn bài viết để xem chi tiết',
            style: TextStyle(
              fontSize: context.scaleFont(18),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bấm vào bài viết bên trái để xem nội dung đầy đủ',
            style: TextStyle(
              fontSize: context.scaleFont(14),
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🎯 Post detail panel for iPad
  Widget _buildPostDetailPanel(Map<String, dynamic> post) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post card with full details
          FeedPostCardWidget(
            key: ValueKey(post['id']),
            post: post,
            onLike: () => _handlePostAction('like', post),
            onComment: () => _handlePostAction('comment', post),
            onShare: () => _handlePostAction('share', post),
            onUserTap: () => _handleUserTap(post),
            onSave: () => _handleSavePost(post),
            onHide: () => _handleHidePost(post),
          ),
          
          // Comments section would go here
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Bình luận',
            style: TextStyle(
              fontSize: context.scaleFont(18),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // TODO: Add comments list here
          Center(
            child: Text(
              'Chức năng bình luận sẽ được thêm sau',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: context.scaleFont(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 Single column layout for iPhone/iPad portrait
  Widget _buildSingleColumnLayout() {
    return Column(
      children: [
        // Feed tabs
        FeedTabWidget(
          selectedIndex: _selectedTabIndex,
          onTabChanged: (index) {
            if (mounted) setState(() => _selectedTabIndex = index);
          },
        ),

        // Feed content
        Expanded(
              child: _isLoading && _currentPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Rotating Logo Loading
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(8.0),
                            child: AnimatedBuilder(
                              animation: _logoRotationAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _logoRotationAnimation.value,
                                  child: SvgPicture.asset(
                                    'assets/images/logo.svg',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Đang tải bảng tin...', overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Vui lòng đợi một chút', overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                  ? RefreshableErrorStateWidget(
                      errorMessage: _errorMessage,
                      onRefresh: _refreshFeed,
                      title: 'Không thể tải bài đăng',
                      description:
                          'Đã xảy ra lỗi khi tải bài đăng từ cộng đồng',
                      showErrorDetails: true,
                    )
                  : _isEmpty
                  ? EmptyFeedWidget(
                      isNearbyTab: _selectedTabIndex == 0,
                      onCreatePost: _showCreatePostModal,
                      onFindFriends: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.findOpponentsScreen,
                        );
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshFeed,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 1.h),
                        itemCount:
                            1 +
                            (_isClubOwner && !_hasClub ? 1 : 0) +
                            (_showClubReminderBanner ? 1 : 0) + // 🎯 Phase 3
                            _currentPosts.length +
                            (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show create post hint first
                          if (index == 0) {
                            return CreatePostHintWidget(
                              onTap: _showCreatePostModal,
                            );
                          }

                          // Show club owner banner if applicable
                          if (_isClubOwner && !_hasClub && index == 1) {
                            return _buildClubOwnerBanner();
                          }

                          // 🎯 Phase 3: Show CLB reminder banner if applicable
                          if (_showClubReminderBanner &&
                              index == (_isClubOwner && !_hasClub ? 2 : 1)) {
                            return _buildClubReminderBanner();
                          }

                          // Adjust index for actual posts
                          int adjustedIndex =
                              index - 1; // -1 for create post hint
                          if (_isClubOwner && !_hasClub) adjustedIndex--;
                          if (_showClubReminderBanner)
                            adjustedIndex--; // -1 for reminder banner
                          final postIndex = adjustedIndex;
                          if (postIndex == _currentPosts.length) {
                            return Container(
                              padding: EdgeInsets.all(4.w),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = _currentPosts[postIndex];
                          
                          // 🎯 iPad: Handle tap to update selected post
                          final isIPad = DeviceInfo.isIPad(context);
                          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                          final showMasterDetail = isIPad && isLandscape;
                          final isSelected = showMasterDetail && _selectedPost?['id'] == post['id'];
                          
                          return GestureDetector(
                            onTap: showMasterDetail
                                ? () {
                                    if (mounted) {
                                      setState(() {
                                        _selectedPost = post;
                                      });
                                    }
                                  }
                                : null,
                            child: Container(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
                              child: FeedPostCardWidget(
                                key: ValueKey(post['id']), // Force rebuild when post changes
                                post: post,
                                onLike: () => _handlePostAction('like', post),
                                onComment: () => _handlePostAction('comment', post),
                                onShare: () => _handlePostAction('share', post),
                                onUserTap: () => _handleUserTap(post),
                                onSave: () => _handleSavePost(post),
                                onHide: () => _handleHidePost(post),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }

  Future<void> _checkClubOwnerStatus() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      // Check user role
      final userRole = await AuthService.instance.getCurrentUserRole();

      if (userRole == 'club_owner') {
        // Check if user has any clubs
        final club = await ClubService.instance.getFirstClubForUser(user.id);

        // 🎯 Phase 3: Check pending CLB registration flag
        await _checkPendingClubRegistration();

        if (mounted) {
          setState(() {
            _isClubOwner = true;
            _hasClub = club != null;
            // _isPlayer = false;
          });
        }
      } else if (userRole == 'player') {
        if (mounted) {
          setState(() {
            // _isPlayer = true;
            _isClubOwner = false;
          });
        }
      }
    } catch (e) {
      // Ignore error
    }
  }

  // 🎯 Phase 3: Check if user has pending CLB registration
  Future<void> _checkPendingClubRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPending = prefs.getBool('pending_club_registration') ?? false;
      final dismissed = prefs.getBool('dismissed_club_reminder') ?? false;

      if (mounted) {
        setState(() {
          _showClubReminderBanner = hasPending && !dismissed && !_hasClub;
        });
      }

    } catch (e) {
      // Ignore error
    }
  }

  // 🎯 Phase 3: Dismiss reminder banner
  Future<void> _dismissClubReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dismissed_club_reminder', true);

      if (mounted) {
        setState(() {
          _showClubReminderBanner = false;
        });
      }

      // Ignore error
    } catch (e) {
      // Ignore error
    }
  }

  // 🎯 Phase 3: Clear pending flag when user navigates to CLB registration
  Future<void> _navigateToClubRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pending_club_registration', false);
      await prefs.setBool('dismissed_club_reminder', false);

      if (mounted) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => const ClubRegistrationScreen(),
              ),
            )
            .then((_) {
              // Refresh club status after returning
              _checkClubOwnerStatus();
            });
      }

      // Ignore error
    } catch (e) {
      // Ignore error
    }
  }

  Widget _buildClubOwnerBanner() {
    if (!_isClubOwner || _hasClub) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info50, AppColors.success50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info100, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.info100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: AppColors.info700,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chủ CLB', overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info700,
                      ),
                    ),
                    Text(
                      'Bạn chưa đăng ký câu lạc bộ', overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.info600,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Đăng ký CLB',
                type: AppButtonType.primary,
                size: AppButtonSize.medium,
                customColor: AppColors.info600,
                customTextColor: AppColors.textOnPrimary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClubRegistrationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '🏢 Tạo và quản lý câu lạc bộ của bạn\n'
            '🎯 Tổ chức giải đấu và sự kiện\n'
            '👥 Thu hút thành viên mới', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.info700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 Phase 3: CLB Registration Reminder Banner
  Widget _buildClubReminderBanner() {
    if (!_showClubReminderBanner) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.info50, AppColors.info100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info600.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.info600.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and dismiss button
          Row(
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.info700, AppColors.info600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info600.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business_center,
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  'Hoàn tất đăng ký CLB', overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info700,
                  ),
                ),
              ),
              // Dismiss button
              IconButton(
                onPressed: _dismissClubReminder,
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Đóng',
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Description
          Text(
            'Bạn chưa hoàn thành đăng ký câu lạc bộ.\n'
            'Hoàn tất ngay để bắt đầu quản lý CLB của bạn!', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 11.5.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          SizedBox(height: 2.h),

          // Action button với gradient (giữ nguyên gradient design)
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.info700, AppColors.info600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppButton(
                label: 'Đăng ký ngay',
                type: AppButtonType.primary,
                size: AppButtonSize.large,
                icon: Icons.arrow_forward,
                iconTrailing: false,
                customColor: Colors.transparent, // Gradient sẽ override
                customTextColor: AppColors.textOnPrimary,
                fullWidth: true,
                onPressed: _navigateToClubRegistration,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

