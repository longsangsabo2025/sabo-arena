import 'package:flutter/material.dart';

/// Model cho loại thành viên CLB
/// VIP, Regular, Student, Day Pass, etc.
class MembershipType {
  final String id;
  final String clubId;
  final String name;
  final String description;
  final Color color;
  final String icon; // Icon name as string
  final double monthlyFee;
  final double? dailyFee;
  final double? yearlyFee;
  final List<String> benefits;
  final bool isActive;
  final bool requiresApproval;
  final int? maxMembers;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MembershipType({
    required this.id,
    required this.clubId,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    this.monthlyFee = 0,
    this.dailyFee,
    this.yearlyFee,
    this.benefits = const [],
    this.isActive = true,
    this.requiresApproval = false,
    this.maxMembers,
    this.priority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory MembershipType.fromJson(Map<String, dynamic> json) {
    // Parse color from hex string
    String colorHex = json['color'] as String? ?? '#4CAF50';
    if (colorHex.startsWith('#')) {
      colorHex = colorHex.substring(1);
    }
    final color = Color(int.parse('FF$colorHex', radix: 16));

    // Parse benefits from JSONB
    List<String> benefits = [];
    if (json['benefits'] != null) {
      if (json['benefits'] is List) {
        benefits = (json['benefits'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return MembershipType(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      color: color,
      icon: json['icon'] as String? ?? 'card_membership',
      monthlyFee: (json['monthly_fee'] as num?)?.toDouble() ?? 0,
      dailyFee: (json['daily_fee'] as num?)?.toDouble(),
      yearlyFee: (json['yearly_fee'] as num?)?.toDouble(),
      benefits: benefits,
      isActive: json['is_active'] as bool? ?? true,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      maxMembers: json['max_members'] as int?,
      priority: json['priority'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    // Convert color to hex string
    final colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    return {
      'id': id,
      'club_id': clubId,
      'name': name,
      'description': description,
      'color': colorHex,
      'icon': icon,
      'monthly_fee': monthlyFee,
      'daily_fee': dailyFee,
      'yearly_fee': yearlyFee,
      'benefits': benefits,
      'is_active': isActive,
      'requires_approval': requiresApproval,
      'max_members': maxMembers,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to JSON for INSERT (without id, timestamps)
  Map<String, dynamic> toInsertJson() {
    final colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    return {
      'club_id': clubId,
      'name': name,
      'description': description,
      'color': colorHex,
      'icon': icon,
      'monthly_fee': monthlyFee,
      'daily_fee': dailyFee,
      'yearly_fee': yearlyFee,
      'benefits': benefits,
      'is_active': isActive,
      'requires_approval': requiresApproval,
      'max_members': maxMembers,
      'priority': priority,
    };
  }

  /// Get IconData from icon string
  IconData get iconData {
    switch (icon) {
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'card_membership':
        return Icons.card_membership;
      case 'school':
        return Icons.school;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'star':
        return Icons.star;
      case 'diamond':
        return Icons.diamond;
      default:
        return Icons.card_membership;
    }
  }

  /// Copy with method
  MembershipType copyWith({
    String? id,
    String? clubId,
    String? name,
    String? description,
    Color? color,
    String? icon,
    double? monthlyFee,
    double? dailyFee,
    double? yearlyFee,
    List<String>? benefits,
    bool? isActive,
    bool? requiresApproval,
    int? maxMembers,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MembershipType(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      dailyFee: dailyFee ?? this.dailyFee,
      yearlyFee: yearlyFee ?? this.yearlyFee,
      benefits: benefits ?? this.benefits,
      isActive: isActive ?? this.isActive,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      maxMembers: maxMembers ?? this.maxMembers,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
