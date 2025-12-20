import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class AdminBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) => _handleNavigation(context, index),
        selectedItemColor: AppTheme.primaryLight,
        unselectedItemColor: AppTheme.textSecondaryLight,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.approval),
            activeIcon: Icon(Icons.approval),
            label: 'Duyệt CLB',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Tournament',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'Khác',
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    // Prevent navigation if already on the same tab
    if (index == currentIndex) return;

    onTap(index);

    switch (index) {
      case 0:
        // Dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboardScreen);
        break;
      case 1:
        // Club Approval
        Navigator.pushReplacementNamed(context, AppRoutes.clubApprovalScreen);
        break;
      case 2:
        // Tournament Management
        Navigator.pushReplacementNamed(
            context, AppRoutes.adminTournamentScreen);
        break;
      case 3:
        // User Management
        Navigator.pushReplacementNamed(
            context, AppRoutes.adminUserManagementScreen);
        break;
      case 4:
        // More options
        Navigator.pushReplacementNamed(context, AppRoutes.adminMoreScreen);
        break;
    }
  }
}
