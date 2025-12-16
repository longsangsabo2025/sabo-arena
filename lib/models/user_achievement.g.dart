// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAchievement _$UserAchievementFromJson(Map<String, dynamic> json) =>
    UserAchievement(
      id: json['id'] as String,
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String?,
      criteria: json['criteria'] as Map<String, dynamic>?,
      progressCurrent: (json['progressCurrent'] as num).toInt(),
      progressRequired: (json['progressRequired'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      rewardVoucherIds: (json['rewardVoucherIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UserAchievementToJson(UserAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'achievementId': instance.achievementId,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'criteria': instance.criteria,
      'progressCurrent': instance.progressCurrent,
      'progressRequired': instance.progressRequired,
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'rewardVoucherIds': instance.rewardVoucherIds,
    };

const _$AchievementTypeEnumMap = {
  AchievementType.matchesPlayed: 'matches_played',
  AchievementType.matchesWon: 'matches_won',
  AchievementType.tournamentsJoined: 'tournaments_joined',
  AchievementType.tournamentsWon: 'tournaments_won',
  AchievementType.clubVisits: 'club_visits',
  AchievementType.consecutiveDays: 'consecutive_days',
  AchievementType.spendingMilestone: 'spending_milestone',
  AchievementType.socialEngagement: 'social_engagement',
  AchievementType.referralSuccess: 'referral_success',
  AchievementType.skillImprovement: 'skill_improvement',
};

UserVoucher _$UserVoucherFromJson(Map<String, dynamic> json) => UserVoucher(
      id: json['id'] as String,
      userId: json['userId'] as String,
      promotionId: json['promotionId'] as String,
      clubId: json['clubId'] as String,
      clubName: json['clubName'] as String,
      voucherCode: json['voucherCode'] as String,
      source: $enumDecode(_$VoucherSourceEnumMap, json['source']),
      sourceId: json['sourceId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      type: $enumDecode(_$VoucherTypeEnumMap, json['type']),
      status: $enumDecode(_$VoucherStatusEnumMap, json['status']),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble(),
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      usedAt: json['usedAt'] == null
          ? null
          : DateTime.parse(json['usedAt'] as String),
      usedAtClub: json['usedAtClub'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserVoucherToJson(UserVoucher instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'promotionId': instance.promotionId,
      'clubId': instance.clubId,
      'clubName': instance.clubName,
      'voucherCode': instance.voucherCode,
      'source': _$VoucherSourceEnumMap[instance.source]!,
      'sourceId': instance.sourceId,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'type': _$VoucherTypeEnumMap[instance.type]!,
      'status': _$VoucherStatusEnumMap[instance.status]!,
      'discountAmount': instance.discountAmount,
      'discountPercentage': instance.discountPercentage,
      'minOrderAmount': instance.minOrderAmount,
      'issuedAt': instance.issuedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'usedAt': instance.usedAt?.toIso8601String(),
      'usedAtClub': instance.usedAtClub,
      'metadata': instance.metadata,
    };

const _$VoucherSourceEnumMap = {
  VoucherSource.achievement: 'achievement',
  VoucherSource.event: 'event',
  VoucherSource.referral: 'referral',
  VoucherSource.birthday: 'birthday',
  VoucherSource.loyalty: 'loyalty',
  VoucherSource.manual: 'manual',
};

const _$VoucherTypeEnumMap = {
  VoucherType.percentageDiscount: 'percentage_discount',
  VoucherType.fixedDiscount: 'fixed_discount',
  VoucherType.freeService: 'free_service',
  VoucherType.bonusTime: 'bonus_time',
  VoucherType.freeDrink: 'free_drink',
};

const _$VoucherStatusEnumMap = {
  VoucherStatus.active: 'active',
  VoucherStatus.used: 'used',
  VoucherStatus.expired: 'expired',
  VoucherStatus.cancelled: 'cancelled',
};
