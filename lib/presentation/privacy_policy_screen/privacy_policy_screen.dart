import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1C1C1E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chính sách bảo mật', overflow: TextOverflow.ellipsis, style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: SizedBox(
                height: 60,
                width: 60,
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Header
            const Center(
              child: Text(
                'CHÍNH SÁCH BẢO MẬT SABO ARENA', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            const Center(
              child: Text(
                'Có hiệu lực từ ngày 17 tháng 10 năm 2025', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
              ),
            ),

            const SizedBox(height: 32),

            // Content sections
            _buildSection(
              '1. CAM KẾT BẢO MẬT',
              'SABO Arena cam kết bảo vệ quyền riêng tư và thông tin cá nhân của bạn. Chính sách này mô tả cách chúng tôi thu thập, sử dụng, lưu trữ và bảo vệ thông tin của bạn khi sử dụng ứng dụng và dịch vụ của chúng tôi.',
            ),

            _buildSection(
              '2. THÔNG TIN CHÚNG TÔI THU THẬP',
              'Chúng tôi thu thập các loại thông tin sau:\n\n• Thông tin đăng ký: Họ tên, email, số điện thoại, mật khẩu\n• Thông tin hồ sơ: Ảnh đại diện, trình độ chơi, sở thích\n• Thông tin vị trí: Để tìm sân và đối thủ gần bạn\n• Dữ liệu sử dụng: Cách bạn tương tác với ứng dụng\n• Thông tin thiết bị: Loại thiết bị, hệ điều hành, ID thiết bị\n• Thông tin thanh toán: Chi tiết giao dịch (không lưu thông tin thẻ)',
            ),

            _buildSection(
              '3. CÁCH CHÚNG TÔI SỬ DỤNG THÔNG TIN',
              'Thông tin của bạn được sử dụng để:\n\n• Cung cấp và cải thiện dịch vụ SABO Arena\n• Kết nối bạn với người chơi và câu lạc bộ phù hợp\n• Xử lý thanh toán và giao dịch\n• Gửi thông báo về giải đấu, sự kiện\n• Hỗ trợ khách hàng và giải đáp thắc mắc\n• Phân tích và cải thiện trải nghiệm người dùng\n• Tuân thủ yêu cầu pháp lý',
            ),

            _buildSection(
              '4. CHIA SẺ THÔNG TIN',
              'Chúng tôi không bán thông tin cá nhân của bạn. Thông tin chỉ được chia sẻ trong các trường hợp:\n\n• Với sự đồng ý của bạn\n• Với đối tác dịch vụ đáng tin cậy (cloud hosting, thanh toán)\n• Khi có yêu cầu pháp lý từ cơ quan có thẩm quyền\n• Để bảo vệ quyền lợi và an toàn của người dùng\n• Trong trường hợp sáp nhập hoặc chuyển nhượng doanh nghiệp',
            ),

            _buildSection(
              '5. BẢO MẬT THÔNG TIN',
              'Chúng tôi áp dụng các biện pháp bảo mật:\n\n• Mã hóa dữ liệu SSL/TLS\n• Hệ thống xác thực đa lớp\n• Firewall và giám sát bảo mật 24/7\n• Sao lưu dữ liệu thường xuyên\n• Đào tạo nhân viên về bảo mật thông tin\n• Kiểm tra bảo mật định kỳ\n• Tuân thủ các tiêu chuẩn bảo mật quốc tế',
            ),

            _buildSection(
              '6. QUYỀN CỦA NGƯỜI DÙNG',
              'Bạn có quyền:\n\n• Truy cập và xem thông tin cá nhân\n• Chỉnh sửa hoặc cập nhật thông tin\n• Xóa tài khoản và dữ liệu cá nhân\n• Rút lại sự đồng ý xử lý dữ liệu\n• Yêu cầu sao chép dữ liệu cá nhân\n• Khiếu nại về việc xử lý dữ liệu\n• Từ chối nhận email marketing',
            ),

            _buildSection(
              '7. COOKIE VÀ CÔNG NGHỆ THEO DÕI',
              'SABO Arena sử dụng:\n\n• Cookie để ghi nhớ đăng nhập và tùy chọn\n• Analytics để hiểu cách sử dụng ứng dụng\n• Push notification để gửi thông báo quan trọng\n• Location services để tìm sân gần bạn\n\nBạn có thể tắt các tính năng này trong cài đặt thiết bị.',
            ),

            _buildSection(
              '8. THÔNG TIN TRẺ EM',
              'SABO Arena không dành cho trẻ em dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin từ trẻ em. Nếu phát hiện, chúng tôi sẽ xóa ngay lập tức và thông báo cho phụ huynh.',
            ),

            _buildSection(
              '9. CHUYỂN GIAO DỮ LIỆU QUỐC TẾ',
              'Dữ liệu của bạn có thể được xử lý tại:\n\n• Việt Nam (máy chủ chính)\n• Singapore (sao lưu dữ liệu)\n• Các quốc gia khác có đối tác dịch vụ\n\nChúng tôi đảm bảo mức độ bảo mật tương đương ở tất cả các địa điểm.',
            ),

            _buildSection(
              '10. LƯU TRỮ DỮ LIỆU',
              'Chúng tôi lưu trữ thông tin của bạn:\n\n• Trong thời gian tài khoản còn hoạt động\n• 30 ngày sau khi xóa tài khoản (để khôi phục nếu cần)\n• Theo yêu cầu pháp lý (tối đa 7 năm)\n• Dữ liệu thống kê được ẩn danh có thể lưu lâu hơn',
            ),

            _buildSection(
              '11. CẬP NHẬT CHÍNH SÁCH',
              'Chúng tôi có thể cập nhật chính sách này và sẽ thông báo qua:\n\n• Thông báo trong ứng dụng\n• Email đến địa chỉ đăng ký\n• Đăng tải trên website\n\nCác thay đổi quan trọng sẽ được thông báo trước 30 ngày.',
            ),

            _buildSection(
              '12. LIÊN HỆ VỀ QUYỀN RIÊNG TƯ',
              'Nếu có thắc mắc về chính sách bảo mật:\n\n📧 Email: privacy@saboarena.com\n📱 Hotline: 1900 xxxx\n🏢 Địa chỉ: [Địa chỉ công ty]\n🌐 Website: www.saboarena.com\n\nChúng tôi sẽ phản hồi trong vòng 72 giờ.',
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '🔒 Cam kết bảo mật', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SABO Arena tuân thủ Luật An toàn thông tin mạng Việt Nam và các tiêu chuẩn bảo mật quốc tế. Thông tin của bạn được bảo vệ bằng công nghệ mã hóa tiên tiến.', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content, style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1C1C1E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
