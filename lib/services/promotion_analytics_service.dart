import 'package:supabase_flutter/supabase_flutter.dart';

/// Service quản lý Analytics cho Promotions & Vouchers
/// - Daily analytics
/// - ROI calculation
/// - Club metrics
/// - Promotion comparison
/// - Voucher analytics
class PromotionAnalyticsService {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // CALCULATE ANALYTICS
  // ============================================================

  /// Calculate daily analytics cho 1 promotion
  Future<Map<String, dynamic>> calculateDailyAnalytics({
    required String promotionId,
    required DateTime date,
  }) async {
    try {
      final response = await _supabase.rpc(
        'calculate_promotion_daily_analytics',
        params: {
          'p_promotion_id': promotionId,
          'p_date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to calculate daily analytics: $e');
    }
  }

  /// Calculate ROI cho 1 promotion
  Future<double> calculateROI({
    required String promotionId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'calculate_promotion_roi',
        params: {
          'p_promotion_id': promotionId,
        },
      );

      return (response as num).toDouble();
    } catch (e) {
      throw Exception('Failed to calculate ROI: $e');
    }
  }

  // ============================================================
  // GET CLUB METRICS
  // ============================================================

  /// Lấy comprehensive metrics của club
  Future<Map<String, dynamic>> getClubMetrics({
    required String clubId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_club_promotion_metrics',
        params: {
          'p_club_id': clubId,
          'p_start_date': startDate?.toIso8601String().split('T')[0],
          'p_end_date': endDate?.toIso8601String().split('T')[0],
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get club metrics: $e');
    }
  }

  // ============================================================
  // COMPARE PROMOTIONS
  // ============================================================

  /// So sánh nhiều promotions side-by-side
  Future<List<Map<String, dynamic>>> comparePromotions({
    required List<String> promotionIds,
  }) async {
    try {
      final response = await _supabase.rpc(
        'compare_promotions',
        params: {
          'p_promotion_ids': promotionIds,
        },
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to compare promotions: $e');
    }
  }

  // ============================================================
  // VOUCHER ANALYTICS
  // ============================================================

  /// Calculate voucher analytics
  Future<Map<String, dynamic>> calculateVoucherAnalytics({
    required String campaignId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'calculate_voucher_analytics',
        params: {
          'p_campaign_id': campaignId,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to calculate voucher analytics: $e');
    }
  }

  // ============================================================
  // GET DAILY ANALYTICS
  // ============================================================

  /// Lấy daily analytics của 1 promotion
  Future<List<Map<String, dynamic>>> getDailyAnalytics({
    required String promotionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('promotion_analytics_daily')
          .select()
          .eq('promotion_id', promotionId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get daily analytics: $e');
    }
  }

  /// Lấy daily analytics của club (all promotions)
  Future<List<Map<String, dynamic>>> getClubDailyAnalytics({
    required String clubId,
    DateTime? date,
  }) async {
    try {
      var query = _supabase
          .from('promotion_analytics_daily')
          .select('''
            *,
            promotion:promotions(id, promotion_name, promotion_type)
          ''')
          .eq('club_id', clubId);

      if (date != null) {
        query = query.eq('date', date.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get club daily analytics: $e');
    }
  }

  // ============================================================
  // GET SUMMARY ANALYTICS
  // ============================================================

  /// Lấy summary analytics của 1 promotion
  Future<Map<String, dynamic>?> getPromotionSummary({
    required String promotionId,
  }) async {
    try {
      final response = await _supabase
          .from('promotion_analytics_summary')
          .select()
          .eq('promotion_id', promotionId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get promotion summary: $e');
    }
  }

  /// Lấy summary của tất cả promotions của club
  Future<List<Map<String, dynamic>>> getClubPromotionsSummary({
    required String clubId,
  }) async {
    try {
      final response = await _supabase
          .from('promotion_analytics_summary')
          .select('''
            *,
            promotion:promotions(id, promotion_name, promotion_type, status, start_date, end_date)
          ''')
          .eq('club_id', clubId)
          .order('roi_percentage', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get club promotions summary: $e');
    }
  }

  // ============================================================
  // GET VOUCHER ANALYTICS SUMMARY
  // ============================================================

  /// Lấy voucher analytics summary
  Future<Map<String, dynamic>?> getVoucherSummary({
    required String campaignId,
  }) async {
    try {
      final response = await _supabase
          .from('voucher_analytics_summary')
          .select()
          .eq('campaign_id', campaignId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get voucher summary: $e');
    }
  }

  /// Lấy all voucher summaries của club
  Future<List<Map<String, dynamic>>> getClubVouchersSummary({
    required String clubId,
  }) async {
    try {
      final response = await _supabase
          .from('voucher_analytics_summary')
          .select('''
            *,
            campaign:voucher_campaigns(id, campaign_name, campaign_type, status, start_date, end_date)
          ''')
          .eq('club_id', clubId)
          .order('effectiveness_score', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get club vouchers summary: $e');
    }
  }

  // ============================================================
  // AUTO UPDATE PROMOTION STATUS
  // ============================================================

  /// Auto-expire promotions đã hết hạn
  Future<int> autoUpdatePromotionStatus() async {
    try {
      final response = await _supabase.rpc('auto_update_promotion_status');
      return response as int;
    } catch (e) {
      throw Exception('Failed to auto-update promotion status: $e');
    }
  }

  // ============================================================
  // TOP PERFORMERS
  // ============================================================

  /// Lấy top performing promotions
  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String clubId,
    String metric = 'roi_percentage', // roi_percentage, total_revenue, total_redemptions
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('promotion_analytics_summary')
          .select('''
            *,
            promotion:promotions(id, promotion_name, promotion_type)
          ''')
          .eq('club_id', clubId)
          .order(metric, ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get top performers: $e');
    }
  }

  /// Lấy worst performing promotions
  Future<List<Map<String, dynamic>>> getWorstPerformers({
    required String clubId,
    String metric = 'roi_percentage',
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('promotion_analytics_summary')
          .select('''
            *,
            promotion:promotions(id, promotion_name, promotion_type)
          ''')
          .eq('club_id', clubId)
          .order(metric, ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get worst performers: $e');
    }
  }

  // ============================================================
  // TRENDS & INSIGHTS
  // ============================================================

  /// Lấy weekly trends
  Future<List<Map<String, dynamic>>> getWeeklyTrends({
    required String clubId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('promotion_analytics_daily')
          .select()
          .eq('club_id', clubId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      final dailyData = List<Map<String, dynamic>>.from(response);

      // Group by week
      final weeklyData = <String, Map<String, dynamic>>{};
      
      for (final day in dailyData) {
        final date = DateTime.parse(day['date']);
        final weekKey = '${date.year}-W${_getWeekNumber(date)}';
        
        if (!weeklyData.containsKey(weekKey)) {
          weeklyData[weekKey] = {
            'week': weekKey,
            'total_redemptions': 0,
            'total_revenue': 0.0,
            'total_discount': 0.0,
            'unique_users': <String>{},
          };
        }
        
        weeklyData[weekKey]!['total_redemptions'] = 
            (weeklyData[weekKey]!['total_redemptions'] as int) + 
            (day['total_redemptions'] as int? ?? 0);
        
        weeklyData[weekKey]!['total_revenue'] = 
            (weeklyData[weekKey]!['total_revenue'] as double) + 
            (day['total_revenue_generated'] as num? ?? 0).toDouble();
        
        weeklyData[weekKey]!['total_discount'] = 
            (weeklyData[weekKey]!['total_discount'] as double) + 
            (day['total_discount_given'] as num? ?? 0).toDouble();
      }

      return weeklyData.values.toList();
    } catch (e) {
      throw Exception('Failed to get weekly trends: $e');
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Calculate average ROI
  double calculateAverageROI(List<Map<String, dynamic>> summaries) {
    if (summaries.isEmpty) return 0.0;
    
    final totalROI = summaries.fold<double>(
      0.0,
      (sum, s) => sum + ((s['roi_percentage'] as num?)?.toDouble() ?? 0.0),
    );
    
    return totalROI / summaries.length;
  }

  /// Get total revenue
  double getTotalRevenue(List<Map<String, dynamic>> summaries) {
    return summaries.fold<double>(
      0.0,
      (sum, s) => sum + ((s['total_revenue_generated'] as num?)?.toDouble() ?? 0.0),
    );
  }

  /// Get total discount given
  double getTotalDiscount(List<Map<String, dynamic>> summaries) {
    return summaries.fold<double>(
      0.0,
      (sum, s) => sum + ((s['total_discount_given'] as num?)?.toDouble() ?? 0.0),
    );
  }

  /// Calculate total ROI
  double calculateTotalROI(List<Map<String, dynamic>> summaries) {
    final totalRevenue = getTotalRevenue(summaries);
    final totalCost = summaries.fold<double>(
      0.0,
      (sum, s) => sum + ((s['promotion_cost'] as num?)?.toDouble() ?? 0.0),
    );
    
    if (totalCost == 0) return 0.0;
    return ((totalRevenue - totalCost) / totalCost) * 100;
  }
}
