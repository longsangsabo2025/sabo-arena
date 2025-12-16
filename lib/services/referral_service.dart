import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to manage referral codes for users
class ReferralService {
  static ReferralService? _instance;
  static ReferralService get instance => _instance ??= ReferralService._();
  ReferralService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate a unique referral code for a user
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Create a referral code for a user when they register
  Future<String?> createReferralCodeForUser(String userId) async {
    try {
      // Generate unique code
      String? code; // Make nullable
      bool isUnique = false;

      // Ensure code is unique
      for (int attempts = 0; attempts < 10 && !isUnique; attempts++) {
        code = _generateReferralCode();

        final existing = await _supabase
            .from('referral_codes')
            .select('id')
            .eq('code', code)
            .maybeSingle();

        if (existing == null) {
          isUnique = true;
        }
      }

      if (!isUnique || code == null) {
        throw Exception('Could not generate unique referral code');
      }

      // Create referral code record
      final response = await _supabase
          .from('referral_codes')
          .insert({
            'user_id': userId,
            'code': code,
            'code_type': 'user_referral',
            'max_uses': 10, // Each user can refer up to 10 people
            'current_uses': 0,
            'rewards': {
              'referrer_bonus': 50, // SPA points for referrer
              'referee_bonus': 25, // SPA points for referee
            },
            'expires_at': DateTime.now()
                .add(const Duration(days: 365))
                .toIso8601String(),
            'is_active': true,
          })
          .select('code')
          .single();

      if (kDebugMode) ProductionLogger.info('✅ Referral code created: $code for user: $userId', tag: 'referral_service');
      return response['code'] as String?;
    } catch (error) {
      if (kDebugMode) ProductionLogger.info('❌ Failed to create referral code: $error', tag: 'referral_service');
      return null;
    }
  }

  /// Get user's referral code
  Future<String?> getUserReferralCode(String userId) async {
    try {
      final response = await _supabase
          .from('referral_codes')
          .select('code')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response?['code'] as String?;
    } catch (error) {
      if (kDebugMode) ProductionLogger.info('❌ Failed to get referral code: $error', tag: 'referral_service');
      return null;
    }
  }

  /// Use a referral code (cập nhật để phù hợp với schema thực tế)
  Future<bool> useReferralCode(String code, String userId) async {
    try {
      // Tìm referral_code_id từ code string
      final referralResponse = await _supabase
          .from('referral_codes')
          .select('id, user_id, current_uses, max_uses, rewards')
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();

      if (referralResponse == null) {
        throw Exception('Invalid or expired referral code');
      }

      // Kiểm tra giới hạn sử dụng
      if ((referralResponse['current_uses'] as int) >=
          (referralResponse['max_uses'] as int)) {
        throw Exception('Referral code has reached maximum uses');
      }

      // Kiểm tra user đã sử dụng mã này chưa
      final usageCheck = await _supabase
          .from('referral_usage')
          .select('id')
          .eq('referral_code_id', referralResponse['id'])
          .eq('referred_user_id', userId)
          .maybeSingle();

      if (usageCheck != null) {
        throw Exception('You have already used this referral code');
      }

      // Get bonus amounts from rewards
      final rewards = referralResponse['rewards'] as Map<String, dynamic>;
      final referrerBonus = (rewards['referrer_bonus'] as num?)?.toInt() ?? 50;
      final refereeBonus = (rewards['referee_bonus'] as num?)?.toInt() ?? 25;
      final referrerId = referralResponse['user_id'] as String;

      // Get current SPA points for both users
      final referrerData = await _supabase
          .from('users')
          .select('spa_points')
          .eq('id', referrerId)
          .maybeSingle();
      
      final refereeData = await _supabase
          .from('users')
          .select('spa_points')
          .eq('id', userId)
          .maybeSingle();

      final referrerCurrentSpa = (referrerData?['spa_points'] as num?)?.toInt() ?? 0;
      final refereeCurrentSpa = (refereeData?['spa_points'] as num?)?.toInt() ?? 0;

      // Cập nhật số lần sử dụng
      await _supabase
          .from('referral_codes')
          .update({
            'current_uses': (referralResponse['current_uses'] as int) + 1,
          })
          .eq('id', referralResponse['id']);

      // Cộng SPA cho người giới thiệu (referrer)
      await _supabase
          .from('users')
          .update({
            'spa_points': referrerCurrentSpa + referrerBonus,
          })
          .eq('id', referrerId);

      if (kDebugMode) {
        ProductionLogger.info('✅ Cộng $referrerBonus SPA cho referrer (total: ${referrerCurrentSpa + referrerBonus})', tag: 'referral_service');
      }

      // Cộng SPA cho người được giới thiệu (referee)
      await _supabase
          .from('users')
          .update({
            'spa_points': refereeCurrentSpa + refereeBonus,
          })
          .eq('id', userId);

      if (kDebugMode) {
        ProductionLogger.info('✅ Cộng $refereeBonus SPA cho referee (total: ${refereeCurrentSpa + refereeBonus})', tag: 'referral_service');
      }

      // Ghi nhận transactions
      final now = DateTime.now().toIso8601String();
      await _supabase.from('spa_transactions').insert([
        {
          'user_id': referrerId,
          'amount': referrerBonus,
          'transaction_type': 'referral_bonus',
          'description': 'Thưởng giới thiệu thành viên mới',
          'balance_before': referrerCurrentSpa,
          'balance_after': referrerCurrentSpa + referrerBonus,
          'created_at': now,
        },
        {
          'user_id': userId,
          'amount': refereeBonus,
          'transaction_type': 'welcome_bonus',
          'description': 'Thưởng chào mừng thành viên mới',
          'balance_before': refereeCurrentSpa,
          'balance_after': refereeCurrentSpa + refereeBonus,
          'created_at': now,
        },
      ]);

      if (kDebugMode) ProductionLogger.info('✅ Đã ghi nhận spa_transactions', tag: 'referral_service');

      // Ghi nhận việc sử dụng vào bảng referral_usage
      await _supabase.from('referral_usage').insert({
        'referral_code_id': referralResponse['id'],
        'referrer_id': referrerId,
        'referred_user_id': userId,
        'bonus_awarded': {
          'referrer_bonus': referrerBonus,
          'referee_bonus': refereeBonus
        },
        'status': 'completed',
      });

      if (kDebugMode) ProductionLogger.info('✅ Referral code used successfully: $code', tag: 'referral_service');
      return true;
    } catch (error) {
      if (kDebugMode) ProductionLogger.info('❌ Failed to use referral code: $error', tag: 'referral_service');
      return false;
    }
  }

  /// Check if a user already has a referral code
  Future<bool> userHasReferralCode(String userId) async {
    try {
      final response = await _supabase
          .from('referral_codes')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (error) {
      if (kDebugMode)
        ProductionLogger.info('❌ Failed to check if user has referral code: $error', tag: 'referral_service');
      return false;
    }
  }

  /// Create referral codes for multiple users in batch
  Future<int> createReferralCodesForUsers(List<String> userIds) async {
    int createdCount = 0;

    for (String userId in userIds) {
      try {
        // Check if user already has a referral code
        final hasCode = await userHasReferralCode(userId);
        if (hasCode) {
          if (kDebugMode)
            ProductionLogger.info('⏭️ User $userId already has referral code, skipping', tag: 'referral_service');
          continue;
        }

        // Create referral code for user
        final code = await createReferralCodeForUser(userId);
        if (code != null) {
          createdCount++;
          if (kDebugMode)
            ProductionLogger.info('✅ Created referral code $code for user $userId', tag: 'referral_service');
        } else {
          if (kDebugMode)
            ProductionLogger.info('❌ Failed to create referral code for user $userId', tag: 'referral_service');
        }
      } catch (error) {
        if (kDebugMode)
          ProductionLogger.info('❌ Error creating referral code for user $userId: $error', tag: 'referral_service');
      }
    }

    return createdCount;
  }

  /// Get all users who don't have referral codes yet
  Future<List<String>> getUsersWithoutReferralCodes() async {
    try {
      final usersResponse = await _supabase
          .from('users')
          .select('id')
          .eq('is_active', true);

      final userIds = usersResponse
          .map<String>((user) => user['id'] as String)
          .toList();

      // Get users who already have referral codes
      final existingCodesResponse = await _supabase
          .from('referral_codes')
          .select('user_id')
          .eq('is_active', true);

      final usersWithCodes = <String>{};
      for (var code in existingCodesResponse) {
        if (code['user_id'] != null) {
          usersWithCodes.add(code['user_id'] as String);
        }
      }

      // Return users without referral codes
      return userIds
          .where((userId) => !usersWithCodes.contains(userId))
          .toList();
    } catch (error) {
      if (kDebugMode)
        ProductionLogger.info('❌ Failed to get users without referral codes: $error', tag: 'referral_service');
      return [];
    }
  }

  /// Create referral codes for all existing users who don't have them
  Future<int> createReferralCodesForAllExistingUsers() async {
    try {
      if (kDebugMode)
        ProductionLogger.info('🔄 Starting to create referral codes for existing users...', tag: 'referral_service');

      final usersWithoutCodes = await getUsersWithoutReferralCodes();

      if (usersWithoutCodes.isEmpty) {
        if (kDebugMode) ProductionLogger.info('✅ All users already have referral codes', tag: 'referral_service');
        return 0;
      }

      if (kDebugMode)
        ProductionLogger.info('📋 Found ${usersWithoutCodes.length} users without referral codes',  tag: 'referral_service');

      final createdCount = await createReferralCodesForUsers(usersWithoutCodes);

      if (kDebugMode) ProductionLogger.info('✅ Created referral codes for $createdCount users', tag: 'referral_service');
      return createdCount;
    } catch (error) {
      if (kDebugMode)
        ProductionLogger.info('❌ Failed to create referral codes for existing users: $error', tag: 'referral_service');
      return 0;
    }
  }

  /// Get referral statistics for a user
  Future<Map<String, dynamic>?> getReferralStats(String userId) async {
    try {
      final response = await _supabase
          .from('referral_codes')
          .select('code, current_uses, max_uses, rewards')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      // Đếm số người đã sử dụng mã ref của user này
      final usageCount = await _supabase
          .from('referral_usage')
          .select('id')
          .eq('referrer_id', userId)
          .eq('status', 'completed');

      final totalReferrals = (usageCount as List).length;

      return {
        'code': response['code'],
        'uses': response['current_uses'],
        'max_uses': response['max_uses'],
        'total_referrals': totalReferrals,
        'rewards': response['rewards'],
      };
    } catch (error) {
      if (kDebugMode) ProductionLogger.info('❌ Failed to get referral stats: $error', tag: 'referral_service');
      return null;
    }
  }

  /// Get referral history for a user (list of people they referred)
  Future<List<Map<String, dynamic>>> getReferralHistory(String userId) async {
    try {
      final response = await _supabase
          .from('referral_usage')
          .select('''
            id,
            used_at,
            bonus_awarded,
            status,
            referred_user_id,
            users!referral_usage_referred_user_id_fkey(
              id,
              full_name,
              email,
              avatar_url,
              created_at
            )
          ''')
          .eq('referrer_id', userId)
          .order('used_at', ascending: false);

      final history = <Map<String, dynamic>>[];

      for (var record in response) {
        final userData = record['users'];
        history.add({
          'id': record['id'],
          'used_at': record['used_at'],
          'status': record['status'],
          'reward_earned': record['bonus_awarded']?['referrer_bonus'] ?? 0,
          'referred_user': {
            'id': userData?['id'],
            'name': userData?['full_name'] ?? 'Anonymous',
            'email': userData?['email'],
            'avatar_url': userData?['avatar_url'],
            'joined_at': userData?['created_at'],
          },
        });
      }

      if (kDebugMode) {
        ProductionLogger.info('✅ Loaded ${history.length} referral records for user $userId', tag: 'referral_service');
      }

      return history;
    } catch (error) {
      if (kDebugMode) ProductionLogger.info('❌ Failed to get referral history: $error', tag: 'referral_service');
      return [];
    }
  }

  /// Get summary of total SPA earned from referrals
  Future<int> getTotalSpaEarnedFromReferrals(String userId) async {
    try {
      final response = await _supabase
          .from('spa_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('transaction_type', 'referral_bonus');

      int total = 0;
      for (var tx in response) {
        total += (tx['amount'] as num?)?.toInt() ?? 0;
      }

      return total;
    } catch (error) {
      if (kDebugMode) {
        ProductionLogger.info('❌ Failed to get total SPA from referrals: $error', tag: 'referral_service');
      }
      return 0;
    }
  }
}
