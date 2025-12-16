// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_prize_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentPrizeTemplate _$TournamentPrizeTemplateFromJson(
        Map<String, dynamic> json) =>
    TournamentPrizeTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isSystem: json['isSystem'] as bool,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      prizePool: (json['prizePool'] as num).toInt(),
      prizeDistribution: json['prizeDistribution'] as String,
      voucherConfigs: (json['voucherConfigs'] as List<dynamic>)
          .map((e) => VoucherPrizeConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TournamentPrizeTemplateToJson(
        TournamentPrizeTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'isSystem': instance.isSystem,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'prizePool': instance.prizePool,
      'prizeDistribution': instance.prizeDistribution,
      'voucherConfigs': instance.voucherConfigs,
    };

VoucherPrizeConfig _$VoucherPrizeConfigFromJson(Map<String, dynamic> json) =>
    VoucherPrizeConfig(
      position: (json['position'] as num).toInt(),
      vndValue: (json['vndValue'] as num).toInt(),
      validityDays: (json['validityDays'] as num).toInt(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$VoucherPrizeConfigToJson(VoucherPrizeConfig instance) =>
    <String, dynamic>{
      'position': instance.position,
      'vndValue': instance.vndValue,
      'validityDays': instance.validityDays,
      'description': instance.description,
    };
