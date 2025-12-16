import 'package:json_annotation/json_annotation.dart';

part 'club_promotion.g.dart';

@JsonSerializable()
class ClubPromotion {
  final String id;
  final String clubId;
  final String title;
  final String description;
  final String? imageUrl;
  final PromotionType type;
  final PromotionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic>? conditions;
  final Map<String, dynamic>? rewards;
  final int? maxRedemptions;
  final int currentRedemptions;
  final double? discountPercentage;
  final double? discountAmount;
  final String? promoCode;
  final List<String>? applicableServices;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const ClubPromotion({
    required this.id,
    required this.clubId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.conditions,
    this.rewards,
    this.maxRedemptions,
    required this.currentRedemptions,
    this.discountPercentage,
    this.discountAmount,
    this.promoCode,
    this.applicableServices,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory ClubPromotion.fromJson(Map<String, dynamic> json) =>
      _$ClubPromotionFromJson(json);

  Map<String, dynamic> toJson() => _$ClubPromotionToJson(this);

  bool get isActive {
    final now = DateTime.now();
    return status == PromotionStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (maxRedemptions == null || currentRedemptions < maxRedemptions!);
  }

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  double get completionPercentage {
    if (maxRedemptions == null) return 0.0;
    return (currentRedemptions / maxRedemptions!) * 100;
  }

  String get statusText {
    if (isExpired) return 'Đã hết hạn';
    if (isUpcoming) return 'Sắp diễn ra';
    if (isActive) return 'Đang diễn ra';
    return status.displayName;
  }
}

enum PromotionType {
  discount('discount', 'Giảm giá'),
  cashback('cashback', 'Hoàn tiền'),
  freeService('free_service', 'Dịch vụ miễn phí'),
  bundleOffer('bundle_offer', 'Combo ưu đãi'),
  membershipDiscount('membership_discount', 'Giảm giá thành viên'),
  eventSpecial('event_special', 'Ưu đãi sự kiện'),
  seasonalOffer('seasonal_offer', 'Ưu đãi theo mùa'),
  loyaltyReward('loyalty_reward', 'Thưởng khách hàng thân thiết');

  const PromotionType(this.value, this.displayName);
  final String value;
  final String displayName;
}

enum PromotionStatus {
  draft('draft', 'Bản nháp'),
  active('active', 'Đang hoạt động'),
  paused('paused', 'Tạm dừng'),
  expired('expired', 'Đã hết hạn'),
  cancelled('cancelled', 'Đã hủy');

  const PromotionStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}

@JsonSerializable()
class PromotionRedemption {
  final String id;
  final String promotionId;
  final String userId;
  final String clubId;
  final DateTime redeemedAt;
  final Map<String, dynamic>? metadata;
  final String status;
  final double? discountApplied;
  final String? transactionId;

  const PromotionRedemption({
    required this.id,
    required this.promotionId,
    required this.userId,
    required this.clubId,
    required this.redeemedAt,
    this.metadata,
    required this.status,
    this.discountApplied,
    this.transactionId,
  });

  factory PromotionRedemption.fromJson(Map<String, dynamic> json) =>
      _$PromotionRedemptionFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionRedemptionToJson(this);
}
