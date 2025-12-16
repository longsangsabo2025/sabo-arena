import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/post_repository.dart';
import '../../home_feed_screen/widgets/feed_post_card_widget.dart';
import '../../../widgets/comments_modal.dart';
import '../../../widgets/share_bottom_sheet.dart';
import '../../../core/app_export.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Widget hiển thị danh sách bài đăng của user trong profile
class UserPostsWidget extends StatefulWidget {
  final String userId;

  const UserPostsWidget({super.key, required this.userId});

  @override
  State<UserPostsWidget> createState() => _UserPostsWidgetState();
}

class _UserPostsWidgetState extends State<UserPostsWidget> {
  final PostRepository _postRepository = PostRepository();
  List<PostModel> _userPosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Lấy bài đăng của user từ database
      final userPosts = await _postRepository.getUserPostsByUserId(
        widget.userId,
        limit: 50,
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (mounted) {
        setState(() {
          _userPosts = userPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải bài đăng: $e';
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

      // Reload posts to update like status
      await _loadUserPosts();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
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
            final postId = post['id'];
            final index = _userPosts.indexWhere((p) => p.id == postId);
            if (index != -1) {
              setState(() {
                _userPosts[index] = PostModel(
                  id: _userPosts[index].id,
                  title: _userPosts[index].title,
                  content: _userPosts[index].content,
                  authorId: _userPosts[index].authorId,
                  authorName: _userPosts[index].authorName,
                  authorAvatarUrl: _userPosts[index].authorAvatarUrl,
                  imageUrl: _userPosts[index].imageUrl,
                  videoUrl: _userPosts[index].videoUrl,
                  createdAt: _userPosts[index].createdAt,
                  tags: _userPosts[index].tags,
                  likeCount: _userPosts[index].likeCount,
                  shareCount: _userPosts[index].shareCount,
                  isLiked: _userPosts[index].isLiked,
                  isSaved: _userPosts[index].isSaved,
                  // 💬 Increment comment count
                  commentCount: _userPosts[index].commentCount + 1,
                );
              });
            }
          }
          // Reload to sync from database
          await _loadUserPosts();
        },
        onCommentDeleted: () async {
          // Update comment count when comment is deleted
          if (mounted) {
            final postId = post['id'];
            final index = _userPosts.indexWhere((p) => p.id == postId);
            if (index != -1) {
              setState(() {
                final currentCount = _userPosts[index].commentCount;
                _userPosts[index] = PostModel(
                  id: _userPosts[index].id,
                  title: _userPosts[index].title,
                  content: _userPosts[index].content,
                  authorId: _userPosts[index].authorId,
                  authorName: _userPosts[index].authorName,
                  authorAvatarUrl: _userPosts[index].authorAvatarUrl,
                  imageUrl: _userPosts[index].imageUrl,
                  videoUrl: _userPosts[index].videoUrl,
                  createdAt: _userPosts[index].createdAt,
                  tags: _userPosts[index].tags,
                  likeCount: _userPosts[index].likeCount,
                  shareCount: _userPosts[index].shareCount,
                  isLiked: _userPosts[index].isLiked,
                  isSaved: _userPosts[index].isSaved,
                  // 💬 Decrement comment count (min 0)
                  commentCount: (currentCount - 1).clamp(0, currentCount),
                );
              });
            }
          }
          // Reload to sync from database
          await _loadUserPosts();
        },
      ),
    );
  }

  Future<void> _handleSharePost(Map<String, dynamic> post) async {
    // Optimistic update: increment share count
    final postId = post['id'];
    final index = _userPosts.indexWhere((p) => p.id == postId);

    if (index != -1 && mounted) {
      setState(() {
        _userPosts[index] = PostModel(
          id: _userPosts[index].id,
          title: _userPosts[index].title,
          content: _userPosts[index].content,
          authorId: _userPosts[index].authorId,
          authorName: _userPosts[index].authorName,
          authorAvatarUrl: _userPosts[index].authorAvatarUrl,
          imageUrl: _userPosts[index].imageUrl,
          videoUrl: _userPosts[index].videoUrl,
          createdAt: _userPosts[index].createdAt,
          tags: _userPosts[index].tags,
          commentCount: _userPosts[index].commentCount,
          likeCount: _userPosts[index].likeCount,
          isLiked: _userPosts[index].isLiked,
          isSaved: _userPosts[index].isSaved,
          // 🚀 Increment share count optimistically
          shareCount: _userPosts[index].shareCount + 1,
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
        authorName: post['authorName'] ?? post['author_name'] ?? 'Unknown',
        authorAvatar: post['authorAvatarUrl'] ?? post['author_avatar_url'],
        likeCount: post['likeCount'] ?? post['like_count'] ?? 0,
        commentCount: post['commentCount'] ?? post['comment_count'] ?? 0,
        shareCount: post['shareCount'] ?? post['share_count'] ?? 0,
        createdAt: DateTime.tryParse(post['createdAt']?.toString() ?? post['created_at']?.toString() ?? '') ?? DateTime.now(),
      ),
    );

    // Reload from database to sync count
    if (result == true || result == null) {
      await _loadUserPosts();
    }
  }

  Future<void> _handleSavePost(Map<String, dynamic> post) async {
    try {
      final postId = post['id'];
      final isSaved = post['isSaved'] ?? false;

      // Determine action: save or unsave
      final success = isSaved
          ? await _postRepository.unsavePost(postId)
          : await _postRepository.savePost(postId);

      if (mounted && success) {
        // ✅ Update isSaved state
        final index = _userPosts.indexWhere((p) => p.id == postId);

        if (index != -1) {
          setState(() {
            _userPosts[index] = PostModel(
              id: _userPosts[index].id,
              title: _userPosts[index].title,
              content: _userPosts[index].content,
              authorId: _userPosts[index].authorId,
              authorName: _userPosts[index].authorName,
              authorAvatarUrl: _userPosts[index].authorAvatarUrl,
              imageUrl: _userPosts[index].imageUrl,
              videoUrl: _userPosts[index].videoUrl,
              createdAt: _userPosts[index].createdAt,
              tags: _userPosts[index].tags,
              commentCount: _userPosts[index].commentCount,
              shareCount: _userPosts[index].shareCount,
              likeCount: _userPosts[index].likeCount,
              isLiked: _userPosts[index].isLiked,
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
    // Already on user's profile, no need to navigate
  }

  void _handleHidePost(Map<String, dynamic> post) {
    // TODO: Implement hide functionality
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
      'userAvatar':
          post.authorAvatarUrl ??
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
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadUserPosts,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.article_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bài đăng nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Các bài đăng của bạn sẽ hiển thị ở đây',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = _userPosts[index];
        final postMap = _postToMap(post);

        return FeedPostCardWidget(
          post: postMap,
          onLike: () => _handleLikeToggle(postMap),
          onComment: () => _showCommentsModal(postMap),
          onShare: () => _handleSharePost(postMap),
          onUserTap: () => _handleUserTap(postMap),
          onSave: () => _handleSavePost(postMap),
          onHide: () => _handleHidePost(postMap),
        );
      }, childCount: _userPosts.length),
    );
  }
}

