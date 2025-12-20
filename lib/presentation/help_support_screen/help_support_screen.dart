import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/common/app_button.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<int> _expandedFaqIndices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Trợ giúp & Hỗ trợ'),
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFAQTab(),
                _buildContactTab(),
                _buildGuideTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.question_answer), text: 'FAQ'),
          Tab(icon: Icon(Icons.contact_support), text: 'Liên hệ'),
          Tab(icon: Icon(Icons.menu_book), text: 'Hướng dẫn'),
        ],
      ),
    );
  }

  // ==================== FAQ TAB ====================
  Widget _buildFAQTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFAQSection(
          title: '🏟️ Câu hỏi chung',
          faqs: [
            {
              'q': 'SaboArena là gì?',
              'a':
                  'SaboArena là nền tảng quản lý và tổ chức giải đấu bi-a trực tuyến, kết nối người chơi, câu lạc bộ và giải đấu.'
            },
            {
              'q': 'Làm sao để tạo tài khoản?',
              'a':
                  'Nhấn "Đăng ký" trên màn hình đăng nhập, điền thông tin email và mật khẩu, sau đó xác nhận email của bạn.'
            },
            {
              'q': 'Tôi quên mật khẩu, làm sao để lấy lại?',
              'a':
                  'Nhấn "Quên mật khẩu" trên màn hình đăng nhập, nhập email đã đăng ký và làm theo hướng dẫn trong email.'
            },
          ],
        ),
        const SizedBox(height: 16),
        _buildFAQSection(
          title: '🎮 Về giải đấu',
          faqs: [
            {
              'q': 'Làm sao để tham gia giải đấu?',
              'a':
                  'Vào tab "Giải đấu", chọn giải bạn muốn tham gia, nhấn "Đăng ký" và thanh toán phí (nếu có).'
            },
            {
              'q': 'Có thể hủy đăng ký giải đấu không?',
              'a':
                  'Có, bạn có thể hủy trước thời gian đóng đăng ký. Phí sẽ được hoàn lại theo chính sách của giải đấu.'
            },
            {
              'q': 'Làm sao để xem lịch thi đấu?',
              'a':
                  'Sau khi đăng ký, vào "Giải đấu của tôi" và chọn giải đang tham gia để xem lịch thi đấu chi tiết.'
            },
            {
              'q': 'Làm sao để cập nhật kết quả trận đấu?',
              'a':
                  'Nếu bạn là người chơi hoặc trọng tài, vào trận đấu và nhấn "Cập nhật kết quả", nhập điểm số và xác nhận.'
            },
          ],
        ),
        const SizedBox(height: 16),
        _buildFAQSection(
          title: '💰 Thanh toán & Voucher',
          faqs: [
            {
              'q': 'Có những hình thức thanh toán nào?',
              'a':
                  'Hỗ trợ thanh toán qua ví SPA (nạp từ ngân hàng), thẻ tín dụng, hoặc thanh toán trực tiếp tại CLB.'
            },
            {
              'q': 'Voucher là gì và dùng như thế nào?',
              'a':
                  'Voucher là mã giảm giá cho phí giải đấu hoặc dịch vụ. Nhập mã voucher khi thanh toán để được giảm giá.'
            },
            {
              'q': 'Làm sao để nạp tiền vào ví SPA?',
              'a':
                  'Vào "Ví của tôi" trong profile, chọn "Nạp tiền", nhập số tiền và chọn phương thức thanh toán.'
            },
          ],
        ),
        const SizedBox(height: 16),
        _buildFAQSection(
          title: '🏆 Xếp hạng & ELO',
          faqs: [
            {
              'q': 'Hệ thống ELO hoạt động như thế nào?',
              'a':
                  'ELO là điểm xếp hạng dựa trên kết quả thi đấu. Thắng sẽ tăng điểm, thua sẽ giảm điểm. Đối thủ mạnh hơn = thay đổi điểm lớn hơn.'
            },
            {
              'q': 'Làm sao để nâng hạng?',
              'a':
                  'Tham gia và chiến thắng nhiều trận đấu để tăng điểm ELO. Đạt ngưỡng điểm sẽ tự động lên hạng.'
            },
            {
              'q': 'Bảng xếp hạng được cập nhật khi nào?',
              'a': 'Bảng xếp hạng được cập nhật realtime sau mỗi trận đấu.'
            },
          ],
        ),
        const SizedBox(height: 16),
        _buildFAQSection(
          title: '👥 Câu lạc bộ',
          faqs: [
            {
              'q': 'Làm sao để tạo câu lạc bộ?',
              'a':
                  'Vào "Câu lạc bộ", nhấn nút "+" ở góc phải, điền thông tin CLB và chọn "Tạo".'
            },
            {
              'q': 'Ai có thể tham gia câu lạc bộ của tôi?',
              'a':
                  'Tùy vào cài đặt của CLB: có thể công khai (ai cũng tham gia), yêu cầu phê duyệt, hoặc chỉ theo mời.'
            },
            {
              'q': 'Làm sao để quản lý thành viên CLB?',
              'a':
                  'Vào CLB của bạn, tab "Thành viên", chọn thành viên để xem chi tiết, phê duyệt hoặc xóa.'
            },
          ],
        ),
      ],
    );
  }

  Widget _buildFAQSection({
    required String title,
    required List<Map<String, String>> faqs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ),
        ...faqs.asMap().entries.map((entry) {
          final faq = entry.value;
          final globalIndex = faqs.indexOf(faq);
          final isExpanded = _expandedFaqIndices.contains(globalIndex);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpanded
                    ? AppTheme.primaryLight
                    : Colors.grey.withValues(alpha: 0.2),
              ),
              boxShadow: [
                if (isExpanded)
                  BoxShadow(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedFaqIndices.remove(globalIndex);
                    } else {
                      _expandedFaqIndices.add(globalIndex);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.remove_circle_outline
                                : Icons.add_circle_outline,
                            color: AppTheme.primaryLight,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              faq['q']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isExpanded
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: AppTheme.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            faq['a']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==================== CONTACT TAB ====================
  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildContactCard(
          icon: Icons.email,
          title: 'Email hỗ trợ',
          subtitle: 'support@saboarena.com',
          color: Colors.blue,
          onTap: () => _launchEmail(),
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          icon: Icons.phone,
          title: 'Hotline',
          subtitle: '1900 xxxx',
          color: Colors.green,
          onTap: () => _launchPhone('1900xxxx'),
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          icon: Icons.facebook,
          title: 'Facebook',
          subtitle: 'fb.com/saboarena',
          color: Colors.blue[800]!,
          onTap: () => _launchUrl('https://facebook.com/saboarena'),
        ),
        const SizedBox(height: 16),
        _buildContactCard(
          icon: Icons.public,
          title: 'Website',
          subtitle: 'www.saboarena.com',
          color: Colors.purple,
          onTap: () => _launchUrl('https://www.saboarena.com'),
        ),
        const SizedBox(height: 32),
        _buildContactForm(),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📧 Gửi tin nhắn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Họ tên',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: messageController,
            decoration: InputDecoration(
              labelText: 'Nội dung',
              prefixIcon: const Icon(Icons.message_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButton(
              label: 'Gửi tin nhắn',
              type: AppButtonType.primary,
              size: AppButtonSize.large,
              icon: Icons.send,
              iconTrailing: false,
              fullWidth: true,
              onPressed: () {
                _sendContactMessage(
                  nameController.text,
                  emailController.text,
                  messageController.text,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== GUIDE TAB ====================
  Widget _buildGuideTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGuideCard(
          icon: Icons.how_to_reg,
          title: 'Hướng dẫn đăng ký & Đăng nhập',
          description: 'Cách tạo tài khoản và đăng nhập vào SaboArena',
          steps: [
            'Mở app và chọn "Đăng ký"',
            'Nhập email và mật khẩu (tối thiểu 6 ký tự)',
            'Xác nhận email qua link được gửi',
            'Đăng nhập với tài khoản đã tạo',
          ],
        ),
        const SizedBox(height: 16),
        _buildGuideCard(
          icon: Icons.emoji_events,
          title: 'Hướng dẫn tham gia giải đấu',
          description: 'Các bước để tham gia giải đấu bi-a',
          steps: [
            'Vào tab "Giải đấu" trên thanh điều hướng',
            'Chọn giải đấu bạn muốn tham gia',
            'Đọc kỹ thể lệ và thông tin giải',
            'Nhấn "Đăng ký" và thanh toán (nếu có)',
            'Chờ xác nhận và xem lịch thi đấu',
          ],
        ),
        const SizedBox(height: 16),
        _buildGuideCard(
          icon: Icons.sports_baseball,
          title: 'Hướng dẫn cập nhật kết quả',
          description: 'Cách nhập và xác nhận kết quả trận đấu',
          steps: [
            'Vào "Giải đấu của tôi" → Chọn giải đang tham gia',
            'Nhấn vào trận đấu của bạn',
            'Chọn "Cập nhật kết quả"',
            'Nhập điểm số cho mỗi người chơi',
            'Xác nhận kết quả (cần cả 2 người chơi đồng ý)',
          ],
        ),
        const SizedBox(height: 16),
        _buildGuideCard(
          icon: Icons.account_balance_wallet,
          title: 'Hướng dẫn nạp tiền & Thanh toán',
          description: 'Cách nạp tiền vào ví SPA và thanh toán',
          steps: [
            'Vào "Profile" → "Ví của tôi"',
            'Chọn "Nạp tiền"',
            'Nhập số tiền muốn nạp',
            'Chọn phương thức: Chuyển khoản/Thẻ/Momo',
            'Hoàn tất thanh toán theo hướng dẫn',
            'Tiền sẽ được cộng vào ví sau 1-5 phút',
          ],
        ),
        const SizedBox(height: 16),
        _buildGuideCard(
          icon: Icons.stars,
          title: 'Hướng dẫn sử dụng Voucher',
          description: 'Cách sử dụng mã giảm giá và voucher',
          steps: [
            'Lấy mã voucher từ sự kiện hoặc chương trình khuyến mãi',
            'Khi thanh toán, chọn "Áp dụng voucher"',
            'Nhập mã voucher và nhấn "Kiểm tra"',
            'Nếu hợp lệ, giảm giá sẽ được áp dụng tự động',
            'Hoàn tất thanh toán với giá sau giảm',
          ],
        ),
      ],
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryLight, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@saboarena.com',
      query: 'subject=Hỗ trợ SaboArena&body=Xin chào,\n\n',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showError('Không thể mở email');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showError('Không thể gọi điện');
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Không thể mở liên kết');
    }
  }

  void _sendContactMessage(String name, String email, String message) {
    if (name.isEmpty || email.isEmpty || message.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin');
      return;
    }

    // TODO: Gửi tin nhắn qua API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi tin nhắn! Chúng tôi sẽ phản hồi sớm nhất.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
