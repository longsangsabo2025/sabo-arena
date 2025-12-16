import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to manage Club SPA balance and reward system
/// Handles all SPA-related operations for clubs and users
class ClubSpaService {
  static final ClubSpaService _instance = ClubSpaService._internal();
  factory ClubSpaService() => _instance;
  ClubSpaService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get SPA balance for a specific club
  Future<Map<String, dynamic>?> getClubSpaBalance(String clubId) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('club_spa_balances')
          .select('*')
          .eq('club_id', clubId)
          .maybeSingle();

      if (response == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return null;
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return response;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Get user's SPA balance in a specific club
  Future<Map<String, dynamic>?> getUserSpaBalance(
    String userId,
    String clubId,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Try user_spa_balances first
      final response = await _supabase
          .from('user_spa_balances')
          .select('*')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .maybeSingle();

      if (response != null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {
          'user_id': userId,
          'club_id': clubId,
          'spa_balance': response['current_balance'] ?? 0,
          'total_earned': response['total_earned'] ?? 0,
          'total_spent': response['total_spent'] ?? 0,
        };
      }

      // Fallback: Check users table for spa_points
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      final userResponse = await _supabase
          .from('users')
          .select('spa_points')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse != null && userResponse['spa_points'] != null) {
        final spaPoints = userResponse['spa_points'] as int;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {
          'user_id': userId,
          'club_id': clubId,
          'spa_balance': spaPoints,
          'total_earned': spaPoints,
          'total_spent': 0,
        };
      }

      // No balance found anywhere
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'user_id': userId,
        'club_id': clubId,
        'spa_balance': 0,
        'total_earned': 0,
        'total_spent': 0,
      };
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Get SPA transaction history for a user in a club
  Future<List<Map<String, dynamic>>> getUserSpaTransactions(
    String userId,
    String clubId, {
    int limit = 50,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('spa_transactions')
          .select('*')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(limit);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  /// Award SPA bonus to user (used when user wins challenges)
  Future<bool> awardSpaBonus(
    String userId,
    String clubId,
    double spaAmount, {
    String? matchId,
    String? description,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Call the database function to award SPA bonus
      final response = await _supabase.rpc(
        'award_spa_bonus',
        params: {
          'p_user_id': userId,
          'p_club_id': clubId,
          'p_spa_amount': spaAmount,
          'p_match_id': matchId,
        },
      );

      if (response == true) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return true;
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return false;
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Get all available rewards for a club
  Future<List<Map<String, dynamic>>> getClubRewards(String clubId) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('spa_rewards')
          .select('*')
          .eq('club_id', clubId)
          .eq('is_active', true)
          .order('spa_cost');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  /// Create a new reward (club owner only)
  Future<bool> createReward({
    required String clubId,
    required String rewardName,
    required String rewardDescription,
    required String rewardType,
    required double spaCost,
    required String rewardValue,
    int? quantityAvailable,
    DateTime? validUntil,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      await _supabase.from('spa_rewards').insert({
        'club_id': clubId,
        'reward_name': rewardName,
        'reward_description': rewardDescription,
        'reward_type': rewardType,
        'spa_cost': spaCost,
        'reward_value': rewardValue,
        'quantity_available': quantityAvailable,
        'valid_until': validUntil?.toIso8601String(),
        'created_by': _supabase.auth.currentUser?.id,
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Redeem a reward with SPA
  Future<Map<String, dynamic>?> redeemReward(
    String rewardId,
    String userId,
    String clubId,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get reward details first
      final reward = await _supabase
          .from('spa_rewards')
          .select('*')
          .eq('id', rewardId)
          .maybeSingle();

      if (reward == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {'success': false, 'error': 'Reward not found'};
      }

      // Check user has enough SPA
      final userBalance = await getUserSpaBalance(userId, clubId);
      if (userBalance == null ||
          userBalance['spa_balance'] < reward['spa_cost']) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {'success': false, 'error': 'Insufficient SPA balance'};
      }

      // Check quantity if limited
      if (reward['quantity_available'] != null &&
          reward['quantity_claimed'] >= reward['quantity_available']) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {'success': false, 'error': 'Reward is out of stock'};
      }

      // Generate redemption code
      final redemptionCode = _generateRedemptionCode();
      
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Create redemption record first (before deducting SPA)
      final redemption = await _supabase
          .from('spa_reward_redemptions')
          .insert({
            'reward_id': rewardId,
            'user_id': userId,
            'club_id': clubId,
            'spa_spent': reward['spa_cost'],
            'status': 'claimed', // User can immediately use the voucher
            'voucher_code': redemptionCode,
            'redeemed_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // 🎯 NEW: Create user_voucher record so user can actually use the voucher
      final userVoucher = await _supabase
          .from('user_vouchers')
          .insert({
            'user_id': userId,
            'club_id': clubId,
            'voucher_code': redemptionCode,
            'campaign_id': null, // Not from campaign, from SPA redemption
            'status': 'active', // Ready to use
            'issue_reason': 'spa_redemption',
            'issue_details': {
              'reward_id': rewardId,
              'reward_name': reward['reward_name'],
              'spa_spent': reward['spa_cost'],
              'redemption_id': redemption['id'],
            },
            'rewards': {
              'type': reward['reward_type'] ?? 'spa_voucher',
              'name': reward['reward_name'],
              'description': reward['description'] ?? '',
              'value': reward['spa_cost'],
            },
            'usage_rules': {
              'min_order': 0,
              'applicable_to': 'all_services',
              'club_only': true,
            },
            'issued_at': DateTime.now().toIso8601String(),
            'expires_at': DateTime.now()
                .add(const Duration(days: 90))
                .toIso8601String(), // 90 days expiry
          })
          .select()
          .single();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Update redemption record with voucher_id link
      await _supabase
          .from('spa_reward_redemptions')
          .update({'voucher_id': userVoucher['id']})
          .eq('id', redemption['id']);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Now deduct SPA from user balance 
      final currentBalance = userBalance['spa_balance'] ?? userBalance['spa_points'] ?? 0;
      final newBalance = currentBalance - reward['spa_cost'];
      
      await _supabase
          .from('users')
          .update({'spa_points': newBalance})
          .eq('id', userId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Update reward quantity
      final currentAvailable = (reward['available_quantity'] ?? 0) as int;
      if (currentAvailable > 0) {
        await _supabase
            .from('spa_rewards')
            .update({'available_quantity': currentAvailable - 1})
            .eq('id', rewardId);
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // Record transaction
      await _supabase.from('spa_transactions').insert({
        'club_id': clubId,
        'user_id': userId,
        'transaction_type': 'spent',
        'amount': reward['spa_cost'],
        'balance_before': currentBalance,
        'balance_after': newBalance,
        'reference_id': redemption['id'],
        'reference_type': 'reward',
        'description': 'Redeemed reward: ${reward['reward_name']}',
        'created_by': userId,
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': true,
        'redemption': redemption,
        'voucher': userVoucher,
        'redemption_code': redemptionCode,
        'voucher_code': redemptionCode,
        'reward_name': reward['reward_name'],
        'spa_spent': reward['spa_cost'],
        'voucher_id': userVoucher['id'],
        'message': 'Đã tạo voucher thành công! Bạn có thể sử dụng ngay tại quán.',
      };
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      // If there's an error, we should try to rollback any changes made
      // But for now, just return the error
      return {'success': false, 'error': 'Failed to redeem reward: ${e.toString()}'};
    }
  }

  /// Generate a unique redemption code
  String _generateRedemptionCode() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    final random = (timestamp.hashCode % 10000).toString().padLeft(4, '0');
    return 'SPA$timestamp$random';
  }

  /// Get user's reward redemption history
  Future<List<Map<String, dynamic>>> getUserRedemptions(
    String userId,
    String clubId,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('spa_reward_redemptions')
          .select('''
            *,
            spa_rewards (
              reward_name,
              description,
              reward_type
            )
          ''')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .order('redeemed_at', ascending: false);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  /// Admin function to add SPA to club balance
  Future<bool> addSpaToClub(
    String clubId,
    double spaAmount,
    String description,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase.rpc(
        'add_spa_to_club',
        params: {
          'p_club_id': clubId,
          'p_spa_amount': spaAmount,
          'p_description': description,
        },
      );

      if (response == true) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return true;
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return false;
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Get club's SPA transaction history (for club owners)
  Future<List<Map<String, dynamic>>> getClubSpaTransactions(
    String clubId, {
    int limit = 100,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('spa_transactions')
          .select('''
            *,
            auth.users (email)
          ''')
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(limit);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  // ADMIN METHODS

  /// Get all clubs with their SPA balance information (admin only)
  Future<List<Map<String, dynamic>>> getAllClubsWithSpaBalance() async {
    try {
      final response = await _supabase.from('clubs').select('''
            id,
            name,
            club_spa_balances:club_spa_balances!left(
              total_spa_allocated,
              available_spa,
              spent_spa,
              reserved_spa
            )
          ''');

      // Get additional stats for each club
      final enrichedClubs = <Map<String, dynamic>>[];
      for (final club in response) {
        final clubId = club['id'] as String;

        // Get rewards count
        final rewardsResponse = await _supabase
            .from('spa_rewards')
            .select('id')
            .eq('club_id', clubId);

        // Get redemptions count
        final redemptionsResponse = await _supabase
            .from('spa_transactions')
            .select('id')
            .eq('club_id', clubId)
            .eq('transaction_type', 'reward_redemption');

        enrichedClubs.add({
          ...club,
          'rewards_count': rewardsResponse.length,
          'redemptions_count': redemptionsResponse.length,
        });
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return enrichedClubs;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  /// Get all SPA transactions across the system (admin only)
  Future<List<Map<String, dynamic>>> getAllSpaTransactions() async {
    try {
      final response = await _supabase
          .from('spa_transactions')
          .select('''
            *,
            club:clubs!spa_transactions_club_id_fkey(name),
            user:users!spa_transactions_user_id_fkey(full_name)
          ''')
          .order('created_at', ascending: false)
          .limit(100);

      final enrichedTransactions = response
          .map(
            (transaction) => {
              ...transaction,
              'club_name': transaction['club']?['name'],
              'user_name': transaction['user']?['display_name'] ?? transaction['user']?['full_name'],
            },
          )
          .toList();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return List<Map<String, dynamic>>.from(enrichedTransactions);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  /// Get system-wide SPA statistics (admin only)
  Future<Map<String, dynamic>> getSystemSpaStats() async {
    try {
      final results = await Future.wait([
        // Total allocated SPA
        _supabase
            .from('club_spa_balances')
            .select('total_spa_allocated')
            .then(
              (response) => response.fold<double>(
                0,
                (sum, item) =>
                    sum + (item['total_spa_allocated'] as double? ?? 0),
              ),
            ),

        // Total spent SPA
        _supabase
            .from('club_spa_balances')
            .select('spent_spa')
            .then(
              (response) => response.fold<double>(
                0,
                (sum, item) => sum + (item['spent_spa'] as double? ?? 0),
              ),
            ),

        // Total available SPA
        _supabase
            .from('club_spa_balances')
            .select('available_spa')
            .then(
              (response) => response.fold<double>(
                0,
                (sum, item) => sum + (item['available_spa'] as double? ?? 0),
              ),
            ),

        // Total rewards
        _supabase
            .from('spa_rewards')
            .select('id')
            .then((response) => response.length),

        // Total redemptions
        _supabase
            .from('spa_transactions')
            .select('id')
            .eq('transaction_type', 'reward_redemption')
            .then((response) => response.length),

        // Active clubs (with SPA balance)
        _supabase
            .from('club_spa_balances')
            .select('club_id')
            .then((response) => response.length),
      ]);

      final stats = {
        'total_spa_allocated': results[0],
        'total_spa_spent': results[1],
        'total_spa_available': results[2],
        'total_rewards': results[3],
        'total_redemptions': results[4],
        'active_clubs': results[5],
      };

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return stats;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {};
    }
  }

  /// Allocate SPA to a club (admin only)
  Future<bool> allocateSpaToClub({
    required String clubId,
    required double spaAmount,
    String? description,
  }) async {
    try {
      final response = await _supabase.rpc(
        'add_spa_to_club',
        params: {
          'p_club_id': clubId,
          'p_spa_amount': spaAmount,
          'p_description': description ?? 'Admin SPA allocation',
        },
      );

      if (response == true) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return true;
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return false;
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Verify redemption code for staff
  /// Returns redemption details if valid, error if invalid
  Future<Map<String, dynamic>> verifyRedemptionCode(
    String code,
    String clubId,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('spa_reward_redemptions')
          .select('''
            id,
            user_id,
            spa_spent,
            redeemed_at,
            status,
            voucher_code,
            spa_rewards!inner(
              id,
              reward_name,
              description,
              spa_cost,
              club_id
            ),
            users!inner(
              id,
              username,
              email
            )
          ''')
          .eq('voucher_code', code)
          .eq('spa_rewards.club_id', clubId)
          .maybeSingle();

      if (response == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {
          'success': false,
          'error': 'Mã không tồn tại hoặc không thuộc về quán này',
        };
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': true,
        'redemption': response,
      };
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': false,
        'error': 'Lỗi hệ thống khi kiểm tra mã',
      };
    }
  }

  /// Mark redemption as delivered by staff
  Future<Map<String, dynamic>> markRedemptionAsDelivered(
    String redemptionId,
    String clubId,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Verify this redemption belongs to the club
      final verification = await _supabase
          .from('spa_reward_redemptions')
          .select('''
            id,
            status,
            spa_rewards!inner(club_id)
          ''')
          .eq('id', redemptionId)
          .eq('spa_rewards.club_id', clubId)
          .maybeSingle();

      if (verification == null) {
        return {
          'success': false,
          'error': 'Không tìm thấy đơn đổi thưởng này',
        };
      }

      if (verification['status'] == 'delivered') {
        return {
          'success': false,
          'error': 'Đơn đổi thưởng đã được giao trước đó',
        };
      }

      if (verification['status'] == 'cancelled') {
        return {
          'success': false,
          'error': 'Đơn đổi thưởng đã bị hủy',
        };
      }

      // Update status to delivered
      await _supabase
          .from('spa_reward_redemptions')
          .update({
            'status': 'delivered',
            'delivered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', redemptionId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': true,
        'message': 'Đã xác nhận giao thưởng thành công',
      };
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': false,
        'error': 'Lỗi hệ thống khi cập nhật trạng thái',
      };
    }
  }

  /// Get pending redemptions for club (staff dashboard)
  Future<List<Map<String, dynamic>>> getPendingRedemptions(
    String clubId,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('spa_reward_redemptions')
          .select('''
            id,
            user_id,
            spa_spent,
            redeemed_at,
            status,
            voucher_code,
            spa_rewards!inner(
              id,
              reward_name,
              description,
              spa_cost,
              club_id
            ),
            users!inner(
              id,
              username,
              email
            )
          ''')
          .eq('status', 'pending')
          .eq('spa_rewards.club_id', clubId)
          .order('redeemed_at', ascending: false);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  /// Get redemption history for club (staff analytics)
  Future<List<Map<String, dynamic>>> getRedemptionHistory(
    String clubId, {
    int limit = 50,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('spa_reward_redemptions')
          .select('''
            id,
            user_id,
            spa_spent,
            redeemed_at,
            delivered_at,
            status,
            voucher_code,
            spa_rewards!inner(
              id,
              reward_name,
              description,
              spa_cost,
              club_id
            ),
            users!inner(
              id,
              username,
              email
            )
          ''')
          .eq('spa_rewards.club_id', clubId)
          .order('redeemed_at', ascending: false)
          .limit(limit);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }
}

