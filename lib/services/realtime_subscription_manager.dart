import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
// ELON_MODE_AUTO_FIX

/// Real-time Subscription Manager
/// Manages and limits concurrent real-time subscriptions per user
/// 
/// Limits:
/// - Max 10 concurrent subscriptions per user
/// - Automatic cleanup on dispose
/// - Subscription pooling for efficiency
class RealtimeSubscriptionManager {
  static RealtimeSubscriptionManager? _instance;
  static RealtimeSubscriptionManager get instance =>
      _instance ??= RealtimeSubscriptionManager._();

  RealtimeSubscriptionManager._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Active subscriptions tracking
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, DateTime> _subscriptionTimestamps = {};
  final Map<String, String> _subscriptionTypes = {}; // 'tournament', 'club', 'user', etc.
  
  // Configuration
  static const int _maxConcurrentSubscriptions = 10;
  static const Duration _subscriptionTimeout = Duration(minutes: 30);
  
  // Statistics
  int _totalSubscriptions = 0;
  int _subscriptionsCleaned = 0;

  /// Subscribe to tournament updates with limits
  Future<RealtimeChannel?> subscribeTournament(
    String tournamentId, {
    Function(Map<String, dynamic>)? onUpdate,
    Function(Map<String, dynamic>)? onInsert,
    Function(Map<String, dynamic>)? onDelete,
  }) async {
    final key = 'tournament:$tournamentId';
    
    // Check if already subscribed
    if (_activeChannels.containsKey(key)) {
      if (kDebugMode) {
      }
      return _activeChannels[key];
    }

    // Check subscription limit
    if (_activeChannels.length >= _maxConcurrentSubscriptions) {
      await _cleanupOldestSubscription();
    }

    try {
      final channel = _supabase
          .channel(key)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tournaments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: tournamentId,
            ),
            callback: (payload) {
              if (onUpdate != null && payload.eventType == 'UPDATE') {
                onUpdate(payload.newRecord);
              } else if (onInsert != null && payload.eventType == 'INSERT') {
                onInsert(payload.newRecord);
              } else if (onDelete != null && payload.eventType == 'DELETE') {
                onDelete(payload.oldRecord);
              }
            },
          )
          .subscribe();

      _activeChannels[key] = channel;
      _subscriptionTimestamps[key] = DateTime.now();
      _subscriptionTypes[key] = 'tournament';
      _totalSubscriptions++;

      if (kDebugMode) {
      }

      return channel;
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    }
  }

  /// Subscribe to match updates for a tournament
  Future<RealtimeChannel?> subscribeMatches(
    String tournamentId, {
    Function(Map<String, dynamic>)? onUpdate,
  }) async {
    final key = 'matches:$tournamentId';
    
    if (_activeChannels.containsKey(key)) {
      return _activeChannels[key];
    }

    if (_activeChannels.length >= _maxConcurrentSubscriptions) {
      await _cleanupOldestSubscription();
    }

    try {
      final channel = _supabase
          .channel(key)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'matches',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'tournament_id',
              value: tournamentId,
            ),
            callback: (payload) {
              if (onUpdate != null) {
                final data = payload.newRecord.isNotEmpty 
                    ? payload.newRecord 
                    : payload.oldRecord;
                onUpdate(data);
              }
            },
          )
          .subscribe();

      _activeChannels[key] = channel;
      _subscriptionTimestamps[key] = DateTime.now();
      _subscriptionTypes[key] = 'matches';
      _totalSubscriptions++;

      if (kDebugMode) {
      }

      return channel;
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    }
  }

  /// Subscribe to user-specific updates
  Future<RealtimeChannel?> subscribeUser(
    String userId, {
    Function(Map<String, dynamic>)? onUpdate,
  }) async {
    final key = 'user:$userId';
    
    if (_activeChannels.containsKey(key)) {
      return _activeChannels[key];
    }

    if (_activeChannels.length >= _maxConcurrentSubscriptions) {
      await _cleanupOldestSubscription();
    }

    try {
      final channel = _supabase
          .channel(key)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: userId,
            ),
            callback: (payload) {
              if (onUpdate != null) {
                final data = payload.newRecord.isNotEmpty 
                    ? payload.newRecord 
                    : payload.oldRecord;
                onUpdate(data);
              }
            },
          )
          .subscribe();

      _activeChannels[key] = channel;
      _subscriptionTimestamps[key] = DateTime.now();
      _subscriptionTypes[key] = 'user';
      _totalSubscriptions++;

      return channel;
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    }
  }

  /// Subscribe to club updates
  Future<RealtimeChannel?> subscribeClub(
    String clubId, {
    Function(Map<String, dynamic>)? onUpdate,
  }) async {
    final key = 'club:$clubId';
    
    if (_activeChannels.containsKey(key)) {
      return _activeChannels[key];
    }

    if (_activeChannels.length >= _maxConcurrentSubscriptions) {
      await _cleanupOldestSubscription();
    }

    try {
      final channel = _supabase
          .channel(key)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'clubs',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: clubId,
            ),
            callback: (payload) {
              if (onUpdate != null) {
                final data = payload.newRecord.isNotEmpty 
                    ? payload.newRecord 
                    : payload.oldRecord;
                onUpdate(data);
              }
            },
          )
          .subscribe();

      _activeChannels[key] = channel;
      _subscriptionTimestamps[key] = DateTime.now();
      _subscriptionTypes[key] = 'club';
      _totalSubscriptions++;

      return channel;
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    }
  }

  /// Unsubscribe from a specific subscription
  Future<void> unsubscribe(String key) async {
    final channel = _activeChannels[key];
    if (channel != null) {
      await _supabase.removeChannel(channel);
      _activeChannels.remove(key);
      _subscriptionTimestamps.remove(key);
      _subscriptionTypes.remove(key);
      
      if (kDebugMode) {
      }
    }
  }

  /// Unsubscribe from tournament
  Future<void> unsubscribeTournament(String tournamentId) async {
    await unsubscribe('tournament:$tournamentId');
    await unsubscribe('matches:$tournamentId');
    await unsubscribe('participants:$tournamentId');
  }

  /// Unsubscribe from user
  Future<void> unsubscribeUser(String userId) async {
    await unsubscribe('user:$userId');
  }

  /// Unsubscribe from club
  Future<void> unsubscribeClub(String clubId) async {
    await unsubscribe('club:$clubId');
  }

  /// Cleanup oldest subscription when limit reached
  Future<void> _cleanupOldestSubscription() async {
    if (_activeChannels.isEmpty) return;

    // Find oldest subscription
    String? oldestKey;
    DateTime? oldestTime;
    
    for (final entry in _subscriptionTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      await unsubscribe(oldestKey);
      _subscriptionsCleaned++;
      
      if (kDebugMode) {
      }
    }
  }

  /// Cleanup expired subscriptions (older than timeout)
  Future<void> cleanupExpiredSubscriptions() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _subscriptionTimestamps.entries) {
      final age = now.difference(entry.value);
      if (age > _subscriptionTimeout) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await unsubscribe(key);
    }

    if (expiredKeys.isNotEmpty && kDebugMode) {
    }
  }

  /// Cleanup all subscriptions
  Future<void> cleanupAll() async {
    final keys = _activeChannels.keys.toList();
    for (final key in keys) {
      await unsubscribe(key);
    }
    
    if (kDebugMode) {
    }
  }

  /// Get subscription statistics
  Map<String, dynamic> getStats() {
    final byType = <String, int>{};
    for (final type in _subscriptionTypes.values) {
      byType[type] = (byType[type] ?? 0) + 1;
    }

    return {
      'active_subscriptions': _activeChannels.length,
      'max_subscriptions': _maxConcurrentSubscriptions,
      'total_subscriptions': _totalSubscriptions,
      'subscriptions_cleaned': _subscriptionsCleaned,
      'by_type': byType,
    };
  }

  /// Dispose resources
  void dispose() {
    cleanupAll();
  }
}


