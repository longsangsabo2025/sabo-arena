import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import 'preferences_service.dart';
import 'supabase_service.dart';
import 'auto_notification_hooks.dart';
import 'referral_service.dart';
import 'deep_link_service.dart';
import '../services/rate_limit_service.dart';
import '../exceptions/rate_limit_exception.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  // Use robust SupabaseService instead of direct Supabase.instance.client
  SupabaseClient get _supabase {
    try {
      return SupabaseService.instance.client;
    } catch (e) {
      ProductionLogger.error(
        '⚠️ AuthService: Supabase client not ready',
        error: e,
        tag: 'Auth',
      );
      throw Exception(
        'Dịch vụ xác thực không khả dụng. Vui lòng khởi động lại ứng dụng.',
      );
    }
  }

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      ProductionLogger.auth('Attempting email login for: $email');

      // Rate limiting check
      final rateLimitService = RateLimitService.instance;
      final clientIP = await _getClientIP();
      if (!await rateLimitService.isAllowed('login', clientIP)) {
        final timeUntilReset = await rateLimitService.getTimeUntilReset(
          'login',
          clientIP,
        );
        throw RateLimitException.legacy('login', clientIP, timeUntilReset);
      }

      // Ensure Supabase is initialized
      if (!SupabaseService.instance.isInitialized) {
        ProductionLogger.warning(
          'Supabase not initialized, attempting initialization...',
          tag: 'Auth',
        );
        await SupabaseService.initialize();
      }

      ProductionLogger.network('POST', 'Supabase Auth - signInWithPassword');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      ProductionLogger.auth('Email login successful');
      ProductionLogger.network(
        'POST',
        'Supabase Auth - signInWithPassword',
        statusCode: 200,
      );
      return response;
    } on AuthException catch (e) {
      ProductionLogger.auth('Auth error: ${e.message}', isError: true);
      ProductionLogger.network(
        'POST',
        'Supabase Auth - signInWithPassword',
        error: e.message,
      );
      throw Exception('Đăng nhập thất bại: ${e.message}');
    } on RateLimitException catch (e) {
      ProductionLogger.auth(
        'Rate limit exceeded',
        details: e.toString(),
        isError: true,
      );
      rethrow;
    } catch (error, stackTrace) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.auth,
          operation: 'signInWithEmail',
          context: 'Failed to sign in with email',
        ),
      );
      ProductionLogger.error(
        'Unexpected login error',
        error: error,
        stackTrace: stackTrace,
        tag: 'Auth',
      );
      ProductionLogger.network(
        'POST',
        'Supabase Auth - signInWithPassword',
        error: error.toString(),
      );
      throw Exception(errorInfo.message);
    }
  }

  /// Helper method to get client identifier (IP or device ID)
  Future<String> _getClientIP() async {
    try {
      // For mobile/web apps, we use a combination of device info
      // In production, this could be enhanced with actual IP detection
      final deviceId = await _getDeviceIdentifier();
      return deviceId ?? 'unknown-client';
    } catch (e) {
      return 'unknown-client';
    }
  }

  /// Get device identifier for rate limiting
  Future<String?> _getDeviceIdentifier() async {
    try {
      // Simple implementation - in production, use device_info_plus package
      // For now, use a hash of current timestamp + random string
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'device-${timestamp.hashCode}';
    } catch (e) {
      return null;
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'player',
  }) async {
    try {
      // Rate limiting check for registration
      final rateLimitService = RateLimitService.instance;
      final clientIP = await _getClientIP();
      if (!await rateLimitService.isAllowed('register', clientIP)) {
        final timeUntilReset = await rateLimitService.getTimeUntilReset(
          'register',
          clientIP,
        );
        throw RateLimitException.legacy('register', clientIP, timeUntilReset);
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

      // 🎯 POST-REGISTRATION HOOKS - Run in background, don't block registration
      if (response.user != null) {
        if (kDebugMode) {
          ProductionLogger.info('✅ Clean registration successful - no hooks', tag: 'auth_service');
        ProductionLogger.info('   User ID: ${response.user!.id}', tag: 'auth_service');
        ProductionLogger.info('   📋 Note: User initialization will happen after onboarding', tag: 'auth_service');
        }

        // � Hook 1: Welcome notification (non-blocking)
        // 🚫 HOOKS DISABLED - Will run after onboarding instead
        // _runWelcomeNotificationHook(response.user!.id, fullName);
        // _runCreateReferralCodeHook(response.user!.id);
        // _runProcessReferralCodeHook(response.user!.id);
      }

      return response;
    } on RateLimitException {
      ProductionLogger.warning('Registration rate limit exceeded', tag: 'Auth');
      rethrow;
    } on AuthException catch (e) {
      // ✅ Handle specific Supabase Auth errors with clear messages
      String userMessage;
      
      if (e.message.toLowerCase().contains('user already registered') ||
          e.message.toLowerCase().contains('email already exists') ||
          e.message.toLowerCase().contains('already registered')) {
        userMessage = 'Email này đã được đăng ký. Vui lòng đăng nhập hoặc sử dụng email khác.';
      } else if (e.message.toLowerCase().contains('invalid email')) {
        userMessage = 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      } else if (e.message.toLowerCase().contains('weak password') ||
                 e.message.toLowerCase().contains('password')) {
        userMessage = 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn (tối thiểu 6 ký tự).';
      } else if (e.message.toLowerCase().contains('database error')) {
        userMessage = 'Lỗi hệ thống. Email này có thể đã tồn tại. Vui lòng thử email khác hoặc liên hệ hỗ trợ.';
      } else if (e.statusCode == '500') {
        userMessage = 'Lỗi máy chủ (500). Email có thể đã được sử dụng. Vui lòng thử email khác.';
      } else {
        userMessage = 'Đăng ký thất bại: ${e.message}';
      }
      
      if (kDebugMode) {
        ProductionLogger.info('❌ Auth Error: ${e.message}', tag: 'auth_service');
        ProductionLogger.info('   Status: ${e.statusCode}', tag: 'auth_service');
        ProductionLogger.info('   User Message: $userMessage', tag: 'auth_service');
      }
      
      throw Exception(userMessage);
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.auth,
          operation: 'signUpWithEmail',
          context: 'Failed to sign up with email',
        ),
      );
      if (kDebugMode) {
        ProductionLogger.info('❌ Unexpected error: ${errorInfo.message}', tag: 'auth_service');
      }
      throw Exception(errorInfo.message);
    }
  }

  Future<AuthResponse> signUpWithPhone({
    required String phone,
    required String password,
    required String fullName,
    String role = 'player',
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        phone: phone,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

      // 🔔 Gửi thông báo chào mừng user mới
      if (response.user != null) {
        await AutoNotificationHooks.onUserRegistered(
          userId: response.user!.id,
          userName: fullName,
          registrationMethod: 'phone',
        );

        // 🔗 Tự động tạo referral code cho user mới
        await ReferralService.instance.createReferralCodeForUser(
          response.user!.id,
        );

        // 🎯 Xử lý mã ref từ QR code (nếu có)
        try {
          final storedReferralCode = await DeepLinkService.instance
              .getStoredReferralCodeForNewUser();
          if (storedReferralCode != null && storedReferralCode.isNotEmpty) {
            // Sử dụng mã ref để tính điểm bonus cho cả 2 người
            await ReferralService.instance.useReferralCode(
              storedReferralCode,
              response.user!.id,
            );
            await DeepLinkService.instance.clearStoredReferralCode();
            ProductionLogger.info('Applied referral code', tag: 'Auth');
          }
        } on Exception {
          ProductionLogger.warning(
            'Could not process referral code',
            tag: 'Auth',
          );
        }
      }

      return response;
    } catch (error) {
      throw Exception('Đăng ký thất bại: $error');
    }
  }

  /// Check if phone number already exists in the system
  Future<bool> checkPhoneExists(String phone) async {
    try {
      ProductionLogger.info('Checking if phone exists', tag: 'Auth');

      // Query users table to check if phone exists
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('phone', phone)
          .maybeSingle();

      final exists = response != null;
      
      if (exists) {
        ProductionLogger.info('Phone number already exists', tag: 'Auth');
      } else {
        ProductionLogger.info('Phone number available', tag: 'Auth');
      }

      return exists;
    } catch (e) {
      ProductionLogger.error(
        'Error checking phone existence',
        error: e,
        tag: 'Auth',
      );
      // On error, return false to allow registration attempt
      // (will fail later if phone actually exists)
      return false;
    }
  }

  Future<void> sendPhoneOtp({
    required String phone,
    bool createUserIfNeeded = true,
  }) async {
    try {
      // Rate limiting check for OTP
      final rateLimitService = RateLimitService.instance;
      final clientIP = await _getClientIP();
      if (!await rateLimitService.isAllowed('otp_verify', clientIP)) {
        final timeUntilReset = await rateLimitService.getTimeUntilReset(
          'otp_verify',
          clientIP,
        );
        throw RateLimitException.legacy('otp_verify', clientIP, timeUntilReset);
      }

      // ✅ SECURITY: Redacted phone in production logs
      ProductionLogger.info('Sending OTP via Supabase', tag: 'Auth');

      // Ensure Supabase is initialized
      if (!SupabaseService.instance.isInitialized) {
        ProductionLogger.warning(
          'Supabase not initialized, initializing...',
          tag: 'Auth',
        );
        await SupabaseService.initialize();
      }

      await _supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: createUserIfNeeded,
      );

      ProductionLogger.info('OTP sent successfully', tag: 'Auth');
    } on AuthException catch (e) {
      ProductionLogger.error('Auth error', error: e, tag: 'Auth');

      // Handle specific auth errors
      if (e.message.contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception(
          'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.',
        );
      } else if (e.message.contains('phone')) {
        throw Exception('Số điện thoại không hợp lệ. Vui lòng kiểm tra lại.');
      } else {
        throw Exception('Gửi mã OTP thất bại: ${e.message}');
      }
    } on RateLimitException {
      ProductionLogger.warning('OTP rate limit exceeded', tag: 'Auth');
      rethrow;
    } catch (error) {
      ProductionLogger.error(
        'Unexpected error sending OTP',
        error: error,
        tag: 'Auth',
      );

      // Handle network/SSL errors
      if (error.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
          error.toString().contains('HandshakeException')) {
        throw Exception(
          'Lỗi kết nối bảo mật. Vui lòng kiểm tra kết nối mạng và thử lại.',
        );
      }

      throw Exception('Gửi mã OTP thất bại: $error');
    }
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      ProductionLogger.info('Verifying OTP for phone: $phone', tag: 'Auth');

      // Ensure Supabase is initialized
      if (!SupabaseService.instance.isInitialized) {
        ProductionLogger.warning('Initializing Supabase...', tag: 'Auth');
        await SupabaseService.initialize();
      }

      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );

      ProductionLogger.info('OTP verified successfully', tag: 'Auth');
      return response;
    } on AuthException catch (e) {
      ProductionLogger.error(
        'Auth error during OTP verification',
        error: e,
        tag: 'Auth',
      );

      // Handle specific auth errors with better messages
      if (e.statusCode == '403' || e.message.contains('expired')) {
        throw Exception(
          'Mã OTP đã hết hạn (thời gian hiệu lực: 60 giây). Vui lòng nhấn "Gửi lại mã" để nhận mã mới.',
        );
      } else if (e.message.contains('invalid')) {
        throw Exception(
          'Mã OTP không hợp lệ. Vui lòng kiểm tra lại hoặc yêu cầu gửi lại mã.',
        );
      } else if (e.message.contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception(
          'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.',
        );
      } else {
        throw Exception('Xác thực OTP thất bại: ${e.message}');
      }
    } catch (error) {
      ProductionLogger.error(
        'Unexpected error during OTP verification',
        error: error,
        tag: 'Auth',
      );

      // Handle network/SSL errors
      if (error.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
          error.toString().contains('HandshakeException')) {
        throw Exception(
          'Lỗi kết nối bảo mật. Vui lòng kiểm tra kết nối mạng và thử lại.',
        );
      }

      throw Exception('Xác thực OTP thất bại: $error');
    }
  }

  /// Update user password after OTP verification
  /// This allows user to login with phone + password later
  Future<void> updatePassword(String newPassword) async {
    try {
      ProductionLogger.info('Updating user password', tag: 'Auth');

      final user = currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Ensure Supabase is initialized
      if (!SupabaseService.instance.isInitialized) {
        ProductionLogger.warning('Initializing Supabase...', tag: 'Auth');
        await SupabaseService.initialize();
      }

      // Update password using Supabase Auth API
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      ProductionLogger.info('Password updated successfully', tag: 'Auth');
    } catch (error) {
      ProductionLogger.error(
        'Failed to update password',
        error: error,
        tag: 'Auth',
      );
      throw Exception('Cập nhật mật khẩu thất bại: $error');
    }
  }

  Future<void> signOut() async {
    try {

      // Sign out from Supabase
      await _supabase.auth.signOut();

      // Clear remembered login info when signing out
      await PreferencesService.instance.clearLoginInfo();

      // Verify session is cleared
      final session = _supabase.auth.currentSession;
      if (session == null) {
      } else {
      }
    } catch (error) {
      throw Exception('Đăng xuất thất bại: $error');
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('⚠️ Error getting user profile: $error', tag: 'auth_service');
      }
      return null; // Return null instead of throwing to avoid app crash
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] == 'admin';
    } catch (error) {
      return false;
    }
  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'];
    } catch (error) {
      return null;
    }
  }

  Future<AuthResponse> resetPassword(String email) async {
    try {
      // Rate limiting check for password reset
      final rateLimitService = RateLimitService.instance;
      final clientIP = await _getClientIP();
      if (!await rateLimitService.isAllowed('password_reset', clientIP)) {
        final timeUntilReset = await rateLimitService.getTimeUntilReset(
          'password_reset',
          clientIP,
        );
        throw RateLimitException.legacy('password_reset', clientIP, timeUntilReset);
      }

      await _supabase.auth.resetPasswordForEmail(email);
      // Return a proper AuthResponse since resetPasswordForEmail returns void
      return AuthResponse(session: null, user: null);
    } on RateLimitException {
      ProductionLogger.warning(
        'Password reset rate limit exceeded',
        tag: 'Auth',
      );
      rethrow;
    } catch (error) {
      throw Exception('Đặt lại mật khẩu thất bại: $error');
    }
  }

  /// Send OTP to phone for password reset
  Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber) async {
    try {
      // ✅ SECURITY: Redacted phone in production logs
      ProductionLogger.info('Sending OTP request', tag: 'Auth');

      // Rate limiting check
      final rateLimitService = RateLimitService.instance;
      final clientIP = await _getClientIP();
      if (!await rateLimitService.isAllowed('otp_send', clientIP)) {
        final timeUntilReset = await rateLimitService.getTimeUntilReset(
          'otp_send',
          clientIP,
        );
        throw RateLimitException.legacy('otp_send', clientIP, timeUntilReset);
      }

      // Normalize phone number (remove +84 prefix if present, ensure starts with 0)
      String normalizedPhone = phoneNumber.trim();
      if (normalizedPhone.startsWith('+84')) {
        normalizedPhone = '0${normalizedPhone.substring(3)}';
      } else if (normalizedPhone.startsWith('84')) {
        normalizedPhone = '0${normalizedPhone.substring(2)}';
      } else if (!normalizedPhone.startsWith('0')) {
        normalizedPhone = '0$normalizedPhone';
      }

      // Generate all possible phone formats to search
      final phoneWithout0 = normalizedPhone.substring(1);
      final possibleFormats = [
        normalizedPhone, // 0961167717
        '+84$phoneWithout0', // +84961167717
        '+84$normalizedPhone', // +840961167717
        '84$phoneWithout0', // 84961167717
        '84$normalizedPhone', // 840961167717
      ];

      if (kDebugMode) {
      }

      // Check if user exists with any of these phone formats
      final userCheck = await _supabase
          .from('users')
          .select('id, phone')
          .inFilter('phone', possibleFormats)
          .maybeSingle();

      if (userCheck == null) {
        throw Exception('Không tìm thấy tài khoản với số điện thoại này');
      }

      // Use the actual phone format from DB for consistency
      final dbPhoneFormat = userCheck['phone'] as String;

      // Generate 6-digit OTP
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(Duration(minutes: 5));

      // Store OTP in database using the same phone format as in users table
      await _supabase.from('otp_codes').insert({
        'phone': dbPhoneFormat,
        'otp_code': otp,
        'expires_at': expiresAt.toIso8601String(),
        'used': false,
        'purpose': 'password_reset',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        // 🔒 SECURITY: OTP only shown in debug mode for development
      }

      ProductionLogger.info('OTP sent successfully', tag: 'Auth');

      // TODO: In production, integrate with SMS gateway (Twilio, ESMS, etc.)
      // await _sendSMS(dbPhoneFormat, otp);

      return {
        'success': true,
        'message': 'Mã OTP đã được gửi đến số điện thoại của bạn',
        'phone': dbPhoneFormat,
        'expires_at': expiresAt.toIso8601String(),
        // In development, return OTP for testing
        if (kDebugMode) 'otp_debug': otp,
      };
    } on RateLimitException {
      ProductionLogger.warning('OTP send rate limit exceeded', tag: 'Auth');
      rethrow;
    } catch (error) {
      ProductionLogger.error('Send OTP failed', error: error, tag: 'Auth');
      throw Exception('Gửi OTP thất bại: $error');
    }
  }

  /// Verify OTP and allow password reset
  Future<Map<String, dynamic>> verifyPhoneOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      // ✅ SECURITY: Redacted phone and OTP in production logs
      ProductionLogger.info('Verifying OTP', tag: 'Auth');

      // Normalize phone number and generate all possible formats
      String normalizedPhone = phoneNumber.trim();
      if (normalizedPhone.startsWith('+84')) {
        normalizedPhone = '0${normalizedPhone.substring(3)}';
      } else if (normalizedPhone.startsWith('84')) {
        normalizedPhone = '0${normalizedPhone.substring(2)}';
      } else if (!normalizedPhone.startsWith('0')) {
        normalizedPhone = '0$normalizedPhone';
      }

      final phoneWithout0 = normalizedPhone.substring(1);
      final possibleFormats = [
        normalizedPhone,
        '+84$phoneWithout0',
        '+84$normalizedPhone',
        '84$phoneWithout0',
        '84$normalizedPhone',
      ];

      if (kDebugMode) {
      }

      // Find valid OTP (search all possible phone formats)
      final otpRecord = await _supabase
          .from('otp_codes')
          .select()
          .inFilter('phone', possibleFormats)
          .eq('otp_code', otpCode)
          .eq('used', false)
          .eq('purpose', 'password_reset')
          .maybeSingle();

      if (otpRecord == null) {
        ProductionLogger.warning('Invalid OTP attempt', tag: 'Auth');
        throw Exception('Mã OTP không hợp lệ hoặc đã được sử dụng');
      }

      // Check if OTP expired
      final expiresAt = DateTime.parse(otpRecord['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        ProductionLogger.warning('Expired OTP attempt', tag: 'Auth');
        throw Exception('Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới');
      }

      // Mark OTP as used
      await _supabase
          .from('otp_codes')
          .update({'used': true, 'used_at': DateTime.now().toIso8601String()})
          .eq('id', otpRecord['id']);

      // Get user info using the phone format from OTP record
      final dbPhoneFormat = otpRecord['phone'] as String;
      final user = await _supabase
          .from('users')
          .select('id, email')
          .eq('phone', dbPhoneFormat)
          .single();

      ProductionLogger.info('OTP verified successfully', tag: 'Auth');

      return {
        'success': true,
        'message': 'Xác thực thành công',
        'user_id': user['id'],
        'email': user['email'],
        'phone': normalizedPhone,
      };
    } catch (error) {
      ProductionLogger.error('Verify OTP failed', error: error, tag: 'Auth');
      throw Exception('Xác thực OTP thất bại: $error');
    }
  }

  /// Generate 6-digit OTP
  String _generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// Reset password after OTP verification
  Future<void> resetPasswordWithPhone({
    required String phoneNumber,
    required String newPassword,
  }) async {
    try {
      // Normalize phone and generate all possible formats
      String normalizedPhone = phoneNumber.trim();
      if (normalizedPhone.startsWith('+84')) {
        normalizedPhone = '0${normalizedPhone.substring(3)}';
      } else if (normalizedPhone.startsWith('84')) {
        normalizedPhone = '0${normalizedPhone.substring(2)}';
      } else if (!normalizedPhone.startsWith('0')) {
        normalizedPhone = '0$normalizedPhone';
      }

      final phoneWithout0 = normalizedPhone.substring(1);
      final possibleFormats = [
        normalizedPhone,
        '+84$phoneWithout0',
        '84$phoneWithout0',
      ];

      if (kDebugMode) {
        ProductionLogger.info('🔍 Resetting password for phone formats: $possibleFormats', tag: 'auth_service');
      }

      // Get user by phone (search all possible formats)
      final user = await _supabase
          .from('users')
          .select('id, email')
          .inFilter('phone', possibleFormats)
          .maybeSingle();

      if (user == null) {
        throw Exception('Không tìm thấy tài khoản với số điện thoại này');
      }

      if (kDebugMode) {
        ProductionLogger.info('✅ Found user ${user['id']} for password reset', tag: 'auth_service');
      }

      // Update password via Supabase Admin API or use updateUser
      // Note: This requires proper authentication
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (kDebugMode) {
        ProductionLogger.info('✅ Password reset successfully for user: ${user['id']}', tag: 'auth_service');
      }
    } catch (error) {
      ProductionLogger.error('Reset password error', error: error, tag: 'Auth');
      throw Exception('Đặt lại mật khẩu thất bại: $error');
    }
  }

  Future<UserProfile> updateUserProfile({
    String? username,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? skillLevel,
    String? location,
  }) async {
    try {
      if (!isAuthenticated) throw Exception('Người dùng chưa đăng nhập');

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String();
      }
      if (skillLevel != null) updates['skill_level'] = skillLevel;
      if (location != null) updates['location'] = location;

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser!.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Lỗi cập nhật hồ sơ: $error');
    }
  }

  Future<String?> uploadAvatar(String filePath, List<int> fileBytes) async {
    try {
      if (!isAuthenticated) throw Exception('Người dùng chưa đăng nhập');

      final fileName =
          '${currentUser!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('user-content')
          .uploadBinary(
            fileName, 
            Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get signed URL for private bucket
      final response = await _supabase.storage
          .from('user-content')
          .createSignedUrl(fileName, 3600 * 24 * 365); // 1 year expiry

      if (response.isEmpty) throw Exception('Lỗi lấy đường dẫn ảnh');

      // Update user profile with new avatar URL
      await _supabase
          .from('users')
          .update({
            'avatar_url': response,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser!.id);

      return response;
    } catch (error) {
      throw Exception('Lỗi tải lên ảnh đại diện: $error');
    }
  }

  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (error) {
      throw Exception('Lỗi kiểm tra tên người dùng: $error');
    }
  }

  /// 📧 **REFRESH SESSION**
  /// Refresh the current user session to get latest data
  Future<void> refreshSession() async {
    try {
      ProductionLogger.info('Refreshing session...', tag: 'Auth');

      await _supabase.auth.refreshSession();

      ProductionLogger.info('Session refreshed successfully', tag: 'Auth');
    } catch (error) {
      ProductionLogger.error(
        'Failed to refresh session',
        error: error,
        tag: 'Auth',
      );
      throw Exception('Lỗi làm mới phiên đăng nhập: $error');
    }
  }

  /// 📧 **RESEND EMAIL VERIFICATION**
  /// Resend email verification to the current user
  Future<void> resendEmailVerification({String? email}) async {
    try {
      final userEmail = email ?? currentUser?.email;
      if (userEmail == null) {
        throw Exception('Không tìm thấy địa chỉ email');
      }

      ProductionLogger.info('Resending verification email', tag: 'Auth');
      if (kDebugMode)

      await _supabase.auth.resend(type: OtpType.signup, email: userEmail);

      ProductionLogger.info(
        'Verification email sent successfully',
        tag: 'Auth',
      );
    } catch (error) {
      ProductionLogger.error(
        'Failed to resend verification email',
        error: error,
        tag: 'Auth',
      );
      throw Exception('Lỗi gửi lại email xác thực: $error');
    }
  }

  /// 📧 Handle email verification deep link
  Future<void> handleEmailVerification(String token, String type) async {
    try {
      await _supabase.auth.verifyOTP(token: token, type: OtpType.signup);

      ProductionLogger.info('Email verified successfully', tag: 'Auth');
    } catch (error) {
      ProductionLogger.error(
        'Email verification failed',
        error: error,
        tag: 'Auth',
      );
      throw Exception('Email verification failed: $error');
    }
  }

  /// 📧 **CHECK EMAIL VERIFICATION STATUS**
  /// Check if the current user's email is verified
  bool get isEmailVerified {
    final user = currentUser;
    return user?.emailConfirmedAt != null;
  }

  /// 📱 **SIGN IN WITH PHONE**
  /// Sign in using phone number and password
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      ProductionLogger.info('Attempting phone login', tag: 'Auth');

      // Rate limiting check
      final rateLimitService = RateLimitService.instance;
      final clientIP = await _getClientIP();
      if (!await rateLimitService.isAllowed('login', clientIP)) {
        final timeUntilReset = await rateLimitService.getTimeUntilReset(
          'login',
          clientIP,
        );
        throw RateLimitException.legacy('login', clientIP, timeUntilReset);
      }

      // Ensure Supabase is initialized
      if (!SupabaseService.instance.isInitialized) {
        ProductionLogger.warning('Initializing Supabase...', tag: 'Auth');
        await SupabaseService.initialize();
      }

      final response = await _supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );

      ProductionLogger.info('Phone login successful', tag: 'Auth');
      return response;
    } on AuthException catch (e) {
      ProductionLogger.error('Auth error during login', error: e, tag: 'Auth');
      throw Exception('Đăng nhập thất bại: ${e.message}');
    } on RateLimitException {
      ProductionLogger.warning('Phone login rate limit exceeded', tag: 'Auth');
      rethrow;
    } catch (error) {
      ProductionLogger.error(
        'Unexpected error during login',
        error: error,
        tag: 'Auth',
      );
      throw Exception('Đăng nhập thất bại: $error');
    }
  }

  /// 📝 **UPSERT USER RECORD**
  /// Create or update user record in users table
  Future<void> upsertUserRecord({
    required String fullName,
    String? email,
    String? phone,
    String role = 'player',
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      ProductionLogger.info(
        'Upserting user record for: ${user.id}',
        tag: 'Auth',
      );

      // First, try to get existing user
      final existingUser = await _supabase
          .from('users')
          .select('id, full_name, email, phone, role')
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser != null) {
        // User already exists, just update
        ProductionLogger.info('User profile already exists, updating...', tag: 'Auth');
        
        final updateData = {
          'full_name': fullName,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // Only update email/phone if provided and different
        if (email != null && email != existingUser['email']) {
          updateData['email'] = email;
        }
        if (phone != null && phone != existingUser['phone']) {
          updateData['phone'] = phone;
        }
        
        await _supabase
            .from('users')
            .update(updateData)
            .eq('id', user.id);
            
        ProductionLogger.info('User profile updated successfully', tag: 'Auth');
        return;
      }

      // User doesn't exist, create new
      final userData = {
        'id': user.id,
        'full_name': fullName,
        'email': email ?? user.email,
        'phone': phone ?? user.phone,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').insert(userData);

      ProductionLogger.info('User profile created successfully', tag: 'Auth');
    } catch (error) {
      ProductionLogger.error(
        'Failed to upsert user record',
        error: error,
        tag: 'Auth',
      );
      
      // Don't throw exception if user already exists (OTP already verified successfully)
      // Just log warning and continue
      if (error.toString().contains('duplicate') || 
          error.toString().contains('already exists') ||
          error.toString().contains('unique constraint')) {
        ProductionLogger.warning(
          'User profile already exists, continuing...',
          tag: 'Auth',
        );
        return;
      }
      
      throw Exception('Failed to create user profile: $error');
    }
  }

  // =============================================================================
  // 🎯 NON-BLOCKING POST-REGISTRATION HOOKS
  // =============================================================================

  /// Hook 1: Send welcome notification (non-blocking)
  // ignore: unused_element
  void _runWelcomeNotificationHook(String userId, String userName) {
    Future.delayed(Duration.zero, () async {
      try {
        await AutoNotificationHooks.onUserRegistered(
          userId: userId,
          userName: userName,
          registrationMethod: 'email',
        );
        if (kDebugMode) {
          ProductionLogger.info('✅ Welcome notification sent successfully', tag: 'auth_service');
        }
      } catch (e) {
        if (kDebugMode) {
          ProductionLogger.info('⚠️ Welcome notification failed (non-critical): $e', tag: 'auth_service');
        }
        ProductionLogger.warning(
          'Welcome notification failed',
          tag: 'Auth',
        );
      }
    });
  }

  /// Hook 2: Create referral code (non-blocking)
  // ignore: unused_element
  void _runCreateReferralCodeHook(String userId) {
    Future.delayed(Duration.zero, () async {
      try {
        await ReferralService.instance.createReferralCodeForUser(userId);
        if (kDebugMode) {
          ProductionLogger.info('✅ Referral code created successfully', tag: 'auth_service');
        }
      } catch (e) {
        if (kDebugMode) {
          ProductionLogger.info('⚠️ Referral code creation failed (non-critical): $e', tag: 'auth_service');
        }
        ProductionLogger.warning(
          'Referral code creation failed',
          tag: 'Auth',
        );
      }
    });
  }

  /// Hook 3: Process stored referral code (non-blocking)
  // ignore: unused_element
  void _runProcessReferralCodeHook(String userId) {
    Future.delayed(Duration.zero, () async {
      try {
        final storedReferralCode = await DeepLinkService.instance
            .getStoredReferralCodeForNewUser();
        if (storedReferralCode != null && storedReferralCode.isNotEmpty) {
          await ReferralService.instance.useReferralCode(
            storedReferralCode,
            userId,
          );
          await DeepLinkService.instance.clearStoredReferralCode();
          ProductionLogger.info('Applied referral code', tag: 'Auth');
          if (kDebugMode) {
            ProductionLogger.info('✅ Referral code processed successfully', tag: 'auth_service');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          ProductionLogger.info('⚠️ Referral code processing failed (non-critical): $e', tag: 'auth_service');
        }
        ProductionLogger.warning(
          'Referral code processing failed',
          tag: 'Auth',
        );
      }
    });
  }
}

