import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../home_feed_screen/widgets/feed_post_card_widget.dart';
import '../../services/post_repository.dart';
import '../../theme/app_bar_theme.dart' as app_theme;
import '../../widgets/comments_modal.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../../core/app_export.dart';
// ELON_MODE_AUTO_FIX

/// Màn hình chi tiết bài đăng - hiển thị bài đăng dạng full screen với lazy loading
class PostDetailScreen extends StatefulWidget {
  final PostModel? post;
  final String? postId;
  final String? userId; // User ID để load thêm posts
  final int initialIndex;

  const PostDetailScreen({
    super.key,
    this.post,
    this.postId,
    this.userId,
    this.initialIndex = 0,
  }) : assert(post != null || postId != null,
            'Either post or postId must be provided');

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final PostRepository _postRepository = PostRepository();

  // Posts list with lazy loading
  List<PostModel> _posts = [];
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  int _currentOffset = 0;
  static const int _pageSize = 10; // Load 10 posts at a time

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _initData();

    // Listen to page changes to trigger lazy loading
    _pageController.addListener(_onPageScroll);
  }

  Future<void> _initData() async {
    if (widget.post != null) {
      _posts = [widget.post!];
      _loadInitialPosts(); // Load more posts related to this user/context
    } else if (widget.postId != null) {
      try {
        final post = await _postRepository.getPostById(widget.postId!);
        if (post != null) {
          if (mounted) {
            setState(() {
              _posts = [post];
            });
            _loadInitialPosts();
          }
        } else {
          // Handle post not found
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post not found')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading post: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPosts() async {
    // If userId is not provided, try to get it from the first post
    final targetUserId =
        widget.userId ?? (_posts.isNotEmpty ? _posts.first.authorId : null);

    if (targetUserId == null) return;

    try {
      final posts = await _postRepository.getUserPostsByUserId(
        targetUserId,
        limit: _pageSize,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          // If we already have a post (from notification), keep it at the top if it's not in the list
          if (_posts.isNotEmpty && widget.userId == null) {
            final currentPostId = _posts.first.id;
            // Filter out the current post from the fetched list to avoid duplicates
            final newPosts = posts.where((p) => p.id != currentPostId).toList();
            _posts.addAll(newPosts);
          } else {
            _posts = posts;
          }

          _currentOffset = _posts.length;
          _hasMorePosts = posts.length >= _pageSize;
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  void _onPageScroll() {
    // Load more when user is near the end (3 posts before the end)
    if (_currentIndex >= _posts.length - 3 &&
        !_isLoadingMore &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;

    final targetUserId =
        widget.userId ?? (_posts.isNotEmpty ? _posts.first.authorId : null);
    if (targetUserId == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final morePosts = await _postRepository.getUserPostsByUserId(
        targetUserId,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(morePosts);
          _currentOffset += morePosts.length;
          _hasMorePosts = morePosts.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _handleLikeToggle(Map<String, dynamic> post) async {
    try {
      final postId = post['id'] as String;
      final isLiked = post['isLiked'] as bool;

      if (isLiked) {
        await _postRepository.unlikePost(postId);
      } else {
        await _postRepository.likePost(postId);
      }
    } catch (e) {
      // Ignore error
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
          // Update comment count
          if (mounted) {
            final postId = post['id'];
            final index = _posts.indexWhere((p) => p.id == postId);
            if (index != -1) {
              setState(() {
                _posts[index] = PostModel(
                  id: _posts[index].id,
                  title: _posts[index].title,
                  content: _posts[index].content,
                  authorId: _posts[index].authorId,
                  authorName: _posts[index].authorName,
                  authorAvatarUrl: _posts[index].authorAvatarUrl,
                  imageUrl: _posts[index].imageUrl,
                  videoUrl: _posts[index].videoUrl,
                  createdAt: _posts[index].createdAt,
                  tags: _posts[index].tags,
                  likeCount: _posts[index].likeCount,
                  shareCount: _posts[index].shareCount,
                  isLiked: _posts[index].isLiked,
                  isSaved: _posts[index].isSaved,
                  // 💬 Increment comment count
                  commentCount: _posts[index].commentCount + 1,
                );
              });
            }
          }
          // Reload the current post
          await _loadMorePosts();
        },
        onCommentDeleted: () async {
          // Update comment count
          if (mounted) {
            final postId = post['id'];
            final index = _posts.indexWhere((p) => p.id == postId);
            if (index != -1) {
              setState(() {
                final currentCount = _posts[index].commentCount;
                _posts[index] = PostModel(
                  id: _posts[index].id,
                  title: _posts[index].title,
                  content: _posts[index].content,
                  authorId: _posts[index].authorId,
                  authorName: _posts[index].authorName,
                  authorAvatarUrl: _posts[index].authorAvatarUrl,
                  imageUrl: _posts[index].imageUrl,
                  videoUrl: _posts[index].videoUrl,
                  createdAt: _posts[index].createdAt,
                  tags: _posts[index].tags,
                  likeCount: _posts[index].likeCount,
                  shareCount: _posts[index].shareCount,
                  isLiked: _posts[index].isLiked,
                  isSaved: _posts[index].isSaved,
                  // 💬 Decrement comment count
                  commentCount: (currentCount - 1).clamp(0, currentCount),
                );
              });
            }
          }
          // Reload the current post
          await _loadMorePosts();
        },
      ),
    );
  }

  Future<void> _handleSharePost(Map<String, dynamic> post) async {
    // Optimistic update
    final postId = post['id'];
    final index = _posts.indexWhere((p) => p.id == postId);

    if (index != -1 && mounted) {
      setState(() {
        _posts[index] = PostModel(
          id: _posts[index].id,
          title: _posts[index].title,
          content: _posts[index].content,
          authorId: _posts[index].authorId,
          authorName: _posts[index].authorName,
          authorAvatarUrl: _posts[index].authorAvatarUrl,
          imageUrl: _posts[index].imageUrl,
          videoUrl: _posts[index].videoUrl,
          createdAt: _posts[index].createdAt,
          tags: _posts[index].tags,
          commentCount: _posts[index].commentCount,
          likeCount: _posts[index].likeCount,
          isLiked: _posts[index].isLiked,
          isSaved: _posts[index].isSaved,
          // 🚀 Increment share count
          shareCount: _posts[index].shareCount + 1,
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
        authorName:
            post['authorName'] ?? post['author_name'] ?? 'Không xác định',
        authorAvatar: post['authorAvatarUrl'] ?? post['author_avatar_url'],
        likeCount: post['likeCount'] ?? post['like_count'] ?? 0,
        commentCount: post['commentCount'] ?? post['comment_count'] ?? 0,
        shareCount: post['shareCount'] ?? post['share_count'] ?? 0,
        createdAt: DateTime.tryParse(post['createdAt']?.toString() ??
                post['created_at']?.toString() ??
                '') ??
            DateTime.now(),
      ),
    );

    // Reload to sync
    if (result == true || result == null) {
      await _loadMorePosts();
    }
  }

  Future<void> _handleSavePost(Map<String, dynamic> post) async {
    try {
      final postId = post['id'];
      final isSaved = post['isSaved'] ?? false;

      // Save or unsave
      final success = isSaved
          ? await _postRepository.unsavePost(postId)
          : await _postRepository.savePost(postId);

      if (mounted && success) {
        // Update state
        final index = _posts.indexWhere((p) => p.id == postId);

        if (index != -1) {
          setState(() {
            _posts[index] = PostModel(
              id: _posts[index].id,
              title: _posts[index].title,
              content: _posts[index].content,
              authorId: _posts[index].authorId,
              authorName: _posts[index].authorName,
              authorAvatarUrl: _posts[index].authorAvatarUrl,
              imageUrl: _posts[index].imageUrl,
              videoUrl: _posts[index].videoUrl,
              createdAt: _posts[index].createdAt,
              tags: _posts[index].tags,
              commentCount: _posts[index].commentCount,
              shareCount: _posts[index].shareCount,
              likeCount: _posts[index].likeCount,
              isLiked: _posts[index].isLiked,
              // 🔖 Toggle saved state
              isSaved: !isSaved,
            );
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSaved ? '❌ Đã bỏ lưu bài viết' : '✅ Đã lưu bài viết',
            ),
            action: !isSaved
                ? SnackBarAction(
                    label: 'Xem',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.userProfileScreen);
                    },
                  )
                : null,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSaved ? '❌ Lỗi bỏ lưu bài viết' : '❌ Lỗi lưu bài viết',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Lỗi: ${e.toString()}')));
      }
    }
  }

  void _handleUserTap(Map<String, dynamic> post) {
    // Already on user's profile
  }

  void _handleHidePost(Map<String, dynamic> post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng ẩn bài đăng đang được phát triển'),
      ),
    );
  }

  Map<String, dynamic> _postToMap(PostModel post) {
    return {
      'id': post.id,
      'userId': post.authorId,
      'userName': post.authorName,
      'userAvatar': post.authorAvatarUrl ??
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'userRank': null,
      'content': post.content,
      'imageUrl': post.imageUrl,
      'location': '',
      'hashtags': post.tags ?? [],
      'timestamp': post.createdAt,
      'likeCount': post.likeCount,
      'commentCount': post.commentCount,
      'shareCount': post.shareCount,
      'isLiked': post.isLiked,
      'isSaved':
          post.isSaved, // ✅ FIX: Thêm isSaved để icon bookmark hiển thị đúng
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: app_theme.AppBarTheme.buildAppBar(
          context: context,
          title: 'Đang tải...',
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: app_theme.AppBarTheme.buildAppBar(
        context: context,
        title:
            'Bài đăng ${_currentIndex + 1}/${_posts.length}${_hasMorePosts ? '+' : ''}',
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end
              if (index >= _posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final post = _posts[index];
              final postMap = _postToMap(post);

              return SingleChildScrollView(
                child: FeedPostCardWidget(
                  post: postMap,
                  onLike: () => _handleLikeToggle(postMap),
                  onComment: () => _showCommentsModal(postMap),
                  onShare: () => _handleSharePost(postMap),
                  onUserTap: () => _handleUserTap(postMap),
                  onSave: () => _handleSavePost(postMap),
                  onHide: () => _handleHidePost(postMap),
                ),
              );
            },
          ),

          // Loading indicator overlay when loading more
          if (_isLoadingMore && _currentIndex >= _posts.length - 3)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang tải thêm...',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
