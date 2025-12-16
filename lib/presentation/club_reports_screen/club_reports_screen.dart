import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/services/club_analytics_service.dart';
import 'package:sabo_arena/presentation/tournament_history_screen/tournament_history_screen.dart';
import 'package:sabo_arena/core/device/device_info.dart';
import 'package:sabo_arena/core/design_system/responsive_grid.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class ClubReportsScreen extends StatefulWidget {
  final String clubId;

  const ClubReportsScreen({super.key, required this.clubId});

  @override
  State<ClubReportsScreen> createState() => _ClubReportsScreenState();
}

class _ClubReportsScreenState extends State<ClubReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';
  
  // Real data from analytics service
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  String? _error;

  final ClubAnalyticsService _analyticsService = ClubAnalyticsService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _analyticsService.getClubAnalytics(widget.clubId);
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Báo cáo & Phân tích'),
      backgroundColor: Colors.grey[50],
      body: _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    final isIPad = DeviceInfo.isIPad(context);
    final maxWidth = isIPad ? 1100.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Lỗi tải dữ liệu', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // Period Filter
                      _buildPeriodFilter(),

                      // Tab Bar
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppTheme.primaryLight,
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: AppTheme.primaryLight,
                          tabs: const [
                            Tab(text: 'Tổng quan'),
                            Tab(text: 'Doanh thu'),
                            Tab(text: 'Thành viên'),
                            Tab(text: 'Hoạt động'),
                          ],
                        ),
                      ),

                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewReport(),
                            _buildRevenueReport(),
                            _buildMemberReport(),
                            _buildActivityReport(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'Thời gian:', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildPeriodChip('week', 'Tuần'),
                const SizedBox(width: 8),
                _buildPeriodChip('month', 'Tháng'),
                const SizedBox(width: 8),
                _buildPeriodChip('quarter', 'Quý'),
                const SizedBox(width: 8),
                _buildPeriodChip('year', 'Năm'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = value;
        });
      },
      selectedColor: AppTheme.primaryLight.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryLight,
    );
  }

  Widget _buildOverviewReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          _buildMetricsGrid(),
          const SizedBox(height: 24),

          // Performance Chart
          _buildPerformanceChart(),
          const SizedBox(height: 24),

          // Top Performers
          _buildTopPerformers(),
          const SizedBox(height: 24),

          // Recent Trends
          _buildRecentTrends(),
        ],
      ),
    );
  }

  Widget _buildRevenueReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Summary
          _buildRevenueCards(),
          const SizedBox(height: 24),

          // Revenue Chart
          _buildRevenueChart(),
          const SizedBox(height: 24),

          // Revenue Sources
          _buildRevenueSources(),
          const SizedBox(height: 24),

          // Payment Methods
          _buildPaymentMethods(),
        ],
      ),
    );
  }

  Widget _buildMemberReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Stats
          _buildMemberStats(),
          const SizedBox(height: 24),

          // Growth Chart
          _buildMemberGrowthChart(),
          const SizedBox(height: 24),

          // Member Activity
          _buildMemberActivity(),
          const SizedBox(height: 24),

          // Retention Rate
          _buildRetentionRate(),
        ],
      ),
    );
  }

  Widget _buildActivityReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Summary
          _buildActivitySummary(),
          const SizedBox(height: 24),

          // Popular Times
          _buildPopularTimes(),
          const SizedBox(height: 24),

          // Equipment Usage
          _buildEquipmentUsage(),
          const SizedBox(height: 24),

          // Event Statistics
          _buildEventStatistics(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final tournamentStats = _analyticsData?['tournament_stats'] ?? {};
    final memberStats = _analyticsData?['member_stats'] ?? {};
    final revenueStats = _analyticsData?['revenue_stats'] ?? {};

    // Tournament data
    final totalTournaments = tournamentStats['total_tournaments'] ?? 0;
    final completedTournaments = tournamentStats['completed'] ?? 0;
    final ongoingTournaments = tournamentStats['ongoing'] ?? 0;
    final upcomingTournaments = tournamentStats['upcoming'] ?? 0;
    final avgParticipants = tournamentStats['avg_participants'] ?? 0;
    final totalPrizePool = tournamentStats['total_prize_pool'] ?? 0;
    final registrations = tournamentStats['registrations'] ?? 0;

    // Member data
    final totalMembers = memberStats['total_members'] ?? 0;
    final activeMembers = memberStats['active_members'] ?? 0;
    final newMembers30d = memberStats['new_members_30d'] ?? 0;

    // Revenue data
    final totalRevenue = revenueStats['total_revenue'] ?? 0;
    final revenue30d = revenueStats['revenue_30d'] ?? 0;

    final metrics = [
      {
        'title': 'Tổng doanh thu',
        'value': _formatCurrency(totalRevenue),
        'icon': Icons.monetization_on,
        'color': AppTheme.successLight,
        'subtitle': revenue30d > 0 ? '+${_formatCurrency(revenue30d)}' : '0 VND',
      },
      {
        'title': 'Thành viên hoạt động',
        'value': '$activeMembers/$totalMembers',
        'icon': Icons.person_add,
        'color': AppTheme.primaryLight,
        'subtitle': newMembers30d > 0 ? '+$newMembers30d mới' : 'Không có mới',
      },
      {
        'title': 'Giải đấu',
        'value': '$totalTournaments tổng',
        'icon': Icons.emoji_events,
        'color': AppTheme.accentLight,
        'subtitle': 'Đang: $ongoingTournaments, Sắp: $upcomingTournaments',
      },
      {
        'title': 'Tỷ lệ tham gia',
        'value': totalTournaments > 0
            ? '${((registrations / totalTournaments) * 100).toStringAsFixed(1)}%'
            : '0%',
        'icon': Icons.sports,
        'color': AppTheme.primaryLight,
        'subtitle': '$registrations đăng ký',
      },
    ];

    return ResponsiveGrid(
      items: metrics,
      itemBuilder: (context, metric, index) {
        return _buildMetricCard(
          metric['title'] as String,
          metric['value'] as String,
          metric['icon'] as IconData,
          metric['color'] as Color,
          metric['subtitle'] as String,
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      spacing: 12,
      runSpacing: 12,
      childAspectRatio: 1.2,
      padding: EdgeInsets.zero,
    );
  }

  String _formatCurrency(num amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M VND';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K VND';
    } else {
      return '$amount VND';
    }
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change, style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.successLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final tournamentStats = _analyticsData?['tournament_stats'] ?? {};
    final memberStats = _analyticsData?['member_stats'] ?? {};
    final revenueStats = _analyticsData?['revenue_stats'] ?? {};
    
    final totalTournaments = tournamentStats['total_tournaments'] ?? 0;
    final totalMembers = memberStats['total_members'] ?? 0;
    final totalRevenue = double.tryParse(revenueStats['total_revenue']?.toString() ?? '0') ?? 0;

    return _buildChartCard(
      'Hiệu suất tổng quan',
      '📊 Tổng quan:\n'
      '• $totalTournaments giải đấu đã tổ chức\n'
      '• $totalMembers thành viên trong CLB\n'
      '• ${_formatCurrency(totalRevenue)} doanh thu tích lũy\n\n'
      '💡 Biểu đồ chi tiết sẽ được cập nhật trong phiên bản tiếp theo',
      Icons.show_chart,
    );
  }

  Widget _buildRevenueCards() {
    final revenueStats = _analyticsData?['revenue_stats'] ?? {};
    final totalRevenue = revenueStats['total_revenue'] ?? 0;
    final revenue30d = revenueStats['revenue_30d'] ?? 0;
    final revenueToday = revenueStats['revenue_today'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildRevenueCard(
            'Doanh thu hôm nay',
            _formatCurrency(revenueToday),
            AppTheme.successLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRevenueCard(
            'Doanh thu 30 ngày',
            _formatCurrency(revenue30d),
            AppTheme.primaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text(
            value, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final revenueStats = _analyticsData?['revenue_stats'] ?? {};
    final tournamentRevenue = double.tryParse(revenueStats['tournament_revenue']?.toString() ?? '0') ?? 0;
    final reservationRevenue = double.tryParse(revenueStats['reservation_revenue']?.toString() ?? '0') ?? 0;
    final revenue30d = double.tryParse(revenueStats['revenue_30d']?.toString() ?? '0') ?? 0;

    return _buildChartCard(
      'Biểu đồ doanh thu',
      '💰 Phân tích doanh thu:\n'
      '• Giải đấu: ${_formatCurrency(tournamentRevenue)}\n'
      '• Thuê bàn: ${_formatCurrency(reservationRevenue)}\n'
      '• 30 ngày qua: ${_formatCurrency(revenue30d)}\n\n'
      '📈 Biểu đồ chi tiết sẽ được cập nhật trong phiên bản tiếp theo',
      Icons.bar_chart,
    );
  }

  Widget _buildRevenueSources() {
    final revenueStats = _analyticsData?['revenue_stats'] ?? {};
    final totalRevenue = double.tryParse(revenueStats['total_revenue']?.toString() ?? '0') ?? 0;
    final tournamentRevenue = double.tryParse(revenueStats['tournament_revenue']?.toString() ?? '0') ?? 0;
    final reservationRevenue = double.tryParse(revenueStats['reservation_revenue']?.toString() ?? '0') ?? 0;

    double tournamentPercent = 0;
    double reservationPercent = 0;

    if (totalRevenue > 0) {
      tournamentPercent = (tournamentRevenue / totalRevenue) * 100;
      reservationPercent = (reservationRevenue / totalRevenue) * 100;
    }

    return _buildListCard('Nguồn doanh thu', [
      {
        'title': 'Giải đấu',
        'value': '${tournamentPercent.toStringAsFixed(1)}%',
        'amount': _formatCurrency(tournamentRevenue),
      },
      {
        'title': 'Thuê bàn',
        'value': '${reservationPercent.toStringAsFixed(1)}%',
        'amount': _formatCurrency(reservationRevenue),
      },
      {
        'title': 'Tổng cộng',
        'value': '100%',
        'amount': _formatCurrency(totalRevenue),
      },
    ]);
  }

  Widget _buildPaymentMethods() {
    return _buildListCard('Phương thức thanh toán', [
      {'title': 'Chuyển khoản', 'value': '60%', 'amount': '9.3M VND'},
      {'title': 'Tiền mặt', 'value': '25%', 'amount': '3.9M VND'},
      {'title': 'Ví điện tử', 'value': '15%', 'amount': '2.3M VND'},
    ]);
  }

  Widget _buildMemberStats() {
    final memberStats = _analyticsData?['member_stats'] ?? {};
    final totalMembers = memberStats['total_members'] ?? 0;
    final newMembers30d = memberStats['new_members_30d'] ?? 0;
    final activeMembers = memberStats['active_members_30d'] ?? 0;

    final stats = [
      {'title': 'Tổng TV', 'value': '$totalMembers', 'color': AppTheme.primaryLight},
      {'title': 'TV mới (30d)', 'value': '$newMembers30d', 'color': AppTheme.successLight},
      {'title': 'TV hoạt động', 'value': '$activeMembers', 'color': AppTheme.accentLight},
    ];

    return ResponsiveGrid(
      items: stats,
      itemBuilder: (context, stat, index) {
        return _buildStatCard(
          stat['title'] as String,
          stat['value'] as String,
          stat['color'] as Color,
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      spacing: 12,
      runSpacing: 12,
      childAspectRatio: 1.1,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberGrowthChart() {
    final memberStats = _analyticsData?['member_stats'] ?? {};
    final totalMembers = memberStats['total_members'] ?? 0;
    final newMembers30d = memberStats['new_members_30d'] ?? 0;
    final activeMembers = memberStats['active_members_30d'] ?? 0;
    final activityRate = memberStats['activity_rate'] ?? '0';

    return _buildChartCard(
      'Tăng trưởng thành viên',
      '👥 Thống kê thành viên:\n'
      '• Tổng: $totalMembers thành viên\n'
      '• Mới (30 ngày): $newMembers30d người\n'
      '• Hoạt động: $activeMembers người ($activityRate%)\n\n'
      '📊 Biểu đồ xu hướng sẽ được cập nhật trong phiên bản tiếp theo',
      Icons.trending_up,
    );
  }

  Widget _buildMemberActivity() {
    final memberStats = _analyticsData?['member_stats'] ?? {};
    final totalMembers = memberStats['total_members'] ?? 0;
    final activeMembers = memberStats['active_members_30d'] ?? 0;
    
    if (totalMembers == 0) {
      return _buildListCard('Hoạt động thành viên', [
        {'title': 'Chưa có thành viên', 'value': '0%', 'amount': '0 người'},
      ]);
    }

    final activePercent = ((activeMembers / totalMembers) * 100).toStringAsFixed(1);
    final inactiveMembers = totalMembers - activeMembers;
    final inactivePercent = ((inactiveMembers / totalMembers) * 100).toStringAsFixed(1);

    return _buildListCard('Hoạt động thành viên', [
      {
        'title': 'Thành viên tích cực',
        'value': '$activePercent%',
        'amount': '$activeMembers người',
      },
      {
        'title': 'Thành viên ít hoạt động',
        'value': '$inactivePercent%',
        'amount': '$inactiveMembers người',
      },
    ]);
  }

  Widget _buildRetentionRate() {
    final memberStats = _analyticsData?['member_stats'] ?? {};
    final totalMembers = memberStats['total_members'] ?? 0;
    final activeMembers = memberStats['active_members_30d'] ?? 0;
    
    final retentionRate = totalMembers > 0 
        ? ((activeMembers / totalMembers) * 100).toStringAsFixed(1)
        : '0';

    return _buildChartCard(
      'Tỷ lệ giữ chân thành viên',
      '🎯 Retention Rate: $retentionRate%\n\n'
      '📍 Tỷ lệ thành viên hoạt động trong 30 ngày qua:\n'
      '• Hoạt động: $activeMembers/$totalMembers người\n'
      '• Tỷ lệ: $retentionRate%\n\n'
      '💡 Biểu đồ xu hướng giữ chân sẽ được cập nhật trong phiên bản tiếp theo',
      Icons.people_outline,
    );
  }

  Widget _buildActivitySummary() {
    final engagementStats = _analyticsData?['engagement_stats'] ?? {};
    final totalPosts = engagementStats['total_posts'] ?? 0;
    final posts30d = engagementStats['posts_30d'] ?? 0;
    final totalLikes = engagementStats['total_likes'] ?? 0;
    final totalComments = engagementStats['total_comments'] ?? 0;

    final activities = [
      {'title': 'Tổng bài viết', 'value': '$totalPosts bài', 'icon': Icons.article},
      {'title': 'Bài viết 30d', 'value': '$posts30d bài', 'icon': Icons.access_time},
      {'title': 'Tổng lượt thích', 'value': '$totalLikes', 'icon': Icons.thumb_up},
      {'title': 'Tổng bình luận', 'value': '$totalComments', 'icon': Icons.comment},
    ];

    return ResponsiveGrid(
      items: activities,
      itemBuilder: (context, activity, index) {
        return _buildActivityCard(
          activity['title'] as String,
          activity['value'] as String,
          activity['icon'] as IconData,
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      spacing: 12,
      runSpacing: 12,
      childAspectRatio: 1.5,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildActivityCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 24),
          const SizedBox(height: 12),
          Text(
            value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPopularTimes() {
    return _buildChartCard(
      'Giờ hoạt động phổ biến',
      'Biểu đồ giờ hoạt động sẽ được hiển thị ở đây',
      Icons.schedule,
    );
  }

  Widget _buildEquipmentUsage() {
    return _buildListCard('Sử dụng thiết bị', [
      {'title': 'Bàn billiards', 'value': '85%', 'amount': '120 giờ'},
      {'title': 'Phòng VIP', 'value': '60%', 'amount': '80 giờ'},
      {'title': 'Vợt cho thuê', 'value': '60%', 'amount': '45 lượt'},
      {'title': 'Shuttle cock', 'value': '95%', 'amount': '200 quả'},
    ]);
  }

  Widget _buildEventStatistics() {
    return _buildListCard('Thống kê sự kiện', [
      {
        'title': 'Giải đấu tháng này',
        'value': '3',
        'amount': '45 người tham gia',
      },
      {'title': 'Lớp học', 'value': '8', 'amount': '25 học viên'},
      {
        'title': 'Sự kiện đặc biệt',
        'value': '2',
        'amount': '60 người tham gia',
      },
    ]);
  }

  Widget _buildTopPerformers() {
    final tournamentStats = _analyticsData?['tournament_stats'] ?? {};
    final recentTournaments = tournamentStats['recent_tournaments'] as List<dynamic>? ?? [];

    if (recentTournaments.isEmpty) {
      return _buildListCardWithAction(
        'Giải đấu gần đây',
        [
          {'title': 'Chưa có giải đấu nào', 'value': '', 'amount': 'Hãy tạo giải đấu đầu tiên'},
        ],
        null,
      );
    }

    final items = recentTournaments.take(3).map((tournament) {
      final name = tournament['name'] ?? 'Giải đấu không tên';
      final participants = tournament['participant_count'] ?? 0;
      final status = tournament['status'] ?? 'unknown';
      
      String statusText;
      switch (status) {
        case 'completed':
          statusText = 'Đã kết thúc';
          break;
        case 'ongoing':
          statusText = 'Đang diễn ra';
          break;
        case 'upcoming':
          statusText = 'Sắp diễn ra';
          break;
        default:
          statusText = 'Không rõ';
      }

      return <String, String>{
        'title': name.toString(),
        'value': '$participants người',
        'amount': statusText,
      };
    }).toList();

    return _buildListCardWithAction(
      'Giải đấu gần đây',
      items,
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentHistoryScreen(clubId: widget.clubId),
          ),
        );
      },
    );
  }

  Widget _buildRecentTrends() {
    final tournamentStats = _analyticsData?['tournament_stats'] ?? {};
    final memberStats = _analyticsData?['member_stats'] ?? {};
    final engagementStats = _analyticsData?['engagement_stats'] ?? {};
    
    final tournaments30d = tournamentStats['tournaments_30d'] ?? 0;
    final newMembers30d = memberStats['new_members_30d'] ?? 0;
    final posts30d = engagementStats['posts_30d'] ?? 0;

    return _buildChartCard(
      'Xu hướng gần đây',
      '📈 Hoạt động 30 ngày qua:\n\n'
      '🏆 Giải đấu: $tournaments30d giải mới\n'
      '👤 Thành viên: $newMembers30d người mới tham gia\n'
      '📝 Bài viết: $posts30d bài đăng mới\n\n'
      '💡 Phân tích xu hướng chi tiết sẽ được cập nhật trong phiên bản tiếp theo',
      Icons.insights,
    );
  }

  Widget _buildChartCard(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 12),
              Text(
                title, style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                description, style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, List<Map<String, String>> items) {
    return _buildListCardWithAction(title, items, null);
  }

  Widget _buildListCardWithAction(
    String title,
    List<Map<String, String>> items,
    VoidCallback? onViewAll,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppTheme.primaryLight,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['title']!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value']!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item['amount']!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

