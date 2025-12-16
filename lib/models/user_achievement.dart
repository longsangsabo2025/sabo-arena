import 'package:json_annotation/json_annotation.dart';

part 'user_achievement.g.dart';

@JsonSerializable()
class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final AchievementType type;
  final String title;
  final String description;
  final String? iconUrl;
  final Map<String, dynamic>? criteria;
  final int progressCurrent;
  final int progressRequired;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? rewardVoucherIds; // Vouchers nhận được

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.type,
    required this.title,
    required this.description,
    this.iconUrl,
    this.criteria,
    required this.progressCurrent,
    required this.progressRequired,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.rewardVoucherIds,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserAchievementFromJson(json);

  Map<String, dynamic> toJson() => _$UserAchievementToJson(this);

  double get progressPercentage => progressRequired > 0
      ? (progressCurrent / progressRequired).clamp(0.0, 1.0)
      : 0.0;

  bool get canClaim =>
      isCompleted && completedAt != null && (rewardVoucherIds?.isEmpty ?? true);
}

@JsonSerializable()
class UserVoucher {
  final String id;
  final String userId;
  final String promotionId; // Link to ClubPromotion
  final String clubId;
  final String clubName;
  final String voucherCode;
  final VoucherSource source; // Achievement, Event, Manual, etc.
  final String? sourceId; // Achievement ID nếu source = Achievement
  final String title;
  final String description;
  final String? imageUrl;
  final VoucherType type;
  final VoucherStatus status;
  final double? discountAmount;
  final double? discountPercentage;
  final double? minOrderAmount;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedAtClub;
  final Map<String, dynamic>? metadata;

  const UserVoucher({
    required this.id,
    required this.userId,
    required this.promotionId,
    required this.clubId,
    required this.clubName,
    required this.voucherCode,
    required this.source,
    this.sourceId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.type,
    required this.status,
    this.discountAmount,
    this.discountPercentage,
    this.minOrderAmount,
    required this.issuedAt,
    required this.expiresAt,
    this.usedAt,
    this.usedAtClub,
    this.metadata,
  });

  factory UserVoucher.fromJson(Map<String, dynamic> json) =>
      _$UserVoucherFromJson(json);

  Map<String, dynamic> toJson() => _$UserVoucherToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsable => status == VoucherStatus.active && !isExpired;

  int get daysUntilExpiry => expiresAt.difference(DateTime.now()).inDays;
}

enum AchievementType {
  @JsonValue('matches_played')
  matchesPlayed,
  @JsonValue('matches_won')
  matchesWon,
  @JsonValue('tournaments_joined')
  tournamentsJoined,
  @JsonValue('tournaments_won')
  tournamentsWon,
  @JsonValue('club_visits')
  clubVisits,
  @JsonValue('consecutive_days')
  consecutiveDays,
  @JsonValue('spending_milestone')
  spendingMilestone,
  @JsonValue('social_engagement')
  socialEngagement,
  @JsonValue('referral_success')
  referralSuccess,
  @JsonValue('skill_improvement')
  skillImprovement,
}

enum VoucherSource {
  @JsonValue('achievement')
  achievement,
  @JsonValue('event')
  event,
  @JsonValue('referral')
  referral,
  @JsonValue('birthday')
  birthday,
  @JsonValue('loyalty')
  loyalty,
  @JsonValue('manual')
  manual,
}

enum VoucherType {
  @JsonValue('percentage_discount')
  percentageDiscount,
  @JsonValue('fixed_discount')
  fixedDiscount,
  @JsonValue('free_service')
  freeService,
  @JsonValue('bonus_time')
  bonusTime,
  @JsonValue('free_drink')
  freeDrink,
}

enum VoucherStatus {
  @JsonValue('active')
  active,
  @JsonValue('used')
  used,
  @JsonValue('expired')
  expired,
  @JsonValue('cancelled')
  cancelled,
}
