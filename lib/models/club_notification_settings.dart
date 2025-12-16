/// Model for Club Notification Settings
/// Controls what notifications club members receive
class ClubNotificationSettings {
  final String id;
  final String clubId;
  final bool notifyNewMember;
  final bool notifyMembershipExpiring;
  final bool notifyNewTournament;
  final bool notifyTournamentUpdates;
  final bool notifyNewPost;
  final bool notifyNewAnnouncement;
  final bool notifyPaymentReceived;
  final int expiringNotificationDays; // Days before expiry to notify
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClubNotificationSettings({
    required this.id,
    required this.clubId,
    this.notifyNewMember = true,
    this.notifyMembershipExpiring = true,
    this.notifyNewTournament = true,
    this.notifyTournamentUpdates = true,
    this.notifyNewPost = false,
    this.notifyNewAnnouncement = true,
    this.notifyPaymentReceived = true,
    this.expiringNotificationDays = 7,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON (Supabase)
  factory ClubNotificationSettings.fromJson(Map<String, dynamic> json) {
    return ClubNotificationSettings(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      notifyNewMember: json['notify_new_member'] as bool? ?? true,
      notifyMembershipExpiring:
          json['notify_membership_expiring'] as bool? ?? true,
      notifyNewTournament: json['notify_new_tournament'] as bool? ?? true,
      notifyTournamentUpdates:
          json['notify_tournament_updates'] as bool? ?? true,
      notifyNewPost: json['notify_new_post'] as bool? ?? false,
      notifyNewAnnouncement: json['notify_new_announcement'] as bool? ?? true,
      notifyPaymentReceived: json['notify_payment_received'] as bool? ?? true,
      expiringNotificationDays:
          json['expiring_notification_days'] as int? ?? 7,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'notify_new_member': notifyNewMember,
      'notify_membership_expiring': notifyMembershipExpiring,
      'notify_new_tournament': notifyNewTournament,
      'notify_tournament_updates': notifyTournamentUpdates,
      'notify_new_post': notifyNewPost,
      'notify_new_announcement': notifyNewAnnouncement,
      'notify_payment_received': notifyPaymentReceived,
      'expiring_notification_days': expiringNotificationDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ClubNotificationSettings copyWith({
    String? id,
    String? clubId,
    bool? notifyNewMember,
    bool? notifyMembershipExpiring,
    bool? notifyNewTournament,
    bool? notifyTournamentUpdates,
    bool? notifyNewPost,
    bool? notifyNewAnnouncement,
    bool? notifyPaymentReceived,
    int? expiringNotificationDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClubNotificationSettings(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      notifyNewMember: notifyNewMember ?? this.notifyNewMember,
      notifyMembershipExpiring:
          notifyMembershipExpiring ?? this.notifyMembershipExpiring,
      notifyNewTournament: notifyNewTournament ?? this.notifyNewTournament,
      notifyTournamentUpdates:
          notifyTournamentUpdates ?? this.notifyTournamentUpdates,
      notifyNewPost: notifyNewPost ?? this.notifyNewPost,
      notifyNewAnnouncement:
          notifyNewAnnouncement ?? this.notifyNewAnnouncement,
      notifyPaymentReceived:
          notifyPaymentReceived ?? this.notifyPaymentReceived,
      expiringNotificationDays:
          expiringNotificationDays ?? this.expiringNotificationDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get count of enabled notifications
  int get enabledNotificationCount {
    int count = 0;
    if (notifyNewMember) count++;
    if (notifyMembershipExpiring) count++;
    if (notifyNewTournament) count++;
    if (notifyTournamentUpdates) count++;
    if (notifyNewPost) count++;
    if (notifyNewAnnouncement) count++;
    if (notifyPaymentReceived) count++;
    return count;
  }

  /// Check if all notifications are disabled
  bool get allDisabled =>
      !notifyNewMember &&
      !notifyMembershipExpiring &&
      !notifyNewTournament &&
      !notifyTournamentUpdates &&
      !notifyNewPost &&
      !notifyNewAnnouncement &&
      !notifyPaymentReceived;

  @override
  String toString() {
    return 'ClubNotificationSettings(clubId: $clubId, enabled: $enabledNotificationCount/7)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubNotificationSettings && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
