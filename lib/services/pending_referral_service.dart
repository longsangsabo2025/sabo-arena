import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import 'dart:io' show Platform;

/// Service to claim pending referral from server-side tracking
class PendingReferralService {
  static PendingReferralService? _instance;
  static PendingReferralService get instance =>
      _instance ??= PendingReferralService._();
  PendingReferralService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Claim pending referral after user registration
  /// This matches with referral clicks tracked on website
  Future<Map<String, dynamic>> claimPendingReferral(String newUserId) async {
    try {
      if (kDebugMode) {
        ProductionLogger.info(
            '🎯 Attempting to claim pending referral for user: $newUserId',
            tag: 'pending_referral_service');
      }

      // Get device info for matching
      final deviceFingerprint = await _getDeviceFingerprint();
      final userAgent = await _getUserAgent();
      final ipAddress = ''; // Will be captured by backend from request

      if (kDebugMode) {
        ProductionLogger.info('📱 Device fingerprint: $deviceFingerprint',
            tag: 'pending_referral_service');
        ProductionLogger.info('🌐 User agent: $userAgent',
            tag: 'pending_referral_service');
      }

      // Call Supabase RPC to claim pending referral
      final response = await _supabase.rpc('claim_pending_referral', params: {
        'p_new_user_id': newUserId,
        'p_device_fingerprint': deviceFingerprint,
        'p_ip_address': ipAddress,
        'p_user_agent': userAgent,
      });

      if (kDebugMode) {
        ProductionLogger.info('📊 Claim response: $response',
            tag: 'pending_referral_service');
      }

      // Response is JSONB, parse it
      if (response is Map<String, dynamic>) {
        final success = response['success'] == true;

        if (success) {
          if (kDebugMode) {
            ProductionLogger.info('✅ Pending referral claimed successfully!',
                tag: 'pending_referral_service');
            ProductionLogger.info(
                '   Referral code: ${response['referral_code']}',
                tag: 'pending_referral_service');
            ProductionLogger.info(
                '   Referee bonus: ${response['referee_bonus']} SPA',
                tag: 'pending_referral_service');
            ProductionLogger.info(
                '   Referrer bonus: ${response['referrer_bonus']} SPA',
                tag: 'pending_referral_service');
            ProductionLogger.info(
                '   Match method: ${response['match_method']}',
                tag: 'pending_referral_service');
          }

          // Clear any stored referral code since we claimed server-side one
          await _clearStoredReferralCode();

          return {
            'success': true,
            'claimed': true,
            'referral_code': response['referral_code'],
            'referee_bonus': response['referee_bonus'],
            'referrer_bonus': response['referrer_bonus'],
            'match_method': response['match_method'],
            'message': response['message'],
          };
        } else {
          if (kDebugMode) {
            ProductionLogger.info(
                '⚠️  No pending referral found: ${response['message']}',
                tag: 'pending_referral_service');
          }

          return {
            'success': true,
            'claimed': false,
            'message': response['message'],
          };
        }
      }

      return {
        'success': false,
        'claimed': false,
        'message': 'Invalid response format',
      };
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('❌ Error claiming pending referral: $error',
            tag: 'pending_referral_service');
      }

      return {
        'success': false,
        'claimed': false,
        'error': error.toString(),
        'message': 'Error claiming pending referral',
      };
    }
  }

  /// Get device fingerprint for matching
  /// This is a simple implementation - for better accuracy, use device_info_plus
  Future<String> _getDeviceFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we already have a fingerprint
      String? fingerprint = prefs.getString('device_fingerprint');

      if (fingerprint == null) {
        // Generate new fingerprint
        // In production, use device_info_plus to get real device info
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fingerprint = 'flutter_${Platform.operatingSystem}_$timestamp';

        // Store it
        await prefs.setString('device_fingerprint', fingerprint);

        if (kDebugMode) {
          ProductionLogger.info(
              '🆕 Generated new device fingerprint: $fingerprint',
              tag: 'pending_referral_service');
        }
      }

      return fingerprint;
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('❌ Error getting device fingerprint: $error',
            tag: 'pending_referral_service');
      }
      return 'unknown_device';
    }
  }

  /// Get user agent string
  Future<String> _getUserAgent() async {
    try {
      // Build user agent from platform info
      final platform = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;

      return 'SaboArena/1.0 ($platform; $version)';
    } catch (error) {
      return 'SaboArena/1.0 (Unknown)';
    }
  }

  /// Clear stored referral code
  Future<void> _clearStoredReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_referral_code');
      await prefs.remove('referral_code_expiry');

      if (kDebugMode) {
        ProductionLogger.info('🗑️  Cleared stored referral code',
            tag: 'pending_referral_service');
      }
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('❌ Error clearing stored referral code: $error',
            tag: 'pending_referral_service');
      }
    }
  }
}
