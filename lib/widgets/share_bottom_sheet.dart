import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sabo_arena/services/share_service.dart';

class ShareBottomSheet extends StatelessWidget {
  final String postId;
  final String postTitle;
  final String? postContent;
  final String? postImageUrl;
  final String authorName;
  final String? authorAvatar;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;

  const ShareBottomSheet({
    super.key,
    required this.postId,
    required this.postTitle,
    this.postContent,
    this.postImageUrl,
    required this.authorName,
    this.authorAvatar,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chia sẻ bài viết',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Share options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildShareOption(
                  context,
                  icon: Icons.share,
                  title: 'Chia sẻ chung',
                  subtitle: 'Chia sẻ qua các ứng dụng khác',
                  onTap: () => _shareGeneric(context),
                ),
                _buildShareOption(
                  context,
                  icon: Icons.copy,
                  title: 'Sao chép liên kết',
                  subtitle: 'Sao chép link bài viết vào clipboard',
                  onTap: () => _copyLink(context),
                ),
                _buildShareOption(
                  context,
                  icon: Icons.message,
                  title: 'Chia sẻ dưới dạng text',
                  subtitle: 'Chia sẻ nội dung bài viết',
                  onTap: () => _shareAsText(context),
                ),
                if (postImageUrl != null)
                  _buildShareOption(
                    context,
                    icon: Icons.image,
                    title: 'Chia sẻ hình ảnh',
                    subtitle: 'Chia sẻ hình ảnh từ bài viết',
                    onTap: () => _shareImage(context),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.grey.shade700, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _shareGeneric(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tạo hình ảnh chia sẻ...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Use rich share with 4:5 image card
      await ShareService.sharePostRich(
        postId: postId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: postContent ?? postTitle,
        imageUrl: postImageUrl,
        likeCount: likeCount,
        commentCount: commentCount,
        shareCount: shareCount,
        createdAt: createdAt,
        context: context,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context, true); // Close bottom sheet with success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã chia sẻ bài viết!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showError(context, 'Lỗi chia sẻ: $e');
      }
    }
  }

  void _copyLink(BuildContext context) async {
    try {
      final link = 'https://saboarena.app/post/$postId';
      await Clipboard.setData(ClipboardData(text: link));
      
      // 🔐 SECURITY FIX: Check if context is still mounted before using it
      if (!context.mounted) return;
      Navigator.pop(context);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép liên kết vào clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Lỗi sao chép: $e');
    }
  }

  void _shareAsText(BuildContext context) async {
    try {
      // Try rich share first, fallback to text if fails
      try {
        await ShareService.sharePostRich(
          postId: postId,
          authorName: authorName,
          authorAvatar: authorAvatar,
          content: postContent ?? postTitle,
          imageUrl: postImageUrl,
          likeCount: likeCount,
          commentCount: commentCount,
          shareCount: shareCount,
          createdAt: createdAt,
          context: context,
        );
      } catch (richError) {
        // Fallback to text-only
        final shareText = _buildShareText();
        await ShareService.shareCustom(
          text: shareText,
          subject: 'Post từ SABO ARENA',
        );
      }
      
      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã chia sẻ bài viết!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Lỗi chia sẻ text: $e');
      }
    }
  }

  void _shareImage(BuildContext context) async {
    if (postImageUrl == null) return;

    try {
      // Use rich share with image card
      await ShareService.sharePostRich(
        postId: postId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: postContent ?? postTitle,
        imageUrl: postImageUrl,
        likeCount: likeCount,
        commentCount: commentCount,
        shareCount: shareCount,
        createdAt: createdAt,
        context: context,
      );
      
      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã chia sẻ bài viết với hình ảnh!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Lỗi chia sẻ hình ảnh: $e');
      }
    }
  }

  String _buildShareText() {
    final buffer = StringBuffer();

    // Add title if different from content
    if (postTitle.isNotEmpty && postTitle != postContent) {
      buffer.write('📌 $postTitle');
      buffer.write('\n\n');
    }

    // Add content with proper formatting
    if (postContent != null && postContent!.isNotEmpty) {
      // Trim and remove excessive newlines
      final cleanContent = postContent!.trim().replaceAll(
        RegExp(r'\n{3,}'),
        '\n\n',
      );
      buffer.write(cleanContent);
      buffer.write('\n\n');
    }

    // Add footer
    buffer.write('🎯 Từ Sabo Arena - Cộng đồng Billiards Việt Nam');
    buffer.write('\n');
    buffer.write('Xem chi tiết: https://saboarena.app/post/$postId');

    return buffer.toString();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
