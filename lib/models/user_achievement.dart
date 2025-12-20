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

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    // Map category to AchievementType
    AchievementType type;
    final category = json['category'] as String?;
    switch (category) {
      case 'participation':
        type = AchievementType.tournamentsJoined;
        break;
      case 'winning':
        type = AchievementType.tournamentsWon;
        break;
      case 'matches':
        type = AchievementType.matchesPlayed;
        break;
      default:
        type = AchievementType.matchesPlayed; // Default
    }

    // Determine progress required based on type/category
    int progressRequired = 0;
    if (json['points_required'] != null &&
        (json['points_required'] as num) > 0) {
      progressRequired = (json['points_required'] as num).toInt();
    } else if (json['tournaments_required'] != null &&
        (json['tournaments_required'] as num) > 0) {
      progressRequired = (json['tournaments_required'] as num).toInt();
    } else if (json['wins_required'] != null &&
        (json['wins_required'] as num) > 0) {
      progressRequired = (json['wins_required'] as num).toInt();
    }

    final earnedAtStr = json['earned_at'] as String?;
    final earnedAt = earnedAtStr != null ? DateTime.parse(earnedAtStr) : null;
    final isCompleted = earnedAt != null;

    return UserAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      type: type,
      title: json['name'] as String? ?? 'Achievement',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      criteria: {
        'points_required': json['points_required'],
        'tournaments_required': json['tournaments_required'],
        'wins_required': json['wins_required'],
        'badge_color': json['badge_color'],
      },
      progressCurrent: (json['progress_current'] as num?)?.toInt() ??
          (isCompleted ? progressRequired : 0),
      progressRequired: progressRequired,
      isCompleted: isCompleted,
      completedAt: earnedAt,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      rewardVoucherIds: (json['reward_voucher_ids'] as List?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

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

  factory UserVoucher.fromJson(Map<String, dynamic> json) {
    // Handle nested rewards object
    final rewards = json['rewards'] as Map<String, dynamic>? ?? {};
    final issueReason = json['issue_reason'] as String?;

    // Map source
    VoucherSource source;
    switch (issueReason) {
      case 'spa_redemption':
        source = VoucherSource.loyalty;
        break;
      case 'achievement':
        source = VoucherSource.achievement;
        break;
      case 'event':
        source = VoucherSource.event;
        break;
      case 'referral':
        source = VoucherSource.referral;
        break;
      case 'birthday':
        source = VoucherSource.birthday;
        break;
      default:
        source = VoucherSource.manual;
    }

    // Map type
    VoucherType type;
    final rewardType = rewards['type'] as String?;
    // Simple mapping based on reward type string
    if (rewardType == 'voucher') {
      type = VoucherType.fixedDiscount;
    } else if (rewardType == 'percentage') {
      type = VoucherType.percentageDiscount;
    } else if (rewardType == 'free_hours' || rewardType == 'free_service') {
      type = VoucherType.freeService;
    } else {
      type = VoucherType.fixedDiscount; // Default fallback
    }

    // Map status
    VoucherStatus status;
    final statusStr = json['status'] as String?;
    try {
      status = VoucherStatus.values.firstWhere(
          (e) => _getEnumName(e) == statusStr,
          orElse: () => VoucherStatus.active);
    } catch (_) {
      status = VoucherStatus.active;
    }

    return UserVoucher(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      promotionId: json['campaign_id'] as String? ?? '',
      clubId: json['club_id'] as String,
      clubName: (json['clubs'] as Map<String, dynamic>?)?['name'] as String? ??
          'Unknown Club',
      voucherCode: json['voucher_code'] as String,
      source: source,
      sourceId: null,
      title: rewards['name'] as String? ?? 'Voucher',
      description: rewards['description'] as String? ?? '',
      imageUrl: null,
      type: type,
      status: status,
      discountAmount: (rewards['value'] as num?)?.toDouble(),
      discountPercentage: null,
      minOrderAmount: null,
      issuedAt: DateTime.parse(json['issued_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] == null
          ? null
          : DateTime.parse(json['used_at'] as String),
      usedAtClub: null,
      metadata: json['issue_details'] as Map<String, dynamic>?,
    );
  }

  // Helper to get enum name matching JsonValue if possible, or just name
  static String _getEnumName(dynamic enumItem) {
    // This is a simplification. Ideally we use the JsonValue annotation but that requires reflection or manual mapping.
    // For now, we assume the DB values match the enum names (snake_case vs camelCase might be an issue).
    // VoucherStatus values are: active, used, expired, cancelled.
    // Enum names: active, used, expired, cancelled.
    // So .name works.
    return enumItem.name;
  }

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
