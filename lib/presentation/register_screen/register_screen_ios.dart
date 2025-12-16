import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/social_auth_service.dart';
import '../../services/enhanced_validation_service.dart';
import 'registration_result_screen.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class RegisterScreenIOS extends StatefulWidget {
  const RegisterScreenIOS({super.key});

  @override
  State<RegisterScreenIOS> createState() => _RegisterScreenIOSState();
}

class _RegisterScreenIOSState extends State<RegisterScreenIOS> {
  final _formKey = GlobalKey<FormState>();
  String _fullPhoneNumber = '';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEmailTab = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  String? _userRole; // Role from login/onboarding

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get role from login screen
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _userRole = args?['userRole'];
    if (kDebugMode && _userRole != null) {
      ProductionLogger.info('🎯 Register: Received role: $_userRole', tag: 'register_screen_ios');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (kDebugMode) ProductionLogger.info('🎯 REGISTER: _handleRegister called', tag: 'register_screen_ios');

    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) ProductionLogger.info('❌ REGISTER: Form validation failed', tag: 'register_screen_ios');
      return;
    }

    if (!_acceptTerms) {
      if (kDebugMode) ProductionLogger.info('⚠️ REGISTER: Terms not accepted', tag: 'register_screen_ios');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản và chính sách bảo mật'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (kDebugMode) ProductionLogger.info('✅ REGISTER: Form valid, starting registration...', tag: 'register_screen_ios');
    setState(() => _isLoading = true);

    try {
      // Email registration
      final authService = AuthService.instance;

      if (_isEmailTab) {
        // ✅ Fix: Handle empty string role, not just null
        final effectiveRole = (_userRole == null || _userRole!.isEmpty) 
            ? 'player' 
            : _userRole!;
            
        if (kDebugMode) {
          ProductionLogger.info('📧 REGISTER: Email registration', tag: 'register_screen_ios');
          ProductionLogger.info('   Email: ${_emailController.text.trim()}', tag: 'register_screen_ios');
          ProductionLogger.info('   Name: ${_fullNameController.text.trim()}', tag: 'register_screen_ios');
          ProductionLogger.info('   Role: $effectiveRole (original: $_userRole)', tag: 'register_screen_ios');
        }
        final response = await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          role: effectiveRole,
        );

        if (mounted && response.user != null) {
          // 🎯 Navigate to success screen with email verification check
          final needsVerification = response.user!.emailConfirmedAt == null;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RegistrationResultScreen(
                isSuccess: true,
                userId: response.user!.id,
                email: response.user!.email ?? _emailController.text.trim(),
                userRole: effectiveRole, // ✅ Use effectiveRole instead of _userRole
                needsEmailVerification: needsVerification,
              ),
            ),
          );
        }
      } else {
        // Phone registration - TEMPORARILY DISABLED FOR MAINTENANCE
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.build, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🔧 Bảo trì tính năng',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Đăng ký bằng số điện thoại đang được bảo trì để cải thiện trải nghiệm.',
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '💡 Khuyến nghị:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Sử dụng Email để đăng ký\n'
                    '• Nhanh chóng và bảo mật\n'
                    '• Không mất phí SMS',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Switch to Email tab
                    setState(() {
                      _isEmailTab = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                  ),
                  child: const Text('Đăng ký bằng Email'),
                ),
              ],
            ),
          );
        }
        
        setState(() => _isLoading = false);
        return;
        
        // COMMENTED OUT - ORIGINAL PHONE REGISTRATION CODE
        /*
        // Phone registration - Check if phone exists first
        if (_fullPhoneNumber.isEmpty) {
          throw Exception('Vui lòng nhập số điện thoại');
        }

        if (kDebugMode) {
          ProductionLogger.info('📱 REGISTER: Checking if phone exists: $_fullPhoneNumber', tag: 'register_screen_ios');
        }

        // ✅ Check if phone number already exists
        final phoneExists = await authService.checkPhoneExists(_fullPhoneNumber);
        
        if (phoneExists) {
          if (kDebugMode) {
            ProductionLogger.info('⚠️ REGISTER: Phone already exists', tag: 'register_screen_ios');
          }
          
          // Show error dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('⚠️ Số điện thoại đã tồn tại'),
                content: const Text(
                  'Số điện thoại này đã được đăng ký.\n\n'
                  'Vui lòng:\n'
                  '• Đăng nhập nếu đây là tài khoản của bạn\n'
                  '• Sử dụng số điện thoại khác để đăng ký\n'
                  '• Liên hệ hỗ trợ nếu bạn quên mật khẩu'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to login
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text('Đến trang đăng nhập'),
                  ),
                ],
              ),
            );
          }
          return; // Stop registration process
        }

        if (kDebugMode) {
          ProductionLogger.info('✅ REGISTER: Phone number available, sending OTP', tag: 'register_screen_ios');
        }

        // Send OTP
        await authService.sendPhoneOtp(
          phone: _fullPhoneNumber,
          createUserIfNeeded: true,
        );

        if (kDebugMode) {
          ProductionLogger.info('✅ OTP sent successfully', tag: 'register_screen_ios');
        }

        // Navigate to OTP verification screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PhoneOtpVerificationScreen(
                phoneNumber: _fullPhoneNumber,
                fullName: _fullNameController.text.trim(),
                password: _passwordController.text,
                isLogin: false, // This is registration
              ),
            ),
          );
        }
        */ // END OF COMMENTED CODE
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('❌ REGISTER ERROR: $e', tag: 'register_screen_ios');
      }
      
      if (mounted) {
        // ✅ Extract user-friendly message
        String errorMessage = e.toString();
        
        // Remove "Exception: " prefix if present
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        // Show error in a dialog for better visibility
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Đăng ký thất bại'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialRegister(String provider) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final socialAuthService = SocialAuthService();
      AuthResponse? response;

      switch (provider) {
        case 'google':
          response = await socialAuthService.signInWithGoogle();
          break;
        case 'facebook':
          response = await socialAuthService.signInWithFacebook();
          break;
        case 'apple':
          response = await socialAuthService.signInWithApple();
          break;
      }

      if (response?.user != null && mounted) {
        // Update user metadata in our database
        await AuthService.instance.upsertUserRecord(
          fullName:
              response!.user!.userMetadata?['full_name'] ??
              response.user!.userMetadata?['name'] ??
              'User',
          role: 'player',
        );

        // 🎯 Navigate to success screen for social auth
        final user = response.user!;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RegistrationResultScreen(
              isSuccess: true,
              userId: user.id,
              email: user.email ?? '',
              userRole: _userRole ?? 'player', // ✅ Pass role from onboarding
              needsEmailVerification:
                  false, // Social auth doesn't need email verification
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // 🎯 Navigate to failure screen for social auth
        String errorMessage = 'Đăng ký ${provider.toUpperCase()} thất bại';
        if (e.toString().contains('canceled') ||
            e.toString().contains('cancelled')) {
          errorMessage = 'Đăng ký bị hủy bởi người dùng';
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RegistrationResultScreen(
              isSuccess: false,
              errorMessage: errorMessage,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo Section - Simple without background
                SizedBox(
                  height: 80,
                  width: 80,
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // Welcome Text - iOS Style
                const Text(
                  'Tạo tài khoản mới',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Tham gia SABO Arena ngay hôm nay',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                  textAlign: TextAlign.center,
                ),

                // Role Badge - Show if role is pre-selected
                if (_userRole == 'club_owner') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.business_center,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Vai trò: Chủ CLB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Tab Selector - iOS Style
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isEmailTab = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isEmailTab
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isEmailTab
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: _isEmailTab
                                      ? const Color(0xFF007AFF)
                                      : const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isEmailTab = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            decoration: BoxDecoration(
                              color: !_isEmailTab
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !_isEmailTab
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Số điện thoại',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: !_isEmailTab
                                      ? const Color(0xFF007AFF)
                                      : const Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form Section
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name Field - iOS Style
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _fullNameController,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1C1C1E),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Họ và tên',
                            hintStyle: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 17,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Color(0xFF8E8E93),
                              size: 20,
                            ),
                          ),
                          validator: (value) =>
                              EnhancedValidationService.validateFullName(value),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_isEmailTab) ...[
                        // Email Field - iOS Style
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF1C1C1E),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 17,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Color(0xFF8E8E93),
                                size: 20,
                              ),
                            ),
                            validator: (value) =>
                                EnhancedValidationService.validateEmail(value),
                          ),
                        ),
                      ] else ...[
                        // Phone Field with Country Picker - iOS Style
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IntlPhoneField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              hintText: 'Số điện thoại',
                              hintStyle: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 17,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            initialCountryCode: 'VN', // Mặc định Việt Nam
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF1C1C1E),
                            ),
                            dropdownIconPosition: IconPosition.trailing,
                            dropdownTextStyle: const TextStyle(
                              fontSize: 17,
                              color: Color(0xFF1C1C1E),
                            ),
                            flagsButtonPadding: const EdgeInsets.only(left: 8),
                            disableLengthCheck:
                                true, // Tắt validation độ dài tự động
                            onChanged: (phone) {
                              // Normalize số điện thoại: loại bỏ spaces, dashes, brackets
                              // Twilio yêu cầu E.164 format: +[country][number] (không có spaces/dashes)
                              final normalized = phone.completeNumber
                                  .replaceAll(' ', '')
                                  .replaceAll('-', '')
                                  .replaceAll('(', '')
                                  .replaceAll(')', '');
                              _fullPhoneNumber = normalized;
                            },
                            validator: (phone) {
                              if (phone == null || phone.number.isEmpty) {
                                return 'Vui lòng nhập số điện thoại';
                              }
                              // Kiểm tra tối thiểu 8 chữ số
                              if (phone.number.length < 8) {
                                return 'Số điện thoại quá ngắn';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Password Field - iOS Style
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1C1C1E),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Mật khẩu',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 17,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF8E8E93),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF8E8E93),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              EnhancedValidationService.validatePassword(value),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password Field - iOS Style
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1C1C1E),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Xác nhận mật khẩu',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 17,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF8E8E93),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF8E8E93),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Vui lòng xác nhận mật khẩu';
                            if (value != _passwordController.text)
                              return 'Mật khẩu không khớp';
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Terms & Conditions Checkbox - iOS Style
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _acceptTerms = !_acceptTerms),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _acceptTerms
                                    ? const Color(0xFF007AFF)
                                    : Colors.white,
                                border: Border.all(
                                  color: _acceptTerms
                                      ? const Color(0xFF007AFF)
                                      : const Color(0xFFE5E5EA),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _acceptTerms
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF8E8E93),
                                ),
                                children: [
                                  const TextSpan(text: 'Tôi đồng ý với '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.termsOfServiceScreen,
                                        );
                                      },
                                      child: const Text(
                                        'Điều khoản sử dụng',
                                        style: TextStyle(
                                          color: Color(0xFF007AFF),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' và '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.privacyPolicyScreen,
                                        );
                                      },
                                      child: const Text(
                                        'Chính sách bảo mật',
                                        style: TextStyle(
                                          color: Color(0xFF007AFF),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Register Button - iOS Style
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: const Color(0xFF8E8E93),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Tạo tài khoản',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider - iOS Style
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'hoặc',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social Login Buttons - Ẩn Google trên iOS và Apple trên Android
                      Row(
                        children: [
                          Expanded(
                            child: _buildDisabledSocialButton(
                              'Facebook',
                              Icons.facebook,
                              const Color(0xFF1877F2),
                              'Đăng ký Facebook sẽ được phát triển trong tương lai',
                            ),
                          ),
                          // Ẩn Apple trên Android
                          if (!kIsWeb && Platform.isIOS) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSocialButton(
                                'Apple',
                                Icons.apple,
                                Colors.black,
                                () => _handleSocialRegister('apple'),
                              ),
                            ),
                          ],
                          // Ẩn Google trên iOS
                          if (!kIsWeb && Platform.isAndroid) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSocialButton(
                                'Google',
                                Icons.g_mobiledata,
                                const Color(0xFF4285F4),
                                () => _handleSocialRegister('google'),
                              ),
                            ),
                          ],
                          // Trên Web, hiển thị cả 2
                          if (kIsWeb) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSocialButton(
                                'Apple',
                                Icons.apple,
                                Colors.black,
                                () => _handleSocialRegister('apple'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSocialButton(
                                'Google',
                                Icons.g_mobiledata,
                                const Color(0xFF4285F4),
                                () => _handleSocialRegister('google'),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Login Link - iOS Style
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.loginScreen);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E5EA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        icon: Icon(icon, color: color, size: 16),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1C1C1E),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDisabledSocialButton(
    String text,
    IconData icon,
    Color color,
    String message,
  ) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.grey[700],
              duration: const Duration(seconds: 3),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E5EA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        icon: Opacity(
          opacity: 0.4,
          child: Icon(icon, color: color, size: 16),
        ),
        label: Opacity(
          opacity: 0.4,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1C1E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
