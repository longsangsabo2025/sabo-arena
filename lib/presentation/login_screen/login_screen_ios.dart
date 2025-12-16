import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/social_auth_service.dart';
import '../../services/auth_navigation_controller.dart';
import '../../utils/error_message_helper.dart';
import '../../helpers/welcome_voucher_helper.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class LoginScreenIOS extends StatefulWidget {
  const LoginScreenIOS({super.key});

  @override
  State<LoginScreenIOS> createState() => _LoginScreenIOSState();
}

class _LoginScreenIOSState extends State<LoginScreenIOS> {
  final _formKey = GlobalKey<FormState>();
  String _fullPhoneNumber = '';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEmailTab = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  String? _preselectedRole; // Role from onboarding

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get role from onboarding
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _preselectedRole = args?['preselectedRole'];
    if (kDebugMode && _preselectedRole != null) {
      ProductionLogger.info('🎯 Login: Received role from onboarding: $_preselectedRole', tag: 'login_screen_ios');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe) {
        final savedEmail = prefs.getString('saved_email') ?? '';
        final savedPhone = prefs.getString('saved_phone') ?? '';
        final isEmailMode = prefs.getBool('is_email_mode') ?? true;

        setState(() {
          _rememberMe = true;
          _isEmailTab = isEmailMode;
          if (isEmailMode && savedEmail.isNotEmpty) {
            _emailController.text = savedEmail;
          } else if (!isEmailMode && savedPhone.isNotEmpty) {
            _phoneController.text = savedPhone;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('Error loading saved credentials: $e', tag: 'login_screen_ios');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setBool('is_email_mode', _isEmailTab);

        if (_isEmailTab) {
          await prefs.setString('saved_email', _emailController.text.trim());
          await prefs.remove('saved_phone');
        } else {
          await prefs.setString('saved_phone', _phoneController.text.trim());
          await prefs.remove('saved_email');
        }
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('saved_email');
        await prefs.remove('saved_phone');
        await prefs.remove('is_email_mode');
      }
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('Error saving credentials: $e', tag: 'login_screen_ios');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService.instance;
      AuthResponse? response;

      if (_isEmailTab) {
        response = await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Phone login - TEMPORARILY DISABLED FOR MAINTENANCE
        if (mounted) {
          setState(() => _isLoading = false);
          
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
                    'Đăng nhập bằng số điện thoại đang được bảo trì để cải thiện trải nghiệm.',
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
                    '• Sử dụng Email để đăng nhập\n'
                    '• Nhanh chóng và bảo mật\n'
                    '• Không cần OTP/SMS',
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
                  child: const Text('Đăng nhập bằng Email'),
                ),
              ],
            ),
          );
        }
        return;
        
        /* COMMENTED OUT - ORIGINAL PHONE LOGIN CODE
        // Sử dụng số điện thoại đầy đủ từ IntlPhoneField
        if (kDebugMode) {
          ProductionLogger.info('📱 Login: Phone number: $_fullPhoneNumber', tag: 'login_screen_ios');
          ProductionLogger.info('📱 Login: Password length: ${_passwordController.text.length}',  tag: 'login_screen_ios');
        }

        if (_fullPhoneNumber.isEmpty) {
          throw Exception('Vui lòng nhập số điện thoại');
        }

        if (_passwordController.text.isEmpty) {
          throw Exception('Vui lòng nhập mật khẩu');
        }

        if (kDebugMode) ProductionLogger.info('📱 Login: Calling signInWithPhone...', tag: 'login_screen_ios');
        response = await authService.signInWithPhone(
          phone: _fullPhoneNumber,
          password: _passwordController.text,
        );
        if (kDebugMode)
          ProductionLogger.info('📱 Login: signInWithPhone completed successfully', tag: 'login_screen_ios');
        */
      }

      if (mounted && response.user != null) {
        // Save credentials if "Remember Me" is checked
        await _saveCredentials();

        // � Check for welcome voucher
        await WelcomeVoucherHelper.checkAndShowWelcomeVoucher(
          context,
          response.user!.id,
        );

        // �🎯 Use AuthNavigationController for proper post-login flow
        await AuthNavigationController.navigateAfterLogin(
          context,
          userId: response.user!.id,
          isFirstLogin: false, // Regular login, not first time
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageHelper.getContextualError('login', e)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
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

        // � Check for welcome voucher
        await WelcomeVoucherHelper.checkAndShowWelcomeVoucher(
          context,
          response.user!.id,
        );

        // �🎯 Use AuthNavigationController for proper post-social-login flow
        await AuthNavigationController.navigateAfterLogin(
          context,
          userId: response.user!.id,
          isFirstLogin: false, // Social login, not first time
        );
      }
    } on SocialAuthException catch (e) {
      if (mounted) {
        // Custom social auth exceptions with user-friendly messages
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor:
                e.code == 'WEB_NOT_CONFIGURED' || e.code == 'WEB_NOT_SUPPORTED'
                ? Colors.orange
                : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Đăng nhập ${provider.toUpperCase()} thất bại';

        // Handle specific web errors
        if (kIsWeb && e.toString().contains('Platform._operatingSystem')) {
          errorMessage =
              'Tính năng này đang được cập nhật cho web. Vui lòng sử dụng email/số điện thoại để đăng nhập.';
        } else if (e.toString().contains('YOUR_GOOGLE_WEB_CLIENT_ID')) {
          errorMessage =
              'Google Sign-In chưa được cấu hình. Vui lòng liên hệ support.';
        } else if (e.toString().contains('canceled') ||
            e.toString().contains('cancelled') ||
            e.toString().contains('popup_closed')) {
          errorMessage = 'Đăng nhập bị hủy';
        } else {
          errorMessage =
              'Đăng nhập ${provider.toUpperCase()} thất bại. Vui lòng thử lại.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                  'Chào mừng trở lại',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Đăng nhập vào tài khoản SABO Arena của bạn',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

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

                const SizedBox(height: 20),

                // Form Section
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
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
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Vui lòng nhập email';
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value!)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Password Field - iOS Style
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
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
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Vui lòng nhập mật khẩu';
                              if (value!.length < 6)
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              return null;
                            },
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
                              // E.164 format: +[country][number] (không có spaces/dashes/leading zero)
                              var normalized = phone.completeNumber
                                  .replaceAll(' ', '')
                                  .replaceAll('-', '')
                                  .replaceAll('(', '')
                                  .replaceAll(')', '');

                              // Match database format: 840961167717 (no + sign, with 0)
                              // Database stores: 840961167717 (without +)
                              if (normalized.startsWith('+84')) {
                                // Remove the + sign to match database format
                                normalized = normalized.substring(
                                  1,
                                ); // +84961167717 -> 84961167717

                                // Add the 0 after country code if not present
                                if (!normalized.startsWith('840')) {
                                  normalized =
                                      '840${normalized.substring(
                                        2,
                                      )}'; // 84961167717 -> 840961167717
                                }
                              }

                              _fullPhoneNumber = normalized;
                              if (kDebugMode)
                                ProductionLogger.info('📱 Normalized phone: $normalized', tag: 'login_screen_ios');
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

                        const SizedBox(height: 16),

                        // Password Field for Phone Login - iOS Style
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
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Vui lòng nhập mật khẩu';
                              if (value!.length < 6)
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              return null;
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Remember Me Checkbox - iOS Style
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                              activeColor: const Color(0xFF007AFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ghi nhớ đăng nhập',
                            style: TextStyle(
                              fontSize: 15,
                              color: const Color(0xFF1C1C1E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          // Forgot Password - iOS Style
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.forgotPasswordScreen);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF007AFF),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Login Button - iOS Style
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
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
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

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

                      const SizedBox(height: 16),

                      // Social Login Buttons - Ẩn Google trên iOS và Apple trên Android
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Facebook - Disabled temporarily
                          _buildDisabledSocialButton(
                            Icons.facebook,
                            const Color(0xFF1877F2),
                            'Đăng nhập Facebook sẽ được phát triển trong tương lai',
                          ),
                          // Ẩn Apple trên Android
                          if (!kIsWeb && Platform.isIOS) ...[
                            const SizedBox(width: 24),
                            _buildSocialIconButton(
                              Icons.apple,
                              Colors.black,
                              () => _handleSocialLogin('apple'),
                            ),
                          ],
                          // Ẩn Google trên iOS
                          if (!kIsWeb && Platform.isAndroid) ...[
                            const SizedBox(width: 24),
                            _buildSocialIconButton(
                              Icons.g_mobiledata,
                              const Color(0xFF4285F4),
                              () => _handleSocialLogin('google'),
                            ),
                          ],
                          // Trên Web, hiển thị cả 2
                          if (kIsWeb) ...[
                            const SizedBox(width: 24),
                            _buildSocialIconButton(
                              Icons.apple,
                              Colors.black,
                              () => _handleSocialLogin('apple'),
                            ),
                            const SizedBox(width: 24),
                            _buildSocialIconButton(
                              Icons.g_mobiledata,
                              const Color(0xFF4285F4),
                              () => _handleSocialLogin('google'),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Register Link - iOS Style
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.registerScreen,
                                arguments: _preselectedRole != null
                                    ? {'userRole': _preselectedRole}
                                    : null,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Đăng ký',
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

  Widget _buildSocialIconButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildDisabledSocialButton(
    IconData icon,
    Color color,
    String message,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.grey[700],
            duration: const Duration(seconds: 3),
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[100],
          border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: 0.4,
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
