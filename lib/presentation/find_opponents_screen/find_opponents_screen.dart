import 'package:flutter/material.dart';
import '../../theme/app_bar_theme.dart' as app_theme;
import '../../routes/app_routes.dart';
import './widgets/community_tab.dart';
import './widgets/my_challenges_tab.dart';
import '../find_opponents_list_screen/find_opponents_list_screen.dart';
// TODO: Re-enable after App Store approval
// import '../../widgets/qr_scanner_widget.dart';

class FindOpponentsScreen extends StatefulWidget {
  const FindOpponentsScreen({super.key});

  @override
  State<FindOpponentsScreen> createState() => _FindOpponentsScreenState();
}

class _FindOpponentsScreenState extends State<FindOpponentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // void _handleNavigation(String route) {
  //   if (route != AppRoutes.findOpponentsScreen) {
  //     Navigator.pushReplacementNamed(context, route);
  //   }
  // }

  // TODO: Re-enable after App Store approval
  // void _showQRScanner() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => QRScannerWidget(
  //         onUserFound: (Map<String, dynamic> userData) {
  //           Navigator.pop(context);
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(
  //               content: Text(
  //                 'Đã tìm thấy người chơi: ${userData['fullName'] ?? 'Không rõ tên'}',
  //               ),
  //               duration: Duration(seconds: 3),
  //             ),
  //           );
  //           // Optionally navigate to user profile or add to opponents list
  //           Navigator.pushNamed(
  //             context,
  //             AppRoutes.userProfileScreen,
  //             arguments: {'userId': userData['id']},
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: app_theme.AppBarTheme.buildGradientTitle('Tìm đối thủ'),
        centerTitle: false,
        actions: [
          // TODO: Re-enable QR Scanner after App Store approval
          // IconButton(
          //   onPressed: _showQRScanner,
          //   icon: const Icon(Icons.qr_code_scanner),
          //   tooltip: 'Quét QR để tìm người chơi',
          // ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E4B3E),
          unselectedLabelColor: const Color(0xFF6B7B73),
          indicatorColor: const Color(0xFF3A5544),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.search, size: 22),
              text: 'Tìm đối',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.people, size: 22),
              text: 'Cộng đồng',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.workspace_premium, size: 22),
              text: 'Của tôi',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FindOpponentsListScreen(isTab: true),
          CommunityTab(),
          MyChallengesTab(),
        ],
      ),
      // 🎯 PHASE 1: Bottom navigation moved to PersistentTabScaffold
      // No bottomNavigationBar here to prevent duplicate navigation bars
    );
  }
}
