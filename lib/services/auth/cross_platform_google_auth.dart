// =============================================
// 🌐 CROSS-PLATFORM GOOGLE AUTHENTICATION
// =============================================
// Universal Google Sign-In service for iOS, Android, and Web
// Handles platform-specific OAuth client IDs automatically
// Created: 2025-01-16

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class CrossPlatformGoogleAuth {
  
  // Platform-specific Google OAuth Client IDs
  static const String _iosClientId = '930620766039-8e22o5kk0vl82vpq2uj2drlojbfgtvts.apps.googleusercontent.com';
  static const String _androidClientId = '930620766039-e6h7oqtm3rnp4dsfh0fqn7jkh9vsfgq6.apps.googleusercontent.com';
  static const String _webClientId = '930620766039-dv2u7ajkpb3lugbp9djg8s5gtko7iupb.apps.googleusercontent.com';

  /// Get the appropriate client ID for the current platform
  static String getClientId() {
    if (kIsWeb) {
      return _webClientId;
    } else if (Platform.isIOS) {
      return _iosClientId;
    } else if (Platform.isAndroid) {
      return _androidClientId;
    }
    throw UnsupportedError('Platform not supported');
  }

  /// Get platform name for logging
  static String getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Unknown';
  }

  /// Sign in with Google using platform-appropriate client ID
  static Future<AuthResponse> signInWithGoogle() async {
    try {
      ProductionLogger.info('🚀 [CrossPlatformAuth] Starting Google Sign-In for ${getPlatformName()}', tag: 'cross_platform_google_auth');
      
      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? null : getClientId(), // Web uses client ID from HTML meta tag
        scopes: ['email', 'profile', 'openid'],
      );

      // Sign in to Google
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      
      if (account == null) {
        throw Exception('Google Sign-In was cancelled by user');
      }

      ProductionLogger.info('✅ [CrossPlatformAuth] Google account: ${account.email}', tag: 'cross_platform_google_auth');

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await account.authentication;
      
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      ProductionLogger.info('🔑 [CrossPlatformAuth] Tokens retrieved, authenticating with Supabase...', tag: 'cross_platform_google_auth');

      // Authenticate with Supabase
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        ProductionLogger.info('✅ [CrossPlatformAuth] Authentication successful!', tag: 'cross_platform_google_auth');
        ProductionLogger.info('👤 User: ${response.user!.email}', tag: 'cross_platform_google_auth');
        return response;
      } else {
        throw Exception('Supabase authentication failed');
      }

    } catch (e) {
      ProductionLogger.info('❌ [CrossPlatformAuth] Error: $e', tag: 'cross_platform_google_auth');
      rethrow;
    }
  }

  /// Sign out from both Google and Supabase
  static Future<void> signOut() async {
    try {
      ProductionLogger.info('🔐 [CrossPlatformAuth] Signing out...', tag: 'cross_platform_google_auth');
      
      // Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? null : getClientId(),
      );
      await googleSignIn.signOut();
      
      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();
      
      ProductionLogger.info('✅ [CrossPlatformAuth] Sign-out successful', tag: 'cross_platform_google_auth');
    } catch (e) {
      ProductionLogger.info('❌ [CrossPlatformAuth] Sign-out error: $e', tag: 'cross_platform_google_auth');
      rethrow;
    }
  }

  /// Check if user is currently signed in
  static User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }

  /// Get current platform info for debugging
  static Map<String, String> getPlatformInfo() {
    return {
      'platform': getPlatformName(),
      'clientId': getClientId(),
      'isWeb': kIsWeb.toString(),
      'isIOS': (!kIsWeb && Platform.isIOS).toString(),
      'isAndroid': (!kIsWeb && Platform.isAndroid).toString(),
    };
  }
}