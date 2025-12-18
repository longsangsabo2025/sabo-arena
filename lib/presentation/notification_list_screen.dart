import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../core/performance/performance_widgets.dart';
import '../services/notification_service.dart';
import '../services/notification_navigation_service.dart';
import '../models/notification_models.dart';

/// Modern Notification List Screen - Facebook 2025 Style with Real Data
class NotificationListScreen extends StatefulWidget {
  final bool isClubContext;

  const NotificationListScreen({
    super.key,
    this.isClubContext = false,
  });

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  final NotificationNavigationService _navigationService =
      NotificationNavigationService.instance;
  String _selectedFilter = 'Tất cả';
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<NotificationModel> notifications;

      if (_selectedFilter == 'Tất cả') {
        notifications = await _notificationService.getNotifications(
          limit: 50,
          isClubContext: widget.isClubContext,
        );
      } else if (_selectedFilter == 'Chưa đọc') {
        notifications = await _notificationService.getNotifications(
          isRead: false,
          limit: 50,
          isClubContext: widget.isClubContext,
        );
      } else {
        // Đã đọc
        notifications = await _notificationService.getNotifications(
          isRead: true,
          limit: 50,
          isClubContext: widget.isClubContext,
        );
      }

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        'Thông báo',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
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
        if (_notifications.any((n) => !n.isRead))
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đánh dấu tất cả',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
                    filter,
                    style: TextStyle(
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

  Widget _buildNotificationItem(NotificationModel notification) {
    final isRead = notification.isRead;
    final type = notification.type;
    final title = notification.title;
    final message = notification.body;
    final createdAt = notification.createdAt;

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
            await _markAsRead(notification.id);
          }

          if (!mounted) return;

          // Navigate to appropriate screen based on notification type
          _navigationService.navigateFromNotification(
            context: context,
            type: type.value,
            data: notification.data,
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
                      title,
                      style: TextStyle(
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
                      message,
                      style: const TextStyle(
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
                      timeAgo,
                      style: const TextStyle(
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

  void _showNotificationOptions(NotificationModel notification) {
    // TODO: Show bottom sheet with options (delete, turn off, etc.)
  }

  // Helper methods for notification display
  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.tournamentInvitation:
      case NotificationType.tournamentRegistration:
        return Icons.emoji_events;
      case NotificationType.matchResult:
        return Icons.sports_soccer;
      case NotificationType.clubAnnouncement:
        return Icons.business;
      case NotificationType.rankUpdate:
        return Icons.trending_up;
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.systemNotification:
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.tournamentInvitation:
      case NotificationType.tournamentRegistration:
        return const Color(0xFFF7B500);
      case NotificationType.matchResult:
        return const Color(0xFF10B981);
      case NotificationType.clubAnnouncement:
      case NotificationType.friendRequest:
        return const Color(0xFF0866FF);
      case NotificationType.rankUpdate:
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF65676B);
    }
  }

  String _getTimeAgo(DateTime? createdAt) {
    if (createdAt == null) return '';

    try {
      final now = DateTime.now();
      final difference = now.difference(createdAt);

      if (difference.inDays > 7) {
        return '${createdAt.day}/${createdAt.month}';
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
      await _notificationService.getUnreadNotificationCount(); // Refresh count
      _loadNotifications(); // Reload to update UI
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      await _notificationService.getUnreadNotificationCount(); // Refresh count
      _loadNotifications(); // Reload to update UI
    } catch (e) {
      // Handle error
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
            'Không có thông báo',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: Color(0xFF050505),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn chưa có thông báo nào',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
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

