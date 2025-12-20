import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/user_onboarding_completion_service.dart';
import '../routes/app_routes.dart';
import '../services/member_realtime_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 **AUTHENTICATION NAVIGATION CONTROLLER**
///
/// Quản lý logic điều hướng theo chuẩn của các nền tảng lớn:
/// - Facebook: Registration → Email Verification → Welcome → Profile Setup
/// - Instagram: Registration → Username Setup → Find Friends → Home
/// - LinkedIn: Registration → Email Verification → Profile Building → Home
///
/// **SABO ARENA FLOW:**
/// 1. Registration Success → Email Verification (if needed)
/// 2. First Login → Onboarding Tour (if not seen)
/// 3. Profile Incomplete → Profile Setup
/// 4. Authentication Complete → Main App
class AuthNavigationController {
  /// 🎯 **MAIN NAVIGATION ENTRY POINT**
  ///
  /// Được gọi từ splash screen để điều hướng chính xác
  static Future<void> navigateFromSplash(BuildContext context) async {
    if (!context.mounted) return;

    try {
      // Check authentication status
      final isAuthenticated = AuthService.instance.isAuthenticated;
      ProductionLogger.debug('Navigation: isAuthenticated = $isAuthenticated',
          tag: 'AuthNav');

      if (isAuthenticated) {
        await _handleAuthenticatedUser(context);
      } else {
        await _handleUnauthenticatedUser(context);
      }
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.auth,
          operation: 'navigateFromSplash',
          context: 'Navigation error from splash',
        ),
      );
      ProductionLogger.error('Navigation Error',
          error: e, stackTrace: stackTrace, tag: 'AuthNav');
      // Fallback to login on any error
      if (context.mounted) {
        _safeNavigate(context, AppRoutes.loginScreen);
      }
    }
  }

  /// 🎯 **POST-REGISTRATION NAVIGATION**
  ///
  /// Được gọi sau khi đăng ký thành công
  static Future<void> navigateAfterRegistration(
    BuildContext context, {
    required String userId,
    required String email,
    bool needsEmailVerification = false,
  }) async {
    if (!context.mounted) return;

    try {
      ProductionLogger.info('Registration Success: User $userId created',
          tag: 'AuthNav');

      // Save registration completion flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('registration_completed', true);
      await prefs.setString('registered_user_id', userId);
      await prefs.setString('registered_email', email);

      if (needsEmailVerification) {
        // Show email verification screen (to be implemented)
        if (context.mounted) await _showEmailVerificationScreen(context, email);
      } else {
        // Proceed to onboarding or main app
        if (context.mounted) await _handleNewUserOnboarding(context);
      }
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.auth,
          operation: 'navigateAfterRegistration',
          context: 'Post-registration navigation error',
        ),
      );
      ProductionLogger.error('Post-Registration Navigation Error',
          error: e, stackTrace: stackTrace, tag: 'AuthNav');
      // Fallback to login
      if (context.mounted) _safeNavigate(context, AppRoutes.loginScreen);
    }
  }

  /// 🎯 **POST-LOGIN NAVIGATION**
  ///
  /// Được gọi sau khi đăng nhập thành công
  static Future<void> navigateAfterLogin(
    BuildContext context, {
    required String userId,
    bool isFirstLogin = false,
  }) async {
    if (!context.mounted) return;

    try {
      ProductionLogger.info('Login Success: User $userId authenticated',
          tag: 'AuthNav');

      // ✅ CHECK ADMIN ROLE FIRST!
      final isAdmin = await AuthService.instance.isCurrentUserAdmin();
      ProductionLogger.debug('Post-Login: isAdmin = $isAdmin', tag: 'AuthNav');

      if (isAdmin) {
        // Admin users go directly to admin dashboard
        ProductionLogger.info('Redirecting admin to dashboard', tag: 'AuthNav');
        if (context.mounted)
          _safeNavigate(context, AppRoutes.adminDashboardScreen);
        return; // Exit early for admin
      }

      // Continue with regular user flow below...
      // Initialize realtime for notifications immediately after login
      await MemberRealtimeService().initializeForUser(userId);

      // ✨ NEW: Subscribe to real-time notifications
      try {
        await NotificationService.instance.subscribeToNotifications(userId);
        ProductionLogger.info('Subscribed to real-time notifications',
            tag: 'AuthNav');
      } catch (notificationError) {
        ProductionLogger.warning(
          'Notification subscription failed (non-critical): $notificationError',
          error: notificationError,
          tag: 'AuthNav',
        );
      }

      // Register device for push notifications (skip on web)
      // NON-CRITICAL: Don't let push notification errors block login flow
      if (!kIsWeb) {
        try {
          await PushService.instance.registerForPush(userId);
          ProductionLogger.info('Push notifications registered successfully',
              tag: 'AuthNav');
        } catch (pushError) {
          // Push notifications are optional - log but continue
          ProductionLogger.warning(
            'Push notification registration failed (non-critical): $pushError',
            error: pushError,
            tag: 'AuthNav',
          );
        }
      } else {
        ProductionLogger.debug('Skipping push registration on web platform',
            tag: 'AuthNav');
      }

      // Send welcome notification once for first login
      // NON-CRITICAL: Don't block login if welcome notification fails
      if (isFirstLogin) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final hasSentWelcome =
              prefs.getBool('has_sent_welcome_notification_$userId') ?? false;
          if (!hasSentWelcome) {
            await NotificationService.instance.sendWelcomeNotification(
              userId: userId,
            );
            await prefs.setBool('has_sent_welcome_notification_$userId', true);
          }
        } catch (notificationError) {
          ProductionLogger.warning(
            'Welcome notification failed (non-critical): $notificationError',
            error: notificationError,
            tag: 'AuthNav',
          );
        }
      }

      // ✅ Check if user needs initialization (regardless of isFirstLogin flag)
      final needsInitialization = await _checkIfNeedsInitialization(userId);

      if (needsInitialization) {
        ProductionLogger.info(
            'User needs initialization - triggering onboarding completion',
            tag: 'AuthNav');
        if (context.mounted) await _handleNewUserOnboarding(context);
      } else if (isFirstLogin) {
        if (context.mounted) await _handleNewUserOnboarding(context);
      } else {
        if (context.mounted) await _handleReturningUser(context);
      }
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.auth,
          operation: 'navigateAfterLogin',
          context: 'CRITICAL Post-Login Navigation Error',
        ),
      );
      ProductionLogger.error('CRITICAL Post-Login Navigation Error',
          error: e, stackTrace: stackTrace, tag: 'AuthNav');
      // Only fallback to login for CRITICAL errors
      if (context.mounted) _safeNavigate(context, AppRoutes.loginScreen);
    }
  }

  /// 🔒 **AUTHENTICATED USER HANDLING**
  static Future<void> _handleAuthenticatedUser(BuildContext context) async {
    final isAdmin = await AuthService.instance.isCurrentUserAdmin();
    ProductionLogger.debug('Navigation: isAdmin = $isAdmin', tag: 'AuthNav');

    if (isAdmin) {
      if (context.mounted)
        _safeNavigate(context, AppRoutes.adminDashboardScreen);
    } else {
      final uid = AuthService.instance.currentUser?.id;
      if (uid != null) {
        try {
          await MemberRealtimeService().initializeForUser(uid);
        } catch (e) {
          ProductionLogger.warning('Failed to initialize realtime service',
              error: e, tag: 'AuthNav');
        }

        // ✨ NEW: Subscribe to real-time notifications (Fix for missing unread count)
        try {
          await NotificationService.instance.subscribeToNotifications(uid);
          ProductionLogger.info(
              'Subscribed to real-time notifications (Auto-login)',
              tag: 'AuthNav');
        } catch (e) {
          ProductionLogger.warning('Failed to subscribe to notifications',
              error: e, tag: 'AuthNav');
        }

        // Register for push notifications (skip on web)
        if (!kIsWeb) {
          try {
            await PushService.instance.registerForPush(uid);
          } catch (e) {
            ProductionLogger.warning('Failed to register push notifications',
                error: e, tag: 'AuthNav');
          }
        }
      }
      // Check if user needs onboarding
      final needsOnboarding = await _checkIfNeedsOnboarding();

      if (needsOnboarding) {
        if (context.mounted) await _handleNewUserOnboarding(context);
      } else {
        // 🚀 PHASE 1: Navigate to main screen with persistent tabs
        if (context.mounted) _safeNavigate(context, AppRoutes.mainScreen);
      }
    }
  }

  /// 🚫 **UNAUTHENTICATED USER HANDLING**
  static Future<void> _handleUnauthenticatedUser(BuildContext context) async {
    // final prefs = await SharedPreferences.getInstance();
    // ELON_MODE: Force onboarding for review
    // final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    // ProductionLogger.debug('Navigation: hasSeenOnboarding = $hasSeenOnboarding', tag: 'AuthNav');

    // if (hasSeenOnboarding) {
    //   if (context.mounted) _safeNavigate(context, AppRoutes.loginScreen);
    // } else {
    if (context.mounted) _safeNavigate(context, AppRoutes.onboardingScreen);
    // }
  }

  /// 🆕 **NEW USER ONBOARDING**
  static Future<void> _handleNewUserOnboarding(BuildContext context) async {
    ProductionLogger.info('Starting user onboarding completion...',
        tag: 'AuthNav');

    try {
      // Get current user info
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        ProductionLogger.warning('No current user found', tag: 'AuthNav');
        if (context.mounted) _safeNavigate(context, AppRoutes.loginScreen);
        return;
      }

      // 🚀 TRIGGER USER INITIALIZATION AFTER ONBOARDING
      final initializationService = UserOnboardingCompletionService.instance;
      final success = await initializationService.completeUserInitialization(
        userId: currentUser.id,
        userName: currentUser.userMetadata?['full_name'] ?? 'User',
        email: currentUser.email ?? '',
        registrationMethod: 'email',
      );

      if (success) {
        ProductionLogger.info('User initialization completed successfully',
            tag: 'AuthNav');
      } else {
        ProductionLogger.warning(
            'User initialization partially failed (non-critical)',
            tag: 'AuthNav');
      }

      // Navigate to main screen with persistent tabs
      ProductionLogger.info('Directing user to main screen', tag: 'AuthNav');
      if (context.mounted) _safeNavigate(context, AppRoutes.mainScreen);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.auth,
          operation: '_handleNewUserOnboarding',
          context: 'Error during user onboarding',
        ),
      );
      ProductionLogger.error('Error during user onboarding',
          error: e, stackTrace: stackTrace, tag: 'AuthNav');
      // Still navigate to main screen - initialization failures are non-critical
      if (context.mounted) _safeNavigate(context, AppRoutes.mainScreen);
    }
  }

  /// 👤 **RETURNING USER HANDLING**
  static Future<void> _handleReturningUser(BuildContext context) async {
    // 🚀 PHASE 1: Navigate to main screen with persistent tabs
    ProductionLogger.info('Returning user: Directing to main screen',
        tag: 'AuthNav');
    _safeNavigate(context, AppRoutes.mainScreen);
  }

  /// 📧 **EMAIL VERIFICATION SCREEN**
  static Future<void> _showEmailVerificationScreen(
    BuildContext context,
    String email,
  ) async {
    // Navigate to dedicated email verification screen
    _safeNavigateWithArguments(
      context,
      AppRoutes.emailVerificationScreen,
      arguments: {
        'email': email,
        'userId': AuthService.instance.currentUser?.id ?? '',
      },
    );
  }

  /// 🔍 **CHECK ONBOARDING STATUS**
  static Future<bool> _checkIfNeedsOnboarding() async {
    // ⚠️ ARCHIVED: Tutorial feature moved to archive
    // Always return false (no onboarding needed)
    return false;
  }

  /// ️ **SAFE NAVIGATION**
  static void _safeNavigate(BuildContext context, String routeName) {
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  /// 🛡️ **SAFE NAVIGATION WITH ARGUMENTS**
  static void _safeNavigateWithArguments(
    BuildContext context,
    String routeName, {
    Map<String, dynamic>? arguments,
  }) {
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
    }
  }

  /// 🚪 **LOGOUT NAVIGATION**
  static Future<void> navigateAfterLogout(BuildContext context) async {
    try {
      // Clear all stored preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('registration_completed');
      await prefs.remove('registered_user_id');
      await prefs.remove('registered_email');
      await prefs.remove('has_seen_app_onboarding');

      ProductionLogger.info('Logout: All session data cleared', tag: 'AuthNav');

      // Navigate to login
      if (context.mounted) _safeNavigate(context, AppRoutes.loginScreen);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.auth,
          operation: 'navigateAfterLogout',
          context: 'Logout Navigation Error',
        ),
      );
      ProductionLogger.error('Logout Navigation Error',
          error: e, stackTrace: stackTrace, tag: 'AuthNav');
      if (context.mounted) _safeNavigate(context, AppRoutes.loginScreen);
    }
  }

  /// ✅ **CHECK IF USER NEEDS INITIALIZATION**
  /// Returns true if user hasn't completed post-registration initialization
  static Future<bool> _checkIfNeedsInitialization(String userId) async {
    try {
      final initService = UserOnboardingCompletionService.instance;
      final hasCompleted = await initService.hasCompletedInitialization(userId);

      if (!hasCompleted) {
        ProductionLogger.info(
            'User $userId needs initialization (status not completed)',
            tag: 'AuthNav');
        return true;
      }

      ProductionLogger.info('User $userId has already completed initialization',
          tag: 'AuthNav');
      return false;
    } catch (e) {
      ProductionLogger.warning('Could not check initialization status',
          error: e, tag: 'AuthNav');
      // If we can't check, assume initialization is needed to be safe
      return true;
    }
  }
}

/// 🎯 **NAVIGATION STATES ENUM**
enum AuthNavigationState {
  splash,
  onboarding,
  login,
  register,
  emailVerification,
  profileSetup,
  appOnboarding,
  mainApp,
  adminDashboard,
}

/// 📱 **NAVIGATION ANALYTICS**
class AuthNavigationAnalytics {
  static void trackNavigation(
    AuthNavigationState from,
    AuthNavigationState to,
  ) {
    ProductionLogger.debug('Navigation: $from → $to', tag: 'AuthNav');
    // In future: Send to analytics service
  }

  static void trackRegistrationFlow(String step, Map<String, dynamic> data) {
    ProductionLogger.debug('Registration Flow: $step - $data', tag: 'AuthNav');
    // In future: Track conversion funnel
  }
}
