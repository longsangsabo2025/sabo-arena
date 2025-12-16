import 'package:equatable/equatable.dart';

// ============================================================
// TABLE RATE MODEL
// ============================================================
class TableRate extends Equatable {
  final String id;
  final String clubId;
  final String name;
  final String description;
  final double hourlyRate;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TableRate({
    required this.id,
    required this.clubId,
    required this.name,
    required this.description,
    required this.hourlyRate,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory TableRate.fromJson(Map<String, dynamic> json) {
    return TableRate(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      hourlyRate: (json['hourly_rate'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'club_id': clubId,
      'name': name,
      'description': description,
      'hourly_rate': hourlyRate,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  TableRate copyWith({
    String? id,
    String? clubId,
    String? name,
    String? description,
    double? hourlyRate,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableRate(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      description: description ?? this.description,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clubId,
        name,
        description,
        hourlyRate,
        isActive,
        displayOrder,
        createdAt,
        updatedAt,
      ];
}

// ============================================================
// MEMBERSHIP FEE MODEL
// ============================================================
class MembershipFee extends Equatable {
  final String id;
  final String clubId;
  final String name;
  final String benefits;
  final double monthlyFee;
  final double yearlyFee;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MembershipFee({
    required this.id,
    required this.clubId,
    required this.name,
    required this.benefits,
    required this.monthlyFee,
    required this.yearlyFee,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory MembershipFee.fromJson(Map<String, dynamic> json) {
    return MembershipFee(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      name: json['name'] ?? '',
      benefits: json['benefits'] ?? '',
      monthlyFee: (json['monthly_fee'] ?? 0).toDouble(),
      yearlyFee: (json['yearly_fee'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'club_id': clubId,
      'name': name,
      'benefits': benefits,
      'monthly_fee': monthlyFee,
      'yearly_fee': yearlyFee,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  MembershipFee copyWith({
    String? id,
    String? clubId,
    String? name,
    String? benefits,
    double? monthlyFee,
    double? yearlyFee,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MembershipFee(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      benefits: benefits ?? this.benefits,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      yearlyFee: yearlyFee ?? this.yearlyFee,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clubId,
        name,
        benefits,
        monthlyFee,
        yearlyFee,
        isActive,
        displayOrder,
        createdAt,
        updatedAt,
      ];
}

// ============================================================
// ADDITIONAL SERVICE MODEL
// ============================================================
class AdditionalService extends Equatable {
  final String id;
  final String clubId;
  final String name;
  final String description;
  final double price;
  final String unit;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdditionalService({
    required this.id,
    required this.clubId,
    required this.name,
    required this.description,
    required this.price,
    this.unit = 'lần',
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory AdditionalService.fromJson(Map<String, dynamic> json) {
    return AdditionalService(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'lần',
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'club_id': clubId,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  AdditionalService copyWith({
    String? id,
    String? clubId,
    String? name,
    String? description,
    double? price,
    String? unit,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdditionalService(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clubId,
        name,
        description,
        price,
        unit,
        isActive,
        displayOrder,
        createdAt,
        updatedAt,
      ];
}

// ============================================================
// CLUB PRICING WRAPPER
// ============================================================
class ClubPricing extends Equatable {
  final List<TableRate> tableRates;
  final List<MembershipFee> membershipFees;
  final List<AdditionalService> additionalServices;

  const ClubPricing({
    this.tableRates = const [],
    this.membershipFees = const [],
    this.additionalServices = const [],
  });

  ClubPricing copyWith({
    List<TableRate>? tableRates,
    List<MembershipFee>? membershipFees,
    List<AdditionalService>? additionalServices,
  }) {
    return ClubPricing(
      tableRates: tableRates ?? this.tableRates,
      membershipFees: membershipFees ?? this.membershipFees,
      additionalServices: additionalServices ?? this.additionalServices,
    );
  }

  @override
  List<Object?> get props => [tableRates, membershipFees, additionalServices];
}
