import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club_review.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Club Review Service - Quản lý đánh giá câu lạc bộ
class ClubReviewService {
  static final ClubReviewService _instance = ClubReviewService._internal();
  factory ClubReviewService() => _instance;
  ClubReviewService._internal();

  final _supabase = Supabase.instance.client;

  /// Get reviews for a club
  Future<List<ClubReview>> getClubReviews(
    String clubId, {
    int limit = 20,
    int offset = 0,
    String sortBy = 'created_at', // created_at, rating, helpful_count
    bool ascending = false,
  }) async {
    try {
      final response = await _supabase
          .from('club_reviews')
          .select('''
            *,
            users!user_id(full_name, avatar_url)
          ''')
          .eq('club_id', clubId)
          .order(sortBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) {
        // Merge user data
        final user = json['users'] as Map<String, dynamic>?;
        return ClubReview.fromJson({
          ...json,
          'user_name':
              user?['display_name'] ?? user?['full_name'] ?? 'Anonymous',
          'user_avatar': user?['avatar_url'],
        });
      }).toList();
    } catch (e) {
      ProductionLogger.info('Error loading club reviews: $e',
          tag: 'club_review_service');
      return [];
    }
  }

  /// Get review statistics for a club
  Future<ClubReviewStats> getClubReviewStats(String clubId) async {
    try {
      final response = await _supabase.rpc(
        'get_club_review_stats',
        params: {'club_id_param': clubId},
      );

      if (response == null) {
        return ClubReviewStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        );
      }

      return ClubReviewStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      ProductionLogger.info('Error loading review stats: $e',
          tag: 'club_review_service');
      return ClubReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }
  }

  /// Check if user has already reviewed this club
  Future<ClubReview?> getUserReview(String clubId, String userId) async {
    try {
      final response = await _supabase.from('club_reviews').select('''
            *,
            users!user_id(full_name, avatar_url)
          ''').eq('club_id', clubId).eq('user_id', userId).maybeSingle();

      if (response == null) return null;

      final user = response['users'] as Map<String, dynamic>?;
      return ClubReview.fromJson({
        ...response,
        'user_name': user?['display_name'] ?? user?['full_name'] ?? 'Anonymous',
        'user_avatar': user?['avatar_url'],
      });
    } catch (e) {
      ProductionLogger.info('Error checking user review: $e',
          tag: 'club_review_service');
      return null;
    }
  }

  /// Submit a new review
  Future<bool> submitReview({
    required String clubId,
    required String userId,
    required double rating,
    String? comment,
    double? facilityRating,
    double? serviceRating,
    double? atmosphereRating,
    double? priceRating,
    List<String>? imageUrls,
  }) async {
    try {
      // Check if user already reviewed
      final existing = await getUserReview(clubId, userId);

      if (existing != null) {
        // Update existing review
        await _supabase.from('club_reviews').update({
          'rating': rating,
          'comment': comment,
          'facility_rating': facilityRating,
          'service_rating': serviceRating,
          'atmosphere_rating': atmosphereRating,
          'price_rating': priceRating,
          'image_urls': imageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing.id);
      } else {
        // Insert new review
        await _supabase.from('club_reviews').insert({
          'club_id': clubId,
          'user_id': userId,
          'rating': rating,
          'comment': comment,
          'facility_rating': facilityRating,
          'service_rating': serviceRating,
          'atmosphere_rating': atmosphereRating,
          'price_rating': priceRating,
          'image_urls': imageUrls,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Update club's average rating
      await _updateClubRating(clubId);

      return true;
    } catch (e) {
      ProductionLogger.info('Error submitting review: $e',
          tag: 'club_review_service');
      return false;
    }
  }

  /// Update club's average rating
  Future<void> _updateClubRating(String clubId) async {
    try {
      final stats = await getClubReviewStats(clubId);

      await _supabase.from('clubs').update({
        'rating': stats.averageRating,
        'total_reviews': stats.totalReviews,
      }).eq('id', clubId);
    } catch (e) {
      ProductionLogger.info('Error updating club rating: $e',
          tag: 'club_review_service');
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId, String clubId) async {
    try {
      await _supabase.from('club_reviews').delete().eq('id', reviewId);

      // Update club rating
      await _updateClubRating(clubId);

      return true;
    } catch (e) {
      ProductionLogger.info('Error deleting review: $e',
          tag: 'club_review_service');
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId) async {
    try {
      await _supabase.rpc(
        'increment_review_helpful',
        params: {'review_id_param': reviewId},
      );
      return true;
    } catch (e) {
      ProductionLogger.info('Error marking review helpful: $e',
          tag: 'club_review_service');
      return false;
    }
  }
}
