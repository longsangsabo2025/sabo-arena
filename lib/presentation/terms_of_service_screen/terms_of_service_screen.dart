import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Điều khoản sử dụng', overflow: TextOverflow.ellipsis, style: TextStyle(
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
                'ĐIỀU KHOẢN SỬ DỤNG SABO ARENA', overflow: TextOverflow.ellipsis, style: TextStyle(
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
              '1. CHẤP NHẬN ĐIỀU KHOẢN',
              'Bằng việc sử dụng ứng dụng SABO Arena, bạn đồng ý tuân thủ và bị ràng buộc bởi các điều khoản và điều kiện sử dụng này. Nếu bạn không đồng ý với bất kỳ phần nào của các điều khoản này, vui lòng không sử dụng dịch vụ của chúng tôi.',
            ),

            _buildSection(
              '2. MÔ TẢ DỊCH VỤ',
              'SABO Arena là nền tảng kết nối cộng đồng người chơi pickleball tại Việt Nam, cung cấp các tính năng:\n\n• Tìm kiếm đối thủ và đồng đội\n• Tham gia các giải đấu và sự kiện\n• Quản lý câu lạc bộ\n• Theo dõi bảng xếp hạng\n• Tin nhắn và kết nối cộng đồng',
            ),

            _buildSection(
              '3. TÀI KHOẢN NGƯỜI DÙNG',
              'Để sử dụng các tính năng của SABO Arena, bạn cần:\n\n• Tạo tài khoản với thông tin chính xác và đầy đủ\n• Bảo mật thông tin đăng nhập của bạn\n• Chịu trách nhiệm về mọi hoạt động diễn ra dưới tài khoản của bạn\n• Thông báo ngay cho chúng tôi nếu phát hiện việc sử dụng trái phép tài khoản',
            ),

            _buildSection(
              '4. QUY TẮC ỨNG XỬ',
              'Khi sử dụng SABO Arena, bạn cam kết:\n\n• Không sử dụng ngôn từ thô tục, xúc phạm hoặc phân biệt đối xử\n• Không spam, quảng cáo hoặc gửi nội dung không liên quan\n• Tôn trọng các thành viên khác trong cộng đồng\n• Tuân thủ luật pháp Việt Nam và quy định của nền tảng\n• Không giả mạo danh tính hoặc cung cấp thông tin sai lệch',
            ),

            _buildSection(
              '5. NỘI DUNG NGƯỜI DÙNG',
              'Khi đăng tải nội dung lên SABO Arena:\n\n• Bạn giữ quyền sở hữu nội dung của mình\n• Bạn cấp cho chúng tôi quyền sử dụng, hiển thị và phân phối nội dung đó\n• Nội dung phải tuân thủ quy tắc ứng xử và pháp luật\n• Chúng tôi có quyền xóa nội dung vi phạm mà không cần thông báo trước',
            ),

            _buildSection(
              '6. THANH TOÁN VÀ HOÀN TIỀN',
              'Đối với các dịch vụ trả phí:\n\n• Giá cả được hiển thị rõ ràng trước khi thanh toán\n• Thanh toán qua các cổng thanh toán an toàn\n• Hoàn tiền theo chính sách cụ thể của từng dịch vụ\n• Liên hệ hỗ trợ khách hàng để được giải quyết tranh chấp',
            ),

            _buildSection(
              '7. GIỚI HẠN TRÁCH NHIỆM',
              'SABO Arena cung cấp dịch vụ "như hiện có" và:\n\n• Không đảm bảo dịch vụ hoạt động liên tục, không lỗi\n• Không chịu trách nhiệm về thiệt hại gián tiếp hoặc ngẫu nhiên\n• Giới hạn trách nhiệm trong phạm vi cho phép của pháp luật\n• Khuyến khích người dùng sao lưu dữ liệu quan trọng',
            ),

            _buildSection(
              '8. QUYỀN SỞ HỮU TRÍ TUỆ',
              'Tất cả nội dung, thiết kế, logo, và tính năng của SABO Arena đều thuộc sở hữu của chúng tôi và được bảo vệ bởi luật sở hữu trí tuệ. Bạn không được sao chép, sửa đổi hoặc phân phối mà không có sự cho phép.',
            ),

            _buildSection(
              '9. CHẤM DỨT DỊCH VỤ',
              'Chúng tôi có quyền:\n\n• Tạm ngưng hoặc chấm dứt tài khoản vi phạm điều khoản\n• Thông báo trước khi ngừng cung cấp dịch vụ\n• Xóa dữ liệu sau thời gian quy định\n• Bạn có thể xóa tài khoản bất cứ lúc nào trong cài đặt',
            ),

            _buildSection(
              '10. THAY ĐỔI ĐIỀU KHOẢN',
              'Chúng tôi có thể cập nhật điều khoản này và sẽ thông báo qua:\n\n• Ứng dụng SABO Arena\n• Email đăng ký\n• Website chính thức\n\nViệc tiếp tục sử dụng sau khi thay đổi đồng nghĩa với việc chấp nhận điều khoản mới.',
            ),

            _buildSection(
              '11. LIÊN HỆ',
              'Nếu có thắc mắc về điều khoản sử dụng, vui lòng liên hệ:\n\n📧 Email: support@saboarena.com\n📱 Hotline: 1900 xxxx\n🏢 Địa chỉ: [Địa chỉ công ty]\n🌐 Website: www.saboarena.com',
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Bằng việc sử dụng SABO Arena, bạn xác nhận đã đọc, hiểu và đồng ý với tất cả các điều khoản trên.', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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
