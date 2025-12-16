import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/auth_navigation_controller.dart';
// ELON_MODE_AUTO_FIX

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
  bool _isResending = false;

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

    // ❌ REMOVED: CLB dialog moved to EmailVerificationScreen (after email verification)
    // Dialog will show AFTER user verifies email and auto-logs in
  }

  @override
  void dispose() {
    _controller.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /* ❌ MOVED TO EmailVerificationScreen
  // 🎯 Show CLB Registration Dialog for Club Owners - MOVED!
  // This dialog now shows AFTER email verification in EmailVerificationScreen
  // Keeping code here for reference only
  Future<void> _showClubRegistrationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Đăng ký CLB của bạn', overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Description
                const Text(
                  'Bạn đã đăng ký thành công với vai trò Chủ CLB.\n\nBạn có muốn tiếp tục đăng ký thông tin CLB ngay bây giờ?', overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 28),
                
                // Action Buttons
                Row(
                  children: [
                    // "Để sau" button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          'Để sau', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // "Đăng ký ngay" button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Đăng ký ngay', overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Handle user choice
    if (result == true) {
      // User chose "Đăng ký ngay" - Navigate to CLB registration
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.clubRegistrationScreen,
        );
      }
    } else {
      // User chose "Để sau" - Set pending flag and continue to dashboard
      await _setPendingClubRegistration();
      if (mounted) {
        _navigateToDashboard();
      }
    }
  }

  // Set pending club registration flag
  Future<void> _setPendingClubRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pending_club_registration', true);
      if (kDebugMode) {
        ProductionLogger.info('🎯 Set pending_club_registration = true', tag: 'registration_result_screen');
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('❌ Failed to set pending flag: $e', tag: 'registration_result_screen');
      }
    }
  }

  // Navigate to dashboard
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.homeFeedScreen);
  }
  */ // END OF MOVED CODE - Now in EmailVerificationScreen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ✨ Gradient Background - Modern & Elegant
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isSuccess
                ? [
                    const Color(0xFF667eea), // Purple
                    const Color(0xFF764ba2), // Deep purple
                  ]
                : [
                    const Color(0xFFfc4a1a), // Red
                    const Color(0xFFf7b733), // Orange
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // 🎯 Main Result Card - Compact & Clean Design
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 🎨 Animated Icon
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: widget.isSuccess
                                            ? [
                                                const Color(0xFF11998e),
                                                const Color(0xFF38ef7d),
                                              ]
                                            : [
                                                const Color(0xFFeb3349),
                                                const Color(0xFFf45c43),
                                              ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (widget.isSuccess
                                                      ? const Color(0xFF38ef7d)
                                                      : const Color(0xFFf45c43))
                                                  .withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      widget.isSuccess
                                          ? Icons.check_circle_rounded
                                          : Icons.error_rounded,
                                      color: Colors.white,
                                      size: 56,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 28),

                            // 📝 Title
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: widget.isSuccess
                                    ? [
                                        const Color(0xFF11998e),
                                        const Color(0xFF38ef7d),
                                      ]
                                    : [
                                        const Color(0xFFeb3349),
                                        const Color(0xFFf45c43),
                                      ],
                              ).createShader(bounds),
                              child: Text(
                                widget.isSuccess ? 'Chúc mừng! 🎉' : 'Thất bại',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              widget.isSuccess
                                  ? 'Đăng ký thành công'
                                  : 'Đăng ký thất bại',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 20),

                            // � Email Verification Message - Compact
                            if (widget.isSuccess && widget.needsEmailVerification && widget.email != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F7FF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF667eea).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667eea),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.email_outlined,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Xác nhận email',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1a1a1a),
                                                ),
                                              ),
                                              Text(
                                                widget.email!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Email xác nhận đã được gửi. Vui lòng kiểm tra hộp thư và click vào đường link để kích hoạt tài khoản.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF9E6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFFFD54F),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Color(0xFFF57C00),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Không thấy email? Kiểm tra spam',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange[900],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Resend button - compact
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _isResending ? null : _handleResendEmail,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          side: const BorderSide(
                                            color: Color(0xFF667eea),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: _isResending
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF667eea),
                                                  ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.refresh_rounded,
                                                color: Color(0xFF667eea),
                                                size: 18,
                                              ),
                                        label: const Text(
                                          'Gửi lại email',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF667eea),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (widget.isSuccess) ...[
                              // Success message for non-email verification cases
                              Text(
                                _getSuccessMessage(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              // Error message
                              Text(
                                widget.errorMessage ?? 'Có lỗi xảy ra trong quá trình đăng ký. Vui lòng thử lại.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🎯 Action Button - Modern Gradient Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.isSuccess
                                ? [
                                    const Color(0xFF667eea),
                                    const Color(0xFF764ba2),
                                  ]
                                : [
                                    const Color(0xFF11998e),
                                    const Color(0xFF38ef7d),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (widget.isSuccess
                                          ? const Color(0xFF667eea)
                                          : const Color(0xFF38ef7d))
                                      .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.isSuccess
                                    ? (widget.needsEmailVerification
                                          ? 'Tôi đã hiểu'
                                          : 'Bắt đầu sử dụng')
                                    : 'Thử lại',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //  Success message helper
  String _getSuccessMessage() {
    if (widget.needsEmailVerification) {
      return 'Tài khoản của bạn đã được tạo thành công! Vui lòng kiểm tra email để xác nhận tài khoản trước khi đăng nhập.';
    }
    return 'Tài khoản của bạn đã được tạo thành công! Bạn có thể bắt đầu sử dụng SABO Arena ngay bây giờ.';
  }

  // 🔄 Handle resend email verification
  Future<void> _handleResendEmail() async {
    if (_isResending || widget.email == null) return;

    setState(() => _isResending = true);

    try {
      final authService = AuthService.instance;
      await authService.resendEmailVerification(email: widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Email xác nhận đã được gửi lại!'),
              ],
            ),
            backgroundColor: Color(0xFF42B883),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Lỗi: ${e.toString()}')),
              ],
            ),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  // 🎯 Handle continue action
  void _handleContinue() async {
    if (widget.isSuccess) {
      if (widget.needsEmailVerification) {
        // Về trang login để user có thể đăng nhập sau khi verify email
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.loginScreen, (route) => false);
      } else {
        // Navigate through auth controller to handle tutorial
        await AuthNavigationController.navigateAfterRegistration(
          context,
          email: widget.email ?? '',
          userId: widget.userId ?? '',
          needsEmailVerification: false,
        );
      }
    } else {
      // Back to registration on failure
      Navigator.of(context).pop();
    }
  }
}
