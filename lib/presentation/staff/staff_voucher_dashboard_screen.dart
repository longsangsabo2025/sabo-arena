import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/voucher_management_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/design_system/design_system.dart';
import 'staff_voucher_verification_screen.dart';

/// Staff Dashboard để quản lý voucher của quán
class StaffVoucherDashboardScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const StaffVoucherDashboardScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<StaffVoucherDashboardScreen> createState() => _StaffVoucherDashboardScreenState();
}

class _StaffVoucherDashboardScreenState extends State<StaffVoucherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _voucherService = VoucherManagementService();

  List<Map<String, dynamic>> _pendingVouchers = [];
  List<Map<String, dynamic>> _usedVouchers = [];
  Map<String, dynamic> _stats = {};
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
      final pendingFuture = _voucherService.getPendingVouchers(widget.clubId);
      final usedFuture = _voucherService.getVoucherHistory(widget.clubId);
      final statsFuture = _voucherService.getVoucherStats(widget.clubId);

      final results = await Future.wait([pendingFuture, usedFuture, statsFuture]);

      if (!mounted) return;

      setState(() {
        _pendingVouchers = results[0] as List<Map<String, dynamic>>;
        _usedVouchers = results[1] as List<Map<String, dynamic>>;
        _stats = (results[2] as Map<String, dynamic>)['stats'] ?? {};
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
        title: 'Quản lý Voucher - ${widget.clubName}',
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Stats Overview
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '🎫 Chưa dùng',
                        '${_stats['pending_vouchers'] ?? 0}',
                        AppColors.warning,
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: _buildStatCard(
                        '✅ Đã dùng',
                        '${_stats['used_vouchers'] ?? 0}',
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.sp),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '💰 Tổng giá trị',
                        _formatCurrency(_stats['total_value'] ?? 0),
                        AppColors.info,
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: _buildStatCard(
                        '💸 Đã sử dụng',
                        _formatCurrency(_stats['used_value'] ?? 0),
                        AppColors.premium,
                      ),
                    ),
                  ],
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.sp),
              ),
              labelColor: AppColors.textOnPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: 'Chưa sử dụng (${_pendingVouchers.length})'),
                Tab(text: 'Đã sử dụng (${_usedVouchers.length})'),
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
                      _buildUsedTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'staff_voucher_verify',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffVoucherVerificationScreen(
                clubId: widget.clubId,
                clubName: widget.clubName,
              ),
            ),
          ).then((_) => _loadData()); // Refresh when returning
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Xác thực Voucher'),
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
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
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
    if (_pendingVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64.sp,
              color: AppColors.gray400,
            ),
            SizedBox(height: 16.sp),
            Text(
              'Không có voucher nào chưa sử dụng',
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
      itemCount: _pendingVouchers.length,
      itemBuilder: (context, index) {
        final voucher = _pendingVouchers[index];
        return _buildVoucherCard(voucher, isPending: true);
      },
    );
  }

  Widget _buildUsedTab() {
    if (_usedVouchers.isEmpty) {
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
              'Chưa có voucher nào được sử dụng',
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
      itemCount: _usedVouchers.length,
      itemBuilder: (context, index) {
        final voucher = _usedVouchers[index];
        return _buildVoucherCard(voucher, isPending: false);
      },
    );
  }

  Widget _buildVoucherCard(
    Map<String, dynamic> voucher, {
    required bool isPending,
  }) {
    final cardColor = isPending ? AppColors.warning50 : AppColors.gray50;
    final borderColor = isPending ? AppColors.warning100 : AppColors.border;

    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: borderColor, width: 1.5),
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
                Icon(
                  isPending ? Icons.schedule : Icons.check_circle,
                  color: isPending ? AppColors.warning : AppColors.success,
                  size: 20.sp,
                ),
                SizedBox(width: 8.sp),
                Expanded(
                  child: Text(
                    _getVoucherTypeText(voucher['voucher_type']),
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
                    color: isPending ? AppColors.warning.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.sp),
                  ),
                  child: Text(
                    isPending ? 'Chưa dùng' : 'Đã dùng',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isPending ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.sp),

            // Details
            _buildDetailRow('👤 Khách hàng:', voucher['users']['username'] ?? 'N/A'),
            _buildDetailRow('💰 Giá trị:', _formatCurrency(voucher['voucher_value'])),
            _buildDetailRow('🔢 Mã voucher:', voucher['voucher_code'] ?? 'N/A'),
            _buildDetailRow('🏆 Tournament:', voucher['tournaments']?['name'] ?? 'N/A'),
            _buildDetailRow('📅 Ngày tạo:', _formatDateTime(voucher['created_at'])),
            
            if (voucher['used_at'] != null)
              _buildDetailRow('✅ Ngày sử dụng:', _formatDateTime(voucher['used_at'])),

            if (voucher['expires_at'] != null)
              _buildDetailRow('⏰ Hết hạn:', _formatDateTime(voucher['expires_at'])),
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
            width: 30.w,
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

  String _getVoucherTypeText(String? type) {
    switch (type?.toLowerCase()) {
      case 'cash':
        return '💵 Tiền mặt';
      case 'discount':
        return '🎯 Giảm giá';
      case 'free_drink':
        return '🥤 Nước uống miễn phí';
      case 'free_game':
        return '🎮 Game miễn phí';
      case 'tournament_prize':
        return '🏆 Giải thưởng Tournament';
      default:
        return '🎫 ${type ?? 'Voucher'}';
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0 VNĐ';
    if (value is num) {
      return '${value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} VNĐ';
    }
    return value.toString();
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