import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'start_livestream_dialog.dart'; // Import helper function

class TournamentMatchPostWidget extends StatelessWidget {
  final Map<String, dynamic> post;
  final Map<String, dynamic>? matchData; // Thêm match data để lấy video_urls
  final VoidCallback? onTap;
  final VoidCallback? onViewMatch;
  final VoidCallback? onViewTournament;

  const TournamentMatchPostWidget({
    Key? key,
    required this.post,
    this.matchData,
    this.onTap,
    this.onViewMatch,
    this.onViewTournament,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final postTrigger = post['post_trigger'] as String?;
    final isPinned = post['is_pinned'] as bool? ?? false;
    final isAutoPosted = post['auto_posted'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isPinned ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPinned
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            if (isPinned || isAutoPosted || postTrigger != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getHeaderGradient(context, postTrigger),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getHeaderIcon(postTrigger),
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getHeaderTitle(postTrigger),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin, size: 12, color: colorScheme.onPrimary),
                            const SizedBox(width: 4),
                            Text(
                              'Ghim',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['content'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                    // Không giới hạn số dòng, hiển thị toàn bộ nội dung
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (postTrigger == 'live' && _hasLivestreamUrl())
                    _ActionButton(
                      icon: Icons.play_circle_fill,
                      label: 'Xem Livestream',
                      color: Colors.red,
                      onTap: () => _openLivestream(context),
                    ),
                  if (onViewMatch != null)
                    _ActionButton(
                      icon: Icons.sports,
                      label: 'Chi tiết trận đấu',
                      color: const Color(0xFF00897B),
                      onTap: onViewMatch,
                    ),
                  if (onViewTournament != null)
                    _ActionButton(
                      icon: Icons.emoji_events,
                      label: 'Xem giải đấu',
                      color: Colors.orange,
                      onTap: onViewTournament,
                    ),
                ],
              ),
            ),

            // Footer with stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  _StatItem(
                    icon: Icons.favorite_border,
                    count: post['likes_count'] as int? ?? 0,
                  ),
                  const SizedBox(width: 16),
                  _StatItem(
                    icon: Icons.comment_outlined,
                    count: post['comments_count'] as int? ?? 0,
                  ),
                  const SizedBox(width: 16),
                  _StatItem(
                    icon: Icons.share_outlined,
                    count: post['share_count'] as int? ?? 0,
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(post['created_at'] as String),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getHeaderGradient(BuildContext context, String? trigger) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (trigger) {
      case 'live':
        return [colorScheme.error, colorScheme.errorContainer];
      case 'result':
        return [const Color(0xFF2E7D32), const Color(0xFF4CAF50)];
      case 'reminder':
        return [const Color(0xFFE65100), const Color(0xFFFF9800)];
      case 'announcement':
      default:
        return [colorScheme.primary, colorScheme.primaryContainer];
    }
  }

  IconData _getHeaderIcon(String? trigger) {
    switch (trigger) {
      case 'live':
        return Icons.fiber_manual_record;
      case 'result':
        return Icons.check_circle;
      case 'reminder':
        return Icons.access_time;
      case 'announcement':
      default:
        return Icons.campaign;
    }
  }

  String _getHeaderTitle(String? trigger) {
    switch (trigger) {
      case 'live':
        return 'ĐANG DIỄN RA TRỰC TIẾP';
      case 'result':
        return 'KẾT QUẢ TRẬN ĐẤU';
      case 'reminder':
        return 'NHẮC NHỞ TRẬN ĐẤU';
      case 'announcement':
      default:
        return 'THÔNG BÁO TRẬN ĐẤU';
    }
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  bool _hasLivestreamUrl() {
    if (matchData == null) return false;
    final videoUrls = matchData!['video_urls'] as List?;
    return videoUrls != null && videoUrls.isNotEmpty;
  }

  void _openLivestream(BuildContext context) {
    if (matchData == null) return;
    final videoUrls = matchData!['video_urls'] as List?;
    if (videoUrls != null && videoUrls.isNotEmpty) {
      final url = videoUrls.first as String;
      openLivestreamUrl(url, context);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;

  const _StatItem({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
