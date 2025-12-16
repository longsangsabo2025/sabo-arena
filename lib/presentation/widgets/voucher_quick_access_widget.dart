import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../routes/app_routes.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../core/design_system/design_system.dart';

class VoucherQuickAccessWidget extends StatefulWidget {
  final bool showInDashboard;

  const VoucherQuickAccessWidget({Key? key, this.showInDashboard = false})
    : super(key: key);

  @override
  State<VoucherQuickAccessWidget> createState() =>
      _VoucherQuickAccessWidgetState();
}

class _VoucherQuickAccessWidgetState extends State<VoucherQuickAccessWidget> {
  UserProfile? currentUser;
  int activeVoucherCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await UserService.instance.getCurrentUserProfile();
      if (user != null) {
        // Simulate voucher count loading - replace with actual service call
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          currentUser = user;
          activeVoucherCount = 3; // Mock data - replace with actual count
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return widget.showInDashboard
        ? _buildDashboardWidget()
        : _buildQuickAccessCard();
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 1.5.h,
                  width: 30.w,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 1.h),
                Container(
                  height: 1.2.h,
                  width: 20.w,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.premium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _navigateToVoucherManagement,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                // Voucher Icon
                Container(
                  padding: EdgeInsets.all(2.5.w),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    size: 6.w,
                    color: AppColors.surface,
                  ),
                ),

                SizedBox(width: 4.w),

                // Voucher Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voucher của bạn',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 0.5.h),

                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            size: 4.w,
                            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '$activeVoucherCount voucher đang hoạt động',
                            style: TextStyle(
                              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),

                      if (activeVoucherCount > 0) ...[
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Sử dụng ngay!',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow
                Icon(Icons.arrow_forward_ios, color: AppColors.textOnPrimary, size: 4.w),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardWidget() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Voucher & Khuyến mãi',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (currentUser?.role == 'club_owner' ||
                    currentUser?.role == 'admin' ||
                    currentUser?.role == 'super_admin')
                  TextButton.icon(
                    onPressed: _navigateToManagement,
                    icon: Icon(Icons.settings, size: 4.w),
                    label: Text('Quản lý', style: TextStyle(fontSize: 10.sp), overflow: TextOverflow.ellipsis),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),

            SizedBox(height: 2.h),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Voucher hiện có',
                    '$activeVoucherCount',
                    Icons.local_offer,
                    AppColors.success,
                  ),
                ),

                SizedBox(width: 3.w),

                Expanded(
                  child: _buildStatCard(
                    'Tiết kiệm tháng này',
                    '250K',
                    Icons.savings,
                    AppColors.warning,
                  ),
                ),
              ],
            ),

            if (activeVoucherCount > 0) ...[
              SizedBox(height: 2.h),

              ElevatedButton.icon(
                onPressed: _navigateToVoucherList,
                icon: const Icon(Icons.redeem),
                label: Text('Xem tất cả voucher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 5.h),
                ),
              ),
            ] else ...[
              SizedBox(height: 2.h),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 8.w,
                      color: AppColors.gray400,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Chưa có voucher nào',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                    Text(
                      'Tham gia các hoạt động để nhận voucher!',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 9.sp),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 4.w),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 9.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToVoucherManagement() {
    Navigator.pushNamed(
      context,
      AppRoutes.voucherManagementMainScreen,
      arguments: {'initialTab': 'my_vouchers'},
    );
  }

  void _navigateToVoucherList() {
    Navigator.pushNamed(
      context,
      AppRoutes.voucherManagementMainScreen,
      arguments: {'initialTab': 'my_vouchers'},
    );
  }

  void _navigateToManagement() {
    if (currentUser?.role == 'admin' || currentUser?.role == 'super_admin') {
      Navigator.pushNamed(context, AppRoutes.voucherManagementMainScreen);
    } else if (currentUser?.role == 'club_owner') {
      Navigator.pushNamed(context, AppRoutes.voucherManagementMainScreen);
    }
  }
}

// Usage Example Widget for Home Screen Integration
class VoucherHomeBanner extends StatelessWidget {
  const VoucherHomeBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const VoucherQuickAccessWidget(showInDashboard: false);
  }
}

// Usage Example Widget for Dashboard Integration
class VoucherDashboardSection extends StatelessWidget {
  const VoucherDashboardSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const VoucherQuickAccessWidget(showInDashboard: true);
  }
}
