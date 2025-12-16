import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/notification_models.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  static NotificationPreferencesService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService.instance;

  /// Get notification preferences for current user
  Future<NotificationPreferences?> getUserPreferences() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('notification_preferences')
          .select('*')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        return NotificationPreferences.fromJson(response);
      }

      // Create default preferences if none exist
      return await _createDefaultPreferences(currentUser.id);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Create default notification preferences
  Future<NotificationPreferences?> _createDefaultPreferences(
    String userId,
  ) async {
    try {
      final defaultPrefs = NotificationPreferences.defaultPreferences(userId);
      final prefsData = defaultPrefs.toJson()..['user_id'] = userId;

      final response = await _supabase
          .from('notification_preferences')
          .insert(prefsData)
          .select('*')
          .single();

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Update notification preferences
  Future<bool> updatePreferences(NotificationPreferences preferences) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      final updateData = preferences.toJson()
        ..['user_id'] = currentUser.id
        ..['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('notification_preferences').upsert(updateData);

      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Update specific notification type setting
  Future<bool> updateNotificationTypeSetting({
    required NotificationType type,
    required bool enabled,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
  }) async {
    try {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedSettings =
          Map<NotificationType, NotificationTypeSetting>.from(
            preferences.typeSettings,
          );

      final currentSetting =
          updatedSettings[type] ?? NotificationTypeSetting.defaultSetting(type);
      updatedSettings[type] = currentSetting.copyWith(
        enabled: enabled,
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
        smsEnabled: smsEnabled,
      );

      final updatedPreferences = preferences.copyWith(
        typeSettings: updatedSettings,
      );
      return await updatePreferences(updatedPreferences);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Update quiet hours
  Future<bool> updateQuietHours({
    required bool enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    try {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedPreferences = preferences.copyWith(
        quietHoursEnabled: enabled,
        quietHoursStart: startTime,
        quietHoursEnd: endTime,
      );

      return await updatePreferences(updatedPreferences);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Update notification sound
  Future<bool> updateNotificationSound(String soundId) async {
    try {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedPreferences = preferences.copyWith(
        notificationSound: soundId,
      );
      return await updatePreferences(updatedPreferences);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Update vibration setting
  Future<bool> updateVibrationEnabled(bool enabled) async {
    try {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedPreferences = preferences.copyWith(
        vibrationEnabled: enabled,
      );
      return await updatePreferences(updatedPreferences);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Update LED setting
  Future<bool> updateLedEnabled(bool enabled) async {
    try {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedPreferences = preferences.copyWith(ledEnabled: enabled);
      return await updatePreferences(updatedPreferences);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Check if notification should be shown based on preferences
  Future<bool> shouldShowNotification({
    required NotificationType type,
    String? channel,
  }) async {
    try {
      final preferences = await getUserPreferences();
      if (preferences == null) return true; // Default to showing notifications

      // Check if notifications are globally enabled
      if (!preferences.notificationsEnabled) return false;

      // Check if this specific type is enabled
      final typeSetting = preferences.typeSettings[type];
      if (typeSetting == null || !typeSetting.enabled) return false;

      // Check channel-specific settings
      if (channel != null) {
        switch (channel.toLowerCase()) {
          case 'push':
            if (!typeSetting.pushEnabled) return false;
            break;
          case 'email':
            if (!typeSetting.emailEnabled) return false;
            break;
          case 'sms':
            if (!typeSetting.smsEnabled) return false;
            break;
        }
      }

      // Check quiet hours
      if (preferences.quietHoursEnabled && _isInQuietHours(preferences)) {
        return false;
      }

      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true; // Default to allowing notifications
    }
  }

  /// Check if current time is within quiet hours
  bool _isInQuietHours(NotificationPreferences preferences) {
    if (!preferences.quietHoursEnabled ||
        preferences.quietHoursStart == null ||
        preferences.quietHoursEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = preferences.quietHoursStart!;
    final end = preferences.quietHoursEnd!;

    // Convert to minutes for easier comparison
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Same day (e.g., 9:00 PM to 11:00 PM)
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Crosses midnight (e.g., 10:00 PM to 6:00 AM)
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  /// Get available notification sounds
  Future<List<NotificationSound>> getAvailableSounds() async {
    try {
      // Return the enum values since NotificationSound is an enum
      return NotificationSound.values;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return NotificationSound.values;
    }
  }

  /// Test notification sound
  Future<void> testNotificationSound(String soundId) async {
    try {
      // TODO: Implement sound playing logic based on platform
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Reset preferences to default
  Future<bool> resetToDefault() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('notification_preferences')
          .delete()
          .eq('user_id', currentUser.id);

      await _createDefaultPreferences(currentUser.id);
      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Export preferences as JSON
  Future<Map<String, dynamic>?> exportPreferences() async {
    try {
      final preferences = await getUserPreferences();
      return preferences?.toJson();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Import preferences from JSON
  Future<bool> importPreferences(Map<String, dynamic> prefsData) async {
    try {
      final preferences = NotificationPreferences.fromJson(prefsData);
      return await updatePreferences(preferences);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Subscribe to preference changes
  RealtimeChannel subscribeToPreferenceChanges(
    Function(NotificationPreferences) onChanged,
  ) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    return _supabase
        .channel('notification_preferences_${currentUser.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notification_preferences',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser.id,
          ),
          callback: (payload) {
            try {
              final preferences = NotificationPreferences.fromJson(
                payload.newRecord,
              );
              onChanged(preferences);
            } catch (e) {
              ProductionLogger.debug('Debug log', tag: 'AutoFix');
            }
          },
        )
        .subscribe();
  }

  // Alias methods for backward compatibility
  Future<NotificationPreferences?> loadPreferences() async {
    return await getUserPreferences();
  }

  Future<bool> savePreferences(NotificationPreferences preferences) async {
    return await updatePreferences(preferences);
  }

  Future<bool> updatePushSetting(NotificationType type, bool enabled) async {
    return await updateNotificationTypeSetting(
      type: type,
      enabled: enabled,
      pushEnabled: enabled,
    );
  }

  // ==================== ENHANCED METHODS (Merged from EnhancedNotificationPreferencesService) ====================

  /// Get preferences as Map (for enhanced screen compatibility)
  Future<Map<String, dynamic>> getPreferencesAsMap() async {
    try {
      final prefs = await getUserPreferences();
      if (prefs == null) {
        return _getDefaultPreferencesMap();
      }
      return prefs.toJson();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return _getDefaultPreferencesMap();
    }
  }

  /// Get default preferences as Map
  Map<String, dynamic> _getDefaultPreferencesMap() {
    return {
      'all_notifications_enabled': true,
      'push_notifications_enabled': true,
      'email_notifications_enabled': false,
      'tournament_notifications_enabled': true,
      'club_notifications_enabled': true,
      'challenge_notifications_enabled': true,
      'match_notifications_enabled': true,
      'social_notifications_enabled': true,
      'system_notifications_enabled': true,
      'quiet_hours_enabled': false,
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '08:00',
    };
  }

  /// Update specific preference by key (for enhanced screen compatibility)
  Future<bool> updatePreference(String key, dynamic value) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Map string keys to NotificationPreferences fields
      final prefs = await getUserPreferences();
      if (prefs == null) return false;

      // Handle different preference types
      if (key == 'all_notifications_enabled') {
        return await updatePreferences(prefs.copyWith(notificationsEnabled: value as bool));
      } else if (key == 'quiet_hours_enabled') {
        return await updateQuietHours(enabled: value as bool);
      } else if (key == 'quiet_hours_start' || key == 'quiet_hours_end') {
        // Parse time string to TimeOfDay
        final timeParts = (value as String).split(':');
        final timeOfDay = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
        if (key == 'quiet_hours_start') {
          return await updateQuietHours(
            enabled: prefs.quietHoursEnabled,
            startTime: timeOfDay,
            endTime: prefs.quietHoursEnd,
          );
        } else {
          return await updateQuietHours(
            enabled: prefs.quietHoursEnabled,
            startTime: prefs.quietHoursStart,
            endTime: timeOfDay,
          );
        }
      }

      // For other keys, update via preferences update
      final updatedData = prefs.toJson();
      updatedData[key] = value;
      updatedData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('notification_preferences')
          .update(updatedData)
          .eq('user_id', currentUser.id);

      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }

  /// Check if notification should be sent (enhanced version)
  Future<bool> shouldSendNotification(String notificationType) async {
    try {
      final prefs = await getUserPreferences();
      if (prefs == null) return true;

      if (!prefs.notificationsEnabled) return false;

      // Check quiet hours
      if (prefs.quietHoursEnabled && _isInQuietHours(prefs)) {
        return false;
      }

      // Check specific notification type
      final type = _mapStringToNotificationType(notificationType);
      if (type != null) {
        final typeSetting = prefs.typeSettings[type];
        return typeSetting?.enabled ?? true;
      }

      return true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return true;
    }
  }

  /// Map string notification type to enum
  NotificationType? _mapStringToNotificationType(String type) {
    // Use NotificationType.fromString if available, otherwise return null
    try {
      return NotificationType.fromString(type);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Get notification type display names
  Map<String, String> getNotificationTypeNames() {
    return {
      'tournament': 'Tournament Updates',
      'club': 'Club Activities',
      'challenge': 'Challenge Invitations',
      'match': 'Match Reminders',
      'social': 'Social Interactions',
      'system': 'System Announcements',
    };
  }

  /// Get notification type descriptions
  Map<String, String> getNotificationTypeDescriptions() {
    return {
      'tournament': 'Tournament registrations, matches, and results',
      'club': 'Club member activities and announcements',
      'challenge': 'Challenge requests and match invitations',
      'match': 'Upcoming match reminders and updates',
      'social': 'Likes, comments, and new followers',
      'system': 'App updates and important announcements',
    };
  }

  /// Batch update for initial setup
  Future<bool> setupInitialPreferences({
    required bool enablePush,
    required bool enableEmail,
    List<String>? enabledTypes,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      final prefs = NotificationPreferences.defaultPreferences(currentUser.id)
          .copyWith(
            notificationsEnabled: true,
            // Map enabled types to NotificationPreferences
          );

      return await updatePreferences(prefs);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }
}

/// Extension to add TimeOfDay functionality
extension TimeOfDayExtension on TimeOfDay {
  static TimeOfDay now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }
}

