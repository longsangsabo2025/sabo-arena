import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// 📊 Share Analytics Service
/// Track share events, engagement, and conversion metrics
class ShareAnalyticsService {
  static final _supabase = Supabase.instance.client;

  /// 📤 Track when user initiates share
  static Future<void> trackShareInitiated({
    required String contentType, // 'tournament', 'match', 'leaderboard'
    required String contentId,
    required String shareMethod, // 'rich_image', 'text_only'
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;

      await _supabase.from('share_analytics').insert({
        'user_id': user,
        'content_type': contentType,
        'content_id': contentId,
        'share_method': shareMethod,
        'event_type': 'share_initiated',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore error
    }
  }

  /// ✅ Track when share is completed successfully
  static Future<void> trackShareCompleted({
    required String contentType,
    required String contentId,
    required String shareMethod,
    required String
        shareDestination, // 'whatsapp', 'facebook', 'messenger', etc.
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;

      await _supabase.from('share_analytics').insert({
        'user_id': user,
        'content_type': contentType,
        'content_id': contentId,
        'share_method': shareMethod,
        'share_destination': shareDestination,
        'event_type': 'share_completed',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore error
    }
  }

  /// ❌ Track when share is cancelled
  static Future<void> trackShareCancelled({
    required String contentType,
    required String contentId,
    required String shareMethod,
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;

      await _supabase.from('share_analytics').insert({
        'user_id': user,
        'content_type': contentType,
        'content_id': contentId,
        'share_method': shareMethod,
        'event_type': 'share_cancelled',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore error
    }
  }

  /// 🔗 Track when shared link is clicked
  static Future<void> trackLinkClicked({
    required String contentType,
    required String contentId,
    String? referralCode, // QR code or deep link code
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;

      await _supabase.from('share_analytics').insert({
        'user_id': user,
        'content_type': contentType,
        'content_id': contentId,
        'referral_code': referralCode,
        'event_type': 'link_clicked',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Ignore error
    } catch (e) {
      // Ignore error
    }
  }

  /// 📱 Track QR code scans
  static Future<void> trackQRCodeScanned({
    required String contentType,
    required String contentId,
    String? userId,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;

      await _supabase.from('share_analytics').insert({
        'user_id': user,
        'content_type': contentType,
        'content_id': contentId,
        'event_type': 'qr_scanned',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Ignore error
    } catch (e) {
      // Ignore error
    }
  }

  /// 📊 Get share statistics for content
  static Future<Map<String, dynamic>> getShareStats({
    required String contentType,
    required String contentId,
  }) async {
    try {
      final response = await _supabase
          .from('share_analytics')
          .select()
          .eq('content_type', contentType)
          .eq('content_id', contentId);

      final data = response as List<dynamic>;

      // Calculate metrics
      final totalShares =
          data.where((e) => e['event_type'] == 'share_completed').length;
      final totalInitiated =
          data.where((e) => e['event_type'] == 'share_initiated').length;
      final totalCancelled =
          data.where((e) => e['event_type'] == 'share_cancelled').length;
      final totalClicks =
          data.where((e) => e['event_type'] == 'link_clicked').length;
      final totalQRScans =
          data.where((e) => e['event_type'] == 'qr_scanned').length;

      // Calculate conversion rate
      final conversionRate = totalInitiated > 0
          ? (totalShares / totalInitiated * 100).toStringAsFixed(1)
          : '0';

      // Calculate click-through rate
      final clickThroughRate = totalShares > 0
          ? (totalClicks / totalShares * 100).toStringAsFixed(1)
          : '0';

      // Get top destinations
      final destinations = <String, int>{};
      for (var item in data) {
        if (item['event_type'] == 'share_completed' &&
            item['share_destination'] != null) {
          final dest = item['share_destination'] as String;
          destinations[dest] = (destinations[dest] ?? 0) + 1;
        }
      }

      return {
        'total_shares': totalShares,
        'total_initiated': totalInitiated,
        'total_cancelled': totalCancelled,
        'total_clicks': totalClicks,
        'total_qr_scans': totalQRScans,
        'conversion_rate': conversionRate,
        'click_through_rate': clickThroughRate,
        'top_destinations': destinations,
      };
    } catch (e) {
      return {};
    }
  }

  /// 📈 Get leaderboard of most shared content
  static Future<List<Map<String, dynamic>>> getMostSharedContent({
    String? contentType,
    int limit = 10,
  }) async {
    try {
      var query = _supabase
          .from('share_analytics')
          .select('content_type, content_id, count(*)')
          .eq('event_type', 'share_completed');

      if (contentType != null) {
        query = query.eq('content_type', contentType);
      }

      final response = await query.limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  /// 👤 Get user's share history
  static Future<List<Map<String, dynamic>>> getUserShareHistory({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final user = userId ?? _supabase.auth.currentUser?.id;
      if (user == null) return [];

      final response = await _supabase
          .from('share_analytics')
          .select()
          .eq('user_id', user)
          .eq('event_type', 'share_completed')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  /// 🎯 Track share performance metrics
  static Future<void> trackSharePerformance({
    required String contentType,
    required String contentId,
    required int processingTimeMs,
    required int imageSizeBytes,
    bool wasSuccessful = true,
    String? errorMessage,
  }) async {
    try {
      await _supabase.from('share_performance').insert({
        'content_type': contentType,
        'content_id': contentId,
        'processing_time_ms': processingTimeMs,
        'image_size_bytes': imageSizeBytes,
        'was_successful': wasSuccessful,
        'error_message': errorMessage,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Ignore error
    } catch (e) {
      // Ignore error
    }
  }
}
