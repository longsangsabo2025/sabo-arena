/// Club Review Model - Đánh giá câu lạc bộ
class ClubReview {
  final String id;
  final String clubId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Review aspects (optional detailed ratings)
  final double? facilityRating; // Cơ sở vật chất
  final double? serviceRating; // Dịch vụ
  final double? atmosphereRating; // Không khí
  final double? priceRating; // Giá cả

  // Images (optional)
  final List<String>? imageUrls;

  // Helpful count
  final int helpfulCount;

  ClubReview({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.facilityRating,
    this.serviceRating,
    this.atmosphereRating,
    this.priceRating,
    this.imageUrls,
    this.helpfulCount = 0,
  });

  factory ClubReview.fromJson(Map<String, dynamic> json) {
    return ClubReview(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Anonymous',
      userAvatar: json['user_avatar'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      facilityRating: json['facility_rating'] != null
          ? (json['facility_rating'] as num).toDouble()
          : null,
      serviceRating: json['service_rating'] != null
          ? (json['service_rating'] as num).toDouble()
          : null,
      atmosphereRating: json['atmosphere_rating'] != null
          ? (json['atmosphere_rating'] as num).toDouble()
          : null,
      priceRating: json['price_rating'] != null
          ? (json['price_rating'] as num).toDouble()
          : null,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      helpfulCount: json['helpful_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'facility_rating': facilityRating,
      'service_rating': serviceRating,
      'atmosphere_rating': atmosphereRating,
      'price_rating': priceRating,
      'image_urls': imageUrls,
      'helpful_count': helpfulCount,
    };
  }
}

/// Club Review Statistics
class ClubReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}

  // Detailed averages
  final double? averageFacilityRating;
  final double? averageServiceRating;
  final double? averageAtmosphereRating;
  final double? averagePriceRating;

  ClubReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    this.averageFacilityRating,
    this.averageServiceRating,
    this.averageAtmosphereRating,
    this.averagePriceRating,
  });

  factory ClubReviewStats.fromJson(Map<String, dynamic> json) {
    return ClubReviewStats(
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      ratingDistribution: json['rating_distribution'] != null
          ? Map<int, int>.from(json['rating_distribution'] as Map)
          : {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      averageFacilityRating: json['average_facility_rating'] != null
          ? (json['average_facility_rating'] as num).toDouble()
          : null,
      averageServiceRating: json['average_service_rating'] != null
          ? (json['average_service_rating'] as num).toDouble()
          : null,
      averageAtmosphereRating: json['average_atmosphere_rating'] != null
          ? (json['average_atmosphere_rating'] as num).toDouble()
          : null,
      averagePriceRating: json['average_price_rating'] != null
          ? (json['average_price_rating'] as num).toDouble()
          : null,
    );
  }
}
