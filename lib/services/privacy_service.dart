import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/production_logger.dart';

/// Privacy settings for user profile visibility and preferences
class UserPrivacySettings {
  // Profile visibility
  final bool profilePublic;
  final bool showEmail;
  final bool showPhone;
  final bool showLocation;
  final bool showStats;

  // Activity visibility
  final bool showOnlineStatus;
  final bool showMatchHistory;
  final bool showTournaments;

  // Search & discoverability
  final bool searchable;
  final bool allowFriendRequests;
  final bool allowMessages;

  // Notifications
  final bool emailNotifications;
  final bool pushNotifications;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPrivacySettings({
    this.profilePublic = true,
    this.showEmail = false,
    this.showPhone = false,
    this.showLocation = true,
    this.showStats = true,
    this.showOnlineStatus = true,
    this.showMatchHistory = true,
    this.showTournaments = true,
    this.searchable = true,
    this.allowFriendRequests = true,
    this.allowMessages = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPrivacySettings.fromJson(Map<String, dynamic> json) {
    return UserPrivacySettings(
      profilePublic: json['profile_public'] ?? true,
      showEmail: json['show_email'] ?? false,
      showPhone: json['show_phone'] ?? false,
      showLocation: json['show_location'] ?? true,
      showStats: json['show_stats'] ?? true,
      showOnlineStatus: json['show_online_status'] ?? true,
      showMatchHistory: json['show_match_history'] ?? true,
      showTournaments: json['show_tournaments'] ?? true,
      searchable: json['searchable'] ?? true,
      allowFriendRequests: json['allow_friend_requests'] ?? true,
      allowMessages: json['allow_messages'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_public': profilePublic,
      'show_email': showEmail,
      'show_phone': showPhone,
      'show_location': showLocation,
      'show_stats': showStats,
      'show_online_status': showOnlineStatus,
      'show_match_history': showMatchHistory,
      'show_tournaments': showTournaments,
      'searchable': searchable,
      'allow_friend_requests': allowFriendRequests,
      'allow_messages': allowMessages,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
    };
  }

  UserPrivacySettings copyWith({
    bool? profilePublic,
    bool? showEmail,
    bool? showPhone,
    bool? showLocation,
    bool? showStats,
    bool? showOnlineStatus,
    bool? showMatchHistory,
    bool? showTournaments,
    bool? searchable,
    bool? allowFriendRequests,
    bool? allowMessages,
    bool? emailNotifications,
    bool? pushNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPrivacySettings(
      profilePublic: profilePublic ?? this.profilePublic,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      showLocation: showLocation ?? this.showLocation,
      showStats: showStats ?? this.showStats,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showMatchHistory: showMatchHistory ?? this.showMatchHistory,
      showTournaments: showTournaments ?? this.showTournaments,
      searchable: searchable ?? this.searchable,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      allowMessages: allowMessages ?? this.allowMessages,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Service for managing user privacy settings
class PrivacyService {
  static final PrivacyService instance = PrivacyService._internal();
  factory PrivacyService() => instance;
  PrivacyService._internal();

  final _supabase = Supabase.instance.client;

  /// Get privacy settings for current user
  Future<UserPrivacySettings> getMyPrivacySettings() async {
    try {
      ProductionLogger.info('Fetching privacy settings', tag: 'Privacy');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      try {
        final response = await _supabase
            .from('user_privacy_settings')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (response == null) {
          // Create default settings if none exist
          ProductionLogger.info('Creating default privacy settings',
              tag: 'Privacy');
          return await _createDefaultSettings(userId);
        }

        return UserPrivacySettings.fromJson(response);
      } catch (e) {
        // If table or column doesn't exist, create default
        ProductionLogger.warning(
            'Privacy settings error, creating defaults: $e',
            tag: 'Privacy');
        return await _createDefaultSettings(userId);
      }
    } catch (error) {
      ProductionLogger.error(
        'Failed to fetch privacy settings',
        error: error,
        tag: 'Privacy',
      );
      rethrow;
    }
  }

  /// Update privacy settings
  Future<UserPrivacySettings> updatePrivacySettings({
    bool? profilePublic,
    bool? showEmail,
    bool? showPhone,
    bool? showLocation,
    bool? showStats,
    bool? showOnlineStatus,
    bool? showMatchHistory,
    bool? showTournaments,
    bool? searchable,
    bool? allowFriendRequests,
    bool? allowMessages,
    bool? emailNotifications,
    bool? pushNotifications,
  }) async {
    try {
      ProductionLogger.info('Updating privacy settings', tag: 'Privacy');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (profilePublic != null) updates['profile_public'] = profilePublic;
      if (showEmail != null) updates['show_email'] = showEmail;
      if (showPhone != null) updates['show_phone'] = showPhone;
      if (showLocation != null) updates['show_location'] = showLocation;
      if (showStats != null) updates['show_stats'] = showStats;
      if (showOnlineStatus != null)
        updates['show_online_status'] = showOnlineStatus;
      if (showMatchHistory != null)
        updates['show_match_history'] = showMatchHistory;
      if (showTournaments != null)
        updates['show_tournaments'] = showTournaments;
      if (searchable != null) updates['searchable'] = searchable;
      if (allowFriendRequests != null)
        updates['allow_friend_requests'] = allowFriendRequests;
      if (allowMessages != null) updates['allow_messages'] = allowMessages;
      if (emailNotifications != null)
        updates['email_notifications'] = emailNotifications;
      if (pushNotifications != null)
        updates['push_notifications'] = pushNotifications;

      final response = await _supabase
          .from('user_privacy_settings')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      ProductionLogger.info('Privacy settings updated successfully',
          tag: 'Privacy');
      return UserPrivacySettings.fromJson(response);
    } catch (error) {
      ProductionLogger.error(
        'Failed to update privacy settings',
        error: error,
        tag: 'Privacy',
      );
      rethrow;
    }
  }

  /// Create default privacy settings for user
  Future<UserPrivacySettings> _createDefaultSettings(String userId) async {
    final now = DateTime.now();
    final defaults = {
      'user_id': userId,
      'profile_public': true,
      'show_email': false,
      'show_phone': false,
      'show_location': true,
      'show_stats': true,
      'show_online_status': true,
      'show_match_history': true,
      'show_tournaments': true,
      'searchable': true,
      'allow_friend_requests': true,
      'allow_messages': true,
      'email_notifications': true,
      'push_notifications': true,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final response = await _supabase
        .from('user_privacy_settings')
        .insert(defaults)
        .select()
        .single();

    return UserPrivacySettings.fromJson(response);
  }

  /// Get privacy settings for another user (respecting their privacy)
  Future<UserPrivacySettings?> getUserPrivacySettings(String userId) async {
    try {
      final response = await _supabase
          .from('user_privacy_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserPrivacySettings.fromJson(response);
    } catch (error) {
      ProductionLogger.error(
        'Failed to fetch user privacy settings',
        error: error,
        tag: 'Privacy',
      );
      return null;
    }
  }
}
