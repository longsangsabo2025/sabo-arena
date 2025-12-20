import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabo_arena/services/referral_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to handle deep links and referral codes from QR scanning
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();
  DeepLinkService._();

  /// Handle URL from QR code scanning
  Future<Map<String, dynamic>> handleQRCodeUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // Check if it's a user profile URL with referral code
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'user') {
        final userId = uri.pathSegments[1];

        // Check for referral code parameter
        final referralCode = uri.queryParameters['ref'];

        if (referralCode != null && referralCode.isNotEmpty) {
          if (kDebugMode)
            ProductionLogger.info(
                '🔗 Detected referral code in QR: $referralCode',
                tag: 'deep_link_service');

          return {
            'type': 'user_profile_with_ref',
            'user_id': userId,
            'referral_code': referralCode,
            'action': 'process_referral_and_show_profile',
          };
        } else {
          return {
            'type': 'user_profile',
            'user_id': userId,
            'action': 'show_profile',
          };
        }
      }

      // Handle other URL types
      return {'type': 'unknown', 'url': url, 'action': 'open_external'};
    } catch (error) {
      if (kDebugMode)
        ProductionLogger.info('❌ Error parsing QR URL: $error',
            tag: 'deep_link_service');
      return {
        'type': 'error',
        'error': error.toString(),
        'action': 'show_error',
      };
    }
  }

  /// Process referral code when user scans QR with ref parameter
  Future<bool> processReferralCode(
    String referralCode,
    String currentUserId,
  ) async {
    try {
      if (kDebugMode)
        ProductionLogger.info(
            '🎯 Processing referral code: $referralCode for user: $currentUserId',
            tag: 'deep_link_service');

      // Use the referral code
      final success = await ReferralService.instance.useReferralCode(
        referralCode,
        currentUserId,
      );

      if (success) {
        if (kDebugMode)
          ProductionLogger.info('✅ Referral code processed successfully',
              tag: 'deep_link_service');
        return true;
      } else {
        if (kDebugMode)
          ProductionLogger.info('❌ Failed to process referral code',
              tag: 'deep_link_service');
        return false;
      }
    } catch (error) {
      if (kDebugMode)
        ProductionLogger.info('❌ Error processing referral code: $error',
            tag: 'deep_link_service');
      return false;
    }
  }

  /// Store referral code temporarily for new users (before they register)
  Future<void> storeReferralCodeForNewUser(String referralCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_referral_code', referralCode);

      // Also store timestamp for expiration (30 days)
      final expiryTime =
          DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
      await prefs.setInt('referral_code_expiry', expiryTime);

      if (kDebugMode)
        ProductionLogger.info(
            '💾 Stored referral code for new user: $referralCode',
            tag: 'deep_link_service');
    } catch (error) {
      if (kDebugMode)
        ProductionLogger.info('❌ Error storing referral code: $error',
            tag: 'deep_link_service');
    }
  }

  /// Get stored referral code for new user
  Future<String?> getStoredReferralCodeForNewUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final referralCode = prefs.getString('pending_referral_code');
      final expiryTime = prefs.getInt('referral_code_expiry');

      // Check if code exists and not expired
      if (referralCode != null && expiryTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now < expiryTime) {
          if (kDebugMode)
            ProductionLogger.info(
                '✅ Retrieved stored referral code: $referralCode',
                tag: 'deep_link_service');
          return referralCode;
        } else {
          // Code expired, clear it
          if (kDebugMode)
            ProductionLogger.info('⏰ Referral code expired, clearing...',
                tag: 'deep_link_service');
          await clearStoredReferralCode();
        }
      }

      return null;
    } catch (error) {
      if (kDebugMode)
        ProductionLogger.info('❌ Error getting stored referral code: $error',
            tag: 'deep_link_service');
      return null;
    }
  }

  /// Clear stored referral code after use
  Future<void> clearStoredReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_referral_code');
      await prefs.remove('referral_code_expiry');

      if (kDebugMode)
        ProductionLogger.info('🗑️ Cleared stored referral code',
            tag: 'deep_link_service');
    } catch (error) {
      if (kDebugMode)
        ProductionLogger.info('❌ Error clearing stored referral code: $error',
            tag: 'deep_link_service');
    }
  }
}
