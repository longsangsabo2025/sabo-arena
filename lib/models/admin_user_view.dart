/// Admin-specific user model with additional admin fields
/// This is separate from UserProfile to avoid polluting the core model
class AdminUserView {
  final String id;
  final String email;
  final String fullName;
  final String displayName;
  final String? avatarUrl;
  final String? phone;
  final String role; // 'user', 'admin', 'moderator'
  final String status; // 'active', 'inactive', 'blocked', 'deleted'
  final String? rank;
  final int? eloRating;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? blockedAt;
  final String? blockedReason;
  final int totalWins;
  final int totalLosses;
  final int totalTournaments;

  AdminUserView({
    required this.id,
    required this.email,
    required this.fullName,
    required this.displayName,
    this.avatarUrl,
    this.phone,
    required this.role,
    required this.status,
    this.rank,
    this.eloRating,
    required this.isVerified,
    required this.createdAt,
    this.blockedAt,
    this.blockedReason,
    required this.totalWins,
    required this.totalLosses,
    required this.totalTournaments,
  });

  factory AdminUserView.fromJson(Map<String, dynamic> json) {
    return AdminUserView(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      displayName: json['display_name'] ?? json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
      phone: json['phone'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      rank: json['rank'],
      eloRating: json['elo_rating'],
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      blockedAt: json['blocked_at'] != null
          ? DateTime.parse(json['blocked_at'])
          : null,
      blockedReason: json['blocked_reason'],
      totalWins: json['total_wins'] ?? 0,
      totalLosses: json['total_losses'] ?? 0,
      totalTournaments: json['total_tournaments'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'role': role,
      'status': status,
      'rank': rank,
      'elo_rating': eloRating,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'blocked_at': blockedAt?.toIso8601String(),
      'blocked_reason': blockedReason,
      'total_wins': totalWins,
      'total_losses': totalLosses,
      'total_tournaments': totalTournaments,
    };
  }

  AdminUserView copyWith({
    String? id,
    String? email,
    String? fullName,
    String? displayName,
    String? avatarUrl,
    String? phone,
    String? role,
    String? status,
    String? rank,
    int? eloRating,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? blockedAt,
    String? blockedReason,
    int? totalWins,
    int? totalLosses,
    int? totalTournaments,
  }) {
    return AdminUserView(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      rank: rank ?? this.rank,
      eloRating: eloRating ?? this.eloRating,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      blockedAt: blockedAt ?? this.blockedAt,
      blockedReason: blockedReason ?? this.blockedReason,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      totalTournaments: totalTournaments ?? this.totalTournaments,
    );
  }

  // Helper methods
  bool get isBlocked => status == 'blocked';
  bool get isActive => status == 'active';
  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      case 'blocked':
        return 'Bị chặn';
      case 'deleted':
        return 'Đã xóa';
      default:
        return status;
    }
  }

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'moderator':
        return 'Điều hành viên';
      case 'user':
        return 'Người dùng';
      default:
        return role;
    }
  }
}
