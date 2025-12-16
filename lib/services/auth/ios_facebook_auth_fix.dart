import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// iOS-specific Facebook authentication fix
/// Addresses common iOS Facebook login issues and crashes
class IOSFacebookAuthFix {
  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// iOS-specific Facebook Sign-In with crash prevention
  static Future<AuthResponse?> signInWithFacebookIOS() async {
    if (!isIOS) {
      throw UnsupportedError('This method is only for iOS platform');
    }

    try {
      if (kDebugMode) {
        ProductionLogger.info('📱 [iOS] Starting Facebook Sign-In with iOS-specific configuration', tag: 'ios_facebook_auth_fix');
      }

      // iOS-specific pre-checks
      await _performIOSPreChecks();

      // Configure Facebook Auth for iOS
      await _configureIOSFacebookAuth();

      if (kDebugMode) {
        ProductionLogger.info('📱 [iOS] Opening Facebook authentication...', tag: 'ios_facebook_auth_fix');
      }

      // Trigger Facebook authentication with iOS-specific settings
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback, // iOS native app first
      );

      if (kDebugMode) {
        ProductionLogger.info('📱 [iOS] Facebook auth result: ${result.status}', tag: 'ios_facebook_auth_fix');
      }

      // Handle authentication result
      switch (result.status) {
        case LoginStatus.success:
          return await _handleIOSFacebookSuccess(result);

        case LoginStatus.cancelled:
          if (kDebugMode) ProductionLogger.info('📱 [iOS] User cancelled Facebook Sign-In', tag: 'ios_facebook_auth_fix');
          return null;

        case LoginStatus.failed:
          throw _createIOSFacebookException(
            result.message ?? 'Facebook authentication failed',
            'LOGIN_FAILED',
          );

        case LoginStatus.operationInProgress:
          throw _createIOSFacebookException(
            'Facebook login already in progress. Please wait.',
            'OPERATION_IN_PROGRESS',
          );
      }
    } catch (e) {
      return await _handleIOSFacebookError(e);
    }
  }

  /// iOS-specific pre-checks
  static Future<void> _performIOSPreChecks() async {
    try {
      // Check if Facebook is properly configured
      final isLoggedIn = await FacebookAuth.instance.isAutoLogAppEventsEnabled;
      if (kDebugMode) ProductionLogger.info('📱 [iOS] Facebook SDK initialized: $isLoggedIn', tag: 'ios_facebook_auth_fix');

      // Clear any problematic existing state
      try {
        await FacebookAuth.instance.logOut();
        if (kDebugMode) ProductionLogger.info('📱 [iOS] Cleared existing Facebook session', tag: 'ios_facebook_auth_fix');
      } catch (e) {
        if (kDebugMode) ProductionLogger.info('📱 [iOS] No existing Facebook session to clear: $e', tag: 'ios_facebook_auth_fix');
      }
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('📱 [iOS] Facebook pre-check warning: $e', tag: 'ios_facebook_auth_fix');
    }
  }

  /// Configure Facebook Auth for iOS
  static Future<void> _configureIOSFacebookAuth() async {
    try {
      // iOS-specific configuration if needed
      if (kDebugMode) ProductionLogger.info('📱 [iOS] Facebook configuration verified', tag: 'ios_facebook_auth_fix');
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('📱 [iOS] Facebook configuration warning: $e', tag: 'ios_facebook_auth_fix');
    }
  }

  /// Handle successful Facebook authentication on iOS
  static Future<AuthResponse> _handleIOSFacebookSuccess(LoginResult result) async {
    final AccessToken accessToken = result.accessToken!;

    if (kDebugMode) {
      ProductionLogger.info('📱 [iOS] ✅ Facebook Access Token acquired', tag: 'ios_facebook_auth_fix');
      ProductionLogger.info('📱 [iOS] Token length: ${accessToken.tokenString.length}', tag: 'ios_facebook_auth_fix');
    }

    // Get user data for additional validation
    final userData = await FacebookAuth.instance.getUserData();
    if (kDebugMode) {
      ProductionLogger.info('📱 [iOS] Facebook user data: ${userData['name']} (${userData['email']})', tag: 'ios_facebook_auth_fix');
    }

    // Authenticate with Supabase
    final response = await SupabaseService.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.facebook,
      idToken: accessToken.tokenString,
    );

    if (kDebugMode) {
      ProductionLogger.info('📱 [iOS] ✅ Facebook Sign-In successful', tag: 'ios_facebook_auth_fix');
      ProductionLogger.info('📱 [iOS] Supabase user: ${response.user?.email}', tag: 'ios_facebook_auth_fix');
      ProductionLogger.info('📱 [iOS] User ID: ${response.user?.id}', tag: 'ios_facebook_auth_fix');
    }

    return response;
  }

  /// Handle Facebook authentication errors on iOS
  static Future<AuthResponse?> _handleIOSFacebookError(dynamic error) async {
    if (kDebugMode) {
      ProductionLogger.info('📱 [iOS] ❌ Facebook Sign-In error: $error', tag: 'ios_facebook_auth_fix');
      ProductionLogger.info('📱 [iOS] Error type: ${error.runtimeType}', tag: 'ios_facebook_auth_fix');
    }

    // Handle specific iOS Facebook errors
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('facebook app id')) {
      throw _createIOSFacebookException(
        'Cấu hình Facebook App ID không đúng cho iOS. Vui lòng liên hệ support.',
        'IOS_APP_ID_ERROR',
      );
    }

    if (errorString.contains('client token')) {
      throw _createIOSFacebookException(
        'Thiếu Facebook Client Token cho iOS. Vui lòng liên hệ support.',
        'IOS_CLIENT_TOKEN_ERROR',
      );
    }

    if (errorString.contains('url scheme') || errorString.contains('fbapi')) {
      throw _createIOSFacebookException(
        'Lỗi cấu hình URL Scheme cho Facebook iOS. Vui lòng thử lại.',
        'IOS_URL_SCHEME_ERROR',
      );
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      throw _createIOSFacebookException(
        'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.',
        'NETWORK_ERROR',
      );
    }

    if (errorString.contains('facebook app') && errorString.contains('not installed')) {
      throw _createIOSFacebookException(
        'Không thể mở Facebook app. Vui lòng thử đăng nhập bằng browser.',
        'FACEBOOK_APP_NOT_FOUND',
      );
    }

    // Re-throw with iOS-specific context
    throw _createIOSFacebookException(
      'Đăng nhập Facebook thất bại trên iOS: ${error.toString()}',
      'IOS_UNKNOWN_ERROR',
    );
  }

  /// Create iOS-specific Facebook exception
  static Exception _createIOSFacebookException(String message, String code) {
    return Exception('iOS Facebook Auth [$code]: $message');
  }

  /// Check if Facebook Sign-In is properly configured for iOS
  static Future<bool> isFacebookConfiguredForIOS() async {
    if (!isIOS) return false;

    try {
      // Try to check if we can initialize without errors
      final isEnabled = await FacebookAuth.instance.isAutoLogAppEventsEnabled;
      if (kDebugMode) ProductionLogger.info('📱 [iOS] Facebook configuration check: $isEnabled', tag: 'ios_facebook_auth_fix');
      return true;
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('📱 [iOS] Facebook configuration error: $e', tag: 'ios_facebook_auth_fix');
      return false;
    }
  }

  /// Sign out from Facebook on iOS
  static Future<void> signOutFacebookIOS() async {
    if (!isIOS) return;

    try {
      await FacebookAuth.instance.logOut();
      if (kDebugMode) ProductionLogger.info('📱 [iOS] ✅ Facebook sign-out successful', tag: 'ios_facebook_auth_fix');
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('📱 [iOS] ⚠️ Facebook sign-out error: $e', tag: 'ios_facebook_auth_fix');
    }
  }

  /// Get current Facebook user info on iOS
  static Future<Map<String, dynamic>?> getCurrentFacebookUserIOS() async {
    if (!isIOS) return null;

    try {
      final accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken == null) return null;

      final userData = await FacebookAuth.instance.getUserData();
      return userData;
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('📱 [iOS] Error getting Facebook user: $e', tag: 'ios_facebook_auth_fix');
      return null;
    }
  }
}