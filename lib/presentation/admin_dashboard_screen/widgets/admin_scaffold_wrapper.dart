import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import './admin_bottom_navigation.dart';

class AdminScaffoldWrapper extends StatelessWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final Function(int) onBottomNavTap;
  final List<Widget>? actions;
  final bool showBottomNavigation;

  const AdminScaffoldWrapper({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    required this.onBottomNavTap,
    this.actions,
    this.showBottomNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(context),
      // drawer: const AdminNavigationDrawer(), // Removed per audit
      body: body,
      bottomNavigationBar: showBottomNavigation
          ? AdminBottomNavigation(
              currentIndex: currentIndex,
              onTap: onBottomNavTap,
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      // leading: Builder( // Removed per audit
      //   builder: (context) => IconButton(
      //     icon: Icon(Icons.menu, color: AppTheme.textPrimaryLight),
      //     onPressed: () => Scaffold.of(context).openDrawer(),
      //   ),
      // ),
      automaticallyImplyLeading:
          false, // Ensure no back button if not needed, or let it default if pushed
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimaryLight,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        ...?actions,
        // IconButton( // Removed per audit - redundant
        //   icon: Icon(Icons.switch_account, color: AppTheme.textPrimaryLight),
        //   onPressed: () => _showAccountSwitchDialog(context),
        //   tooltip: 'Chuyển đổi tài khoản',
        // ),
        IconButton(
          icon: Icon(Icons.refresh, color: AppTheme.textPrimaryLight),
          onPressed: () {
            // Trigger refresh callback if provided
            // This should be handled by the parent widget
          },
          tooltip: 'Làm mới',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppTheme.textPrimaryLight),
          onSelected: (action) => _handleMenuAction(context, action),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'switch_to_user',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Chuyển sang giao diện người dùng'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'switch_to_user':
        _switchToUserMode(context);
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  void _switchToUserMode(BuildContext context) {
    // 🚀 PHASE 1: Navigate to main screen with persistent tabs
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.mainScreen, (route) => false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chuyển sang giao diện người dùng'),
        backgroundColor: AppTheme.primaryLight,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8.0),
              Text('Xác nhận đăng xuất'),
            ],
          ),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await AuthService.instance.signOut();

                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.loginScreen,
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi đăng xuất: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}
