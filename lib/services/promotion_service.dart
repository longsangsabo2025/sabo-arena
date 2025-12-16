import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club_promotion.dart';

class PromotionService {
  static final _supabase = Supabase.instance.client;

  // Lấy danh sách khuyến mãi của club
  static Future<List<ClubPromotion>> getClubPromotions(String clubId) async {
    try {
      final response = await _supabase
          .from('club_promotions')
          .select()
          .eq('club_id', clubId)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClubPromotion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách khuyến mãi: $e');
    }
  }

  // Lấy khuyến mãi đang hoạt động
  static Future<List<ClubPromotion>> getActivePromotions(String clubId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('club_promotions')
          .select()
          .eq('club_id', clubId)
          .eq('status', 'active')
          .lte('start_date', now)
          .gte('end_date', now)
          .order('priority', ascending: false);

      return (response as List)
          .map((json) => ClubPromotion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải khuyến mãi đang hoạt động: $e');
    }
  }

  // Lấy khuyến mãi theo loại
  static Future<List<ClubPromotion>> getPromotionsByType(
    String clubId,
    PromotionType type,
  ) async {
    try {
      final response = await _supabase
          .from('club_promotions')
          .select()
          .eq('club_id', clubId)
          .eq('type', type.value)
          .eq('status', 'active')
          .order('priority', ascending: false);

      return (response as List)
          .map((json) => ClubPromotion.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải khuyến mãi theo loại: $e');
    }
  }

  // Tạo khuyến mãi mới
  static Future<ClubPromotion> createPromotion(
    Map<String, dynamic> promotionData,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Chưa đăng nhập');

      final data = {
        ...promotionData,
        'created_by': userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'current_redemptions': 0,
      };

      final response = await _supabase
          .from('club_promotions')
          .insert(data)
          .select()
          .single();

      return ClubPromotion.fromJson(response);
    } catch (e) {
      throw Exception('Không thể tạo khuyến mãi: $e');
    }
  }

  // Cập nhật khuyến mãi
  static Future<ClubPromotion> updatePromotion(
    String promotionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = {...updates, 'updated_at': DateTime.now().toIso8601String()};

      final response = await _supabase
          .from('club_promotions')
          .update(data)
          .eq('id', promotionId)
          .select()
          .single();

      return ClubPromotion.fromJson(response);
    } catch (e) {
      throw Exception('Không thể cập nhật khuyến mãi: $e');
    }
  }

  // Xóa khuyến mãi
  static Future<void> deletePromotion(String promotionId) async {
    try {
      await _supabase.from('club_promotions').delete().eq('id', promotionId);
    } catch (e) {
      throw Exception('Không thể xóa khuyến mãi: $e');
    }
  }

  // Áp dụng khuyến mãi
  static Future<PromotionRedemption> redeemPromotion(
    String promotionId,
    String userId,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      // Kiểm tra khuyến mãi còn hiệu lực
      final promotion = await getPromotionById(promotionId);
      if (!promotion.isActive) {
        throw Exception('Khuyến mãi không còn hiệu lực');
      }

      // Kiểm tra số lượt sử dụng
      if (promotion.maxRedemptions != null &&
          promotion.currentRedemptions >= promotion.maxRedemptions!) {
        throw Exception('Khuyến mãi đã đạt số lượt sử dụng tối đa');
      }

      // Tạo redemption record
      final redemptionData = {
        'promotion_id': promotionId,
        'user_id': userId,
        'club_id': promotion.clubId,
        'redeemed_at': DateTime.now().toIso8601String(),
        'metadata': metadata,
        'status': 'completed',
        'discount_applied':
            promotion.discountAmount ??
            (promotion.discountPercentage != null
                ? promotion.discountPercentage! / 100
                : null),
      };

      final redemptionResponse = await _supabase
          .from('promotion_redemptions')
          .insert(redemptionData)
          .select()
          .single();

      // Cập nhật số lượt sử dụng
      await _supabase
          .from('club_promotions')
          .update({'current_redemptions': promotion.currentRedemptions + 1})
          .eq('id', promotionId);

      return PromotionRedemption.fromJson(redemptionResponse);
    } catch (e) {
      throw Exception('Không thể áp dụng khuyến mãi: $e');
    }
  }

  // Lấy chi tiết khuyến mãi
  static Future<ClubPromotion> getPromotionById(String promotionId) async {
    try {
      final response = await _supabase
          .from('club_promotions')
          .select()
          .eq('id', promotionId)
          .single();

      return ClubPromotion.fromJson(response);
    } catch (e) {
      throw Exception('Không thể tải chi tiết khuyến mãi: $e');
    }
  }

  // Lấy lịch sử sử dụng khuyến mãi
  static Future<List<PromotionRedemption>> getPromotionRedemptions(
    String promotionId,
  ) async {
    try {
      final response = await _supabase
          .from('promotion_redemptions')
          .select('''
            *,
            users!inner(full_name, avatar_url)
          ''')
          .eq('promotion_id', promotionId)
          .order('redeemed_at', ascending: false);

      return (response as List)
          .map((json) => PromotionRedemption.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải lịch sử sử dụng: $e');
    }
  }

  // Lấy khuyến mãi của user
  static Future<List<PromotionRedemption>> getUserRedemptions(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('promotion_redemptions')
          .select('''
            *,
            club_promotions!inner(title, description, type, club_id),
            clubs!inner(name, logo_url)
          ''')
          .eq('user_id', userId)
          .order('redeemed_at', ascending: false);

      return (response as List)
          .map((json) => PromotionRedemption.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải lịch sử khuyến mãi: $e');
    }
  }

  // Kiểm tra khuyến mãi bằng mã code
  static Future<ClubPromotion?> getPromotionByCode(
    String promoCode,
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('club_promotions')
          .select()
          .eq('promo_code', promoCode)
          .eq('club_id', clubId)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) return null;
      return ClubPromotion.fromJson(response);
    } catch (e) {
      throw Exception('Không thể kiểm tra mã khuyến mãi: $e');
    }
  }

  // Thống kê khuyến mãi
  static Future<Map<String, dynamic>> getPromotionStats(String clubId) async {
    try {
      final promotions = await getClubPromotions(clubId);
      final activePromotions = promotions.where((p) => p.isActive).length;
      final totalRedemptions = promotions.fold<int>(
        0,
        (sum, p) => sum + p.currentRedemptions,
      );

      final redemptionsResponse = await _supabase
          .from('promotion_redemptions')
          .select('discount_applied')
          .eq('club_id', clubId);

      final totalSavings = (redemptionsResponse as List).fold<double>(
        0.0,
        (sum, r) => sum + (r['discount_applied'] as double? ?? 0.0),
      );

      return {
        'total_promotions': promotions.length,
        'active_promotions': activePromotions,
        'total_redemptions': totalRedemptions,
        'total_savings': totalSavings,
        'expired_promotions': promotions.where((p) => p.isExpired).length,
        'upcoming_promotions': promotions.where((p) => p.isUpcoming).length,
      };
    } catch (e) {
      throw Exception('Không thể tải thống kê khuyến mãi: $e');
    }
  }
}
