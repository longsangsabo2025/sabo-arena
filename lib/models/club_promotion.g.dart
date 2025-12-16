// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_promotion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClubPromotion _$ClubPromotionFromJson(Map<String, dynamic> json) =>
    ClubPromotion(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      type: $enumDecode(_$PromotionTypeEnumMap, json['type']),
      status: $enumDecode(_$PromotionStatusEnumMap, json['status']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      conditions: json['conditions'] as Map<String, dynamic>?,
      rewards: json['rewards'] as Map<String, dynamic>?,
      maxRedemptions: (json['maxRedemptions'] as num?)?.toInt(),
      currentRedemptions: (json['currentRedemptions'] as num).toInt(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      promoCode: json['promoCode'] as String?,
      applicableServices: (json['applicableServices'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      priority: (json['priority'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String?,
    );

Map<String, dynamic> _$ClubPromotionToJson(ClubPromotion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clubId': instance.clubId,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'type': _$PromotionTypeEnumMap[instance.type]!,
      'status': _$PromotionStatusEnumMap[instance.status]!,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'conditions': instance.conditions,
      'rewards': instance.rewards,
      'maxRedemptions': instance.maxRedemptions,
      'currentRedemptions': instance.currentRedemptions,
      'discountPercentage': instance.discountPercentage,
      'discountAmount': instance.discountAmount,
      'promoCode': instance.promoCode,
      'applicableServices': instance.applicableServices,
      'priority': instance.priority,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'createdBy': instance.createdBy,
    };

const _$PromotionTypeEnumMap = {
  PromotionType.discount: 'discount',
  PromotionType.cashback: 'cashback',
  PromotionType.freeService: 'freeService',
  PromotionType.bundleOffer: 'bundleOffer',
  PromotionType.membershipDiscount: 'membershipDiscount',
  PromotionType.eventSpecial: 'eventSpecial',
  PromotionType.seasonalOffer: 'seasonalOffer',
  PromotionType.loyaltyReward: 'loyaltyReward',
};

const _$PromotionStatusEnumMap = {
  PromotionStatus.draft: 'draft',
  PromotionStatus.active: 'active',
  PromotionStatus.paused: 'paused',
  PromotionStatus.expired: 'expired',
  PromotionStatus.cancelled: 'cancelled',
};

PromotionRedemption _$PromotionRedemptionFromJson(Map<String, dynamic> json) =>
    PromotionRedemption(
      id: json['id'] as String,
      promotionId: json['promotionId'] as String,
      userId: json['userId'] as String,
      clubId: json['clubId'] as String,
      redeemedAt: DateTime.parse(json['redeemedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: json['status'] as String,
      discountApplied: (json['discountApplied'] as num?)?.toDouble(),
      transactionId: json['transactionId'] as String?,
    );

Map<String, dynamic> _$PromotionRedemptionToJson(
        PromotionRedemption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'promotionId': instance.promotionId,
      'userId': instance.userId,
      'clubId': instance.clubId,
      'redeemedAt': instance.redeemedAt.toIso8601String(),
      'metadata': instance.metadata,
      'status': instance.status,
      'discountApplied': instance.discountApplied,
      'transactionId': instance.transactionId,
    };
