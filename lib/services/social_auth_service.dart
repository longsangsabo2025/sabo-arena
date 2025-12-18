import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// Custom exception for social authentication errors
class SocialAuthException implements Exception {
  final String message;
  final String provider;
  final String? code;

  SocialAuthException(this.message, this.provider, [this.code]);

  @override
  String toString() => 'SocialAuthException($provider): $message';
}

/// Comprehensive social authentication service supporting web and mobile platforms
/// Handles Google, Facebook, and Apple Sign-In with proper fallback strategies
class SocialAuthService {
  static final SocialAuthService _instance = SocialAuthService._internal();
  factory SocialAuthService() => _instance;
  SocialAuthService._internal();

  /// Google Sign-In configuration with NATIVE APP priority
  /// This will open Gmail/Google app instead of web browser
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    hostedDomain: '', // Leave empty for all domains
    // 🔥 NO serverClientId = Native app login (Gmail app opens)
    // This ensures Android/iOS opens the native Google Sign-In UI
    // NOT the web browser popup
  );

  /// Check if a social provider is supported on current platform
  bool isProviderSupported(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return true; // Supported on all platforms when properly configured
      case 'facebook':
        return true; // Supported on all platforms when properly configured
      case 'apple':
        if (kIsWeb) return false;
        return Platform.isIOS || Platform.isMacOS;
      default:
        return false;
    }
  }

  /// Get platform-specific limitation message for unsupported providers
  String getProviderLimitationMessage(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return kIsWeb
            ? 'Google Sign-In đang được cấu hình cho web. Vui lòng sử dụng email để đăng nhập.'
            : 'Google Sign-In chưa sẵn sàng. Vui lòng thử lại sau.';
      case 'facebook':
        return kIsWeb
            ? 'Facebook Login đang được cấu hình cho web. Vui lòng sử dụng email để đăng nhập.'
            : 'Facebook Login chưa sẵn sàng. Vui lòng thử lại sau.';
      case 'apple':
        return kIsWeb
            ? 'Apple Sign-In chỉ khả dụng trên thiết bị iOS/macOS. Vui lòng sử dụng email để đăng nhập.'
            : 'Apple Sign-In chưa sẵn sàng trên thiết bị này.';
      default:
        return 'Phương thức đăng nhập này chưa được hỗ trợ.';
    }
  }

  /// Sign in with Google - Cross-platform implementation
  /// Opens NATIVE Gmail/Google app on mobile devices
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      ProductionLogger.auth('🚀 Starting Google Sign-In (NATIVE mode)');
      ProductionLogger.info(
        'Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}',
        tag: 'GoogleAuth',
      );

      // Platform-specific pre-checks
      if (!kIsWeb && Platform.isAndroid) {
        // Check Google Play Services availability on Android
        try {
          final isSignedIn = await _googleSignIn.isSignedIn();
          ProductionLogger.debug(
            '📱 Google Play Services available: $isSignedIn',
            tag: 'GoogleAuth',
          );
        } catch (e) {
          ProductionLogger.warning(
            '⚠️ Google Play Services check: $e',
            tag: 'GoogleAuth',
          );
        }
      }

      ProductionLogger.auth('📱 Opening native Google Sign-In UI...');

      // Trigger authentication flow - This opens NATIVE app
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        ProductionLogger.auth('❌ User cancelled Google Sign-In');
        return null; // User canceled
      }

      ProductionLogger.auth('✅ User selected account: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        ProductionLogger.error(
          'No ID Token received from Google',
          tag: 'GoogleAuth',
        );
        throw SocialAuthException(
          'Không thể xác thực với Google. Vui lòng thử lại.',
          'google',
          'NO_ID_TOKEN',
        );
      }

      ProductionLogger.auth('✅ Google ID Token acquired');
      ProductionLogger.network('POST', 'Supabase signInWithIdToken (Google)');

      // Authenticate with Supabase
      final response = await SupabaseService.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken,
          );

      ProductionLogger.auth(
        '✅ Google Sign-In SUCCESS',
        details: response.user?.email ?? 'No email',
      );
      ProductionLogger.network(
        'POST',
        'Supabase signInWithIdToken (Google)',
        statusCode: 200,
      );

      return response;
    } on SocialAuthException {
      rethrow; // Re-throw our custom exceptions
    } catch (e, stackTrace) {
      ProductionLogger.error(
        '💥 Google Sign-In error',
        error: e,
        stackTrace: stackTrace,
        tag: 'GoogleAuth',
      );
      ProductionLogger.network(
        'POST',
        'Supabase signInWithIdToken (Google)',
        error: e.toString(),
      );

      // Handle specific error cases
      if (e.toString().contains('YOUR_GOOGLE_WEB_CLIENT_ID')) {
        throw SocialAuthException(
          'Google Sign-In chưa được cấu hình đúng. Vui lòng liên hệ support.',
          'google',
          'CONFIG_ERROR',
        );
      }

      throw SocialAuthException(
        'Đăng nhập Google thất bại. Vui lòng thử lại.',
        'google',
      );
    }
  }

  /// Sign in with Facebook - Cross-platform implementation
  /// Opens NATIVE Facebook app on mobile devices
  Future<AuthResponse?> signInWithFacebook() async {
    try {
      ProductionLogger.auth('🚀 Starting Facebook Sign-In (NATIVE mode)');
      ProductionLogger.info(
        'Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}',
        tag: 'FacebookAuth',
      );

      // Web platform check - Facebook for web needs special configuration
      if (kIsWeb) {
        throw SocialAuthException(
          'Facebook Login đang được cấu hình cho web. Vui lòng sử dụng email để đăng nhập.',
          'facebook',
          'WEB_NOT_CONFIGURED',
        );
      }

      ProductionLogger.auth('📱 Opening native Facebook app...');

      // Trigger Facebook authentication with NATIVE APP priority
      // This opens Facebook app instead of web browser
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior
            .nativeWithFallback, // ← Opens FB app first, web if not installed
      );

      // Handle authentication result
      switch (result.status) {
        case LoginStatus.success:
          final AccessToken accessToken = result.accessToken!;

          ProductionLogger.auth('✅ Facebook Access Token acquired');
          ProductionLogger.network(
            'POST',
            'Supabase signInWithIdToken (Facebook)',
          );

          // Authenticate with Supabase
          final response = await SupabaseService.instance.client.auth
              .signInWithIdToken(
                provider: OAuthProvider.facebook,
                idToken: accessToken.tokenString,
              );

          ProductionLogger.auth(
            '✅ Facebook Sign-In SUCCESS',
            details: response.user?.email ?? 'No email',
          );
          ProductionLogger.network(
            'POST',
            'Supabase signInWithIdToken (Facebook)',
            statusCode: 200,
          );

          return response;

        case LoginStatus.cancelled:
          ProductionLogger.auth('❌ User cancelled Facebook Sign-In');
          return null; // User canceled

        case LoginStatus.failed:
          ProductionLogger.error(
            'Facebook login failed: ${result.message}',
            tag: 'FacebookAuth',
          );
          throw SocialAuthException(
            result.message ?? 'Đăng nhập Facebook thất bại',
            'facebook',
            'LOGIN_FAILED',
          );

        case LoginStatus.operationInProgress:
          ProductionLogger.warning(
            'Facebook login already in progress',
            tag: 'FacebookAuth',
          );
          throw SocialAuthException(
            'Đăng nhập Facebook đang xử lý. Vui lòng đợi.',
            'facebook',
            'OPERATION_IN_PROGRESS',
          );
      }
    } on SocialAuthException {
      rethrow; // Re-throw our custom exceptions
    } catch (e, stackTrace) {
      ProductionLogger.error(
        '💥 Facebook Sign-In error',
        error: e,
        stackTrace: stackTrace,
        tag: 'FacebookAuth',
      );
      ProductionLogger.network(
        'POST',
        'Supabase signInWithIdToken (Facebook)',
        error: e.toString(),
      );
      throw SocialAuthException(
        'Đăng nhập Facebook thất bại. Vui lòng thử lại.',
        'facebook',
      );
    }
  }

  /// Sign in with Apple - iOS/macOS only implementation
  Future<AuthResponse?> signInWithApple() async {
    try {
      if (kDebugMode) {
        ProductionLogger.info('🚀 Attempting Apple Sign-In on ${kIsWeb ? "web" : "mobile"}', tag: 'social_auth_service');
      }

      // Platform compatibility checks
      if (kIsWeb) {
        throw SocialAuthException(
          'Apple Sign-In chỉ khả dụng trên thiết bị iOS/macOS. Vui lòng sử dụng email để đăng nhập.',
          'apple',
          'WEB_NOT_SUPPORTED',
        );
      }

      if (!Platform.isIOS && !Platform.isMacOS) {
        throw SocialAuthException(
          'Apple Sign-In chỉ khả dụng trên thiết bị iOS/macOS.',
          'apple',
          'PLATFORM_NOT_SUPPORTED',
        );
      }

      // Check device availability
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw SocialAuthException(
          'Apple Sign-In không khả dụng trên thiết bị này.',
          'apple',
          'DEVICE_NOT_SUPPORTED',
        );
      }

      // Request Apple ID credential
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        throw SocialAuthException(
          'Không thể xác thực với Apple. Vui lòng thử lại.',
          'apple',
          'NO_IDENTITY_TOKEN',
        );
      }

      if (kDebugMode) ProductionLogger.info('✅ Apple Identity Token acquired', tag: 'social_auth_service');

      // Authenticate with Supabase
      final response = await SupabaseService.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: credential.identityToken!,
          );

      if (kDebugMode) {
        ProductionLogger.info('✅ Apple Sign-In successful: ${response.user?.email}', tag: 'social_auth_service');
      }

      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        if (kDebugMode) ProductionLogger.info('❌ User cancelled Apple Sign-In', tag: 'social_auth_service');
        return null; // User canceled
      }

      if (kDebugMode) ProductionLogger.info('💥 Apple authorization error: ${e.message}', tag: 'social_auth_service');
      throw SocialAuthException(e.message, 'apple', e.code.toString());
    } on PlatformException catch (e) {
      if (kDebugMode) ProductionLogger.info('💥 Apple platform error: ${e.message}', tag: 'social_auth_service');
      throw SocialAuthException(
        e.message ?? 'Lỗi hệ thống Apple Sign-In',
        'apple',
        e.code,
      );
    } on SocialAuthException {
      rethrow; // Re-throw our custom exceptions
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('💥 Apple Sign-In error: $e', tag: 'social_auth_service');
      throw SocialAuthException(
        'Đăng nhập Apple thất bại. Vui lòng thử lại.',
        'apple',
      );
    }
  }

  /// Sign out from all social providers
  Future<void> signOutFromAllProviders() async {
    try {
      if (kDebugMode) ProductionLogger.info('🚪 Signing out from all social providers', tag: 'social_auth_service');

      // Sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        if (kDebugMode) ProductionLogger.info('✅ Signed out from Google', tag: 'social_auth_service');
      }

      // Sign out from Facebook (only on mobile)
      if (!kIsWeb) {
        await FacebookAuth.instance.logOut();
        if (kDebugMode) ProductionLogger.info('✅ Signed out from Facebook', tag: 'social_auth_service');
      }

      // Apple Sign-In doesn't require explicit sign out
      // User credentials are managed by iOS system

      if (kDebugMode) ProductionLogger.info('✅ Signed out from all social providers', tag: 'social_auth_service');
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('⚠️ Error during social sign out: $e', tag: 'social_auth_service');
      // Don't throw - sign out should be best effort
    }
  }

  /// Get current Google user information
  GoogleSignInAccount? get currentGoogleUser => _googleSignIn.currentUser;

  /// Check if user is currently signed in with Google
  Future<bool> isSignedInWithGoogle() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('Error checking Google sign-in status: $e', tag: 'social_auth_service');
      return false;
    }
  }

  /// Check if Apple Sign-In is available on current device
  static Future<bool> isAppleSignInAvailable() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
      return false;
    }

    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('Error checking Apple Sign-In availability: $e', tag: 'social_auth_service');
      return false;
    }
  }
}
