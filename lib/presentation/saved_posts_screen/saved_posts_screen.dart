import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/post_model.dart';
import '../../services/post_repository.dart';
import '../home_feed_screen/widgets/feed_post_card_widget.dart';
import '../../widgets/comments_modal.dart';
import '../../widgets/share_bottom_sheet.dart';
import '../other_user_profile_screen/other_user_profile_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final PostRepository _postRepository = PostRepository();
  final ScrollController _scrollController = ScrollController();

  List<PostModel> _savedPosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadSavedPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final posts = await _postRepository.getSavedPosts(limit: 20);

      setState(() {
        _savedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải bài viết: $e';
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final morePosts = await _postRepository.getSavedPosts(
        offset: _savedPosts.length,
        limit: 10,
      );

      setState(() {
        _savedPosts.addAll(morePosts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải thêm: $e')));
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadSavedPosts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _handleUnsave(PostModel post) async {
    try {
      final success = await _postRepository.unsavePost(post.id);

      if (success && mounted) {
        setState(() {
          _savedPosts.removeWhere((p) => p.id == post.id);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã bỏ lưu bài viết')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
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

  // ✅ Implement đầy đủ like functionality
  Future<void> _handleLikeToggle(PostModel post) async {
    try {
      final postId = post.id;
      final isLiked = post.isLiked;

      // Optimistic update
      final index = _savedPosts.indexWhere((p) => p.id == postId);
      if (index != -1 && mounted) {
        setState(() {
          _savedPosts[index] = PostModel(
            id: _savedPosts[index].id,
            title: _savedPosts[index].title,
            content: _savedPosts[index].content,
            authorId: _savedPosts[index].authorId,
            authorName: _savedPosts[index].authorName,
            authorAvatarUrl: _savedPosts[index].authorAvatarUrl,
            imageUrl: _savedPosts[index].imageUrl,
            videoUrl: _savedPosts[index].videoUrl,
            createdAt: _savedPosts[index].createdAt,
            tags: _savedPosts[index].tags,
            commentCount: _savedPosts[index].commentCount,
            shareCount: _savedPosts[index].shareCount,
            isSaved: _savedPosts[index].isSaved,
            // Toggle like
            isLiked: !isLiked,
            likeCount: _savedPosts[index].likeCount + (!isLiked ? 1 : -1),
          );
        });
      }

      // API call
      if (isLiked) {
        await _postRepository.unlikePost(postId);
      } else {
        await _postRepository.likePost(postId);
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      // Revert on error
      await _loadSavedPosts();
    }
  }

  // ✅ Implement comment functionality
  void _showCommentsModal(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(
        postId: post.id,
        postTitle: post.content,
        onCommentAdded: () async {
          // Update comment count
          if (mounted) {
            final index = _savedPosts.indexWhere((p) => p.id == post.id);
            if (index != -1) {
              setState(() {
                _savedPosts[index] = PostModel(
                  id: _savedPosts[index].id,
                  title: _savedPosts[index].title,
                  content: _savedPosts[index].content,
                  authorId: _savedPosts[index].authorId,
                  authorName: _savedPosts[index].authorName,
                  authorAvatarUrl: _savedPosts[index].authorAvatarUrl,
                  imageUrl: _savedPosts[index].imageUrl,
                  videoUrl: _savedPosts[index].videoUrl,
                  createdAt: _savedPosts[index].createdAt,
                  tags: _savedPosts[index].tags,
                  likeCount: _savedPosts[index].likeCount,
                  shareCount: _savedPosts[index].shareCount,
                  isLiked: _savedPosts[index].isLiked,
                  isSaved: _savedPosts[index].isSaved,
                  // Increment comment count
                  commentCount: _savedPosts[index].commentCount + 1,
                );
              });
            }
          }
          // Reload to sync
          await _loadSavedPosts();
        },
        onCommentDeleted: () async {
          // Update comment count
          if (mounted) {
            final index = _savedPosts.indexWhere((p) => p.id == post.id);
            if (index != -1) {
              setState(() {
                final currentCount = _savedPosts[index].commentCount;
                _savedPosts[index] = PostModel(
                  id: _savedPosts[index].id,
                  title: _savedPosts[index].title,
                  content: _savedPosts[index].content,
                  authorId: _savedPosts[index].authorId,
                  authorName: _savedPosts[index].authorName,
                  authorAvatarUrl: _savedPosts[index].authorAvatarUrl,
                  imageUrl: _savedPosts[index].imageUrl,
                  videoUrl: _savedPosts[index].videoUrl,
                  createdAt: _savedPosts[index].createdAt,
                  tags: _savedPosts[index].tags,
                  likeCount: _savedPosts[index].likeCount,
                  shareCount: _savedPosts[index].shareCount,
                  isLiked: _savedPosts[index].isLiked,
                  isSaved: _savedPosts[index].isSaved,
                  // Decrement comment count
                  commentCount: (currentCount - 1).clamp(0, currentCount),
                );
              });
            }
          }
          // Reload to sync
          await _loadSavedPosts();
        },
      ),
    );
  }

  // ✅ Implement share functionality
  Future<void> _handleSharePost(PostModel post) async {
    // Optimistic update
    final index = _savedPosts.indexWhere((p) => p.id == post.id);

    if (index != -1 && mounted) {
      setState(() {
        _savedPosts[index] = PostModel(
          id: _savedPosts[index].id,
          title: _savedPosts[index].title,
          content: _savedPosts[index].content,
          authorId: _savedPosts[index].authorId,
          authorName: _savedPosts[index].authorName,
          authorAvatarUrl: _savedPosts[index].authorAvatarUrl,
          imageUrl: _savedPosts[index].imageUrl,
          videoUrl: _savedPosts[index].videoUrl,
          createdAt: _savedPosts[index].createdAt,
          tags: _savedPosts[index].tags,
          commentCount: _savedPosts[index].commentCount,
          likeCount: _savedPosts[index].likeCount,
          isLiked: _savedPosts[index].isLiked,
          isSaved: _savedPosts[index].isSaved,
          // Increment share count
          shareCount: _savedPosts[index].shareCount + 1,
        );
      });
    }

    // Show share modal with full post data
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        postId: post.id,
        postTitle: post.content,
        postContent: post.content,
        postImageUrl: post.imageUrl,
        authorName: post.authorName,
        authorAvatar: post.authorAvatarUrl,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        shareCount: post.shareCount,
        createdAt: post.createdAt,
      ),
    );

    // Reload to sync
    if (result == true || result == null) {
      await _loadSavedPosts();
    }
  }

  // ✅ Navigate to user profile
  void _handleUserTap(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(userId: post.authorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bài viết đã lưu'),
        centerTitle: true,
      ),
      body: _isLoading && _savedPosts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  SizedBox(height: 2.h),
                  Text(
                    _errorMessage!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 3.h),
                  ElevatedButton(
                    onPressed: _loadSavedPosts,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : _savedPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Chưa có bài viết nào được lưu', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Lưu bài viết để xem lại sau', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshPosts,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: 2.h),
                itemCount: _savedPosts.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _savedPosts.length) {
                    return Container(
                      padding: EdgeInsets.all(4.w),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final post = _savedPosts[index];
                  return FeedPostCardWidget(
                    post: _postToMap(post),
                    onLike: () => _handleLikeToggle(post),
                    onComment: () => _showCommentsModal(post),
                    onShare: () => _handleSharePost(post),
                    onUserTap: () => _handleUserTap(post),
                    onSave: () => _handleUnsave(post),
                    onHide: () {
                      // Hide = Remove from saved posts
                      _handleUnsave(post);
                    },
                  );
                },
              ),
            ),
    );
  }
}

