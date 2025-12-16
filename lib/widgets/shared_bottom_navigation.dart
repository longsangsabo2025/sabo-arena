import 'package:flutter/material.dart';
import '../core/app_export.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';
import 'package:sabo_arena/utils/production_logger.dart';

class SharedBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(String) onNavigate;

  const SharedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  State<SharedBottomNavigation> createState() => _SharedBottomNavigationState();
}

class _SharedBottomNavigationState extends State<SharedBottomNavigation> {
  final MessagingService _messagingService = MessagingService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  int _unreadMessageCount = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadMessageCount();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final count = await _messagingService.getUnreadMessageCount();
      if (mounted) {
        setState(() {
          _unreadMessageCount = count;
        });
      }
    } catch (e) {
      ProductionLogger.error('❌ Error loading unread message count: $e', error: e);
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      ProductionLogger.error('❌ Error loading unread notification count: $e', error: e);
    }
  }

  int _getTotalUnreadCount() {
    return _unreadMessageCount + _unreadNotificationCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: widget.currentIndex,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.grey[500],
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            onTap: (index) {
              switch (index) {
                case 0:
                  widget.onNavigate(AppRoutes.homeFeedScreen);
                  break;
                case 1:
                  widget.onNavigate(AppRoutes.findOpponentsScreen);
                  break;
                case 2:
                  widget.onNavigate(AppRoutes.tournamentListScreen);
                  break;
                case 3:
                  widget.onNavigate(AppRoutes.clubMainScreen);
                  break;
                case 4:
                  widget.onNavigate(AppRoutes.userProfileScreen);
                  break;
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: Semantics(
                  label: 'Trang chủ',
                  hint: 'Nhấn đúp để xem bảng tin trang chủ',
                  child: Opacity(
                    opacity: 0.6,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                activeIcon: Semantics(
                  label: 'Trang chủ đang được chọn',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
                label: 'Trang chủ',
                tooltip: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Semantics(
                  label: 'Tìm đối thủ',
                  hint: 'Nhấn đúp để tìm kiếm đối thủ thi đấu',
                  child: Icon(Icons.sports_outlined, size: 24),
                ),
                activeIcon: Semantics(
                  label: 'Tìm đối thủ đang được chọn',
                  child: Icon(Icons.sports_rounded, size: 26),
                ),
                label: 'Đối thủ',
                tooltip: 'Tìm đối thủ',
              ),
              BottomNavigationBarItem(
                icon: Semantics(
                  label: 'Giải đấu',
                  hint: 'Nhấn đúp để xem danh sách giải đấu',
                  child: Icon(Icons.emoji_events_outlined, size: 24),
                ),
                activeIcon: Semantics(
                  label: 'Giải đấu đang được chọn',
                  child: Icon(Icons.emoji_events_rounded, size: 26),
                ),
                label: 'Giải đấu',
                tooltip: 'Giải đấu',
              ),
              BottomNavigationBarItem(
                icon: Semantics(
                  label: 'Câu lạc bộ',
                  hint: 'Nhấn đúp để xem câu lạc bộ',
                  child: Icon(Icons.groups_outlined, size: 24),
                ),
                activeIcon: Semantics(
                  label: 'Câu lạc bộ đang được chọn',
                  child: Icon(Icons.groups_rounded, size: 26),
                ),
                label: 'Câu lạc bộ',
                tooltip: 'Câu lạc bộ',
              ),
              BottomNavigationBarItem(
                icon: Semantics(
                  label: _getTotalUnreadCount() > 0
                      ? 'Cá nhân, có ${_getTotalUnreadCount()} thông báo chưa đọc'
                      : 'Cá nhân',
                  hint: 'Nhấn đúp để xem trang cá nhân và thông báo',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.person_outline_rounded, size: 24),
                      if (_unreadMessageCount > 0 ||
                          _unreadNotificationCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: ExcludeSemantics(
                              child: Text(
                                _getTotalUnreadCount() > 9
                                    ? '9+'
                                    : _getTotalUnreadCount().toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                activeIcon: Semantics(
                  label: _getTotalUnreadCount() > 0
                      ? 'Cá nhân đang được chọn, có ${_getTotalUnreadCount()} thông báo chưa đọc'
                      : 'Cá nhân đang được chọn',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.person_rounded, size: 26),
                      if (_unreadMessageCount > 0 ||
                          _unreadNotificationCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: ExcludeSemantics(
                              child: Text(
                                _getTotalUnreadCount() > 9
                                    ? '9+'
                                    : _getTotalUnreadCount().toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                label: 'Cá nhân',
                tooltip: 'Trang cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
