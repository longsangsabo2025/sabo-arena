import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../core/performance/performance_widgets.dart';
import '../services/notification_service.dart';
import '../services/notification_navigation_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Modern Notification List Screen - Facebook 2025 Style with Real Data
class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  final NotificationNavigationService _navigationService =
      NotificationNavigationService.instance;
  String _selectedFilter = 'Tất cả';
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> notifications;

      if (_selectedFilter == 'Tất cả') {
        notifications = await _notificationService.getNotifications(limit: 50);
      } else if (_selectedFilter == 'Chưa đọc') {
        notifications = await _notificationService.getNotifications(
          isRead: false,
          limit: 50,
        );
      } else {
        // Đã đọc
        notifications = await _notificationService.getNotifications(
          isRead: true,
          limit: 50,
        );
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildModernAppBar(),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildNotificationList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF050505),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: const Text(
        'Thông báo', overflow: TextOverflow.ellipsis, style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Color(0xFF050505),
        ),
      ),
      actions: [
        // Search button
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                size: 20,
                color: Color(0xFF050505),
              ),
            ),
            onPressed: () {},
          ),
        ),
        // Mark all as read button
        if (_notifications.any((n) => !(n['is_read'] as bool? ?? false)))
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đánh dấu tất cả', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0866FF),
                ),
              ),
            ),
          ),
        // More options
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz,
                size: 20,
                color: Color(0xFF050505),
              ),
            ),
            onPressed: () {
              // TODO: Show more options menu
            },
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFE4E6EB)),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Tất cả', 'Chưa đọc', 'Đã đọc'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedFilter = filter);
                  _loadNotifications(); // Reload with new filter
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0866FF)
                        : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter, style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF050505),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0866FF)),
      );
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF0866FF),
      child: OptimizedListView(
        padding: const EdgeInsets.only(top: 4),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] as bool? ?? false;
    final type = notification['type'] as String? ?? 'default';
    final title = notification['title'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final createdAt = notification['created_at'] as String?;
    // final data = notification['data'] as Map<String, dynamic>?; // For future use

    // Get icon and color based on type
    final iconData = _getIconForType(type);
    final iconColor = _getColorForType(type);
    final timeAgo = _getTimeAgo(createdAt);

    return Material(
      color: isRead ? Colors.white : const Color(0xFFE7F3FF),
      child: InkWell(
        onTap: () async {
          // Mark as read
          if (!isRead) {
            await _markAsRead(notification['id'] as String);
          }

          // Navigate to appropriate screen based on notification type
          final data = notification['data'] as Map<String, dynamic>?;
          _navigationService.navigateFromNotification(
            context: context,
            type: type,
            data: data,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 28),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title, style: TextStyle(
                        fontSize: 15,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        letterSpacing: -0.2,
                        color: const Color(0xFF050505),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Message
                    Text(
                      message, style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                        color: Color(0xFF65676B),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Time
                    Text(
                      timeAgo, style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1,
                        color: Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0866FF),
                    shape: BoxShape.circle,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: Color(0xFF65676B),
                  ),
                  onPressed: () {
                    _showNotificationOptions(notification);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationOptions(Map<String, dynamic> notification) {
    // TODO: Show bottom sheet with options (delete, turn off, etc.)
  }

  Widget _buildNotificationText_OLD(Map<String, dynamic> notification) {
    // OLD method - kept for reference, can be removed
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
          color: Color(0xFF050505),
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: notification['name'],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (notification['action'] != null)
            TextSpan(text: ' ${notification['action']}'),
          if (notification['extra'] != null)
            TextSpan(
              text: ' ${notification['extra']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (notification['action2'] != null)
            TextSpan(text: ' ${notification['action2']}'),
          if (notification['target'] != null)
            TextSpan(
              text: ' ${notification['target']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  // Helper methods for notification display
  IconData _getIconForType(String type) {
    switch (type) {
      case 'tournament_invitation':
      case 'tournament_registration':
      case 'tournament':
        return Icons.emoji_events;
      case 'match_result':
      case 'match':
        return Icons.sports_soccer;
      case 'club_announcement':
      case 'club':
        return Icons.business;
      case 'rank_update':
      case 'rank':
        return Icons.trending_up;
      case 'friend_request':
      case 'follow':
        return Icons.person_add;
      case 'comment':
      case 'mention':
        return Icons.alternate_email;
      case 'like':
      case 'reaction':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'tournament_invitation':
      case 'tournament_registration':
      case 'tournament':
        return const Color(0xFFF7B500);
      case 'match_result':
      case 'match':
        return const Color(0xFF10B981);
      case 'club_announcement':
      case 'club':
      case 'friend_request':
      case 'follow':
        return const Color(0xFF0866FF);
      case 'rank_update':
      case 'rank':
        return const Color(0xFF9333EA);
      case 'like':
      case 'reaction':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF65676B);
    }
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${dateTime.day}/${dateTime.month}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ngày';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      await _notificationService.refreshUnreadCount();
      _loadNotifications(); // Reload to update UI
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      await _notificationService.refreshUnreadCount();
      _loadNotifications(); // Reload to update UI
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 48,
              color: Color(0xFF65676B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có thông báo', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn chưa có thông báo nào', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
              color: Color(0xFF65676B),
            ),
          ),
        ],
      ),
    );
  }
}

