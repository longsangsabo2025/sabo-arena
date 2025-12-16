import 'package:supabase_flutter/supabase_flutter.dart';

/// Service quản lý Loyalty Rewards
/// - Get rewards catalog
/// - Create/update/delete rewards
/// - Redeem rewards
/// - Track redemption status
class LoyaltyRewardService {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // GET REWARDS CATALOG
  // ============================================================

  /// Lấy tất cả rewards của club
  Future<List<Map<String, dynamic>>> getClubRewards({
    required String clubId,
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('loyalty_rewards')
          .select()
          .eq('club_id', clubId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('points_cost', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get club rewards: $e');
    }
  }

  /// Lấy rewards theo tier
  Future<List<Map<String, dynamic>>> getRewardsByTier({
    required String clubId,
    required String tier, // bronze, silver, gold, platinum
    bool activeOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('loyalty_rewards')
          .select()
          .eq('club_id', clubId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      // Filter by tier (tier_required <= user's tier)
      final tierOrder = {'bronze': 0, 'silver': 1, 'gold': 2, 'platinum': 3};
      final userTierLevel = tierOrder[tier] ?? 0;

      final response = await query.order('points_cost', ascending: true);
      
      // Client-side filtering by tier
      final filtered = (response as List).where((reward) {
        final requiredTier = reward['tier_required'] as String?;
        final requiredLevel = tierOrder[requiredTier ?? 'bronze'] ?? 0;
        return requiredLevel <= userTierLevel;
      }).toList();

      return List<Map<String, dynamic>>.from(filtered);
    } catch (e) {
      throw Exception('Failed to get rewards by tier: $e');
    }
  }

  /// Lấy rewards theo type
  Future<List<Map<String, dynamic>>> getRewardsByType({
    required String clubId,
    required String rewardType, // discount_voucher, free_game, etc.
  }) async {
    try {
      final response = await _supabase
          .from('loyalty_rewards')
          .select()
          .eq('club_id', clubId)
          .eq('reward_type', rewardType)
          .eq('is_active', true)
          .order('points_cost', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get rewards by type: $e');
    }
  }

  /// Lấy 1 reward by ID
  Future<Map<String, dynamic>?> getRewardById({
    required String rewardId,
  }) async {
    try {
      final response = await _supabase
          .from('loyalty_rewards')
          .select()
          .eq('id', rewardId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get reward: $e');
    }
  }

  // ============================================================
  // CREATE/UPDATE REWARDS (CLUB OWNER)
  // ============================================================

  /// Tạo reward mới
  Future<Map<String, dynamic>> createReward({
    required String clubId,
    required String rewardName,
    required String rewardType,
    required int pointsCost,
    required Map<String, dynamic> rewardValue,
    String? description,
    String? imageUrl,
    String tierRequired = 'bronze',
    int? quantityTotal,
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    try {
      final response = await _supabase
          .from('loyalty_rewards')
          .insert({
            'club_id': clubId,
            'reward_name': rewardName,
            'reward_type': rewardType,
            'points_cost': pointsCost,
            'reward_value': rewardValue,
            'description': description,
            'image_url': imageUrl,
            'tier_required': tierRequired,
            'quantity_total': quantityTotal,
            'quantity_available': quantityTotal,
            'valid_from': validFrom?.toIso8601String(),
            'valid_until': validUntil?.toIso8601String(),
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create reward: $e');
    }
  }

  /// Update reward
  Future<void> updateReward({
    required String rewardId,
    String? rewardName,
    String? description,
    String? imageUrl,
    int? pointsCost,
    Map<String, dynamic>? rewardValue,
    String? tierRequired,
    int? quantityTotal,
    int? quantityAvailable,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (rewardName != null) updates['reward_name'] = rewardName;
      if (description != null) updates['description'] = description;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (pointsCost != null) updates['points_cost'] = pointsCost;
      if (rewardValue != null) updates['reward_value'] = rewardValue;
      if (tierRequired != null) updates['tier_required'] = tierRequired;
      if (quantityTotal != null) updates['quantity_total'] = quantityTotal;
      if (quantityAvailable != null) updates['quantity_available'] = quantityAvailable;
      if (validFrom != null) updates['valid_from'] = validFrom.toIso8601String();
      if (validUntil != null) updates['valid_until'] = validUntil.toIso8601String();
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase
          .from('loyalty_rewards')
          .update(updates)
          .eq('id', rewardId);
    } catch (e) {
      throw Exception('Failed to update reward: $e');
    }
  }

  /// Delete reward (soft delete)
  Future<void> deleteReward({
    required String rewardId,
  }) async {
    try {
      await _supabase
          .from('loyalty_rewards')
          .update({'is_active': false})
          .eq('id', rewardId);
    } catch (e) {
      throw Exception('Failed to delete reward: $e');
    }
  }

  // ============================================================
  // REDEEM REWARD
  // ============================================================

  /// Redeem reward (user)
  Future<Map<String, dynamic>> redeemReward({
    required String userId,
    required String rewardId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'redeem_loyalty_reward',
        params: {
          'p_user_id': userId,
          'p_reward_id': rewardId,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to redeem reward: $e');
    }
  }

  // ============================================================
  // GET REDEMPTIONS
  // ============================================================

  /// Lấy redemption history của user
  Future<List<Map<String, dynamic>>> getUserRedemptions({
    required String userId,
    String? clubId,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('loyalty_reward_redemptions')
          .select('''
            *,
            reward:loyalty_rewards(reward_name, reward_type, reward_value, image_url),
            club:clubs(id, name, avatar_url)
          ''')
          .eq('user_id', userId);

      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get user redemptions: $e');
    }
  }

  /// Lấy redemptions của club (club owner view)
  Future<List<Map<String, dynamic>>> getClubRedemptions({
    required String clubId,
    String? status,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('loyalty_reward_redemptions')
          .select('''
            *,
            user:users(id, full_name, avatar_url, phone_number),
            reward:loyalty_rewards(reward_name, reward_type, points_cost)
          ''')
          .eq('club_id', clubId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get club redemptions: $e');
    }
  }

  /// Get single redemption
  Future<Map<String, dynamic>?> getRedemption({
    required String redemptionId,
  }) async {
    try {
      final response = await _supabase
          .from('loyalty_reward_redemptions')
          .select('''
            *,
            user:users(id, full_name, avatar_url, phone_number),
            reward:loyalty_rewards(reward_name, reward_type, reward_value),
            club:clubs(id, name, avatar_url)
          ''')
          .eq('id', redemptionId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get redemption: $e');
    }
  }

  // ============================================================
  // UPDATE REDEMPTION STATUS (CLUB OWNER)
  // ============================================================

  /// Approve redemption (club owner)
  Future<void> approveRedemption({
    required String redemptionId,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('loyalty_reward_redemptions')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
            'notes': notes,
          })
          .eq('id', redemptionId);
    } catch (e) {
      throw Exception('Failed to approve redemption: $e');
    }
  }

  /// Mark as ready to collect
  Future<void> markReadyToCollect({
    required String redemptionId,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('loyalty_reward_redemptions')
          .update({
            'status': 'ready_to_collect',
            'notes': notes,
          })
          .eq('id', redemptionId);
    } catch (e) {
      throw Exception('Failed to mark ready to collect: $e');
    }
  }

  /// Mark as fulfilled (user đã nhận)
  Future<void> markFulfilled({
    required String redemptionId,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('loyalty_reward_redemptions')
          .update({
            'status': 'fulfilled',
            'fulfilled_at': DateTime.now().toIso8601String(),
            'notes': notes,
          })
          .eq('id', redemptionId);
    } catch (e) {
      throw Exception('Failed to mark fulfilled: $e');
    }
  }

  /// Cancel redemption
  Future<void> cancelRedemption({
    required String redemptionId,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('loyalty_reward_redemptions')
          .update({
            'status': 'cancelled',
            'notes': notes,
          })
          .eq('id', redemptionId);
    } catch (e) {
      throw Exception('Failed to cancel redemption: $e');
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get reward redemption stats
  Future<Map<String, dynamic>> getRewardStats({
    required String rewardId,
  }) async {
    try {
      final response = await _supabase
          .from('loyalty_reward_redemptions')
          .select('status')
          .eq('reward_id', rewardId);

      final redemptions = List<Map<String, dynamic>>.from(response);
      
      return {
        'total_redemptions': redemptions.length,
        'pending': redemptions.where((r) => r['status'] == 'pending').length,
        'approved': redemptions.where((r) => r['status'] == 'approved').length,
        'ready_to_collect': redemptions.where((r) => r['status'] == 'ready_to_collect').length,
        'fulfilled': redemptions.where((r) => r['status'] == 'fulfilled').length,
        'cancelled': redemptions.where((r) => r['status'] == 'cancelled').length,
        'expired': redemptions.where((r) => r['status'] == 'expired').length,
      };
    } catch (e) {
      throw Exception('Failed to get reward stats: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Check if reward is available
  bool isRewardAvailable(Map<String, dynamic> reward) {
    // Check if active
    if (reward['is_active'] != true) return false;

    // Check quantity
    final quantityAvailable = reward['quantity_available'] as int?;
    if (quantityAvailable != null && quantityAvailable <= 0) return false;

    // Check validity dates
    final now = DateTime.now();
    final validFrom = reward['valid_from'] != null 
        ? DateTime.parse(reward['valid_from']) 
        : null;
    final validUntil = reward['valid_until'] != null 
        ? DateTime.parse(reward['valid_until']) 
        : null;

    if (validFrom != null && now.isBefore(validFrom)) return false;
    if (validUntil != null && now.isAfter(validUntil)) return false;

    return true;
  }

  /// Check if user can redeem reward (points + tier)
  bool canUserRedeemReward({
    required Map<String, dynamic> reward,
    required int userPoints,
    required String userTier,
  }) {
    // Check if available
    if (!isRewardAvailable(reward)) return false;

    // Check points
    final pointsCost = reward['points_cost'] as int;
    if (userPoints < pointsCost) return false;

    // Check tier
    final requiredTier = reward['tier_required'] as String? ?? 'bronze';
    final tierOrder = {'bronze': 0, 'silver': 1, 'gold': 2, 'platinum': 3};
    final userTierLevel = tierOrder[userTier] ?? 0;
    final requiredLevel = tierOrder[requiredTier] ?? 0;
    
    if (userTierLevel < requiredLevel) return false;

    return true;
  }
}
