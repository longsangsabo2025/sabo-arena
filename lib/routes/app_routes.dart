import 'package:flutter/material.dart';

import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
// import '../presentation/onboarding_screen/app_tutorial_screen.dart'; // ARCHIVED - Moved to lib/archived/
import '../presentation/home_feed_screen/home_feed_screen.dart';
import '../presentation/tournament_list_screen/tournament_list_screen.dart';
import '../presentation/find_opponents_screen/find_opponents_screen.dart';
import '../presentation/find_opponents_list_screen/find_opponents_list_screen.dart';
import '../presentation/club_main_screen/club_main_screen.dart'; // Original Design - Active
// import '../presentation/club_main_screen/club_main_screen_ios.dart'; // iOS Design - Alternative
import '../presentation/club_profile_screen/club_profile_screen.dart';
import '../presentation/club_registration_screen/club_registration_screen.dart';
import '../presentation/club_selection_screen/club_selection_screen.dart';
import '../presentation/rank_management_screen/rank_management_screen.dart';
import '../presentation/rank_statistics_screen/rank_statistics_screen.dart';
import '../presentation/leaderboard_screen/leaderboard_screen.dart';
import 'package:sabo_arena/presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/tournament_detail_screen/tournament_detail_screen.dart';
import '../presentation/messaging_screen/messaging_screen.dart';
import '../presentation/login_screen/login_screen_ios.dart';
import '../presentation/register_screen/register_screen_ios.dart';
import '../presentation/register_screen/registration_result_screen.dart';
import '../presentation/forgot_password_screen.dart';
import '../presentation/otp_verification_screen.dart';
import '../presentation/reset_password_screen.dart';
import '../presentation/admin_dashboard_screen/admin_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_club_approval_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_tournament_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_user_management_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_more_main_screen.dart';
import '../presentation/my_clubs_screen/my_clubs_screen.dart';
import '../presentation/club_dashboard_screen/club_owner_main_screen.dart';
import '../presentation/direct_messages_screen/direct_messages_screen.dart';
import '../presentation/member_management_screen/member_management_screen.dart';
import '../presentation/notification_analytics_dashboard.dart';
import '../presentation/terms_of_service_screen/terms_of_service_screen.dart';
import '../presentation/privacy_policy_screen/privacy_policy_screen.dart';
import '../presentation/email_verification_screen/email_verification_screen.dart';
import '../presentation/profile_setup_screen/profile_setup_screen.dart';
import '../presentation/settings/post_background_settings_screen_enhanced.dart';
import '../presentation/notification_list_screen.dart';
// Voucher Management System
import '../presentation/voucher_management/voucher_management_main_screen.dart';
// Notification Management System
import '../presentation/admin_dashboard_screen/admin_notification_management_screen.dart';
// Cache Management System
import '../presentation/cache_management_screen/cache_management_screen.dart';
// Admin Guide System
// import '../presentation/admin_dashboard_screen/admin_guide_main_screen.dart'; // TODO: Fix this import
// Test Screens
// import '../test_screens/cross_platform_auth_test.dart'; // ARCHIVED
import '../presentation/admin_dashboard_screen/admin_guide_viewer_screen.dart';
// AI Image Generator
import '../presentation/ai_image_generator/ai_image_generator_screen.dart';
// Welcome Voucher Campaign System
import '../presentation/admin_welcome_campaign_screen/admin_welcome_campaign_screen.dart';
import '../presentation/club_welcome_campaign_screen/club_welcome_campaign_screen.dart';
// User Promotion Screen
import '../presentation/promotion_screen/user_promotion_screen.dart';
import '../presentation/post_detail_screen/post_detail_screen.dart';
import '../presentation/user_voucher_screen/user_voucher_screen.dart';
// 🚀 PHASE 1: Persistent Tabs
import '../widgets/persistent_tab_scaffold.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String onboardingScreen = '/onboarding';
  // static const String appTutorialScreen = '/app_tutorial'; // ARCHIVED - Not used anymore
  static const String mainScreen = '/main'; // 🎯 NEW: Persistent tabs main screen
  static const String homeFeedScreen = '/home_feed_screen';
  static const String tournamentListScreen = '/tournament_list_screen';
  static const String findOpponentsScreen = '/find_opponents_screen';
  static const String findOpponentsListScreen = '/find_opponents_list_screen';
  static const String clubMainScreen = '/club_main_screen';
  static const String clubProfileScreen = '/club_profile_screen';
  static const String clubRegistrationScreen = '/club_registration_screen';
  static const String userProfileScreen = '/user_profile_screen';
  static const String tournamentDetailScreen = '/tournament_detail_screen';
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';
  static const String registrationResultScreen = '/registration_result';
  static const String forgotPasswordScreen = '/forgot-password';
  static const String otpVerificationScreen = '/otp-verification';
  static const String resetPasswordScreen = '/reset-password';
  static const String adminDashboardScreen = '/admin_dashboard';
  static const String adminMainScreen = '/admin_main';
  static const String clubApprovalScreen = '/admin_club_approval';
  static const String adminTournamentScreen = '/admin_tournament';
  static const String adminUserManagementScreen = '/admin_user_management';
  static const String adminMoreScreen = '/admin_more';
  static const String myClubsScreen = '/my_clubs';
  static const String clubDashboardScreen = '/club_dashboard';
  static const String clubSelectionScreen = '/club_selection_screen';
  static const String rankManagementScreen = '/rank_management';
  static const String rankStatisticsScreen = '/rank_statistics';
  static const String leaderboardScreen = '/leaderboard';
  static const String messagingScreen = '/messaging';
  static const String directMessagesScreen = '/direct_messages';
  static const String memberManagementScreen = '/member_management';
  static const String notificationAnalyticsDashboard =
      '/notification_analytics';
  static const String termsOfServiceScreen = '/terms_of_service';
  static const String privacyPolicyScreen = '/privacy_policy';
  static const String emailVerificationScreen = '/email_verification';
  static const String profileSetupScreen = '/profile_setup';
  static const String postBackgroundSettingsScreen =
      '/post_background_settings';
  static const String notificationListScreen = '/notification_list';
  static const String postDetailScreen = '/post_detail';
  static const String userVoucherScreen = '/user_voucher';
  
  // 🧪 TEST SCREENS
  static const String crossPlatformAuthTest = '/cross_platform_auth_test';

  // Voucher Management System
  static const String voucherManagementMainScreen = '/voucher_management_main';

  // Notification Management System
  static const String adminNotificationManagementScreen =
      '/admin_notification_management';

  // Admin Guide System
  static const String adminGuideLibraryScreen = '/admin_guide_library';
  static const String adminGuideViewerScreen = '/admin_guide_viewer';

  // Welcome Voucher Campaign System
  static const String adminWelcomeCampaignScreen = '/admin_welcome_campaign';
  static const String clubWelcomeCampaignScreen = '/club_welcome_campaign';

  // User Promotion Screen
  static const String userPromotionScreen = '/user_promotion';

  // Cache Management System
  static const String cacheManagementScreen = '/cache_management';

  // AI Image Generator
  static const String aiImageGeneratorScreen = '/ai_image_generator';

  static const String initial = splashScreen; // Back to normal flow

  static Map<String, WidgetBuilder> get routes => {
    splashScreen: (context) => const SplashScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    // appTutorialScreen: (context) => const AppTutorialScreen(), // ARCHIVED
    // 🚀 PHASE 1: Main screen with persistent tabs
    mainScreen: (context) => const PersistentTabScaffold(),
    homeFeedScreen: (context) => const HomeFeedScreen(),
    tournamentListScreen: (context) => const TournamentListScreen(),
    findOpponentsScreen: (context) => const FindOpponentsScreen(),
    findOpponentsListScreen: (context) => const FindOpponentsListScreen(),
    clubMainScreen: (context) => const ClubMainScreen(),
    clubProfileScreen: (context) => const ClubProfileScreen(),
    clubRegistrationScreen: (context) => const ClubRegistrationScreen(),
    userProfileScreen: (context) => const UserProfileScreen(),
    emailVerificationScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return EmailVerificationScreen(
        email: args?['email'] as String? ?? '',
        userId: args?['userId'] as String? ?? '',
      );
    },
    profileSetupScreen: (context) => const ProfileSetupScreen(),
    postBackgroundSettingsScreen: (context) =>
        const PostBackgroundSettingsScreenEnhanced(),
    tournamentDetailScreen: (context) => const TournamentDetailScreen(),
    loginScreen: (context) => const LoginScreenIOS(),
    registerScreen: (context) => const RegisterScreenIOS(),
    registrationResultScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return RegistrationResultScreen(
        isSuccess: args?['isSuccess'] as bool? ?? false,
        userId: args?['userId'] as String?,
        email: args?['email'] as String?,
        errorMessage: args?['errorMessage'] as String?,
        userRole: args?['userRole'] as String?,
        needsEmailVerification:
            args?['needsEmailVerification'] as bool? ?? false,
      );
    },
    forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
    otpVerificationScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return OTPVerificationScreen(
        phoneNumber: args?['phone'] as String? ?? '',
      );
    },
    resetPasswordScreen: (context) => const ResetPasswordScreen(),
    adminDashboardScreen: (context) => const AdminDashboardScreen(),
    adminMainScreen: (context) => const AdminMainScreen(),
    clubApprovalScreen: (context) => const AdminClubApprovalMainScreen(),
    adminTournamentScreen: (context) => const AdminTournamentMainScreen(),
    adminUserManagementScreen: (context) =>
        const AdminUserManagementMainScreen(),
    adminMoreScreen: (context) => const AdminMoreMainScreen(),
    myClubsScreen: (context) => const MyClubsScreen(),
    clubSelectionScreen: (context) => const ClubSelectionScreen(),
    rankManagementScreen: (context) => const RankManagementScreen(),
    rankStatisticsScreen: (context) => const RankStatisticsScreen(),
    leaderboardScreen: (context) => const LeaderboardScreen(),
    messagingScreen: (context) => const MessagingScreen(),
    directMessagesScreen: (context) => const DirectMessagesScreen(),
    memberManagementScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final clubId = args?['clubId'] as String? ?? '';
      return MemberManagementScreen(clubId: clubId);
    },
    clubDashboardScreen: (context) => const ClubOwnerMainScreen(clubId: ''),
    notificationAnalyticsDashboard: (context) =>
        const NotificationAnalyticsDashboard(),
    termsOfServiceScreen: (context) => const TermsOfServiceScreen(),
    privacyPolicyScreen: (context) => const PrivacyPolicyScreen(),
    notificationListScreen: (context) => const NotificationListScreen(),
    postDetailScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        return PostDetailScreen(
          post: args['post'],
          postId: args['postId'],
          userId: args['userId'],
          initialIndex: args['initialIndex'] ?? 0,
        );
      }
      // Fallback if args are missing or incorrect type
      return const Scaffold(body: Center(child: Text('Invalid arguments')));
    },
    userVoucherScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        return UserVoucherScreen(userId: args);
      }
      // Fallback
      return const Scaffold(body: Center(child: Text('Invalid arguments')));
    },

    // Voucher Management System
    voucherManagementMainScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return VoucherManagementMainScreen(
        userId: args?['userId'] as String? ?? '',
        clubId: args?['clubId'] as String?,
        isAdmin: args?['isAdmin'] as bool? ?? false,
      );
    },

    // Notification Management System
    adminNotificationManagementScreen: (context) =>
        const AdminNotificationManagementScreen(),

    // Admin Guide System
    // adminGuideLibraryScreen: (context) => const AdminGuideLibraryScreen(), // TODO: Fix this class
    adminGuideViewerScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return AdminGuideViewerScreen(
        guide: args?['guide'] as dynamic, // AdminGuide object
      );
    },

    // Welcome Voucher Campaign System
    adminWelcomeCampaignScreen: (context) => const AdminWelcomeCampaignScreen(),
    clubWelcomeCampaignScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ClubWelcomeCampaignScreen(
        clubId: args?['clubId'] as String? ?? '',
        clubName: args?['clubName'] as String? ?? 'Club',
      );
    },

    // User Promotion Screen
    userPromotionScreen: (context) => const UserPromotionScreen(),

    // Cache Management System
    cacheManagementScreen: (context) => const CacheManagementScreen(),
    
    // AI Image Generator
    aiImageGeneratorScreen: (context) => const AiImageGeneratorScreen(),
    
    // 🧪 TEST SCREENS
    // crossPlatformAuthTest: (context) => const CrossPlatformAuthTest(), // ARCHIVED
  };
}
