import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../../models/post_model.dart';
import '../../../services/post_repository.dart';
import '../../../widgets/post_background_card.dart';
import '../../../services/post_background_service.dart';
import '../../../models/post_background_theme.dart';
import '../../post_detail_screen/post_detail_screen.dart';
import '../../widgets/custom_video_player.dart'; // Video player widgets
import '../../home_feed_screen/widgets/create_post_modal_widget.dart';
import '../../../widgets/common/app_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Filter type cho posts
enum PostFilterType {
  textOnly, // Chỉ posts text (không có ảnh và video)
  imagesOnly, // Chỉ posts có ảnh
  videosOnly, // Chỉ posts có video/YouTube link
}

/// Widget hiển thị bài đăng của user theo dạng grid (TikTok style)
class UserPostsGridWidget extends StatefulWidget {
  final String userId;
  final PostFilterType? filterType;

  const UserPostsGridWidget({super.key, required this.userId, this.filterType});

  @override
  State<UserPostsGridWidget> createState() => _UserPostsGridWidgetState();
}

class _UserPostsGridWidgetState extends State<UserPostsGridWidget> {
  final PostRepository _postRepository = PostRepository();
  final PagingController<int, PostModel> _pagingController =
      PagingController(firstPageKey: 0);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPostsPage);
  }

  @override
  void didUpdateWidget(UserPostsGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload khi userId hoặc filterType thay đổi
    if (oldWidget.userId != widget.userId ||
        oldWidget.filterType != widget.filterType) {
      _pagingController.refresh();
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPostsPage(int pageKey) async {
    try {
      final allPosts = await _postRepository.getUserPostsByUserId(
        widget.userId,
        limit: 20,
        offset: pageKey,
      );

      // Apply filter based on filterType
      List<PostModel> filteredPosts;

      switch (widget.filterType ?? PostFilterType.textOnly) {
        case PostFilterType.textOnly:
          // Chỉ lấy posts text (không có ảnh và video)
          filteredPosts = allPosts
              .where(
                (post) =>
                    (post.imageUrl == null || post.imageUrl!.isEmpty) &&
                    (post.videoUrl == null || post.videoUrl!.isEmpty),
              )
              .toList();
          break;
        case PostFilterType.imagesOnly:
          // Chỉ lấy posts có image_url
          filteredPosts = allPosts
              .where(
                (post) => post.imageUrl != null && post.imageUrl!.isNotEmpty,
              )
              .toList();
          break;
        case PostFilterType.videosOnly:
          // Chỉ lấy posts có video_url (YouTube link) VÀ KHÔNG có ảnh
          filteredPosts = allPosts
              .where(
                (post) =>
                    (post.videoUrl != null && post.videoUrl!.isNotEmpty) &&
                    (post.imageUrl == null || post.imageUrl!.isEmpty),
              )
              .toList();
          break;
      }

      final isLastPage = allPosts.length < 20;
      if (isLastPage) {
        _pagingController.appendLastPage(filteredPosts);
      } else {
        final nextPageKey = pageKey + allPosts.length;
        _pagingController.appendPage(filteredPosts, nextPageKey);
      }
    } catch (e) {
      _errorMessage = 'Không thể tải bài đăng: $e';
      _pagingController.error = e;
    }
  }

  Future<void> _loadUserPosts() async {
    _pagingController.refresh();
  }

  void _openPostDetail(PostModel post, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          post: post,
          userId: widget.userId,
          initialIndex: index,
        ),
      ),
    );
  }

  void _showCreatePostModal() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tạo bài viết')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostModalWidget(
        onPostCreated: () {
          // Reload posts after creating new post
          _loadUserPosts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagedSliverGrid<int, PostModel>(
      pagingController: _pagingController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 3 / 4,
      ),
      builderDelegate: PagedChildBuilderDelegate<PostModel>(
        itemBuilder: (context, post, index) {
          // First item is create post card
          if (index == 0) {
            return _buildCreatePostCard();
          }
          return _buildPostGridItem(post, index);
        },
        firstPageProgressIndicatorBuilder: (context) => const Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        newPageProgressIndicatorBuilder: (context) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        firstPageErrorIndicatorBuilder: (context) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Có lỗi xảy ra',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Thử lại',
                  type: AppButtonType.primary,
                  size: AppButtonSize.medium,
                  onPressed: _loadUserPosts,
                ),
              ],
            ),
          ),
        ),
        noItemsFoundIndicatorBuilder: (context) => Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: _buildCreatePostCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostCard() {
    return GestureDetector(
      onTap: _showCreatePostModal,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tạo bài viết',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chia sẻ khoảnh khắc',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostGridItem(PostModel post, int index) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _openPostDetail(post, index),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần ảnh/video 1:1 (square)
            Expanded(
              flex: 3, // 3 phần cho ảnh/video
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: post.videoUrl != null
                    ? VideoThumbnailWidget(
                        videoId: post.videoUrl!,
                        onTap: () {
                          VideoPlayerDialog.show(
                            context,
                            videoId: post.videoUrl!,
                            autoPlay: true,
                          );
                        },
                      )
                    : hasImage
                        ? CachedNetworkImage(
                            imageUrl: post.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              child: Icon(
                                Icons.broken_image,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                                size: 32,
                              ),
                            ),
                          )
                        : FutureBuilder<PostBackgroundTheme>(
                            future:
                                PostBackgroundService.instance.getThemeForPost(
                              postId: post.id,
                            ),
                            builder: (context, snapshot) {
                              return PostBackgroundCardCompact(
                                content: post.content,
                                theme: snapshot.data,
                                onTap: () => _openPostDetail(post, index),
                              );
                            },
                          ),
              ),
            ),

            // Phần caption + stats (1 phần còn lại)
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Caption
                    Expanded(
                      child: Text(
                        post.content,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Stats row
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(post.likeCount),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(post.commentCount),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
