import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 UNIFIED AUTH SERVICE
/// 
/// Consolidates all authentication functionality:
/// - auth_service.dart
/// - auth/simple_auth_service.dart
/// - auth/platform_aware_google_auth_service.dart
/// - auth/ios_google_signin_fix.dart
/// - auth/ios_facebook_auth_fix.dart
/// - auth/debug_auth_service.dart
/// - auth/cross_platform_google_auth.dart
/// - social_auth_service.dart
/// 
/// Features:
/// - Email/Password authentication
/// - Google Sign In (cross-platform)
/// - Facebook Sign In
/// - Apple Sign In (iOS only)
/// - Session management
/// - Profile management
class UnifiedAuthService {
  static UnifiedAuthService? _instance;
  static UnifiedAuthService get instance =>
      _instance ??= UnifiedAuthService._();

  UnifiedAuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tag = 'UnifiedAuth';

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Current user ID
  String? get currentUserId => currentUser?.id;

  /// Is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ============================================================================
  // EMAIL/PASSWORD AUTH
  // ============================================================================

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? referralCode,
  }) async {
    try {
      ProductionLogger.info('$_tag: Signing up with email: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'referral_code': referralCode,
        },
      );

      if (response.user == null) {
        return AuthResult.failure('Sign up failed');
      }

      // Create user profile
      await _createUserProfile(
        oderId: response.user!.id,
        email: email,
        fullName: fullName,
      );

      ProductionLogger.info('$_tag: Sign up successful: ${response.user!.id}');
      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      ProductionLogger.error('$_tag: Sign up error', error: e);
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      ProductionLogger.error('$_tag: Sign up error', error: e);
      return AuthResult.failure(e.toString());
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      ProductionLogger.info('$_tag: Signing in with email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('Sign in failed');
      }

      ProductionLogger.info('$_tag: Sign in successful: ${response.user!.id}');
      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      ProductionLogger.error('$_tag: Sign in error', error: e);
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      ProductionLogger.error('$_tag: Sign in error', error: e);
      return AuthResult.failure(e.toString());
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      ProductionLogger.info('$_tag: Password reset email sent to $email');
      return true;
    } catch (e) {
      ProductionLogger.error('$_tag: Password reset error', error: e);
      return false;
    }
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      ProductionLogger.info('$_tag: Password updated');
      return true;
    } catch (e) {
      ProductionLogger.error('$_tag: Password update error', error: e);
      return false;
    }
  }

  // ============================================================================
  // SOCIAL AUTH
  // ============================================================================

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      ProductionLogger.info('$_tag: Signing in with Google');

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.saboarena://login-callback/',
      );

      if (!response) {
        return AuthResult.failure('Google sign in was cancelled');
      }

      // Wait for auth state change
      await Future.delayed(const Duration(seconds: 2));
      
      if (currentUser != null) {
        await _ensureUserProfile();
        return AuthResult.success(currentUser!);
      }

      return AuthResult.failure('Google sign in failed');
    } catch (e) {
      ProductionLogger.error('$_tag: Google sign in error', error: e);
      return AuthResult.failure(e.toString());
    }
  }

  /// Sign in with Facebook
  Future<AuthResult> signInWithFacebook() async {
    try {
      ProductionLogger.info('$_tag: Signing in with Facebook');

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'io.supabase.saboarena://login-callback/',
      );

      if (!response) {
        return AuthResult.failure('Facebook sign in was cancelled');
      }

      await Future.delayed(const Duration(seconds: 2));
      
      if (currentUser != null) {
        await _ensureUserProfile();
        return AuthResult.success(currentUser!);
      }

      return AuthResult.failure('Facebook sign in failed');
    } catch (e) {
      ProductionLogger.error('$_tag: Facebook sign in error', error: e);
      return AuthResult.failure(e.toString());
    }
  }

  /// Sign in with Apple (iOS only)
  Future<AuthResult> signInWithApple() async {
    try {
      ProductionLogger.info('$_tag: Signing in with Apple');

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.saboarena://login-callback/',
      );

      if (!response) {
        return AuthResult.failure('Apple sign in was cancelled');
      }

      await Future.delayed(const Duration(seconds: 2));
      
      if (currentUser != null) {
        await _ensureUserProfile();
        return AuthResult.success(currentUser!);
      }

      return AuthResult.failure('Apple sign in failed');
    } catch (e) {
      ProductionLogger.error('$_tag: Apple sign in error', error: e);
      return AuthResult.failure(e.toString());
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Sign out
  Future<void> signOut() async {
    try {
      ProductionLogger.info('$_tag: Signing out');
      await _supabase.auth.signOut();
    } catch (e) {
      ProductionLogger.error('$_tag: Sign out error', error: e);
    }
  }

  /// Refresh session
  Future<bool> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response.session != null;
    } catch (e) {
      ProductionLogger.error('$_tag: Session refresh error', error: e);
      return false;
    }
  }

  /// Check if session is valid
  bool get hasValidSession {
    final session = _supabase.auth.currentSession;
    if (session == null) return false;
    
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt! * 1000,
    );
    return DateTime.now().isBefore(expiresAt);
  }

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile([String? userId]) async {
    try {
      final id = userId ?? currentUserId;
      if (id == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response;
    } catch (e) {
      ProductionLogger.error('$_tag: Get profile error', error: e);
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (currentUserId == null) return false;

      await _supabase
          .from('users')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUserId!);

      ProductionLogger.info('$_tag: Profile updated');
      return true;
    } catch (e) {
      ProductionLogger.error('$_tag: Update profile error', error: e);
      return false;
    }
  }

  /// Check if user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final profile = await getUserProfile();
      return profile?['role'] == 'admin' || profile?['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is club owner
  Future<bool> isCurrentUserClubOwner() async {
    try {
      final profile = await getUserProfile();
      return profile?['role'] == 'club_owner';
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  Future<void> _createUserProfile({
    required String oderId,
    required String email,
    String? fullName,
  }) async {
    try {
      await _supabase.from('users').upsert({
        'id': oderId,
        'email': email,
        'full_name': fullName,
        'role': 'player',
        'elo_rating': 1000,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ProductionLogger.warning('$_tag: Create profile error: $e');
    }
  }

  Future<void> _ensureUserProfile() async {
    if (currentUser == null) return;

    final profile = await getUserProfile();
    if (profile == null) {
      await _createUserProfile(
        oderId: currentUserId!,
        email: currentUser!.email ?? '',
        fullName: currentUser!.userMetadata?['full_name'] as String?,
      );
    }
  }

  String _mapAuthError(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Email hoặc mật khẩu không đúng';
      case 'Email not confirmed':
        return 'Vui lòng xác nhận email trước khi đăng nhập';
      case 'User already registered':
        return 'Email đã được đăng ký';
      default:
        return e.message;
    }
  }
}

/// Auth result class
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult._({
    required this.success,
    this.user,
    this.error,
  });

  factory AuthResult.success(User user) => AuthResult._(
    success: true,
    user: user,
  );

  factory AuthResult.failure(String error) => AuthResult._(
    success: false,
    error: error,
  );
}

