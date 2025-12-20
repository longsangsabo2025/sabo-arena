import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/core/device/device_info.dart';
import '../club_voucher_registration/club_voucher_registration_simple.dart';
import '../club_prize_voucher/club_prize_voucher_screen.dart';
import '../club_welcome_campaign_screen/club_welcome_campaign_screen.dart';
import '../club_promotion_screen/club_promotion_screen.dart';
import '../loyalty_program/loyalty_program_screen.dart';
import '../voucher_management/voucher_management_main_screen.dart';

class ClubPromotionHubScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubPromotionHubScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubPromotionHubScreen> createState() => _ClubPromotionHubScreenState();
}

class _ClubPromotionHubScreenState extends State<ClubPromotionHubScreen> {
  final _supabase = Supabase.instance.client;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _isAdmin = response['role'] == 'admin';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trung Tâm Khuyến Mãi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Trung Tâm Khuyến Mãi')),
      body: _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    final isIPad = DeviceInfo.isIPad(context);
    final maxWidth = isIPad ? 900.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            _buildSectionHeader('Quản lý Voucher', Icons.card_giftcard),
            SizedBox(height: 2.h),
            _buildFeatureCard(
              title: 'Đăng Ký Voucher',
              subtitle: 'Đăng ký và cấu hình voucher cho CLB',
              icon: Icons.app_registration,
              color: Colors.blue,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ClubVoucherRegistrationSimple(
                          clubId: widget.clubId))),
            ),
            SizedBox(height: 1.5.h),
            _buildFeatureCard(
              title: 'Voucher Giải Thưởng',
              subtitle: 'Quản lý voucher từ giải đấu',
              icon: Icons.emoji_events,
              color: Colors.amber,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ClubPrizeVoucherScreen(clubId: widget.clubId))),
            ),
            SizedBox(height: 1.5.h),
            _buildFeatureCard(
              title: 'Chiến Dịch Chào Mừng',
              subtitle: 'Voucher tự động cho thành viên mới',
              icon: Icons.celebration,
              color: Colors.green,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ClubWelcomeCampaignScreen(
                          clubId: widget.clubId, clubName: widget.clubName))),
            ),
            SizedBox(height: 3.h),
            _buildSectionHeader('Ưu đãi & Loyalty', Icons.loyalty),
            SizedBox(height: 2.h),
            _buildFeatureCard(
              title: 'Tạo Ưu Đãi',
              subtitle: 'Tạo chương trình khuyến mãi mới',
              icon: Icons.add_circle,
              color: Colors.purple,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ClubPromotionScreen(
                          clubId: widget.clubId, clubName: widget.clubName))),
            ),
            SizedBox(height: 1.5.h),
            _buildFeatureCard(
              title: 'Hệ Thống Loyalty',
              subtitle: 'Cấu hình điểm thưởng và cấp độ',
              icon: Icons.star,
              color: Colors.orange,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          LoyaltyProgramScreen(clubId: widget.clubId))),
            ),
            if (_isAdmin) ...[
              SizedBox(height: 3.h),
              _buildSectionHeader('Quản Trị Viên', Icons.admin_panel_settings),
              SizedBox(height: 2.h),
              _buildFeatureCard(
                title: 'Quản Lý Voucher',
                subtitle: 'Xem và quản lý tất cả voucher',
                icon: Icons.inventory,
                color: Colors.red,
                onTap: () {
                  final userId = _supabase.auth.currentUser?.id ?? '';
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VoucherManagementMainScreen(
                              userId: userId, isAdmin: _isAdmin)));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        SizedBox(width: 2.w),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFeatureCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        leading: CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
