class MemberAnalytics {
  final int totalMembers;
  final int activeMembers;
  final int newThisMonth;
  final double growthRate;
  final Map<String, dynamic>? memberGrowth;
  final double? activityRate;
  final double? retentionRate;

  const MemberAnalytics({
    required this.totalMembers,
    required this.activeMembers,
    required this.newThisMonth,
    required this.growthRate,
    this.memberGrowth,
    this.activityRate,
    this.retentionRate,
  });

  factory MemberAnalytics.fromJson(Map<String, dynamic> json) {
    return MemberAnalytics(
      totalMembers: json['total_members'] ?? 0,
      activeMembers: json['active_members'] ?? 0,
      newThisMonth: json['new_this_month'] ?? 0,
      growthRate: (json['growth_rate'] ?? 0.0).toDouble(),
      memberGrowth: json['member_growth'],
      activityRate: json['activity_rate'] != null
          ? (json['activity_rate'] as num).toDouble()
          : null,
      retentionRate: json['retention_rate'] != null
          ? (json['retention_rate'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_members': totalMembers,
      'active_members': activeMembers,
      'new_this_month': newThisMonth,
      'growth_rate': growthRate,
      if (memberGrowth != null) 'member_growth': memberGrowth,
      if (activityRate != null) 'activity_rate': activityRate,
      if (retentionRate != null) 'retention_rate': retentionRate,
    };
  }
}
