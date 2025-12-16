import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_achievement.dart';
import '../models/club_promotion.dart';

class VoucherRewardService {
  static final VoucherRewardService _instance =
      VoucherRewardService._internal();
  factory VoucherRewardService() => _instance;
  VoucherRewardService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // ACHIEVEMENT MANAGEMENT
  // =====================================================

  /// Lấy tất cả achievements của user
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('user_achievements')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserAchievement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user achievements: $e');
    }
  }

  /// Kiểm tra và cập nhật progress cho achievements
  Future<List<UserAchievement>> checkAndUpdateProgress({
    required String userId,
    required AchievementType type,
    int incrementBy = 1,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Lấy tất cả achievements chưa hoàn thành của type này
      final activeAchievements = await _supabase
          .from('user_achievements')
          .select('*')
          .eq('user_id', userId)
          .eq('type', type.name)
          .eq('is_completed', false);

      List<UserAchievement> completedAchievements = [];

      for (final achievementData in activeAchievements) {
        final achievement = UserAchievement.fromJson(achievementData);
        final newProgress = achievement.progressCurrent + incrementBy;

        // Cập nhật progress
        await _supabase
            .from('user_achievements')
            .update({
              'progress_current': newProgress,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', achievement.id);

        // Kiểm tra xem đã hoàn thành chưa
        if (newProgress >= achievement.progressRequired) {
          final completedAchievement = await _completeAchievement(
            achievement.copyWith(
              progressCurrent: newProgress,
              isCompleted: true,
              completedAt: DateTime.now(),
            ),
          );
          completedAchievements.add(completedAchievement);
        }
      }

      return completedAchievements;
    } catch (e) {
      throw Exception('Failed to update achievement progress: $e');
    }
  }

  /// Hoàn thành achievement và tạo vouchers reward
  Future<UserAchievement> _completeAchievement(
    UserAchievement achievement,
  ) async {
    try {
      // Mark achievement as completed
      await _supabase
          .from('user_achievements')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', achievement.id);

      // Tạo vouchers reward dựa trên achievement type
      final voucherIds = await _generateAchievementRewards(achievement);

      // Cập nhật achievement với voucher IDs
      await _supabase
          .from('user_achievements')
          .update({'reward_voucher_ids': voucherIds})
          .eq('id', achievement.id);

      return achievement.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        rewardVoucherIds: voucherIds,
      );
    } catch (e) {
      throw Exception('Failed to complete achievement: $e');
    }
  }

  /// Tạo vouchers reward dựa trên achievement
  Future<List<String>> _generateAchievementRewards(
    UserAchievement achievement,
  ) async {
    try {
      // Lấy danh sách promotions đang active từ các CLB
      final activePromotions = await _supabase
          .from('club_promotions')
          .select('*, clubs(name)')
          .eq('status', 'active')
          .lte('start_date', DateTime.now().toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String())
          .limit(5); // Tối đa 5 vouchers

      List<String> voucherIds = [];

      for (final promotionData in activePromotions) {
        final promotion = ClubPromotion.fromJson(promotionData);

        // Tạo voucher code unique
        final voucherCode = _generateVoucherCode(
          achievement.type,
          promotion.clubId,
        );

        // Tạo voucher record
        final voucherResponse = await _supabase
            .from('user_vouchers')
            .insert({
              'user_id': achievement.userId,
              'promotion_id': promotion.id,
              'club_id': promotion.clubId,
              'club_name': promotionData['clubs']['name'] ?? 'Unknown Club',
              'voucher_code': voucherCode,
              'source': VoucherSource.achievement.name,
              'source_id': achievement.id,
              'title': '${achievement.title} Reward',
              'description':
                  'Voucher khuyến mãi từ thành tựu: ${achievement.description}',
              'image_url': promotion.imageUrl,
              'type': _mapPromotionTypeToVoucherType(promotion.type).name,
              'status': VoucherStatus.active.name,
              'discount_amount': promotion.discountAmount,
              'discount_percentage': promotion.discountPercentage,
              'min_order_amount': promotion.conditions?['minOrderAmount'] ?? 0,
              'issued_at': DateTime.now().toIso8601String(),
              'expires_at': DateTime.now()
                  .add(Duration(days: 30))
                  .toIso8601String(),
              'metadata': {
                'achievement_type': achievement.type.name,
                'achievement_title': achievement.title,
                'club_promotion_type': promotion.type.name,
              },
            })
            .select('id')
            .single();

        voucherIds.add(voucherResponse['id']);
      }

      return voucherIds;
    } catch (e) {
      throw Exception('Failed to generate achievement rewards: $e');
    }
  }

  // =====================================================
  // VOUCHER MANAGEMENT
  // =====================================================

  /// Lấy tất cả vouchers của user
  Future<List<UserVoucher>> getUserVouchers(
    String userId, {
    VoucherStatus? status,
  }) async {
    try {
      var query = _supabase
          .from('user_vouchers')
          .select('*')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query.order('issued_at', ascending: false);

      return (response as List)
          .map((json) => UserVoucher.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user vouchers: $e');
    }
  }

  /// Sử dụng voucher
  Future<bool> useVoucher(String voucherId, String clubId) async {
    try {
      final response = await _supabase
          .from('user_vouchers')
          .update({
            'status': VoucherStatus.used.name,
            'used_at': DateTime.now().toIso8601String(),
            'used_at_club': clubId,
          })
          .eq('id', voucherId)
          .eq('status', VoucherStatus.active.name)
          .select()
          .single();

      return true;
    } catch (e) {
      throw Exception('Failed to use voucher: $e');
    }
  }

  /// Validate voucher code tại CLB
  Future<UserVoucher?> validateVoucherCode(
    String voucherCode,
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('user_vouchers')
          .select('*')
          .eq('voucher_code', voucherCode)
          .eq('club_id', clubId)
          .eq('status', VoucherStatus.active.name)
          .maybeSingle();

      if (response == null) return null;

      final voucher = UserVoucher.fromJson(response);

      // Kiểm tra expiry
      if (voucher.isExpired) {
        await _supabase
            .from('user_vouchers')
            .update({'status': VoucherStatus.expired.name})
            .eq('id', voucher.id);
        return null;
      }

      return voucher;
    } catch (e) {
      throw Exception('Failed to validate voucher: $e');
    }
  }

  // =====================================================
  // ACHIEVEMENT TRIGGERS
  // =====================================================

  /// Trigger khi user hoàn thành match
  Future<List<UserAchievement>> onMatchCompleted({
    required String userId,
    required bool won,
    required String clubId,
  }) async {
    List<UserAchievement> completed = [];

    // Matches played achievement
    completed.addAll(
      await checkAndUpdateProgress(
        userId: userId,
        type: AchievementType.matchesPlayed,
        context: {'club_id': clubId},
      ),
    );

    // Matches won achievement
    if (won) {
      completed.addAll(
        await checkAndUpdateProgress(
          userId: userId,
          type: AchievementType.matchesWon,
          context: {'club_id': clubId},
        ),
      );
    }

    return completed;
  }

  /// Trigger khi user tham gia tournament
  Future<List<UserAchievement>> onTournamentJoined({
    required String userId,
    required String tournamentId,
    required String clubId,
  }) async {
    return await checkAndUpdateProgress(
      userId: userId,
      type: AchievementType.tournamentsJoined,
      context: {'tournament_id': tournamentId, 'club_id': clubId},
    );
  }

  /// Trigger khi user thắng tournament
  Future<List<UserAchievement>> onTournamentWon({
    required String userId,
    required String tournamentId,
    required String clubId,
  }) async {
    return await checkAndUpdateProgress(
      userId: userId,
      type: AchievementType.tournamentsWon,
      context: {'tournament_id': tournamentId, 'club_id': clubId},
    );
  }

  /// Trigger khi user visit CLB
  Future<List<UserAchievement>> onClubVisit({
    required String userId,
    required String clubId,
  }) async {
    return await checkAndUpdateProgress(
      userId: userId,
      type: AchievementType.clubVisits,
      context: {'club_id': clubId},
    );
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  String _generateVoucherCode(AchievementType achievementType, String clubId) {
    final prefix = achievementType.name.substring(0, 2).toUpperCase();
    final clubPrefix = clubId.substring(0, 2).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    return '$prefix$clubPrefix$timestamp';
  }

  VoucherType _mapPromotionTypeToVoucherType(PromotionType promotionType) {
    switch (promotionType) {
      case PromotionType.discount:
        return VoucherType.percentageDiscount;
      case PromotionType.cashback:
        return VoucherType.fixedDiscount;
      case PromotionType.freeService:
        return VoucherType.freeService;
      case PromotionType.bundleOffer:
        return VoucherType.percentageDiscount;
      case PromotionType.membershipDiscount:
        return VoucherType.percentageDiscount;
      case PromotionType.eventSpecial:
        return VoucherType.fixedDiscount;
      case PromotionType.seasonalOffer:
        return VoucherType.percentageDiscount;
      case PromotionType.loyaltyReward:
        return VoucherType.percentageDiscount;
    }
  }

  /// Get statistics for admin dashboard
  Future<Map<String, dynamic>> getVoucherStatistics() async {
    try {
      final totalVouchersResponse = await _supabase
          .from('user_vouchers')
          .select('*');
      final totalVouchers = totalVouchersResponse.length;

      final usedVouchersResponse = await _supabase
          .from('user_vouchers')
          .select('*')
          .eq('status', VoucherStatus.used.name);
      final usedVouchers = usedVouchersResponse.length;

      final expiredVouchersResponse = await _supabase
          .from('user_vouchers')
          .select('*')
          .eq('status', VoucherStatus.expired.name);
      final expiredVouchers = expiredVouchersResponse.length;

      final activeVouchersResponse = await _supabase
          .from('user_vouchers')
          .select('*')
          .eq('status', VoucherStatus.active.name);
      final activeVouchers = activeVouchersResponse.length;

      return {
        'total_vouchers': totalVouchers,
        'used_vouchers': usedVouchers,
        'expired_vouchers': expiredVouchers,
        'active_vouchers': activeVouchers,
        'usage_rate': totalVouchers > 0
            ? (usedVouchers / totalVouchers * 100).round()
            : 0,
      };
    } catch (e) {
      throw Exception('Failed to get voucher statistics: $e');
    }
  }
}

// Extension để add copyWith method cho UserAchievement
extension UserAchievementExtension on UserAchievement {
  UserAchievement copyWith({
    String? id,
    String? userId,
    String? achievementId,
    AchievementType? type,
    String? title,
    String? description,
    String? iconUrl,
    Map<String, dynamic>? criteria,
    int? progressCurrent,
    int? progressRequired,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? rewardVoucherIds,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      criteria: criteria ?? this.criteria,
      progressCurrent: progressCurrent ?? this.progressCurrent,
      progressRequired: progressRequired ?? this.progressRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rewardVoucherIds: rewardVoucherIds ?? this.rewardVoucherIds,
    );
  }
}
