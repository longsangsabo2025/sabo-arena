import 'package:supabase_flutter/supabase_flutter.dart';

/// Service quản lý Loyalty Program
/// - Tạo/lấy loyalty account
/// - Award points (per game, per purchase, bonus)
/// - Expire points
/// - Get statistics
class LoyaltyService {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // GET OR CREATE USER LOYALTY ACCOUNT
  // ============================================================

  /// Lấy hoặc tạo mới loyalty account cho user
  /// Returns: user_loyalty_points record
  Future<Map<String, dynamic>> getOrCreateUserLoyalty({
    required String userId,
    required String clubId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_or_create_user_loyalty',
        params: {
          'p_user_id': userId,
          'p_club_id': clubId,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get/create loyalty account: $e');
    }
  }

  // ============================================================
  // AWARD LOYALTY POINTS
  // ============================================================

  /// Award points khi user chơi game
  Future<Map<String, dynamic>> awardPointsForGame({
    required String userId,
    required String clubId,
    required int points,
    String? reference,
    double multiplier = 1.0,
  }) async {
    return _awardPoints(
      userId: userId,
      clubId: clubId,
      points: points,
      type: 'earn_game',
      reference: reference,
      multiplier: multiplier,
    );
  }

  /// Award points khi user mua hàng/nạp tiền
  Future<Map<String, dynamic>> awardPointsForPurchase({
    required String userId,
    required String clubId,
    required int points,
    String? reference,
    double multiplier = 1.0,
  }) async {
    return _awardPoints(
      userId: userId,
      clubId: clubId,
      points: points,
      type: 'earn_purchase',
      reference: reference,
      multiplier: multiplier,
    );
  }

  /// Award bonus points (birthday, special event)
  Future<Map<String, dynamic>> awardBonusPoints({
    required String userId,
    required String clubId,
    required int points,
    required String type, // 'earn_bonus' hoặc 'earn_birthday'
    String? reference,
    double multiplier = 1.0,
  }) async {
    return _awardPoints(
      userId: userId,
      clubId: clubId,
      points: points,
      type: type,
      reference: reference,
      multiplier: multiplier,
    );
  }

  /// Internal method để award points
  Future<Map<String, dynamic>> _awardPoints({
    required String userId,
    required String clubId,
    required int points,
    required String type,
    String? reference,
    double multiplier = 1.0,
  }) async {
    try {
      final response = await _supabase.rpc(
        'award_loyalty_points',
        params: {
          'p_user_id': userId,
          'p_club_id': clubId,
          'p_points': points,
          'p_type': type,
          'p_reference': reference,
          'p_multiplier': multiplier,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to award loyalty points: $e');
    }
  }

  // ============================================================
  // GET USER LOYALTY INFO
  // ============================================================

  /// Lấy thông tin loyalty của user tại 1 club
  Future<Map<String, dynamic>?> getUserLoyalty({
    required String userId,
    required String clubId,
  }) async {
    try {
      final response = await _supabase
          .from('user_loyalty_points')
          .select()
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get user loyalty: $e');
    }
  }

  /// Lấy tất cả loyalty accounts của user (all clubs)
  Future<List<Map<String, dynamic>>> getAllUserLoyalty({
    required String userId,
  }) async {
    try {
      final response = await _supabase.from('user_loyalty_points').select('''
            *,
            club:clubs(id, name, avatar_url)
          ''').eq('user_id', userId).order('total_earned', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get all user loyalty: $e');
    }
  }

  // ============================================================
  // GET LOYALTY TRANSACTIONS
  // ============================================================

  /// Lấy lịch sử transactions của user
  Future<List<Map<String, dynamic>>> getTransactions({
    required String userId,
    required String clubId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('loyalty_transactions')
          .select()
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get loyalty transactions: $e');
    }
  }

  /// Lấy transactions by type
  Future<List<Map<String, dynamic>>> getTransactionsByType({
    required String userId,
    required String clubId,
    required String type, // earn_game, earn_purchase, redeem_reward, etc.
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('loyalty_transactions')
          .select()
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .eq('type', type)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get transactions by type: $e');
    }
  }

  // ============================================================
  // GET CLUB STATISTICS
  // ============================================================

  /// Lấy thống kê loyalty của club
  Future<Map<String, dynamic>> getClubStats({
    required String clubId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_loyalty_stats',
        params: {
          'p_club_id': clubId,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get club loyalty stats: $e');
    }
  }

  // ============================================================
  // GET LOYALTY PROGRAM CONFIG
  // ============================================================

  /// Lấy config của loyalty program
  Future<Map<String, dynamic>?> getLoyaltyProgram({
    required String clubId,
  }) async {
    try {
      final response = await _supabase
          .from('loyalty_programs')
          .select()
          .eq('club_id', clubId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get loyalty program: $e');
    }
  }

  /// Update loyalty program config (club owner only)
  Future<void> updateLoyaltyProgram({
    required String clubId,
    String? programName,
    Map<String, dynamic>? pointsPerGame,
    Map<String, dynamic>? pointsPerVnd,
    Map<String, dynamic>? pointsPerHour,
    Map<String, dynamic>? birthdayMultiplier,
    Map<String, dynamic>? weekendMultiplier,
    Map<String, dynamic>? tierSystem,
    int? pointsExpiryDays,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (programName != null) updates['program_name'] = programName;
      if (pointsPerGame != null) updates['points_per_game'] = pointsPerGame;
      if (pointsPerVnd != null) updates['points_per_vnd'] = pointsPerVnd;
      if (pointsPerHour != null) updates['points_per_hour'] = pointsPerHour;
      if (birthdayMultiplier != null)
        updates['birthday_multiplier'] = birthdayMultiplier;
      if (weekendMultiplier != null)
        updates['weekend_multiplier'] = weekendMultiplier;
      if (tierSystem != null) updates['tier_system'] = tierSystem;
      if (pointsExpiryDays != null)
        updates['points_expiry_days'] = pointsExpiryDays;
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase
          .from('loyalty_programs')
          .update(updates)
          .eq('club_id', clubId);
    } catch (e) {
      throw Exception('Failed to update loyalty program: $e');
    }
  }

  // ============================================================
  // CREATE LOYALTY PROGRAM (FIRST TIME)
  // ============================================================

  /// Tạo loyalty program mới cho club
  Future<Map<String, dynamic>> createLoyaltyProgram({
    required String clubId,
    required String programName,
    int pointsPerGame = 10,
    double pointsPerVnd = 0.001,
    double pointsPerHour = 5.0,
    double birthdayMultiplier = 2.0,
    double weekendMultiplier = 1.5,
    int pointsExpiryDays = 365,
  }) async {
    try {
      final tierSystem = {
        'bronze': {
          'min_points': 0,
          'max_points': 499,
          'discount_percent': 5,
          'priority_booking': 1
        },
        'silver': {
          'min_points': 500,
          'max_points': 1499,
          'discount_percent': 10,
          'priority_booking': 2
        },
        'gold': {
          'min_points': 1500,
          'max_points': 4999,
          'discount_percent': 15,
          'priority_booking': 3
        },
        'platinum': {
          'min_points': 5000,
          'max_points': null,
          'discount_percent': 20,
          'priority_booking': 4
        },
      };

      final response = await _supabase
          .from('loyalty_programs')
          .insert({
            'club_id': clubId,
            'program_name': programName,
            'points_per_game': pointsPerGame,
            'points_per_vnd': pointsPerVnd,
            'points_per_hour': pointsPerHour,
            'birthday_multiplier': birthdayMultiplier,
            'weekend_multiplier': weekendMultiplier,
            'tier_system': tierSystem,
            'points_expiry_days': pointsExpiryDays,
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create loyalty program: $e');
    }
  }

  // ============================================================
  // EXPIRE POINTS (ADMIN/CRON)
  // ============================================================

  /// Expire points cũ (chạy định kỳ hoặc manual)
  Future<int> expireOldPoints() async {
    try {
      final response = await _supabase.rpc('expire_loyalty_points');
      return response as int;
    } catch (e) {
      throw Exception('Failed to expire loyalty points: $e');
    }
  }

  // ============================================================
  // HELPER: Calculate Tier from Points
  // ============================================================

  /// Calculate tier dựa vào points (client-side helper)
  String calculateTier(int points, Map<String, dynamic> tierSystem) {
    if (points >= (tierSystem['platinum']?['min_points'] ?? 5000)) {
      return 'platinum';
    } else if (points >= (tierSystem['gold']?['min_points'] ?? 1500)) {
      return 'gold';
    } else if (points >= (tierSystem['silver']?['min_points'] ?? 500)) {
      return 'silver';
    } else {
      return 'bronze';
    }
  }

  /// Get tier benefits
  Map<String, dynamic>? getTierBenefits(
      String tier, Map<String, dynamic> tierSystem) {
    return tierSystem[tier];
  }

  /// Get points to next tier
  int? getPointsToNextTier(int currentPoints, Map<String, dynamic> tierSystem) {
    if (currentPoints < (tierSystem['silver']?['min_points'] ?? 500)) {
      return (tierSystem['silver']?['min_points'] ?? 500) - currentPoints;
    } else if (currentPoints < (tierSystem['gold']?['min_points'] ?? 1500)) {
      return (tierSystem['gold']?['min_points'] ?? 1500) - currentPoints;
    } else if (currentPoints <
        (tierSystem['platinum']?['min_points'] ?? 5000)) {
      return (tierSystem['platinum']?['min_points'] ?? 5000) - currentPoints;
    }
    return null; // Already at max tier
  }
}
