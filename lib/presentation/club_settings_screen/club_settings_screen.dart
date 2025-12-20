import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/routes/app_routes.dart';
import '../club_profile_edit_screen/club_profile_edit_screen_simple.dart';
import '../club_management/club_members_screen.dart';
import 'club_profile_image_settings_screen.dart';
import 'operating_hours_screen.dart';
import 'club_rules_screen.dart';
import 'pricing_settings_screen.dart';
import 'payment_settings_screen.dart';
import 'club_logo_settings_screen.dart';
import 'color_settings_screen.dart';
import 'membership_policy_screen.dart';
import 'membership_types_screen.dart';
import '../club_dashboard_screen/club_analytics_screen.dart';
import '../notification_settings_screen.dart';
import '../../services/club_service.dart';

class ClubSettingsScreen extends StatefulWidget {
  final String clubId;

  const ClubSettingsScreen({super.key, required this.clubId});

  @override
  State<ClubSettingsScreen> createState() => _ClubSettingsScreenState();
}

class _ClubSettingsScreenState extends State<ClubSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Cài đặt CLB'),
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 iOS Facebook Style: Section headers with padding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'CÀI ĐẶT CHUNG',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.edit_outlined,
                'Chỉnh sửa thông tin CLB',
                'Tên, mô tả, địa chỉ, số điện thoại',
                () => _navigateToProfileEdit(),
              ),
              _buildSettingItem(
                Icons.access_time_outlined,
                'Giờ hoạt động',
                'Thiết lập giờ mở cửa và đóng cửa',
                () => _showOperatingHours(),
              ),
              _buildSettingItem(
                Icons.rule_outlined,
                'Quy định CLB',
                'Thiết lập các quy định và điều khoản',
                () => _showClubRules(),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'TÀI CHÍNH',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.monetization_on_outlined,
                'Bảng giá dịch vụ',
                'Thiết lập giá các dịch vụ và sân chơi',
                () => _showPricingSettings(),
              ),
              _buildSettingItem(
                Icons.payment_outlined,
                'Phương thức thanh toán',
                'Thiết lập các phương thức thanh toán',
                () => _showPaymentSettings(),
              ),
              _buildSettingItem(
                Icons.receipt_outlined,
                'Hóa đơn và biên lai',
                'Cài đặt thông tin xuất hóa đơn',
                () => _showInvoiceSettings(),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'GIAO DIỆN',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.image_outlined,
                'Logo câu lạc bộ',
                'Thay đổi logo hiển thị trên dashboard',
                () => _showLogoSettings(),
              ),
              _buildSettingItem(
                Icons.person_outline,
                'Ảnh đại diện & Ảnh bìa',
                'Cập nhật hình ảnh đại diện và ảnh nền',
                () => _showProfileImageSettings(),
              ),
              _buildSettingItem(
                Icons.palette_outlined,
                'Màu sắc chủ đạo',
                'Tùy chỉnh màu sắc giao diện CLB',
                () => _showColorSettings(),
              ),
            ]),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'THÀNH VIÊN',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.admin_panel_settings_outlined,
                'Quản lý quyền thành viên',
                'Cấp quyền Admin, Staff cho thành viên',
                () => _showMemberPermissions(),
              ),
              _buildSettingItem(
                Icons.person_add_outlined,
                'Chính sách thành viên',
                'Thiết lập quy định cho thành viên mới',
                () => _showMembershipPolicy(),
              ),
              _buildSettingItem(
                Icons.card_membership_outlined,
                'Loại thành viên',
                'Thiết lập các loại thành viên và quyền lợi',
                () => _showMembershipTypes(),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'HỆ THỐNG',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.notifications_outlined,
                'Cài đặt thông báo',
                'Thiết lập thông báo tự động',
                () => _showNotificationSettings(),
              ),
              _buildSettingItem(
                Icons.analytics_outlined,
                'Thống kê & Analytics',
                'Xem báo cáo và thống kê câu lạc bộ',
                () => _showAnalytics(),
              ),
              _buildSettingItem(
                Icons.backup_outlined,
                'Sao lưu dữ liệu',
                'Sao lưu và khôi phục dữ liệu CLB',
                () => _showBackupSettings(),
              ),
              _buildSettingItem(
                Icons.security_outlined,
                'Bảo mật',
                'Cài đặt bảo mật và quyền truy cập',
                () => _showSecuritySettings(),
                isLast: true,
              ),
            ]),

            // Switch to Player View Button
            const SizedBox(height: 32),
            _buildPlayerViewButton(),

            const SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12), // iOS style rounded corners
        border: Border.all(
          color: AppTheme.textSecondaryLight.withValues(alpha: 0.1),
          width: 0.5,
        ),
        // 🎯 iOS Style: Very subtle shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // 🎯 iOS Style: Larger circular icon background
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppTheme.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 16),
                  // 🎯 iOS Style: Larger font sizes
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17, // iOS standard 17pt
                            color: AppTheme.textPrimaryLight,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14, // iOS standard 14pt for subtitle
                            color: AppTheme.textSecondaryLight,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 🎯 iOS Style: Chevron icon
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondaryLight.withValues(alpha: 0.5),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 🎯 iOS Style: Separator line (except for last item)
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 72), // Align with text
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: AppTheme.textSecondaryLight.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }

  // Navigation methods
  void _navigateToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClubProfileEditScreenSimple(clubId: widget.clubId),
      ),
    );
  }

  void _showOperatingHours() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OperatingHoursScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showClubRules() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubRulesScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showPricingSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PricingSettingsScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showPaymentSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSettingsScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showInvoiceSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng hóa đơn đang được phát triển')),
    );
  }

  void _showMembershipPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MembershipPolicyScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showMemberPermissions() async {
    // Load club name first
    try {
      final club = await ClubService.instance.getClubById(widget.clubId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClubMembersScreen(
              clubId: widget.clubId,
              clubName: club.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showMembershipTypes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MembershipTypesScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _showAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubAnalyticsScreen(
          clubId: widget.clubId,
          clubName: 'Club Analytics', // TODO: Get actual club name
        ),
      ),
    );
  }

  void _showBackupSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng sao lưu đang được phát triển')),
    );
  }

  void _showSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng bảo mật đang được phát triển')),
    );
  }

  void _showLogoSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubLogoSettingsScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showProfileImageSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClubProfileImageSettingsScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showColorSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColorSettingsScreen(clubId: widget.clubId),
      ),
    );
  }

  Widget _buildPlayerViewButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withValues(alpha: 0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _switchToPlayerView,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 22.sp),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quay về giao diện Player',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chuyển sang giao diện người chơi',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _switchToPlayerView() {
    // 🚀 PHASE 1: Navigate to main screen with persistent tabs
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.mainScreen, (route) => false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã chuyển về giao diện Player'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
