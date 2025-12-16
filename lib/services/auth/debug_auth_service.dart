import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../supabase_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// DEBUG Auth Service - Bypass all hooks for testing email registration
class DebugAuthService {
  static DebugAuthService? _instance;
  static DebugAuthService get instance => _instance ??= DebugAuthService._();
  DebugAuthService._();

  SupabaseClient get _supabase {
    try {
      return SupabaseService.instance.client;
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('⚠️ DebugAuthService: Supabase client not ready - $e', tag: 'debug_auth_service');
      throw Exception('Authentication service not available. Please restart the app.');
    }
  }

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Simple email registration without hooks
  Future<AuthResponse> signUpWithEmailDebug({
    required String email,
    required String password,
    required String fullName,
    String role = 'player',
  }) async {
    try {
      if (kDebugMode) {
        ProductionLogger.info('🐛 DEBUG: Starting simple email registration', tag: 'debug_auth_service');
        ProductionLogger.info('   Email: $email', tag: 'debug_auth_service');
        ProductionLogger.info('   Name: $fullName', tag: 'debug_auth_service'); 
        ProductionLogger.info('   Role: $role', tag: 'debug_auth_service');
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

      if (kDebugMode) {
        ProductionLogger.info('✅ DEBUG: Registration response received', tag: 'debug_auth_service');
        ProductionLogger.info('   User ID: ${response.user?.id}', tag: 'debug_auth_service');
        ProductionLogger.info('   Session: ${response.session != null ? 'Yes' : 'No'}', tag: 'debug_auth_service');
      }

      // 🚫 NO HOOKS - Skip all post-registration hooks for debugging
      if (kDebugMode) {
        ProductionLogger.info('🚫 DEBUG: Skipping all hooks (AutoNotificationHooks, ReferralService, etc.)', tag: 'debug_auth_service');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('❌ DEBUG: Registration failed: $error', tag: 'debug_auth_service');
      }
      throw Exception('Sign up failed: $error');
    }
  }

  /// Simple sign in without hooks
  Future<AuthResponse> signInWithEmailDebug({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        ProductionLogger.info('🐛 DEBUG: Starting simple email sign in', tag: 'debug_auth_service');
        ProductionLogger.info('   Email: $email', tag: 'debug_auth_service');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        ProductionLogger.info('✅ DEBUG: Sign in successful', tag: 'debug_auth_service');
        ProductionLogger.info('   User ID: ${response.user?.id}', tag: 'debug_auth_service');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('❌ DEBUG: Sign in failed: $error', tag: 'debug_auth_service');
      }
      throw Exception('Đăng nhập thất bại: $error');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      if (kDebugMode) ProductionLogger.info('✅ DEBUG: Sign out successful', tag: 'debug_auth_service');
    } catch (error) {
      if (kDebugMode) ProductionLogger.info('❌ DEBUG: Sign out failed: $error', tag: 'debug_auth_service');
      throw Exception('Đăng xuất thất bại: $error');
    }
  }
}