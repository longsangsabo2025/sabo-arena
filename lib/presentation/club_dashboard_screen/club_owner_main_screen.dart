import 'package:flutter/material.dart';
import 'package:sabo_arena/theme/app_theme.dart' as OldTheme;
import './club_dashboard_screen_simple.dart';
import '../club_management/club_members_screen.dart';
import '../club_promotion_hub/club_promotion_hub_screen.dart';
import '../tournament_management_center/tournament_management_center_screen.dart';
import '../club_settings_screen/club_settings_screen.dart';
import '../club/club_match_management_screen.dart';
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    try {
      final club = await ClubService.instance.getClubById(widget.clubId);
      setState(() {
        _clubName = club.name;
        _isLoading = false;
        _screens = [
          ClubDashboardScreenSimple(clubId: widget.clubId),
          ClubMembersScreen(clubId: widget.clubId, clubName: _clubName),
          ClubMatchManagementScreen(
            clubId: widget.clubId,
            clubName: _clubName,
          ),
          ClubPromotionHubScreen(
            clubId: widget.clubId,
            clubName: _clubName,
          ),
          TournamentManagementCenterScreen(clubId: widget.clubId),
          StaffMainScreen(
            clubId: widget.clubId,
            clubName: _clubName,
          ),
          ClubSettingsScreen(clubId: widget.clubId),
        ];
      });
    } catch (e) {
      setState(() {
        _clubName = 'CLB';
        _isLoading = false;
        _screens = [
          ClubDashboardScreenSimple(clubId: widget.clubId),
          ClubMembersScreen(clubId: widget.clubId, clubName: _clubName),
          ClubMatchManagementScreen(
            clubId: widget.clubId,
            clubName: _clubName,
          ),
          ClubPromotionHubScreen(
            clubId: widget.clubId,
            clubName: _clubName,
          ),
          TournamentManagementCenterScreen(clubId: widget.clubId),
          StaffMainScreen(
            clubId: widget.clubId,
            clubName: _clubName,
          ),
          ClubSettingsScreen(clubId: widget.clubId),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Thành viên',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Trận đấu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Khuyến mãi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Giải đấu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Staff',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
