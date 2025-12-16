import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// iOS-specific Google Sign-In fix
/// Addresses common iOS Google Sign-In crash issues
class IOSGoogleSignInFix {
  /// iOS-specific Google Sign-In instance with proper configuration
  static final GoogleSignIn _iosGoogleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Remove serverClientId for iOS to use native configuration
    // iOS will read client ID from GoogleService-Info.plist
  );

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// iOS-specific Google Sign-In with crash prevention
  static Future<AuthResponse?> signInWithGoogleIOS() async {
    if (!isIOS) {
      throw UnsupportedError('This method is only for iOS platform');
    }

    try {
      if (kDebugMode) {
        ProductionLogger.info('🍎 [iOS] Starting Google Sign-In with iOS-specific configuration', tag: 'ios_google_signin_fix');
      }

      // Clear any existing sign-in state to prevent conflicts
      try {
        await _iosGoogleSignIn.signOut();
        if (kDebugMode) ProductionLogger.info('🍎 [iOS] Cleared existing Google sign-in state', tag: 'ios_google_signin_fix');
      } catch (e) {
        if (kDebugMode) ProductionLogger.info('🍎 [iOS] No existing session to clear: $e', tag: 'ios_google_signin_fix');
      }

      // Perform sign-in with iOS-specific handling
      final GoogleSignInAccount? googleUser = await _iosGoogleSignIn.signIn();

      if (googleUser == null) {
        if (kDebugMode) ProductionLogger.info('🍎 [iOS] User cancelled Google Sign-In', tag: 'ios_google_signin_fix');
        return null;
      }

      if (kDebugMode) {
        ProductionLogger.info('🍎 [iOS] Google user acquired: ${googleUser.email}', tag: 'ios_google_signin_fix');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Google ID Token is null - check iOS configuration');
      }

      if (kDebugMode) {
        ProductionLogger.info('🍎 [iOS] Google auth tokens acquired', tag: 'ios_google_signin_fix');
        ProductionLogger.info('🍎 [iOS] ID Token length: ${googleAuth.idToken?.length ?? 0}', tag: 'ios_google_signin_fix');
        ProductionLogger.info('🍎 [iOS] Access Token length: ${googleAuth.accessToken?.length ?? 0}', tag: 'ios_google_signin_fix');
      }

      // Authenticate with Supabase
      final response = await SupabaseService.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (kDebugMode) {
        ProductionLogger.info('🍎 [iOS] ✅ Google Sign-In successful', tag: 'ios_google_signin_fix');
        ProductionLogger.info('🍎 [iOS] User email: ${response.user?.email}', tag: 'ios_google_signin_fix');
        ProductionLogger.info('🍎 [iOS] User ID: ${response.user?.id}', tag: 'ios_google_signin_fix');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('🍎 [iOS] ❌ Google Sign-In error: $e', tag: 'ios_google_signin_fix');
        ProductionLogger.info('🍎 [iOS] Error type: ${e.runtimeType}', tag: 'ios_google_signin_fix');
      }

      // Handle specific iOS errors
      if (e.toString().contains('GoogleService-Info.plist')) {
        throw Exception(
          'iOS Google configuration error: GoogleService-Info.plist not found or invalid'
        );
      }

      if (e.toString().contains('CLIENT_ID')) {
        throw Exception(
          'iOS Google configuration error: Invalid client ID configuration'
        );
      }

      if (e.toString().contains('network')) {
        throw Exception(
          'Network error during Google Sign-In. Please check your internet connection.'
        );
      }

      // Re-throw with iOS-specific context
      throw Exception('iOS Google Sign-In failed: $e');
    }
  }

  /// Check if Google Sign-In is properly configured for iOS
  static Future<bool> isGoogleSignInConfiguredForIOS() async {
    if (!isIOS) return false;

    try {
      // Try to check if we can initialize without errors
      final isSignedIn = await _iosGoogleSignIn.isSignedIn();
      if (kDebugMode) ProductionLogger.info('🍎 [iOS] Google Sign-In configuration check: $isSignedIn', tag: 'ios_google_signin_fix');
      return true;
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('🍎 [iOS] Google Sign-In configuration error: $e', tag: 'ios_google_signin_fix');
      return false;
    }
  }

  /// Sign out from Google on iOS
  static Future<void> signOutGoogleIOS() async {
    if (!isIOS) return;

    try {
      await _iosGoogleSignIn.signOut();
      if (kDebugMode) ProductionLogger.info('🍎 [iOS] ✅ Google sign-out successful', tag: 'ios_google_signin_fix');
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('🍎 [iOS] ⚠️ Google sign-out error: $e', tag: 'ios_google_signin_fix');
    }
  }

  /// Get current Google user on iOS
  static GoogleSignInAccount? get currentGoogleUserIOS {
    if (!isIOS) return null;
    return _iosGoogleSignIn.currentUser;
  }
}