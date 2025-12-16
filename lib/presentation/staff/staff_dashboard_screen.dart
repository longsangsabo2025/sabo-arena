import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../services/club_spa_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/design_system/design_system.dart' hide AppTheme;
import 'staff_redemption_screen.dart';

/// Staff Dashboard để quản lý redemption codes và thống kê
class StaffDashboardScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const StaffDashboardScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _spaService = ClubSpaService();

  List<Map<String, dynamic>> _pendingRedemptions = [];
  List<Map<String, dynamic>> _redemptionHistory = [];
  bool _isLoading = true;

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
    });

    try {
      final pendingFuture = _spaService.getPendingRedemptions(widget.clubId);
      final historyFuture = _spaService.getRedemptionHistory(widget.clubId);

      final results = await Future.wait([pendingFuture, historyFuture]);

      setState(() {
        _pendingRedemptions = results[0];
        _redemptionHistory = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quản lý đổi thưởng - ${widget.clubName}',
        backgroundColor: AppTheme.primaryLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Quick Stats
          Container(
            padding: EdgeInsets.all(16.sp),
            margin: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.sp),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '⏳ Chờ giao',
                    _pendingRedemptions.length.toString(),
                    AppColors.warning,
                  ),
                ),
                SizedBox(width: 16.sp),
                Expanded(
                  child: _buildStatCard(
                    '✅ Đã giao',
                    _redemptionHistory
                        .where((r) => r['status'] == 'delivered')
                        .length
                        .toString(),
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.sp),
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8.sp),
              ),
              labelColor: AppColors.textOnPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Chờ giao hàng'),
                Tab(text: 'Lịch sử'),
              ],
            ),
          ),

          SizedBox(height: 16.sp),

          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingTab(),
                      _buildHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'staff_dashboard_scan',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffRedemptionScreen(clubId: widget.clubId),
            ),
          ).then((_) => _loadData()); // Refresh when returning
        },
        backgroundColor: AppTheme.primaryLight,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Kiểm tra mã'),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingRedemptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64.sp,
              color: AppColors.gray400,
            ),
            SizedBox(height: 16.sp),
            Text(
              'Không có đơn nào chờ giao',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: _pendingRedemptions.length,
      itemBuilder: (context, index) {
        final redemption = _pendingRedemptions[index];
        return _buildRedemptionCard(redemption, isPending: true);
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_redemptionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.sp,
              color: AppColors.gray400,
            ),
            SizedBox(height: 16.sp),
            Text(
              'Chưa có lịch sử giao dịch',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: _redemptionHistory.length,
      itemBuilder: (context, index) {
        final redemption = _redemptionHistory[index];
        return _buildRedemptionCard(redemption, isPending: false);
      },
    );
  }

  Widget _buildRedemptionCard(
    Map<String, dynamic> redemption, {
    required bool isPending,
  }) {
    final status = redemption['status'];
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(
          color: isPending ? AppColors.warning100 : statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20.sp),
                SizedBox(width: 8.sp),
                Expanded(
                  child: Text(
                    redemption['spa_rewards']['reward_name'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.sp,
                    vertical: 4.sp,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.sp),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.sp),

            // Details
            _buildDetailRow('👤 Khách hàng:', redemption['users']['username'] ?? 'N/A'),
            _buildDetailRow('💰 SPA:', '${redemption['spa_spent']} SPA'),
            _buildDetailRow('🔢 Mã đổi:', redemption['voucher_code'] ?? 'N/A'),
            _buildDetailRow('📅 Ngày đổi:', _formatDateTime(redemption['redeemed_at'])),
            
            if (redemption['delivered_at'] != null)
              _buildDetailRow('✅ Ngày giao:', _formatDateTime(redemption['delivered_at'])),

            if (isPending) ...[
              SizedBox(height: 16.sp),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsDelivered(redemption['id']),
                  icon: const Icon(Icons.check),
                  label: const Text('Đánh dấu đã giao'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsDelivered(String redemptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận giao hàng'),
        content: const Text('Bạn có chắc đã giao thưởng cho khách hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _spaService.markRedemptionAsDelivered(
        redemptionId,
        widget.clubId,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Đã xác nhận giao thưởng'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi hệ thống: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textDisabled;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ giao';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}