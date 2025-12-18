import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/avatar_with_quick_follow.dart';
import '../../../widgets/post_background_card.dart';
import '../../../services/post_background_service.dart';
import '../../../models/post_background_theme.dart';
// import '../../../utils/like_count_debugger.dart';
// ELON_MODE_AUTO_FIX

class FeedPostCardWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onUserTap;
  final VoidCallback? onSave;
  final VoidCallback? onHide;

  const FeedPostCardWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onUserTap,
    this.onSave,
    this.onHide,
  });

  @override
  State<FeedPostCardWidget> createState() => _FeedPostCardWidgetState();
}

class _FeedPostCardWidgetState extends State<FeedPostCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // 🎯 LOCAL STATE - Facebook approach for instant UI update
  late bool _isLiked;
  late int _likeCount;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize from post data
    _isLiked = widget.post['isLiked'] == true;
    _likeCount = widget.post['likeCount'] ?? 0;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FeedPostCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔄 Sync with parent when post data changed
    // This happens after parent updates the PostModel
    if (oldWidget.post['isLiked'] != widget.post['isLiked'] ||
        oldWidget.post['likeCount'] != widget.post['likeCount']) {
      setState(() {
        _isLiked = widget.post['isLiked'] == true;
        _likeCount = widget.post['likeCount'] ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // 🎯 Call parent callback ONLY - let parent handle the toggle
    // Parent will update the Map, then didUpdateWidget will sync
    widget.onLike?.call();

    // Reset processing flag
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}p trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.post['userName']?.toString() ?? 'Unknown User';
    // final postId = widget.post['id']?.toString() ?? '';

    return Semantics(
      label: 'Bài viết của $userName',
      hint: 'Nhấn đúp để xem chi tiết',
      child: Container(
        // Modern card style: margin trái phải, shadow nhẹ
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Bo tròn góc
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            _buildUserHeader(context),

            // Post content hoặc Background card
            _buildContentOrBackground(context),

            // Engagement section (stats + actions)
            _buildEngagementSection(context),

            // Location and hashtags
            if (widget.post['location'] != null &&
                    widget.post['location'].toString().isNotEmpty ||
                (widget.post['hashtags'] as List?)?.isNotEmpty == true)
              _buildLocationAndHashtags(context),

            // 🐛 DEBUG: Like Count Debugger (temporary)
            // if (postId.isNotEmpty && const bool.fromEnvironment('DEBUG_LIKES', defaultValue: false))
            //   LikeCountDebugger.buildDebugPanel(postId),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final location = widget.post['location']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Row(
        children: [
          // Avatar with quick follow button
          Semantics(
            label:
                'Ảnh đại diện của ${widget.post['userName']?.toString() ?? 'người dùng'}',
            button: true,
            hint: 'Nhấn đúp để xem trang cá nhân',
            child: AvatarWithQuickFollow(
              userId: widget.post['userId']?.toString() ?? '',
              avatarUrl: widget.post['userAvatar'],
              size: 42, // Larger avatar
              showQuickFollow: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name
                Semantics(
                  label:
                      'Tên người đăng: ${widget.post['userName']?.toString() ?? 'Unknown User'}',
                  button: true,
                  hint: 'Nhấn đúp để xem trang cá nhân',
                  child: GestureDetector(
                    onTap: widget.onUserTap,
                    child: Text(
                      widget.post['userName']?.toString() ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700, // Bold hơn
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                // Location (nếu có) hoặc timestamp
                const SizedBox(height: 2),
                Semantics(
                  label: location.isNotEmpty
                      ? 'Vị trí: $location'
                      : 'Đăng ${widget.post['timestamp'] != null ? _formatTime(widget.post['timestamp'] as DateTime) : 'Vừa xong'}',
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        if (location.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8E8E93),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ] else ...[
                          Text(
                            widget.post['timestamp'] != null
                                ? _formatTime(
                                    widget.post['timestamp'] as DateTime,
                                  )
                                : 'Vừa xong',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Menu button
          Semantics(
            label: 'Tùy chọn bài viết',
            button: true,
            hint: 'Nhấn đúp để mở menu tùy chọn',
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _showPostOptions(context);
                },
                icon: const Icon(
                  Icons.more_horiz,
                  color: Color(0xFF8E8E93),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build content hoặc background card tùy theo có ảnh hay không
  Widget _buildContentOrBackground(BuildContext context) {
    final hasImage =
        widget.post['imageUrl'] != null &&
        widget.post['imageUrl'].toString().isNotEmpty &&
        widget.post['imageUrl'].toString() != 'null';

    final hasContent =
        widget.post['content'] != null &&
        widget.post['content'].toString().isNotEmpty;

    // Nếu không có ảnh nhưng có content → hiển thị background card
    if (!hasImage && hasContent) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FutureBuilder<PostBackgroundTheme>(
          future: PostBackgroundService.instance.getThemeForPost(
            postId: widget.post['id']?.toString(),
          ),
          builder: (context, snapshot) {
            return PostBackgroundCard(
              content: widget.post['content'].toString(),
              theme: snapshot.data,
              height: 280,
              onTap: widget.onComment, // Tap để comment
            );
          },
        ),
      );
    }

    // Nếu có ảnh → hiển thị content text (nếu có) + ảnh
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content text (nếu có)
        if (hasContent) _buildPostContent(context),

        // Ảnh (nếu có)
        if (hasImage) _buildPostMedia(context),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Semantics(
      label: 'Nội dung bài viết: ${widget.post['content'].toString()}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ExcludeSemantics(
          child: Text(
            widget.post['content'].toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1A1A1A),
              height: 1.4,
              letterSpacing: 0.1,
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ),
      ),
    );
  }

  Widget _buildPostMedia(BuildContext context) {
    final imageUrl = widget.post['imageUrl'].toString();

    // Validate URL
    if (imageUrl.isEmpty || imageUrl == 'null' || imageUrl == 'undefined') {
      return const SizedBox.shrink();
    }

    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasAbsolutePath) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          // TODO: Open fullscreen image viewer
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Bo tròn góc ảnh
          child: AspectRatio(
            aspectRatio: 1, // Square image như Instagram
            child: CustomImageWidget(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              showShimmer: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationAndHashtags(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hashtags
          if ((widget.post['hashtags'] as List?)?.isNotEmpty == true)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (widget.post['hashtags'] as List).map((hashtag) {
                return Text(
                  '#$hashtag',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3897F0), // Instagram blue
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection(BuildContext context) {
    // 🎯 Use LOCAL STATE for instant UI update
    final isLiked = _isLiked;
    final likeCount = _likeCount;
    final commentCount = widget.post['commentCount'] ?? 0;

    return Column(
      children: [
        // Action buttons row (Like, Comment, Share icons)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              // Like button
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isLiked ? _scaleAnimation.value : 1.0,
                    child: _buildIconButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked
                          ? const Color(0xFFE41E3F)
                          : const Color(0xFF1A1A1A),
                      onTap: _handleLike,
                      semanticLabel: isLiked ? 'Đã thích' : 'Thích',
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),

              // Comment button
              _buildIconButton(
                icon: Icons.chat_bubble_outline,
                color: const Color(0xFF1A1A1A),
                onTap: widget.onComment,
                semanticLabel: 'Bình luận',
              ),
              const SizedBox(width: 16),

              // Share button
              _buildIconButton(
                icon: Icons.send_outlined,
                color: const Color(0xFF1A1A1A),
                onTap: widget.onShare,
                semanticLabel: 'Chia sẻ',
              ),

              const Spacer(),

              // Bookmark button - Shows filled icon if saved
              _buildIconButton(
                icon: widget.post['isSaved'] == true
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: widget.post['isSaved'] == true
                    ? const Color(0xFF00695C) // Teal primary color when saved
                    : const Color(0xFF1A1A1A),
                onTap: widget.onSave,
                semanticLabel: widget.post['isSaved'] == true
                    ? 'Đã lưu'
                    : 'Lưu bài viết',
              ),
            ],
          ),
        ),

        // Stats row (like count và comment count)
        if (likeCount > 0 || commentCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                if (likeCount > 0) ...[
                  Text(
                    '$likeCount lượt thích',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
                if (likeCount > 0 && commentCount > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '•',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                if (commentCount > 0) ...[
                  Text(
                    '$commentCount bình luận',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      hint: 'Nhấn đúp để ${semanticLabel?.toLowerCase()}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 26, color: color),
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  widget.post['isSaved'] == true
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: widget.post['isSaved'] == true
                      ? const Color(0xFF00695C)
                      : null,
                ),
                title: Text(
                  widget.post['isSaved'] == true
                      ? 'Đã lưu bài viết'
                      : 'Lưu bài viết',
                  style: TextStyle(
                    color: widget.post['isSaved'] == true
                        ? const Color(0xFF00695C)
                        : null,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSave?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Ẩn bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onHide?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Báo cáo bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi báo cáo')),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

