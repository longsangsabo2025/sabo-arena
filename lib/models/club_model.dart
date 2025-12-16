class ClubModel {
  final String id;
  final String name;
  final String location;
  final String? address;
  final String? phone;
  final String? email;
  final String? description;
  final String? coverImageUrl;
  final String? profileImageUrl;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final bool isVerified;
  final double rating;
  final int totalReviews;

  ClubModel({
    required this.id,
    required this.name,
    required this.location,
    this.address,
    this.phone,
    this.email,
    this.description,
    this.coverImageUrl,
    this.profileImageUrl,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalReviews = 0,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['address'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'description': description,
      'cover_image_url': coverImageUrl,
      'profile_image_url': profileImageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'is_verified': isVerified,
      'rating': rating,
      'total_reviews': totalReviews,
    };
  }

  ClubModel copyWith({
    String? id,
    String? name,
    String? location,
    String? address,
    String? phone,
    String? email,
    String? description,
    String? coverImageUrl,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
    bool? isActive,
    bool? isVerified,
    double? rating,
    int? totalReviews,
  }) {
    return ClubModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}
