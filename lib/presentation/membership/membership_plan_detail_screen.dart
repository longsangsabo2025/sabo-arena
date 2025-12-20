import 'package:flutter/material.dart';
import '../../widgets/dialogs/member_registration_dialog_ios.dart';

class MembershipPlanDetailScreen extends StatelessWidget {
  final String clubId;
  final String clubName;
  final String planType;

  const MembershipPlanDetailScreen({
    super.key,
    required this.clubId,
    required this.clubName,
    required this.planType,
  });

  @override
  Widget build(BuildContext context) {
    final planData = _getPlanData(planType);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1E21),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Gói ${planData['title']}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1C1E21),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          planData['color'],
                          planData['color'].withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(planData['icon'], size: 48, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          'Gói ${planData['title']}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          planData['description'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                planData['price'],
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                planData['period'],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Features section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
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
                        Text(
                          'Tính năng của gói ${planData['title']}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1C1E21),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...planData['features']
                            .map<Widget>(
                              (feature) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: (planData['color'] as Color)
                                            .withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        feature['available']
                                            ? Icons.check
                                            : Icons.close,
                                        size: 16,
                                        color: feature['available']
                                            ? planData['color']
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            feature['title'],
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: feature['available']
                                                  ? const Color(0xFF1C1E21)
                                                  : Colors.grey,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (feature['description'] !=
                                              null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              feature['description'],
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: feature['available']
                                                    ? const Color(0xFF65676B)
                                                    : Colors.grey,
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
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
                onPressed:
                    planType == 'free' ? null : () => _handleSubscribe(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: planData['color'],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  planType == 'free'
                      ? 'Gói hiện tại'
                      : 'Đăng ký gói ${planData['title']}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (planType != 'free') ...[
              const SizedBox(height: 12),
              Text(
                'Có thể hủy bất cứ lúc nào • Không có phí ẩn',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: const Color(0xFF65676B), fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPlanData(String type) {
    switch (type) {
      case 'free':
        return {
          'title': 'Free',
          'description': 'Trải nghiệm cơ bản với các tính năng thiết yếu',
          'price': 'Miễn phí',
          'period': '',
          'color': const Color(0xFF42A5F5),
          'icon': Icons.sports_tennis,
          'features': [
            {
              'title': 'Xem thông tin câu lạc bộ',
              'description': 'Truy cập thông tin cơ bản, lịch thi đấu',
              'available': true,
            },
            {
              'title': 'Chat nhóm công khai',
              'description': 'Tham gia thảo luận trong nhóm chung',
              'available': true,
            },
            {
              'title': 'Xem kết quả trận đấu',
              'description': 'Theo dõi điểm số và thống kê cơ bản',
              'available': true,
            },
            {
              'title': 'Hỗ trợ 24/7',
              'description': 'Hỗ trợ chuyên nghiệp qua chat riêng',
              'available': false,
            },
            {
              'title': 'Đặt sân ưu tiên',
              'description': 'Đặt sân trước người dùng thường',
              'available': false,
            },
            {
              'title': 'Giảm giá sân tennis',
              'description': 'Tiết kiệm chi phí khi thuê sân',
              'available': false,
            },
          ],
        };
      case 'premium':
        return {
          'title': 'Premium',
          'description': 'Nâng cao trải nghiệm với các tính năng độc quyền',
          'price': '299.000đ',
          'period': '/tháng',
          'color': const Color(0xFF1877F2),
          'icon': Icons.star,
          'features': [
            {
              'title': 'Tất cả tính năng Free',
              'description': 'Bao gồm tất cả tính năng của gói miễn phí',
              'available': true,
            },
            {
              'title': 'Hỗ trợ 24/7',
              'description': 'Hỗ trợ chuyên nghiệp qua chat riêng',
              'available': true,
            },
            {
              'title': 'Chat nhóm VIP',
              'description': 'Tham gia nhóm chat riêng cho thành viên Premium',
              'available': true,
            },
            {
              'title': 'Đặt sân ưu tiên',
              'description': 'Đặt sân trước người dùng thường',
              'available': true,
            },
            {
              'title': 'Giảm giá 20% phí sân',
              'description': 'Tiết kiệm 20% chi phí khi thuê sân tennis',
              'available': true,
            },
            {
              'title': 'Giải đấu nội bộ',
              'description': 'Tham gia các giải đấu độc quyền',
              'available': true,
            },
            {
              'title': 'Thống kê chi tiết',
              'description': 'Phân tích hiệu suất và tiến bộ cá nhân',
              'available': true,
            },
            {
              'title': 'Huấn luyện viên cá nhân',
              'description': 'Được phân công huấn luyện viên riêng',
              'available': false,
            },
          ],
        };
      case 'vip':
        return {
          'title': 'VIP',
          'description': 'Trải nghiệm cao cấp nhất với mọi đặc quyền',
          'price': '699.000đ',
          'period': '/tháng',
          'color': const Color(0xFFFF6B35),
          'icon': Icons.diamond,
          'features': [
            {
              'title': 'Tất cả tính năng Premium',
              'description': 'Bao gồm tất cả tính năng của gói Premium',
              'available': true,
            },
            {
              'title': 'Huấn luyện viên cá nhân',
              'description': 'Được phân công huấn luyện viên chuyên nghiệp',
              'available': true,
            },
            {
              'title': 'Phân tích video chuyên nghiệp',
              'description': 'Phân tích kỹ thuật qua video AI',
              'available': true,
            },
            {
              'title': 'Tham gia mọi giải đấu',
              'description': 'Không giới hạn số lượng giải đấu',
              'available': true,
            },
            {
              'title': 'Miễn phí 50% phí sân',
              'description': 'Tiết kiệm 50% chi phí thuê sân tennis',
              'available': true,
            },
            {
              'title': 'Ưu tiên tuyệt đối',
              'description': 'Ưu tiên cao nhất trong mọi dịch vụ',
              'available': true,
            },
            {
              'title': 'Thiết bị cao cấp',
              'description': 'Miễn phí sử dụng vợt và phụ kiện premium',
              'available': true,
            },
            {
              'title': 'Sự kiện độc quyền',
              'description': 'Tham gia các sự kiện chỉ dành cho VIP',
              'available': true,
            },
          ],
        };
      default:
        return _getPlanData('premium');
    }
  }

  void _handleSubscribe(BuildContext context) {
    // Show registration dialog with selected plan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MemberRegistrationDialog(
        clubId: clubId,
        clubName: clubName,
        membershipType: planType,
        onMemberRegistered: () {
          // Close this screen and show success
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng ký gói $planType thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      ),
    );
  }
}
