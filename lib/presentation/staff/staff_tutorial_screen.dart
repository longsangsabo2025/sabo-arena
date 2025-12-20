import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import 'staff_voucher_verification_screen.dart';
import 'staff_voucher_dashboard_screen.dart';

/// Demo màn hình hướng dẫn sử dụng cho nhân viên
class StaffTutorialScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const StaffTutorialScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<StaffTutorialScreen> createState() => _StaffTutorialScreenState();
}

class _StaffTutorialScreenState extends State<StaffTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'title': '🏪 Chào mừng nhân viên!',
      'subtitle': 'Hướng dẫn sử dụng hệ thống voucher',
      'content': [
        '👋 Xin chào! Bạn đang sử dụng hệ thống quản lý voucher của SaboArena',
        '🎫 Hệ thống này giúp bạn xác thực và sử dụng voucher của khách hàng',
        '🔒 Chỉ voucher thuộc về quán này mới được chấp nhận',
        '✨ Giao diện được thiết kế đơn giản và dễ sử dụng',
      ],
      'icon': Icons.store,
      'color': Colors.blue,
    },
    {
      'title': '📱 Khách hàng đến quán',
      'subtitle': 'Khi khách hàng có voucher cần sử dụng',
      'content': [
        '👤 Khách hàng đến quán với mã voucher',
        '📱 Mã voucher hiển thị trên app của họ (VD: VOUCHER123456)',
        '🎁 Voucher có thể là: Tiền mặt, Giảm giá, Đồ uống miễn phí, v.v.',
        '⏰ Voucher có thể có hạn sử dụng',
      ],
      'icon': Icons.person,
      'color': Colors.green,
    },
    {
      'title': '🔍 Xác thực voucher',
      'subtitle': 'Bước 1: Kiểm tra tính hợp lệ',
      'content': [
        '1️⃣ Bấm nút "Xác thực Voucher" trên màn hình chính',
        '2️⃣ Nhập mã voucher khách hàng cung cấp',
        '3️⃣ Bấm "Kiểm tra" để xác thực',
        '✅ Nếu hợp lệ: Hiển thị thông tin chi tiết voucher',
        '❌ Nếu không hợp lệ: Hiển thị thông báo lỗi',
      ],
      'icon': Icons.qr_code_scanner,
      'color': Colors.orange,
    },
    {
      'title': '📋 Thông tin voucher',
      'subtitle': 'Những gì bạn sẽ thấy khi voucher hợp lệ',
      'content': [
        '🎁 Loại voucher: Tournament Prize, Cash, Discount...',
        '💰 Giá trị: Số tiền hoặc phần trăm giảm giá',
        '👤 Khách hàng: Tên và email của người sở hữu',
        '🏆 Nguồn gốc: Tournament nào tạo ra voucher',
        '📅 Ngày tạo và hạn sử dụng (nếu có)',
      ],
      'icon': Icons.info_outline,
      'color': Colors.purple,
    },
    {
      'title': '✅ Sử dụng voucher',
      'subtitle': 'Bước 2: Áp dụng voucher cho khách hàng',
      'content': [
        '🔍 Sau khi xác thực thành công, bấm "Sử dụng Voucher"',
        '⚠️ Hiện thông báo xác nhận với chi tiết voucher',
        '✔️ Bấm "Sử dụng voucher" để xác nhận',
        '🎉 Voucher được đánh dấu đã sử dụng',
        '🚫 Voucher không thể sử dụng lại lần nữa',
      ],
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'title': '📊 Dashboard quản lý',
      'subtitle': 'Theo dõi tổng quan voucher của quán',
      'content': [
        '📈 Xem thống kê: Tổng voucher, đã dùng, chưa dùng',
        '💰 Theo dõi giá trị: Tổng tiền, đã sử dụng, còn lại',
        '📋 Tab "Chưa sử dụng": Danh sách voucher pending',
        '✅ Tab "Đã sử dụng": Lịch sử voucher đã dùng',
        '🔄 Nút Refresh để cập nhật dữ liệu mới nhất',
      ],
      'icon': Icons.dashboard,
      'color': Colors.indigo,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hướng dẫn nhân viên',
        backgroundColor: AppTheme.primaryLight,
        actions: [
          TextButton(
            onPressed: _skipTutorial,
            child: const Text(
              'Bỏ qua',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(16.sp),
            child: Row(
              children: List.generate(
                _tutorialSteps.length,
                (index) => Expanded(
                  child: Container(
                    height: 4.sp,
                    margin: EdgeInsets.symmetric(horizontal: 2.sp),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? AppTheme.primaryLight
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.sp),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tutorial content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _tutorialSteps.length,
              itemBuilder: (context, index) {
                final step = _tutorialSteps[index];
                return _buildTutorialPage(step);
              },
            ),
          ),

          // Navigation buttons
          Container(
            padding: EdgeInsets.all(20.sp),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Trước'),
                    ),
                  ),
                if (_currentPage > 0) SizedBox(width: 16.sp),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPage == _tutorialSteps.length - 1
                        ? _completeTutorial
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                    ),
                    child: Text(
                      _currentPage == _tutorialSteps.length - 1
                          ? 'Bắt đầu sử dụng'
                          : 'Tiếp theo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialPage(Map<String, dynamic> step) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.sp),
      child: Column(
        children: [
          // Icon
          Container(
            width: 80.sp,
            height: 80.sp,
            decoration: BoxDecoration(
              color: step['color'].withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step['icon'],
              size: 40.sp,
              color: step['color'],
            ),
          ),

          SizedBox(height: 24.sp),

          // Title
          Text(
            step['title'],
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.sp),

          // Subtitle
          Text(
            step['subtitle'],
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 32.sp),

          // Content
          ...List.generate(
            step['content'].length,
            (index) => Container(
              margin: EdgeInsets.only(bottom: 16.sp),
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.sp),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6.sp,
                    height: 6.sp,
                    margin: EdgeInsets.only(top: 8.sp, right: 12.sp),
                    decoration: BoxDecoration(
                      color: step['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step['content'][index],
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Demo button for specific steps
          if (_currentPage == 2 || _currentPage == 5) ...[
            SizedBox(height: 24.sp),
            ElevatedButton.icon(
              onPressed: () => _openDemoScreen(_currentPage),
              icon: Icon(_currentPage == 2 ? Icons.qr_code : Icons.dashboard),
              label: Text(_currentPage == 2
                  ? 'Xem Demo Xác thực'
                  : 'Xem Demo Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: step['color'],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.sp,
                  vertical: 12.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _tutorialSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipTutorial() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StaffVoucherDashboardScreen(
          clubId: widget.clubId,
          clubName: widget.clubName,
        ),
      ),
    );
  }

  void _completeTutorial() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StaffVoucherDashboardScreen(
          clubId: widget.clubId,
          clubName: widget.clubName,
        ),
      ),
    );
  }

  void _openDemoScreen(int pageIndex) {
    if (pageIndex == 2) {
      // Demo verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StaffVoucherVerificationScreen(
            clubId: widget.clubId,
            clubName: widget.clubName,
          ),
        ),
      );
    } else if (pageIndex == 5) {
      // Demo dashboard screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StaffVoucherDashboardScreen(
            clubId: widget.clubId,
            clubName: widget.clubName,
          ),
        ),
      );
    }
  }
}
