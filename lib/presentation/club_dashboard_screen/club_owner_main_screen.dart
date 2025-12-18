import 'package:flutter/material.dart';
// Temporarily removed: // Temporarily removed AppLocalizations import
import 'package:sabo_arena/theme/app_theme.dart' as OldTheme;
import './club_dashboard_screen.dart';
import '../club_management/club_members_screen.dart';
import '../club_promotion_hub/club_promotion_hub_screen.dart';
import '../tournament_management_center/tournament_management_center_screen.dart';
import '../club_settings_screen/club_settings_screen.dart';
import '../staff/staff_main_screen.dart';
import '../../services/club_service.dart';

/// Main screen wrapper for Club Owner with persistent bottom navigation
class ClubOwnerMainScreen extends StatefulWidget {
  final String clubId;

  const ClubOwnerMainScreen({super.key, required this.clubId});

  @override
  State<ClubOwnerMainScreen> createState() => _ClubOwnerMainScreenState();
}

class _ClubOwnerMainScreenState extends State<ClubOwnerMainScreen> {
  int _currentIndex = 0;
  String _clubName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    try {
      final club = await ClubService.instance.getClubById(widget.clubId);
      if (mounted) {
        setState(() {
          _clubName = club.name;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _clubName = 'CLB';
          _isLoading = false;
        });
      }
    }
  }

  List<Widget> _buildScreens() {
    return [
      ClubDashboardScreen(clubId: widget.clubId),
      ClubMembersScreen(clubId: widget.clubId, clubName: _clubName),
      ClubPromotionHubScreen(
        clubId: widget.clubId,
        clubName: _clubName,
      ),
      TournamentManagementCenterScreen(clubId: widget.clubId),
      _buildMenuScreen(),
    ];
  }

  Widget _buildMenuScreen() {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.blue),
            title: Text('Khuyến mãi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClubPromotionHubScreen(
                    clubId: widget.clubId,
                    clubName: _clubName,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user, color: Colors.green),
            title: Text('Nhân viên'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StaffMainScreen(
                    clubId: widget.clubId,
                    clubName: _clubName,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: Text('Cài đặt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClubSettingsScreen(clubId: widget.clubId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _buildScreens()),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: OldTheme.AppTheme.primaryLight,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: 'Thành viên',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.campaign),
            label: 'Khuyến mãi',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events),
            label: 'Giải đấu',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
