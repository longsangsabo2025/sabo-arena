import 'package:json_annotation/json_annotation.dart';

part 'tournament_prize_template.g.dart';

@JsonSerializable()
class TournamentPrizeTemplate {
  final String id;
  final String name;
  final String description;
  final bool isSystem; // System templates vs user custom
  final String? createdBy; // User ID who created custom template
  final DateTime createdAt;
  
  // Prize Distribution
  final int prizePool;
  final String prizeDistribution; // template name (standard, top_heavy, etc.)
  
  // Voucher Config
  final List<VoucherPrizeConfig> voucherConfigs;
  
  const TournamentPrizeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    this.createdBy,
    required this.createdAt,
    required this.prizePool,
    required this.prizeDistribution,
    required this.voucherConfigs,
  });

  factory TournamentPrizeTemplate.fromJson(Map<String, dynamic> json) =>
      _$TournamentPrizeTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$TournamentPrizeTemplateToJson(this);
}

@JsonSerializable()
class VoucherPrizeConfig {
  final int position; // 1, 2, 3, etc.
  final int vndValue;
  final int validityDays;
  final String? description;
  
  const VoucherPrizeConfig({
    required this.position,
    required this.vndValue,
    required this.validityDays,
    this.description,
  });

  factory VoucherPrizeConfig.fromJson(Map<String, dynamic> json) =>
      _$VoucherPrizeConfigFromJson(json);

  Map<String, dynamic> toJson() => _$VoucherPrizeConfigToJson(this);
}

/// System predefined templates
class PrizeTemplates {
  // 🏆 Winner Focus - Tập trung vào người chiến thắng
  static final winnerFocus = TournamentPrizeTemplate(
    id: 'winner_focus',
    name: '🏆 Winner Focus',
    description: 'Tập trung phần thưởng cho người chiến thắng',
    isSystem: true,
    createdAt: DateTime.now(),
    prizePool: 5000000, // 5 triệu
    prizeDistribution: 'winner_takes_all',
    voucherConfigs: [
      VoucherPrizeConfig(
        position: 1,
        vndValue: 1000000, // 1 triệu
        validityDays: 30,
        description: 'Voucher dành cho nhà vô địch',
      ),
    ],
  );

  // 🥇🥈🥉 Standard Prize - Chuẩn top 3
  static final standardTop3 = TournamentPrizeTemplate(
    id: 'standard_top3',
    name: '🥇🥈🥉 Standard Top 3',
    description: 'Chia đều cho top 3 với voucher hấp dẫn',
    isSystem: true,
    createdAt: DateTime.now(),
    prizePool: 5000000,
    prizeDistribution: 'top_3',
    voucherConfigs: [
      VoucherPrizeConfig(
        position: 1,
        vndValue: 700000,
        validityDays: 30,
        description: 'Voucher vô địch',
      ),
      VoucherPrizeConfig(
        position: 2,
        vndValue: 500000,
        validityDays: 30,
        description: 'Voucher á quân',
      ),
      VoucherPrizeConfig(
        position: 3,
        vndValue: 300000,
        validityDays: 30,
        description: 'Voucher hạng 3',
      ),
    ],
  );

  // ⭐ Everyone Wins - Ai cũng có thưởng
  static final everyoneWins = TournamentPrizeTemplate(
    id: 'everyone_wins',
    name: '⭐ Everyone Wins',
    description: 'Top 8 đều nhận voucher khuyến khích',
    isSystem: true,
    createdAt: DateTime.now(),
    prizePool: 8000000,
    prizeDistribution: 'top_8',
    voucherConfigs: [
      VoucherPrizeConfig(position: 1, vndValue: 500000, validityDays: 30),
      VoucherPrizeConfig(position: 2, vndValue: 400000, validityDays: 30),
      VoucherPrizeConfig(position: 3, vndValue: 300000, validityDays: 30),
      VoucherPrizeConfig(position: 4, vndValue: 200000, validityDays: 30),
      VoucherPrizeConfig(position: 5, vndValue: 150000, validityDays: 25),
      VoucherPrizeConfig(position: 6, vndValue: 150000, validityDays: 25),
      VoucherPrizeConfig(position: 7, vndValue: 100000, validityDays: 20),
      VoucherPrizeConfig(position: 8, vndValue: 100000, validityDays: 20),
    ],
  );

  // 💰 Big Prize Pool - Giải lớn
  static final bigPrizePool = TournamentPrizeTemplate(
    id: 'big_prize_pool',
    name: '💰 Big Prize Pool',
    description: 'Giải lớn với prize pool 10 triệu + vouchers cao',
    isSystem: true,
    createdAt: DateTime.now(),
    prizePool: 10000000, // 10 triệu
    prizeDistribution: 'top_4',
    voucherConfigs: [
      VoucherPrizeConfig(
        position: 1,
        vndValue: 1500000, // 1.5 triệu
        validityDays: 45,
        description: 'Voucher đặc biệt cho nhà vô địch',
      ),
      VoucherPrizeConfig(
        position: 2,
        vndValue: 1000000, // 1 triệu
        validityDays: 40,
      ),
      VoucherPrizeConfig(
        position: 3,
        vndValue: 700000,
        validityDays: 35,
      ),
      VoucherPrizeConfig(
        position: 4,
        vndValue: 500000,
        validityDays: 30,
      ),
    ],
  );

  // 🎁 Club Promotion - Giải khuyến mãi club
  static final clubPromotion = TournamentPrizeTemplate(
    id: 'club_promotion',
    name: '🎁 Club Promotion',
    description: 'Giải khuyến mãi với vouchers hậu hĩnh',
    isSystem: true,
    createdAt: DateTime.now(),
    prizePool: 3000000,
    prizeDistribution: 'top_3',
    voucherConfigs: [
      VoucherPrizeConfig(
        position: 1,
        vndValue: 800000,
        validityDays: 60, // 2 tháng
        description: 'Voucher ưu đãi đặc biệt',
      ),
      VoucherPrizeConfig(
        position: 2,
        vndValue: 600000,
        validityDays: 50,
      ),
      VoucherPrizeConfig(
        position: 3,
        vndValue: 400000,
        validityDays: 40,
      ),
    ],
  );

  /// Get all system templates
  static List<TournamentPrizeTemplate> getAllSystemTemplates() {
    // Fix: Create proper instances with real DateTime
    final now = DateTime.now();
    return [
      TournamentPrizeTemplate(
        id: winnerFocus.id,
        name: winnerFocus.name,
        description: winnerFocus.description,
        isSystem: winnerFocus.isSystem,
        createdAt: now,
        prizePool: winnerFocus.prizePool,
        prizeDistribution: winnerFocus.prizeDistribution,
        voucherConfigs: winnerFocus.voucherConfigs,
      ),
      TournamentPrizeTemplate(
        id: standardTop3.id,
        name: standardTop3.name,
        description: standardTop3.description,
        isSystem: standardTop3.isSystem,
        createdAt: now,
        prizePool: standardTop3.prizePool,
        prizeDistribution: standardTop3.prizeDistribution,
        voucherConfigs: standardTop3.voucherConfigs,
      ),
      TournamentPrizeTemplate(
        id: everyoneWins.id,
        name: everyoneWins.name,
        description: everyoneWins.description,
        isSystem: everyoneWins.isSystem,
        createdAt: now,
        prizePool: everyoneWins.prizePool,
        prizeDistribution: everyoneWins.prizeDistribution,
        voucherConfigs: everyoneWins.voucherConfigs,
      ),
      TournamentPrizeTemplate(
        id: bigPrizePool.id,
        name: bigPrizePool.name,
        description: bigPrizePool.description,
        isSystem: bigPrizePool.isSystem,
        createdAt: now,
        prizePool: bigPrizePool.prizePool,
        prizeDistribution: bigPrizePool.prizeDistribution,
        voucherConfigs: bigPrizePool.voucherConfigs,
      ),
      TournamentPrizeTemplate(
        id: clubPromotion.id,
        name: clubPromotion.name,
        description: clubPromotion.description,
        isSystem: clubPromotion.isSystem,
        createdAt: now,
        prizePool: clubPromotion.prizePool,
        prizeDistribution: clubPromotion.prizeDistribution,
        voucherConfigs: clubPromotion.voucherConfigs,
      ),
    ];
  }
}
