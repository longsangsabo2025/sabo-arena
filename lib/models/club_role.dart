import 'package:flutter/material.dart';

/// Enum representing different roles within a club
enum ClubRole {
  owner,
  admin,
  moderator,
  member,
  guest;

  /// Get string value for database
  String get value {
    switch (this) {
      case ClubRole.owner:
        return 'owner';
      case ClubRole.admin:
        return 'admin';
      case ClubRole.moderator:
        return 'moderator';
      case ClubRole.member:
        return 'member';
      case ClubRole.guest:
        return 'guest';
    }
  }

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case ClubRole.owner:
        return 'Chủ sở hữu';
      case ClubRole.admin:
        return 'Quản trị viên';
      case ClubRole.moderator:
        return 'Người điều hành';
      case ClubRole.member:
        return 'Thành viên';
      case ClubRole.guest:
        return 'Khách';
    }
  }

  /// Check if role has permission to create tournaments
  bool get canCreateTournaments {
    switch (this) {
      case ClubRole.owner:
      case ClubRole.admin:
      case ClubRole.moderator:
        return true;
      case ClubRole.member:
      case ClubRole.guest:
        return false;
    }
  }

  /// Check if role has permission to manage members
  bool get canManageMembers {
    switch (this) {
      case ClubRole.owner:
      case ClubRole.admin:
        return true;
      case ClubRole.moderator:
      case ClubRole.member:
      case ClubRole.guest:
        return false;
    }
  }

  /// Default permission: can verify rank
  bool get canVerifyRank {
    switch (this) {
      case ClubRole.owner:
      case ClubRole.admin:
        return true;
      case ClubRole.moderator:
      case ClubRole.member:
      case ClubRole.guest:
        return false;
    }
  }

  /// Default permission: can input score
  bool get canInputScore {
    switch (this) {
      case ClubRole.owner:
      case ClubRole.admin:
      case ClubRole.moderator:
        return true;
      case ClubRole.member:
      case ClubRole.guest:
        return false;
    }
  }

  /// Default permission: can manage tables
  bool get canManageTables {
    switch (this) {
      case ClubRole.owner:
      case ClubRole.admin:
      case ClubRole.moderator:
        return true;
      case ClubRole.member:
      case ClubRole.guest:
        return false;
    }
  }

  /// Default permission: can view reports
  bool get canViewReports {
    switch (this) {
      case ClubRole.owner:
      case ClubRole.admin:
        return true;
      case ClubRole.moderator:
      case ClubRole.member:
      case ClubRole.guest:
        return false;
    }
  }

  /// Default permission: can manage permissions
  bool get canManagePermissions {
    return this == ClubRole.owner;
  }

  /// Get role badge color (hex string)
  String get badgeColor {
    switch (this) {
      case ClubRole.owner:
        return '#FFD700'; // Gold
      case ClubRole.admin:
        return '#00695C'; // Primary green
      case ClubRole.moderator:
        return '#1976D2'; // Blue
      case ClubRole.member:
        return '#9E9E9E'; // Gray
      case ClubRole.guest:
        return '#757575'; // Dark gray
    }
  }

  /// Get role icon emoji
  String get icon {
    switch (this) {
      case ClubRole.owner:
        return '👑'; // Crown
      case ClubRole.admin:
        return '⚙️'; // Gear
      case ClubRole.moderator:
        return '📋'; // Clipboard
      case ClubRole.member:
        return '👤'; // Person
      case ClubRole.guest:
        return '👁️'; // Eye
    }
  }

  /// Get role color as Color object
  Color get color {
    switch (this) {
      case ClubRole.owner:
        return const Color(0xFFFFD700); // Gold
      case ClubRole.admin:
        return const Color(0xFF00695C); // Primary green
      case ClubRole.moderator:
        return const Color(0xFF1976D2); // Blue
      case ClubRole.member:
        return const Color(0xFF9E9E9E); // Gray
      case ClubRole.guest:
        return const Color(0xFF757575); // Dark gray
    }
  }

  /// Get role description
  String get description {
    switch (this) {
      case ClubRole.owner:
        return 'Toàn quyền quản lý câu lạc bộ';
      case ClubRole.admin:
        return 'Xác thực hạng, nhập tỷ số, quản lý bàn, xem báo cáo';
      case ClubRole.moderator:
        return 'Nhập tỷ số, quản lý bàn, điều hành hoạt động';
      case ClubRole.member:
        return 'Thành viên thường, không có quyền đặc biệt';
      case ClubRole.guest:
        return 'Khách, quyền hạn chế';
    }
  }

  /// Create ClubRole from string
  static ClubRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return ClubRole.owner;
      case 'admin':
        return ClubRole.admin;
      case 'moderator':
        return ClubRole.moderator;
      case 'member':
        return ClubRole.member;
      case 'guest':
        return ClubRole.guest;
      default:
        return ClubRole.guest;
    }
  }
}
