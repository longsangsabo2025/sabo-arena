import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/auth_navigation_controller.dart';
import '../../helpers/welcome_voucher_helper.dart';
import '../../widgets/common/app_button.dart';
// ELON_MODE_AUTO_FIX

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String userId;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.userId,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  Timer? _timer;
  Timer? _autoCheckTimer;
  int _resendCooldown = 0;
  bool _isResending = false;
  bool _isChecking = false;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Animations
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _pulseController.repeat(reverse: true);
    _progressController.forward();

    // Auto-check verification status every 3 seconds
    _startAutoVerificationCheck();

    // Start resend cooldown
    _startResendCooldown();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _timer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _startAutoVerificationCheck() {
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkVerificationStatus(silent: true);
      }
    });
  }

  void _startResendCooldown() {
    _resendCooldown = 60; // 60 seconds cooldown
    _canResend = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _checkVerificationStatus({bool silent = false}) async {
    if (_isChecking) return;

    setState(() => _isChecking = !silent);

    try {
      // Refresh user session to get latest email verification status
      await AuthService.instance.refreshSession();
      final user = AuthService.instance.currentUser;

      if (user?.emailConfirmedAt != null) {
        // ✅ Email verified successfully!
        _autoCheckTimer?.cancel();

        if (mounted) {
          // Show success animation
          await _showSuccessAnimation();

          if (!mounted) return;

          //  Check for welcome voucher (trigger đã auto-issue rồi)
          await WelcomeVoucherHelper.checkAndShowWelcomeVoucher(
            context,
            widget.userId,
          );

          if (!mounted) return;

          // �🎯 CHECK IF USER IS CLUB OWNER - Show CLB dialog AFTER verification
          final userRole = user?.userMetadata?['role'];
          if (userRole == 'club_owner') {
            // Show CLB registration dialog
            await _showClubRegistrationDialog();
          } else {
            // Regular user - navigate to home
            await AuthNavigationController.navigateAfterLogin(
              context,
              userId: widget.userId,
              isFirstLogin: true,
            );
          }
        }
      } else if (!silent) {
        // Manual check - show message
        _showMessage(
          'Email chưa được xác thực. Vui lòng kiểm tra hộp thư.',
          false,
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        _showMessage('Lỗi kiểm tra xác thực: $e', true);
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    try {
      await AuthService.instance.resendEmailVerification();

      _showMessage('📧 Email xác thực đã được gửi lại!', false);
      _startResendCooldown();
    } catch (e) {
      _showMessage('Lỗi gửi lại email: $e', true);
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _showSuccessAnimation() async {
    // Stop pulse animation
    _pulseController.stop();

    // Show success checkmark animation
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 40),
                ),
                SizedBox(height: 20),
                Text(
                  '✅ Email đã xác thực!',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Đang chuyển hướng...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );

      // Wait 2 seconds before closing
      await Future.delayed(Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showMessage(String message, bool isError) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 🎯 Show CLB Registration Dialog for Club Owners (AFTER email verification)
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
                colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
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
                  'Đăng ký CLB của bạn',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
                  'Email đã được xác thực thành công! ✅\n\nBạn có muốn tiếp tục đăng ký thông tin CLB ngay bây giờ?',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
                    // "Để sau" button - iOS style
                    Expanded(
                      child: AppButton(
                        label: 'Để sau',
                        type: AppButtonType.outline,
                        size: AppButtonSize.medium,
                        fullWidth: true,
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // "Đăng ký ngay" button - iOS style
                    Expanded(
                      child: AppButton(
                        label: 'Đăng ký ngay',
                        type: AppButtonType.primary,
                        size: AppButtonSize.medium,
                        customColor: const Color(0xFF3B82F6), // iOS blue
                        customTextColor: Colors.white,
                        fullWidth: true,
                        onPressed: () => Navigator.pop(context, true),
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
        Navigator.of(context).pushReplacementNamed('/club_registration_screen');
      }
    } else {
      // User chose "Để sau" - Set pending flag and continue to home
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pending_club_registration', true);
      } catch (e) {
        // Ignore error
      }

      // Navigate to home
      if (mounted) {
        await AuthNavigationController.navigateAfterLogin(
          context,
          userId: widget.userId,
          isFirstLogin: true,
        );
      }
    }
  }

  void _skipVerification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Bỏ qua xác thực?'),
        content: Text(
          'Bạn có thể sử dụng app mà không xác thực email, '
          'nhưng một số tính năng có thể bị hạn chế.\n\n'
          'Bạn có thể xác thực sau trong phần cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          AppButton(
            label: 'Bỏ qua',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            customColor: Colors.orange,
            customTextColor: Colors.white,
            onPressed: () async {
              Navigator.pop(context);

              // Navigate to next step without verification
              await AuthNavigationController.navigateAfterLogin(
                context,
                userId: widget.userId,
                isFirstLogin: true,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF007AFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      'Xác thực Email',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48), // Balance the back button
                ],
              ),

              SizedBox(height: 40),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Email Icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.mail_outline,
                              size: 60,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 40),

                    // Title
                    Text(
                      '📧 Kiểm tra Email của bạn',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16),

                    // Description
                    Text(
                      'Chúng tôi đã gửi link xác thực đến:',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8),

                    // Email address
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Instructions
                    Text(
                      'Vui lòng kiểm tra hộp thư và nhấn vào link xác thực.\n'
                      'Email có thể ở trong thư mục Spam.',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 40),

                    // Check Status Button - iOS style
                    AppButton(
                      label: 'Kiểm tra trạng thái',
                      type: AppButtonType.primary,
                      size: AppButtonSize.large,
                      icon: Icons.refresh,
                      iconTrailing: false,
                      customColor: Colors.white,
                      customTextColor: const Color(0xFF007AFF), // iOS blue
                      isLoading: _isChecking,
                      fullWidth: true,
                      onPressed:
                          _isChecking ? null : () => _checkVerificationStatus(),
                    ),

                    SizedBox(height: 16),

                    // Resend Button - iOS style
                    AppButton(
                      label: _canResend
                          ? 'Gửi lại email'
                          : 'Gửi lại sau ${_resendCooldown}s',
                      type: AppButtonType.outline,
                      size: AppButtonSize.large,
                      customTextColor: Colors.white,
                      isLoading: _isResending,
                      fullWidth: true,
                      onPressed: (_canResend && !_isResending)
                          ? _resendVerificationEmail
                          : null,
                    ),
                  ],
                ),
              ),

              // Skip option
              TextButton(
                onPressed: _skipVerification,
                child: Text(
                  'Bỏ qua xác thực (không khuyến khích)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Auto-check indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tự động kiểm tra mỗi 3 giây...',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
