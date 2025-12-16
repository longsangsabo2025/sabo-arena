import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Simplified authentication service for debugging email registration issues
class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  static SimpleAuthService get instance => _instance;

  /// Get Supabase client
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Simple email registration without complex features
  Future<AuthResponse> signUpWithEmailSimple({
    required String email,
    required String password,
    required String fullName,
    String role = 'player',
  }) async {
    try {
      if (kDebugMode) {
        ProductionLogger.info('🔐 [SimpleAuth] Starting email registration...', tag: 'simple_auth_service');
        ProductionLogger.info('📧 Email: $email', tag: 'simple_auth_service');
        ProductionLogger.info('👤 Name: $fullName', tag: 'simple_auth_service');
        ProductionLogger.info('🎭 Role: $role', tag: 'simple_auth_service');
      }

      // Direct Supabase call without rate limiting or hooks
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'display_name': fullName,
        },
      );

      if (kDebugMode) {
        ProductionLogger.info('✅ [SimpleAuth] Registration response received', tag: 'simple_auth_service');
        ProductionLogger.info('🆔 User ID: ${response.user?.id ?? 'null'}', tag: 'simple_auth_service');
        ProductionLogger.info('📧 User Email: ${response.user?.email ?? 'null'}', tag: 'simple_auth_service');
        ProductionLogger.info('✉️ Email Confirmed: ${response.user?.emailConfirmedAt ?? 'Not confirmed'}', tag: 'simple_auth_service');
        ProductionLogger.info('🔐 Session: ${response.session != null ? 'Created' : 'No session'}', tag: 'simple_auth_service');
      }

      return response;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        ProductionLogger.info('❌ [SimpleAuth] Registration failed: $error', tag: 'simple_auth_service');
        ProductionLogger.info('📊 Error type: ${error.runtimeType}', tag: 'simple_auth_service');
        ProductionLogger.info('🔍 Stack trace: $stackTrace', tag: 'simple_auth_service');
      }

      // Handle specific Supabase errors
      if (error is AuthException) {
        final authError = error;
        if (kDebugMode) {
          ProductionLogger.info('🔐 Auth error details:', tag: 'simple_auth_service');
          ProductionLogger.info('   Message: ${authError.message}', tag: 'simple_auth_service');
          ProductionLogger.info('   Status Code: ${authError.statusCode}', tag: 'simple_auth_service');
        }

        // User-friendly error messages
        if (authError.message.contains('already registered')) {
          throw Exception('Email này đã được sử dụng. Vui lòng sử dụng email khác hoặc đăng nhập.');
        }
        
        if (authError.message.contains('invalid email')) {
          throw Exception('Email không hợp lệ. Vui lòng kiểm tra lại.');
        }
        
        if (authError.message.contains('weak password')) {
          throw Exception('Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.');
        }

        if (authError.message.contains('Database error')) {
          throw Exception('Lỗi cơ sở dữ liệu. Vui lòng thử lại sau hoặc liên hệ support.');
        }

        throw Exception('Đăng ký thất bại: ${authError.message}');
      }

      // Generic error handling
      throw Exception('Lỗi đăng ký: ${error.toString()}');
    }
  }

  /// Simple email login without complex features
  Future<AuthResponse> signInWithEmailSimple({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        ProductionLogger.info('🔐 [SimpleAuth] Starting email login...', tag: 'simple_auth_service');
        ProductionLogger.info('📧 Email: $email', tag: 'simple_auth_service');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        ProductionLogger.info('✅ [SimpleAuth] Login successful', tag: 'simple_auth_service');
        ProductionLogger.info('🆔 User ID: ${response.user?.id}', tag: 'simple_auth_service');
        ProductionLogger.info('📧 User Email: ${response.user?.email}', tag: 'simple_auth_service');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('❌ [SimpleAuth] Login failed: $error', tag: 'simple_auth_service');
      }

      if (error is AuthException) {
        final authError = error;
        
        if (authError.message.contains('Invalid login')) {
          throw Exception('Email hoặc mật khẩu không đúng.');
        }
        
        if (authError.message.contains('Email not confirmed')) {
          throw Exception('Vui lòng xác nhận email trước khi đăng nhập.');
        }

        throw Exception('Đăng nhập thất bại: ${authError.message}');
      }

      throw Exception('Lỗi đăng nhập: ${error.toString()}');
    }
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      if (kDebugMode) ProductionLogger.info('✅ [SimpleAuth] Signed out successfully', tag: 'simple_auth_service');
    } catch (error) {
      if (kDebugMode) ProductionLogger.info('❌ [SimpleAuth] Sign out error: $error', tag: 'simple_auth_service');
      throw Exception('Lỗi đăng xuất: $error');
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Resend email confirmation
  Future<void> resendEmailConfirmation(String email) async {
    try {
      if (kDebugMode) {
        ProductionLogger.info('📧 [SimpleAuth] Resending email confirmation to: $email', tag: 'simple_auth_service');
      }

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      if (kDebugMode) {
        ProductionLogger.info('✅ [SimpleAuth] Email confirmation resent', tag: 'simple_auth_service');
      }
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('❌ [SimpleAuth] Resend email error: $error', tag: 'simple_auth_service');
      }
      throw Exception('Lỗi gửi lại email xác nhận: $error');
    }
  }
}