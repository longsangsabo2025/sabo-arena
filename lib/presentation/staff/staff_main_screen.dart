import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import 'staff_tutorial_screen.dart';
import 'staff_voucher_dashboard_screen.dart';
import 'staff_voucher_verification_screen.dart';
import '../club_staff/club_voucher_requests_screen.dart';

/// Màn hình chính cho nhân viên - Entry point
class StaffMainScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const StaffMainScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'SaboArena Staff',
        backgroundColor: AppTheme.primaryLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StaffTutorialScreen(
                    clubId: widget.clubId,
                    clubName: widget.clubName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: EdgeInsets.all(20.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryLight.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.sp),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                      SizedBox(width: 12.sp),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào nhân viên!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.sp),
                            Text(
                              widget.clubName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.sp),
                  Text(
                    'Hệ thống quản lý voucher SaboArena\nXác thực và sử dụng voucher khách hàng một cách nhanh chóng và an toàn',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Quick Actions
            Text(
              'Thao tác nhanh',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16.sp),

            // Action Cards
            _buildActionCard(
              icon: Icons.qr_code_scanner,
              title: 'Xác thực Voucher',
              subtitle: 'Nhập mã voucher để kiểm tra và sử dụng',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffVoucherVerificationScreen(
                      clubId: widget.clubId,
                      clubName: widget.clubName,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 12.sp),

            _buildActionCard(
              icon: Icons.dashboard,
              title: 'Dashboard Quản lý',
              subtitle: 'Xem tổng quan và lịch sử voucher',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffVoucherDashboardScreen(
                      clubId: widget.clubId,
                      clubName: widget.clubName,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 12.sp),

            _buildActionCard(
              icon: Icons.request_page,
              title: 'Yêu cầu Voucher',
              subtitle: 'Duyệt/từ chối yêu cầu sử dụng voucher của khách',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClubVoucherRequestsScreen(
                      clubId: widget.clubId,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 12.sp),

            _buildActionCard(
              icon: Icons.help_outline,
              title: 'Hướng dẫn sử dụng',
              subtitle: 'Xem chi tiết cách thao tác hệ thống',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffTutorialScreen(
                      clubId: widget.clubId,
                      clubName: widget.clubName,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 32.sp),

            // Quick Guide
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(width: 8.sp),
                      Text(
                        'Hướng dẫn nhanh',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.sp),
                  _buildGuideStep('1', 'Khách hàng đưa mã voucher'),
                  _buildGuideStep('2', 'Bấm "Xác thực Voucher"'),
                  _buildGuideStep('3', 'Nhập mã và kiểm tra thông tin'),
                  _buildGuideStep('4', 'Bấm "Sử dụng Voucher" để hoàn tất'),
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Safety Note
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: Colors.amber.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.amber.shade700,
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lưu ý bảo mật',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        SizedBox(height: 4.sp),
                        Text(
                          'Voucher chỉ sử dụng được 1 lần. Sau khi sử dụng sẽ bị xóa khỏi hệ thống và không thể hoàn tác.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.sp),
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.sp),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: Row(
        children: [
          Container(
            width: 24.sp,
            height: 24.sp,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}