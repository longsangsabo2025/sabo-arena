import 'package:flutter/material.dart';
import 'membership_plan_detail_screen.dart';

class MembershipPlansScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const MembershipPlansScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  int _selectedPlanIndex = 1; // Default to Premium

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // iOS Facebook background
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1E21),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Gói thành viên', overflow: TextOverflow.ellipsis, style: TextStyle(
            color: const Color(0xFF1C1E21),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn gói thành viên cho ${widget.clubName}', overflow: TextOverflow.ellipsis, style: const TextStyle(
                    color: Color(0xFF1C1E21),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mở khóa các tính năng độc quyền và nâng cao trải nghiệm của bạn', overflow: TextOverflow.ellipsis, style: TextStyle(
                    color: const Color(0xFF65676B),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Plans list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPlanCard(
                  index: 0,
                  title: 'Free',
                  subtitle: 'Miễn phí',
                  price: '0đ',
                  period: '/tháng',
                  color: const Color(0xFF42A5F5),
                  features: [
                    'Xem thông tin cơ bản câu lạc bộ',
                    'Tham gia chat nhóm công khai',
                    'Xem lịch thi đấu',
                    'Theo dõi kết quả trận đấu',
                  ],
                  isPopular: false,
                ),

                const SizedBox(height: 16),

                _buildPlanCard(
                  index: 1,
                  title: 'Premium',
                  subtitle: 'Phổ biến nhất',
                  price: '299.000đ',
                  period: '/tháng',
                  color: const Color(0xFF1877F2),
                  features: [
                    'Tất cả tính năng Free',
                    'Hỗ trợ 24/7 qua chat riêng',
                    'Tham gia nhóm chat riêng VIP',
                    'Đặt sân ưu tiên',
                    'Giảm giá 20% phí sân',
                    'Tham gia giải đấu nội bộ',
                    'Thống kê chi tiết cá nhân',
                  ],
                  isPopular: true,
                ),

                const SizedBox(height: 16),

                _buildPlanCard(
                  index: 2,
                  title: 'VIP',
                  subtitle: 'Cao cấp nhất',
                  price: '699.000đ',
                  period: '/tháng',
                  color: const Color(0xFFFF6B35),
                  features: [
                    'Tất cả tính năng Premium',
                    'Huấn luyện viên cá nhân',
                    'Phân tích video chuyên nghiệp',
                    'Tham gia mọi giải đấu',
                    'Miễn phí 50% phí sân',
                    'Quyền ưu tiên đặt sân',
                    'Trang thiết bị cao cấp',
                    'Sự kiện độc quyền',
                  ],
                  isPopular: false,
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _handleSelectPlan(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  _getSelectedPlanButtonText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Có thể hủy bất cứ lúc nào', overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xFF65676B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String subtitle,
    required String price,
    required String period,
    required Color color,
    required List<String> features,
    required bool isPopular,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE4E6EA),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with popular badge
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title, style: TextStyle(
                                color: color,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isPopular) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  subtitle, style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle, style: const TextStyle(
                                  color: Color(0xFF65676B),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                price, style: TextStyle(
                                  color: const Color(0xFF1C1E21),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                period, style: const TextStyle(
                                  color: Color(0xFF65676B),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (index == 1) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Tiết kiệm 30% so với gói cơ bản', overflow: TextOverflow.ellipsis, style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features list
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tính năng:', overflow: TextOverflow.ellipsis, style: const TextStyle(
                      color: Color(0xFF1C1E21),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...features
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature, style: const TextStyle(
                                    color: Color(0xFF1C1E21),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      ,
                ],
              ),
            ),

            // View details button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _viewPlanDetails(index),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Xem chi tiết', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSelectedPlanButtonText() {
    switch (_selectedPlanIndex) {
      case 0:
        return 'Tiếp tục với gói Free';
      case 1:
        return 'Đăng ký gói Premium';
      case 2:
        return 'Đăng ký gói VIP';
      default:
        return 'Đăng ký ngay';
    }
  }

  void _viewPlanDetails(int planIndex) {
    final planNames = ['free', 'premium', 'vip'];
    final selectedPlan = planNames[planIndex];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MembershipPlanDetailScreen(
          clubId: widget.clubId,
          clubName: widget.clubName,
          planType: selectedPlan,
        ),
      ),
    );
  }

  void _handleSelectPlan() {
    final planNames = ['free', 'premium', 'vip'];
    final selectedPlan = planNames[_selectedPlanIndex];

    // TODO: Navigate to payment or confirmation screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bạn đã chọn gói ${planNames[_selectedPlanIndex].toUpperCase()}',
        ),
        backgroundColor: const Color(0xFF1877F2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Return selected plan to previous screen
    Navigator.pop(context, selectedPlan);
  }
}
