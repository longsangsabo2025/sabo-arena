import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../core/app_export.dart';

class PhoneOtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String fullName;
  final String password;
  final bool isLogin; // true = login, false = register

  const PhoneOtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.fullName,
    required this.password,
    this.isLogin = false,
  }) : super(key: key);

  @override
  State<PhoneOtpVerificationScreen> createState() =>
      _PhoneOtpVerificationScreenState();
}

class _PhoneOtpVerificationScreenState
    extends State<PhoneOtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendCountdown();
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ 6 số')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService.instance;

      if (widget.isLogin) {
        // Login flow
        final response = await authService.verifyPhoneOtp(
          phone: widget.phoneNumber,
          token: _otpCode,
        );

        if (response.user != null && mounted) {
          // Ensure user profile exists (in case it was deleted or missing)
          await authService.upsertUserRecord(
            fullName: response.user!.userMetadata?['full_name'] ?? 'User',
            phone: widget.phoneNumber,
            role: 'player',
          );
          
          // 🚀 PHASE 1: Navigate to main screen with persistent tabs
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.mainScreen, (route) => false);
        }
      } else {
        // Register flow - verify OTP then create user with password
        final response = await authService.verifyPhoneOtp(
          phone: widget.phoneNumber,
          token: _otpCode,
        );

        if (response.user != null && mounted) {
          // 1. Set password for the user (để có thể login bằng phone + password sau này)
          if (widget.password.isNotEmpty) {
            await authService.updatePassword(widget.password);
          }
          
          // 2. Update user profile with full name
          await authService.upsertUserRecord(
            fullName: widget.fullName,
            phone: widget.phoneNumber,
            role: 'player',
          );

          // 🚀 PHASE 1: Navigate to main screen with persistent tabs
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.mainScreen, (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Remove "Exception: " prefix
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        // Handle specific errors
        if (errorMessage.contains('expired') || errorMessage.contains('invalid')) {
          errorMessage = 'Mã OTP đã hết hạn hoặc không hợp lệ. Vui lòng yêu cầu gửi lại mã.';
        } else if (errorMessage.contains('duplicate') || errorMessage.contains('already exists')) {
          errorMessage = 'Số điện thoại này đã được đăng ký. Vui lòng đăng nhập hoặc sử dụng số khác.';
        } else if (errorMessage.contains('403')) {
          errorMessage = 'Mã OTP đã hết hạn. Vui lòng nhấn "Gửi lại mã" để nhận mã mới.';
        }
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Xác thực thất bại'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await AuthService.instance.sendPhoneOtp(
        phone: widget.phoneNumber,
        createUserIfNeeded: !widget.isLogin,
      );

      setState(() {
        _resendCountdown = 60;
        _startResendCountdown();
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã gửi lại mã OTP')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi lại thất bại: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

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
          'Xác thực OTP', overflow: TextOverflow.ellipsis, style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_iphone,
                  size: 40,
                  color: Color(0xFF007AFF),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Nhập mã OTP', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Mã xác thực đã được gửi đến\n${widget.phoneNumber}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF007AFF),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }

                        // Auto verify when all 6 digits entered
                        if (index == 5 && value.isNotEmpty) {
                          _verifyOtp();
                        }
                      },
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Resend Button
              TextButton(
                onPressed: _resendCountdown == 0 ? _resendOtp : null,
                child: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _resendCountdown > 0
                            ? 'Gửi lại mã sau $_resendCountdown giây'
                            : 'Gửi lại mã OTP', overflow: TextOverflow.ellipsis, style: TextStyle(
                          fontSize: 15,
                          color: _resendCountdown == 0
                              ? const Color(0xFF007AFF)
                              : const Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),

              const Spacer(),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Xác nhận', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
