import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Platform-aware Google Sign-In service for SABO Arena
/// Handles iOS, Android, and Web authentication properly
class PlatformAwareGoogleAuthService {
  // Google Client IDs for different platforms
  static const String ANDROID_CLIENT_ID = '930620766039-e6h7955gnp66o7ui36v186r2ajick28nd.apps.googleusercontent.com';
  static const String IOS_CLIENT_ID = '930620766039-8e22rfd8mdj2dp1tu4n7fbl88selpbur.apps.googleusercontent.com';
  static const String WEB_CLIENT_ID = '930620766039-dv2u7ajkpb3lugbp9djg8s5gtko7iupb.apps.googleusercontent.com';
  
  /// Get appropriate client ID based on current platform
  static String getClientIdForPlatform() {
    if (!kIsWeb && Platform.isIOS) {
      return IOS_CLIENT_ID;
    } else if (!kIsWeb && Platform.isAndroid) {
      return ANDROID_CLIENT_ID;
    } else if (kIsWeb) {
      return WEB_CLIENT_ID;
    }
    // Default to Android client for unknown platforms
    return ANDROID_CLIENT_ID;
  }

  /// Platform-aware Google Sign-In
  /// Handles different authentication flows based on platform and Supabase config
  static Future<AuthResponse> signInWithGoogle() async {
    try {
      ProductionLogger.info('🔐 🚀 Starting Platform-Aware Google Sign-In', tag: 'platform_aware_google_auth_service');
      ProductionLogger.info('ℹ️ [PlatformAuth] Platform: ${_getPlatformName()}', tag: 'platform_aware_google_auth_service');
      
      // Strategy 1: Try standard Supabase OAuth flow first
      try {
        ProductionLogger.info('🔄 [PlatformAuth] Attempting standard Supabase OAuth...', tag: 'platform_aware_google_auth_service');
        final bool success = await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'io.supabase.saboarena://login-callback/',
        );
        
        if (success) {
          ProductionLogger.info('✅ [PlatformAuth] Standard OAuth flow initiated', tag: 'platform_aware_google_auth_service');
          // Return success response (user will be set after redirect)
          return AuthResponse(user: null, session: null);
        }
      } catch (e) {
        ProductionLogger.info('⚠️ [PlatformAuth] Standard OAuth failed: $e', tag: 'platform_aware_google_auth_service');
      }

      // Strategy 2: Platform-specific manual flow
      return await _handleManualGoogleSignIn();
      
    } catch (e) {
      ProductionLogger.info('❌ [PlatformAuth] 💥 Platform-aware Google Sign-In error', tag: 'platform_aware_google_auth_service');
      ProductionLogger.info('   Error: $e', tag: 'platform_aware_google_auth_service');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Manual Google Sign-In with platform-specific client IDs
  static Future<AuthResponse> _handleManualGoogleSignIn() async {
    ProductionLogger.info('🔄 [PlatformAuth] Using manual Google Sign-In flow...', tag: 'platform_aware_google_auth_service');
    
    final String clientId = getClientIdForPlatform();
    ProductionLogger.info('ℹ️ [PlatformAuth] Using client ID: ${clientId.substring(0, 20)}...', tag: 'platform_aware_google_auth_service');

    // Initialize Google Sign-In with platform-specific client
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? null : clientId, // Web uses meta tag
      scopes: ['email', 'profile'],
    );

    // Sign in with Google
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      throw Exception('User cancelled Google Sign-In');
    }

    // Get authentication details
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    if (googleAuth.idToken == null) {
      throw Exception('No ID token received from Google');
    }

    ProductionLogger.info('✅ [PlatformAuth] Google authentication successful', tag: 'platform_aware_google_auth_service');
    ProductionLogger.info('ℹ️ [PlatformAuth] User: ${googleUser.email}', tag: 'platform_aware_google_auth_service');

    // Sign in to Supabase with Google ID token
    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );

    ProductionLogger.info('✅ [PlatformAuth] Supabase authentication successful', tag: 'platform_aware_google_auth_service');
    return response;
  }

  /// Get human-readable platform name
  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (!kIsWeb && Platform.isIOS) return 'iOS';
    if (!kIsWeb && Platform.isAndroid) return 'Android';
    return 'Unknown';
  }

  /// Sign out from both Google and Supabase
  static Future<void> signOut() async {
    try {
      ProductionLogger.info('🔐 🚀 Starting Platform-Aware Sign-Out', tag: 'platform_aware_google_auth_service');
      
      // Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? null : getClientIdForPlatform(),
      );
      await googleSignIn.signOut();
      
      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();
      
      ProductionLogger.info('✅ [PlatformAuth] Sign-out successful', tag: 'platform_aware_google_auth_service');
    } catch (e) {
      ProductionLogger.info('❌ [PlatformAuth] Sign-out error: $e', tag: 'platform_aware_google_auth_service');
      throw Exception('Sign-out failed: $e');
    }
  }

  /// Check if user is currently signed in
  static bool isSignedIn() {
    return Supabase.instance.client.auth.currentUser != null;
  }

  /// Get current user
  static User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }
}

/// Usage Example:
/// 
/// ```dart
/// // In your login screen
/// Future<void> _handleGoogleSignIn() async {
///   try {
///     final response = await PlatformAwareGoogleAuthService.signInWithGoogle();
///     if (response.user != null) {
///       // Navigate to main app
///       Navigator.pushReplacementNamed(context, '/home');
///     }
///   } catch (e) {
///     // Show error message
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Sign-in failed: $e')),
///     );
///   }
/// }
/// ```