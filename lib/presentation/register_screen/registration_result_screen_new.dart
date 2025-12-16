import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';

class RegistrationResultScreen extends StatefulWidget {
  final bool isSuccess;
  final String? userId;
  final String? email;
  final String? errorMessage;
  final String? userRole;
  final bool needsEmailVerification;

  const RegistrationResultScreen({
    super.key,
    required this.isSuccess,
    this.userId,
    this.email,
    this.errorMessage,
    this.userRole,
    this.needsEmailVerification = false,
  });

  @override
  State<RegistrationResultScreen> createState() =>
      _RegistrationResultScreenState();
}

class _RegistrationResultScreenState extends State<RegistrationResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation with bounce effect
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Slide animation for content
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Facebook background gray
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 🎯 Main Result Card với Facebook 2025 Design
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),

                          // 🎨 Animated Icon với Facebook style
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.isSuccess
                                        ? const Color(
                                            0xFF42B883,
                                          ) // Facebook green
                                        : const Color(0xFFE74C3C),
                                  ),
                                  child: Icon(
                                    widget.isSuccess
                                        ? Icons.check_rounded
                                        : Icons.close_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // 📝 Title với Facebook typography
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              widget.isSuccess
                                  ? 'Đăng ký thành công! 🎉'
                                  : 'Đăng ký thất bại',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C1E21), // Facebook dark text
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 💬 Subtitle message
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              widget.isSuccess
                                  ? _getSuccessMessage()
                                  : (widget.errorMessage ??
                                        'Có lỗi xảy ra trong quá trình đăng ký. Vui lòng thử lại.'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(
                                  0xFF65676B,
                                ), // Facebook secondary text
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // 📧 Email Verification Card (Facebook style)
                if (widget.isSuccess &&
                    widget.needsEmailVerification &&
                    widget.email != null) ...[
                  const SizedBox(height: 8),

                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header với icon
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1877F2,
                                      ).withValues(alpha: 0.1), // Facebook blue
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF1877F2),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Xác nhận email',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1C1E21),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Chúng tôi đã gửi link xác nhận đến ${widget.email}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF65676B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Instructions box với Facebook style
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '📧 Hướng dẫn xác nhận:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1C1E21),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '1. Kiểm tra hộp thư đến của bạn\n'
                                      '2. Tìm email từ SABO Arena\n'
                                      '3. Click vào link xác nhận\n'
                                      '4. Quay lại app để đăng nhập',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF65676B),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3CD),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '💡 Không thấy email? Kiểm tra thư mục spam',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF856404),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // 👤 Account Info Card (nếu thành công)
                if (widget.isSuccess) ...[
                  const SizedBox(height: 8),

                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF42B883,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF42B883),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Thông tin tài khoản',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1C1E21),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              if (widget.email != null)
                                _buildInfoRow(
                                  Icons.email_outlined,
                                  widget.email!,
                                ),

                              if (widget.userId != null)
                                _buildInfoRow(
                                  Icons.fingerprint_outlined,
                                  'ID: ${widget.userId!.substring(0, 8)}...',
                                ),

                              _buildInfoRow(
                                Icons.sports_esports_outlined,
                                widget.userRole ?? 'Player',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 🎯 Action Button với Facebook style
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isSuccess
                              ? const Color(0xFF1877F2) // Facebook blue
                              : const Color(0xFF42B883),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // Facebook style radius
                          ),
                        ),
                        child: Text(
                          widget.isSuccess
                              ? (widget.needsEmailVerification
                                    ? 'Tôi đã hiểu'
                                    : 'Tiếp tục')
                              : 'Thử lại',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔧 Helper method để build info row
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF65676B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF65676B)),
            ),
          ),
        ],
      ),
    );
  }

  // 💬 Success message helper
  String _getSuccessMessage() {
    if (widget.needsEmailVerification) {
      return 'Tài khoản của bạn đã được tạo thành công! Vui lòng kiểm tra email để xác nhận tài khoản trước khi đăng nhập.';
    }
    return 'Tài khoản của bạn đã được tạo thành công! Bạn có thể bắt đầu sử dụng SABO Arena ngay bây giờ.';
  }

  // 🎯 Handle continue action
  void _handleContinue() {
    if (widget.isSuccess) {
      if (widget.needsEmailVerification) {
        // Về trang login để user có thể đăng nhập sau khi verify email
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.loginScreen, (route) => false);
      } else {
        // 🚀 PHASE 1: Navigate to main screen with persistent tabs
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.mainScreen, (route) => false);
      }
    } else {
      // Back to registration on failure
      Navigator.of(context).pop();
    }
  }
}
