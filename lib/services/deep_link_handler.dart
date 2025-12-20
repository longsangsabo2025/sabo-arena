import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'deep_link_service.dart';
import '../presentation/other_user_profile_screen/other_user_profile_screen.dart';
import '../services/auth_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service xử lý deep links cho QR referral system và authentication
class DeepLinkHandler {
  static StreamSubscription? _sub;
  static final _supabase = Supabase.instance.client;
  static final _appLinks = AppLinks();

  /// Initialize deep link listener
  static Future<void> init(BuildContext context) async {
    ProductionLogger.info('🔗 Initializing deep link handler...',
        tag: 'deep_link_handler');

    // Handle initial link (app opened from terminated state)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && context.mounted) {
        ProductionLogger.info('🔗 Initial deep link: $initialUri',
            tag: 'deep_link_handler');
        await _handleDeepLink(context, initialUri);
      }
    } catch (e) {
      ProductionLogger.info('❌ Error getting initial link: $e',
          tag: 'deep_link_handler');
    }

    // Handle links while app is running
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      if (context.mounted) {
        ProductionLogger.info('🔗 Deep link received: $uri',
            tag: 'deep_link_handler');
        _handleDeepLink(context, uri);
      }
    }, onError: (err) {
      ProductionLogger.info('❌ Deep link error: $err',
          tag: 'deep_link_handler');
    });

    ProductionLogger.info('✅ Deep link handler initialized',
        tag: 'deep_link_handler');
  }

  /// Handle deep link
  static Future<void> _handleDeepLink(BuildContext context, Uri uri) async {
    ProductionLogger.info('📱 Processing deep link: ${uri.toString()}',
        tag: 'deep_link_handler');
    ProductionLogger.info('   Scheme: ${uri.scheme}', tag: 'deep_link_handler');
    ProductionLogger.info('   Host: ${uri.host}', tag: 'deep_link_handler');
    ProductionLogger.info('   Path: ${uri.path}', tag: 'deep_link_handler');
    ProductionLogger.info('   Query: ${uri.queryParameters}',
        tag: 'deep_link_handler');
    ProductionLogger.info('   Fragment: ${uri.fragment}',
        tag: 'deep_link_handler');

    // 🎯 PRIORITY 1: Handle QR Referral Links
    // Format: https://saboarena.com/user/{userCode}?ref={referralCode}
    // Note: userCode is like "SABO123456", not the actual user UUID
    if (uri.host.contains('saboarena.com') || uri.host.contains('localhost')) {
      final pathSegments = uri.pathSegments;

      // User profile with referral code
      if (pathSegments.length >= 2 && pathSegments[0] == 'user') {
        final userCode = pathSegments[1]; // e.g. "SABO123456"
        final referralCode = uri.queryParameters['ref'];

        ProductionLogger.info('👤 User profile deep link detected',
            tag: 'deep_link_handler');
        ProductionLogger.info('   User Code: $userCode',
            tag: 'deep_link_handler');
        ProductionLogger.info('   Referral code: $referralCode',
            tag: 'deep_link_handler');

        // Find user by user_code to get actual user ID
        final userId = await _getUserIdFromUserCode(userCode);

        if (userId == null) {
          ProductionLogger.info('❌ User not found for code: $userCode',
              tag: 'deep_link_handler');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Không tìm thấy người dùng'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (!context.mounted) return;

        if (referralCode != null && referralCode.isNotEmpty) {
          // Process QR referral
          await _handleQRReferral(context, userId, referralCode);
          return;
        } else {
          // Navigate to user profile without referral
          await _navigateToUserProfile(context, userId);
          return;
        }
      }

      // Tournament deep link
      if (pathSegments.length >= 2 && pathSegments[0] == 'tournament') {
        final tournamentId = pathSegments[1];
        ProductionLogger.info('🏆 Tournament deep link: $tournamentId',
            tag: 'deep_link_handler');

        if (context.mounted) {
          Navigator.of(context).pushNamed(
            '/tournament-details',
            arguments: {'tournamentId': tournamentId},
          );
        }
        return;
      }

      // Club deep link
      if (pathSegments.length >= 2 && pathSegments[0] == 'club') {
        final clubId = pathSegments[1];
        ProductionLogger.info('🎪 Club deep link: $clubId',
            tag: 'deep_link_handler');

        if (context.mounted) {
          Navigator.of(context).pushNamed(
            '/club-details',
            arguments: {'clubId': clubId},
          );
        }
        return;
      }
    }

    // 🎯 PRIORITY 2: Handle Supabase Auth Links
    // Extract tokens from URL
    String? accessToken;
    String? type;

    // Check fragment first (Supabase usually puts tokens here)
    if (uri.fragment.isNotEmpty) {
      final fragment = uri.fragment;
      final params = Uri.splitQueryString(fragment);
      accessToken = params['access_token'];
      type = params['type'];
      ProductionLogger.info('   Fragment params: $params',
          tag: 'deep_link_handler');
    }

    // Fallback to query parameters
    if (accessToken == null) {
      accessToken = uri.queryParameters['access_token'];
      type = uri.queryParameters['type'];
      ProductionLogger.info('   Query params: ${uri.queryParameters}',
          tag: 'deep_link_handler');
    }

    // Handle email verification
    if (type == 'signup' ||
        uri.path.contains('email-confirmed') ||
        uri.path.contains('auth/callback')) {
      if (accessToken != null) {
        try {
          // Set session with tokens
          await _supabase.auth.setSession(accessToken);

          ProductionLogger.info('✅ Email verification successful!',
              tag: 'deep_link_handler');

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '✅ Email đã được xác nhận thành công!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Navigate to home
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        } catch (e) {
          ProductionLogger.info('❌ Error setting session: $e',
              tag: 'deep_link_handler');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Lỗi xác nhận email: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ProductionLogger.info('⚠️ No access token found in deep link',
            tag: 'deep_link_handler');

        // Still navigate to home if user is already logged in
        final session = _supabase.auth.currentSession;
        if (session != null && context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      }
    }

    // Handle password reset
    else if (type == 'recovery') {
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          '/reset-password',
          arguments: {'access_token': accessToken},
        );
      }
    }

    // Handle magic link
    else if (type == 'magiclink') {
      if (accessToken != null) {
        try {
          await _supabase.auth.setSession(accessToken);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Đăng nhập thành công!'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        } catch (e) {
          ProductionLogger.info('❌ Error with magic link: $e',
              tag: 'deep_link_handler');
        }
      }
    }
  }

  /// Handle QR referral code
  static Future<void> _handleQRReferral(
    BuildContext context,
    String userId,
    String referralCode,
  ) async {
    ProductionLogger.info('🎯 Processing QR referral...',
        tag: 'deep_link_handler');
    ProductionLogger.info('   Target user: $userId', tag: 'deep_link_handler');
    ProductionLogger.info('   Referral code: $referralCode',
        tag: 'deep_link_handler');

    // Get current user
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      // User not logged in - Store referral code for after login
      ProductionLogger.info('👤 User not logged in - storing referral code',
          tag: 'deep_link_handler');
      await DeepLinkService.instance.storeReferralCodeForNewUser(referralCode);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎁 Đăng nhập để nhận thưởng giới thiệu!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to login
        Navigator.of(context).pushNamed('/login');
      }
      return;
    }

    // User is logged in - Process referral immediately
    final currentUserId = currentUser.id;

    // Don't allow self-referral
    if (currentUserId == userId) {
      ProductionLogger.info('⚠️ Self-referral attempt blocked',
          tag: 'deep_link_handler');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('⚠️ Bạn không thể sử dụng mã giới thiệu của chính mình!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Process referral code
    try {
      final success = await DeepLinkService.instance.processReferralCode(
        referralCode,
        currentUserId,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Nhận thưởng giới thiệu thành công! +25 SPA'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Mã giới thiệu không hợp lệ hoặc đã sử dụng'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Navigate to the user's profile
        await _navigateToUserProfile(context, userId);
      }
    } catch (e) {
      ProductionLogger.info('❌ Error processing referral: $e',
          tag: 'deep_link_handler');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xử lý mã giới thiệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper: Get user ID from user_code (e.g., "SABO123456" -> UUID)
  static Future<String?> _getUserIdFromUserCode(String userCode) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('user_code', userCode)
          .single();

      return response['id'] as String?;
    } catch (e) {
      ProductionLogger.info('❌ Error finding user by code: $e',
          tag: 'deep_link_handler');
      return null;
    }
  }

  /// Helper: Navigate to user profile (own profile or other user's profile)
  static Future<void> _navigateToUserProfile(
    BuildContext context,
    String userId,
  ) async {
    if (!context.mounted) return;

    // Check if viewing own profile or another user's profile
    final currentUserId = AuthService.instance.currentUser?.id;

    if (currentUserId == userId) {
      // Navigate to own profile (UserProfileScreen)
      Navigator.of(context).pushNamed('/profile');
    } else {
      // Navigate to other user's profile
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(userId: userId),
        ),
      );
    }
  }

  /// Dispose listener
  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
