import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';
import '../user_voucher_screen/user_voucher_screen.dart';
// import '../club_list_screen/club_list_screen.dart'; // File not found
import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Màn hình Khuyến mãi & Ưu đãi cho User
/// Tổng hợp tất cả voucher, khuyến mãi từ các CLB
class UserPromotionScreen extends StatefulWidget {
  const UserPromotionScreen({super.key});

  @override
  State<UserPromotionScreen> createState() => _UserPromotionScreenState();
}

class _UserPromotionScreenState extends State<UserPromotionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  // bool _isLoading = false;

  int _myVoucherCount = 0;
  int _availablePromotionCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        // setState(() => _isLoading = false);
        return;
      }

      // Load voucher count
      final voucherResponse = await _supabase
          .from('user_vouchers')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active');

      // Load available promotions (mock data for now)
      setState(() {
        _myVoucherCount = (voucherResponse as List).length;
        _availablePromotionCount = 5; // TODO: Load from database
        // _isLoading = false;
      });
    } catch (e) {
      // setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Khuyến mãi & Ưu đãi',
        backgroundColor: AppTheme.primaryLight,
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Stats Header
          _buildStatsHeader(),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textSecondaryLight,
              indicatorColor: AppTheme.primaryLight,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Voucher của tôi'),
                Tab(text: 'Khám phá'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyVouchersTab(),
                _buildDiscoverTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.card_giftcard,
              title: 'Voucher của tôi',
              value: _myVoucherCount.toString(),
              color: Colors.white,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_offer,
              title: 'Ưu đãi mới',
              value: _availablePromotionCount.toString(),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 2.w),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 11.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMyVouchersTab() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 20.w, color: Colors.grey),
            SizedBox(height: 4.w),
            Text(
              'Vui lòng đăng nhập để xem voucher',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    // Embed UserVoucherScreen content
    return UserVoucherScreen(userId: userId);
  }

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discover Clubs Section
          Text(
            'Khám phá CLB có khuyến mãi',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 3.w),
          Text(
            'Tham gia câu lạc bộ để nhận voucher và ưu đãi đặc biệt',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 4.w),

          // Quick Action Cards
          _buildActionCard(
            icon: Icons.store,
            iconColor: Colors.blue,
            title: 'Xem tất cả CLB',
            description: 'Khám phá các câu lạc bộ đang có ưu đãi',
            onTap: () => _navigateToClubList(),
          ),
          SizedBox(height: 3.w),
          _buildActionCard(
            icon: Icons.celebration,
            iconColor: Colors.green,
            title: 'Welcome Voucher',
            description: 'Nhận voucher chào mừng khi gia nhập CLB mới',
            onTap: () => _showWelcomeInfo(),
          ),
          SizedBox(height: 3.w),
          _buildActionCard(
            icon: Icons.emoji_events,
            iconColor: Colors.orange,
            title: 'Thành tựu & Phần thưởng',
            description: 'Hoàn thành thành tựu để nhận voucher',
            onTap: () => _navigateToAchievements(),
          ),

          SizedBox(height: 6.w),

          // Info Section
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 7.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 1.w),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 5.w,
              color: AppTheme.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Cách nhận voucher',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          Text(
            '1. Tham gia câu lạc bộ để nhận welcome voucher\n'
            '2. Hoàn thành thành tựu để kiếm voucher thưởng\n'
            '3. Tham gia sự kiện và giải đấu của CLB\n'
            '4. Theo dõi thông báo để không bỏ lỡ ưu đãi',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation Methods
  void _navigateToClubList() {
    // TODO: Navigate to club list when screen is available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Danh sách CLB đang được phát triển')),
    );
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const ClubListScreen()),
    // );
  }

  void _navigateToAchievements() {
    // Switch to voucher tab (achievements section)
    _tabController.animateTo(0);
  }

  void _showWelcomeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green),
            SizedBox(width: 2.w),
            const Text('Welcome Voucher'),
          ],
        ),
        content: const Text(
          'Khi bạn tham gia câu lạc bộ lần đầu tiên, bạn sẽ tự động nhận được voucher chào mừng (nếu CLB có tham gia chương trình).\n\n'
          'Hãy tìm và tham gia các CLB để nhận ưu đãi ngay!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToClubList();
            },
            child: const Text('Xem CLB'),
          ),
        ],
      ),
    );
  }
}

