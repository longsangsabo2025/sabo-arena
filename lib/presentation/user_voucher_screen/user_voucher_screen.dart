import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/user_achievement.dart';
import '../../services/voucher_reward_service.dart';
import 'widgets/voucher_card_widget.dart';
import 'widgets/achievement_card_widget.dart';
import 'voucher_detail_screen.dart';
import 'voucher_table_payment_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class UserVoucherScreen extends StatefulWidget {
  final String userId;

  const UserVoucherScreen({super.key, required this.userId});

  @override
  State<UserVoucherScreen> createState() => _UserVoucherScreenState();
}

class _UserVoucherScreenState extends State<UserVoucherScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;

  List<UserVoucher> _allVouchers = [];
  List<UserAchievement> _allAchievements = [];

  final VoucherRewardService _voucherService = VoucherRewardService();

  // Filter & Sort states
  String _selectedFilter = 'all'; // all, active, used, expired
  String _selectedSort = 'value_desc'; // value_desc, value_asc, expiry_asc

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _voucherService.getUserVouchers(widget.userId),
        _voucherService.getUserAchievements(widget.userId),
      ]);

      setState(() {
        _allVouchers = futures[0] as List<UserVoucher>;
        _allAchievements = futures[1] as List<UserAchievement>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // Hiển thị thông báo lỗi thân thiện cho người dùng
        _errorMessage = _getFriendlyErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  /// Chuyển đổi lỗi kỹ thuật thành thông báo thân thiện
  String _getFriendlyErrorMessage(String technicalError) {
    // Log lỗi kỹ thuật cho dev (có thể gửi lên crash analytics)
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Phân tích lỗi và trả về thông báo thân thiện
    if (technicalError.contains('Failed to load user achievements')) {
      return 'Không thể tải thông tin thành tựu.\nVui lòng thử lại sau.';
    } else if (technicalError.contains('Network')) {
      return 'Không có kết nối mạng.\nVui lòng kiểm tra Internet của bạn.';
    } else if (technicalError.contains('timeout')) {
      return 'Kết nối quá chậm.\nVui lòng thử lại.';
    } else if (technicalError.contains('JWT') ||
        technicalError.contains('unauthorized')) {
      return 'Phiên đăng nhập hết hạn.\nVui lòng đăng nhập lại.';
    } else {
      // Lỗi chưa xác định
      return 'Đã có lỗi xảy ra.\nVui lòng thử lại sau hoặc liên hệ hỗ trợ.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Voucher & Thành tựu',
        backgroundColor: AppTheme.primaryLight,
        actions: [
          // Button thanh toán bàn bằng voucher
          IconButton(
            icon: const Icon(Icons.table_restaurant),
            tooltip: 'Thanh toán bàn',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VoucherTablePaymentScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Statistics Header
          _buildStatisticsHeader(),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: AppTheme.textSecondaryLight,
              indicatorColor: AppTheme.primaryLight,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Voucher của tôi'),
                Tab(text: 'Thành tựu'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildVoucherTab(), _buildAchievementTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader() {
    final activeVouchers = _allVouchers.where((v) => v.isUsable).length;
    final completedAchievements = _allAchievements
        .where((a) => a.isCompleted)
        .length;
    final totalAchievements = _allAchievements.length;

    return Container(
      padding: EdgeInsets.all(16.sp),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Voucher khả dụng',
              value: activeVouchers.toString(),
              icon: Icons.local_offer,
              color: Colors.green,
            ),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: _buildStatCard(
              title: 'Thành tựu',
              value: '$completedAchievements/$totalAchievements',
              icon: Icons.emoji_events,
              color: Colors.orange,
            ),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: _buildStatCard(
              title: 'Đã sử dụng',
              value: _allVouchers
                  .where((v) => v.status == VoucherStatus.used)
                  .length
                  .toString(),
              icon: Icons.check_circle,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 4.sp),
          Text(
            value, style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title, style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80.sp,
                color: Colors.orange.shade400,
              ),
              SizedBox(height: 24.sp),
              Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 12.sp),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.sp),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: Icon(Icons.refresh),
                label: Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.sp,
                    vertical: 12.sp,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_allVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer,
              size: 64.sp,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 16.sp),
            Text(
              'Chưa có voucher nào', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Hoàn thành các thành tựu để nhận voucher!', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Apply filters
    List<UserVoucher> filteredVouchers = _allVouchers;
    if (_selectedFilter == 'active') {
      filteredVouchers = _allVouchers.where((v) => v.isUsable).toList();
    } else if (_selectedFilter == 'used') {
      filteredVouchers = _allVouchers.where((v) => v.status == VoucherStatus.used).toList();
    } else if (_selectedFilter == 'expired') {
      filteredVouchers = _allVouchers.where((v) => v.isExpired).toList();
    }

    // Apply sort
    if (_selectedSort == 'value_desc') {
      filteredVouchers.sort((a, b) => (b.discountAmount ?? 0).compareTo(a.discountAmount ?? 0));
    } else if (_selectedSort == 'value_asc') {
      filteredVouchers.sort((a, b) => (a.discountAmount ?? 0).compareTo(b.discountAmount ?? 0));
    } else if (_selectedSort == 'expiry_asc') {
      filteredVouchers.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    }

    return Column(
      children: [
        // Filter & Sort Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
          color: Colors.white,
          child: Row(
            children: [
              // Filter Dropdown
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.sp),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(Icons.filter_list, size: 20.sp),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'active', child: Text('Khả dụng')),
                      DropdownMenuItem(value: 'used', child: Text('Đã dùng')),
                      DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFilter = value);
                      }
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.sp),
              // Sort Dropdown
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.sp),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(Icons.sort, size: 20.sp),
                    items: [
                      DropdownMenuItem(value: 'value_desc', child: Text('Giá trị cao')),
                      DropdownMenuItem(value: 'value_asc', child: Text('Giá trị thấp')),
                      DropdownMenuItem(value: 'expiry_asc', child: Text('Sắp hết hạn')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSort = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Voucher List
        Expanded(
          child: filteredVouchers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64.sp, color: Colors.grey),
                      SizedBox(height: 16.sp),
                      Text(
                        'Không tìm thấy voucher',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.sp),
                  itemCount: filteredVouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = filteredVouchers[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.sp),
                      child: VoucherCardWidget(
                        voucher: voucher,
                        onTap: () => _navigateToVoucherDetail(voucher),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAchievementTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64.sp,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 16.sp),
            Text(
              'Chưa có thành tựu nào', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    // Group achievements by completion status
    final completedAchievements = _allAchievements
        .where((a) => a.isCompleted)
        .toList();
    final inProgressAchievements = _allAchievements
        .where((a) => !a.isCompleted)
        .toList();

    return ListView(
      padding: EdgeInsets.all(16.sp),
      children: [
        if (completedAchievements.isNotEmpty) ...[
          _buildAchievementSection(
            'Đã hoàn thành',
            completedAchievements,
            Colors.green,
          ),
          SizedBox(height: 16.sp),
        ],
        if (inProgressAchievements.isNotEmpty) ...[
          _buildAchievementSection(
            'Đang thực hiện',
            inProgressAchievements,
            Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementSection(
    String title,
    List<UserAchievement> achievements,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 8.sp),
        ...achievements.map(
          (achievement) => Padding(
            padding: EdgeInsets.only(bottom: 8.sp),
            child: AchievementCardWidget(
              achievement: achievement,
              onTap: () => _showAchievementDetail(achievement),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToVoucherDetail(UserVoucher voucher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoucherDetailScreen(voucher: voucher),
      ),
    );
  }

  void _showAchievementDetail(UserAchievement achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.sp,
                height: 4.sp,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.sp),
                ),
              ),
            ),
            SizedBox(height: 20.sp),
            Row(
              children: [
                Icon(
                  achievement.isCompleted
                      ? Icons.emoji_events
                      : Icons.emoji_events_outlined,
                  size: 32.sp,
                  color: achievement.isCompleted ? Colors.amber : Colors.grey,
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title, style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        achievement.description, style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.sp),
            Text(
              'Tiến độ', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.sp),
            LinearProgressIndicator(
              value: achievement.progressPercentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                achievement.isCompleted ? Colors.green : AppTheme.primaryLight,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '${achievement.progressCurrent}/${achievement.progressRequired}', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            if (achievement.isCompleted &&
                achievement.rewardVoucherIds?.isNotEmpty == true) ...[
              SizedBox(height: 20.sp),
              Text(
                'Phần thưởng đã nhận', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.sp),
              Text(
                '${achievement.rewardVoucherIds!.length} voucher khuyến mãi', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

