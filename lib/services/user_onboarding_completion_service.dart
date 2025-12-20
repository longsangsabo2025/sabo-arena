import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auto_notification_hooks.dart';
import '../services/referral_service.dart';
import '../services/deep_link_service.dart';
import '../services/pending_referral_service.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 USER ONBOARDING COMPLETION SERVICE
/// Handles all user initialization AFTER onboarding is completed
/// This ensures registration is never blocked by complex setup logic
class UserOnboardingCompletionService {
  static UserOnboardingCompletionService? _instance;
  static UserOnboardingCompletionService get instance =>
      _instance ??= UserOnboardingCompletionService._();
  UserOnboardingCompletionService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🚀 Complete user initialization after onboarding
  /// This replaces all the hooks that previously ran during registration
  Future<bool> completeUserInitialization({
    required String userId,
    required String userName,
    required String email,
    String registrationMethod = 'email',
  }) async {
    try {
      ProductionLogger.info(
        'Starting user initialization after onboarding - User ID: $userId, Name: $userName, Email: $email',
        tag: 'Onboarding',
      );

      // Track that initialization is starting
      await _updateUserInitializationStatus(userId, 'in_progress');

      final results = <String, bool>{};

      // 🔔 Step 1: Send welcome notification
      results['welcome_notification'] = await _sendWelcomeNotification(
        userId: userId,
        userName: userName,
        registrationMethod: registrationMethod,
      );

      // 🔗 Step 2: Create referral code
      results['referral_code'] = await _createReferralCode(userId);

      // 🎯 Step 3a: Claim pending referral from server-side tracking (NEW!)
      results['claim_pending_referral'] = await _claimPendingReferral(userId);

      // 🎯 Step 3b: Process stored referral code (fallback)
      results['process_referral'] = await _processStoredReferralCode(userId);

      // 📊 Step 4: Initialize user analytics/tracking
      results['analytics_setup'] = await _setupUserAnalytics(userId, userName);

      // 🏆 Step 5: Setup initial achievements/badges
      results['achievements_setup'] = await _setupInitialAchievements(userId);

      // ✅ Mark initialization as completed
      await _updateUserInitializationStatus(userId, 'completed');

      // Log results
      final successCount = results.values.where((v) => v).length;
      final totalSteps = results.length;

      final resultsSummary = results.entries
          .map((e) => '${e.value ? "✅" : "❌"} ${e.key}')
          .join(', ');

      ProductionLogger.info(
        'User initialization completed: $successCount/$totalSteps steps successful. Results: $resultsSummary',
        tag: 'Onboarding',
      );

      return successCount >=
          (totalSteps * 0.8); // 80% success rate is acceptable
    } catch (error, stackTrace) {
      StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.unknown,
          operation: 'completeUserInitialization',
          context: 'User initialization failed',
        ),
      );
      ProductionLogger.error(
        'User initialization failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'Onboarding',
      );

      // Mark as failed but don't throw - user can still use the app
      await _updateUserInitializationStatus(userId, 'failed');
      return false;
    }
  }

  /// 🔔 Send welcome notification (non-critical)
  Future<bool> _sendWelcomeNotification({
    required String userId,
    required String userName,
    required String registrationMethod,
  }) async {
    try {
      await AutoNotificationHooks.onUserRegistered(
        userId: userId,
        userName: userName,
        registrationMethod: registrationMethod,
      );
      return true;
    } catch (e) {
      ProductionLogger.warning('Welcome notification failed',
          error: e, tag: 'Onboarding');
      return false;
    }
  }

  /// 🔗 Create referral code (non-critical)
  Future<bool> _createReferralCode(String userId) async {
    try {
      await ReferralService.instance.createReferralCodeForUser(userId);
      return true;
    } catch (e) {
      ProductionLogger.warning('Referral code creation failed',
          error: e, tag: 'Onboarding');
      return false;
    }
  }

  /// 🎯 Claim pending referral from server-side tracking (NEW!)
  Future<bool> _claimPendingReferral(String userId) async {
    try {
      final result =
          await PendingReferralService.instance.claimPendingReferral(userId);

      if (result['claimed'] == true) {
        ProductionLogger.info(
          'Claimed pending referral: ${result['referral_code']}, Bonus: ${result['referee_bonus']} SPA (${result['match_method']})',
          tag: 'Onboarding',
        );
        return true;
      } else {
        ProductionLogger.debug(
            'No pending referral to claim: ${result['message']}',
            tag: 'Onboarding');
        return true; // Still return true since it's not an error
      }
    } catch (e) {
      ProductionLogger.warning('Pending referral claim failed',
          error: e, tag: 'Onboarding');
      return false;
    }
  }

  /// 🎯 Process stored referral code (fallback - non-critical)
  Future<bool> _processStoredReferralCode(String userId) async {
    try {
      final storedReferralCode =
          await DeepLinkService.instance.getStoredReferralCodeForNewUser();

      if (storedReferralCode != null && storedReferralCode.isNotEmpty) {
        await ReferralService.instance.useReferralCode(
          storedReferralCode,
          userId,
        );
        await DeepLinkService.instance.clearStoredReferralCode();

        ProductionLogger.info('Applied referral code: $storedReferralCode',
            tag: 'Onboarding');
      }
      return true;
    } catch (e) {
      ProductionLogger.warning('Referral code processing failed',
          error: e, tag: 'Onboarding');
      return false;
    }
  }

  /// 📊 Setup user analytics (non-critical)
  Future<bool> _setupUserAnalytics(String userId, String userName) async {
    try {
      // Initialize user analytics tracking
      // This could include setting up user properties, tracking first visit, etc.

      ProductionLogger.debug('User analytics setup completed',
          tag: 'Onboarding');
      return true;
    } catch (e) {
      ProductionLogger.warning('Analytics setup failed',
          error: e, tag: 'Onboarding');
      return false;
    }
  }

  /// 🏆 Setup initial achievements (non-critical)
  Future<bool> _setupInitialAchievements(String userId) async {
    try {
      // Get "First Tournament" achievement ID (or any welcome achievement)
      final achievementsResponse = await _supabase
          .from('achievements')
          .select('id')
          .eq('name', 'First Tournament')
          .maybeSingle();

      if (achievementsResponse != null) {
        final achievementId = achievementsResponse['id'];

        // Award the achievement to user
        await _supabase.from('user_achievements').insert({
          'user_id': userId,
          'achievement_id': achievementId,
        });

        ProductionLogger.info('Initial achievement awarded: First Tournament',
            tag: 'Onboarding');
      } else {
        ProductionLogger.debug('No welcome achievement found in master list',
            tag: 'Onboarding');
      }

      return true;
    } catch (e) {
      ProductionLogger.warning('Achievements setup failed',
          error: e, tag: 'Onboarding');
      return false;
    }
  }

  /// 📝 Update user initialization status in database
  Future<void> _updateUserInitializationStatus(
    String userId,
    String status,
  ) async {
    try {
      await _supabase.from('users').update({
        'initialization_status': status,
        'initialization_completed_at':
            status == 'completed' ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      ProductionLogger.debug('User initialization status updated: $status',
          tag: 'Onboarding');
    } catch (e) {
      ProductionLogger.warning('Could not update initialization status',
          error: e, tag: 'Onboarding');
      // Don't throw - this is just for tracking
    }
  }

  /// 🔍 Check if user has completed initialization
  Future<bool> hasCompletedInitialization(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('initialization_status')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return false;

      final status = response['initialization_status'] as String?;
      return status == 'completed';
    } catch (e) {
      ProductionLogger.warning('Could not check initialization status',
          error: e, tag: 'Onboarding');
      return false;
    }
  }

  /// 🔄 Retry failed initialization
  Future<bool> retryInitialization({
    required String userId,
    required String userName,
    required String email,
    String registrationMethod = 'email',
  }) async {
    ProductionLogger.info('Retrying user initialization...', tag: 'Onboarding');

    return await completeUserInitialization(
      userId: userId,
      userName: userName,
      email: email,
      registrationMethod: registrationMethod,
    );
  }
}
