import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🚀 TESLA-GRADE EVENT SYSTEM: Single stream for all real-time events
enum RealtimeEventType {
  message,
  member,
  notification,
  activity,
  request,
  connection,
  typing,
}

class RealtimeEvent {
  final RealtimeEventType type;
  final String contextId; // roomId, clubId, userId
  final dynamic data;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.contextId,
    required this.data,
  }) : timestamp = DateTime.now();

  @override
  String toString() =>
      '🔄 $type[$contextId] at ${timestamp.millisecondsSinceEpoch}';
}

/// 🚀 SPACEX-OPTIMIZED Real-time Service
class OptimizedRealtimeService {
  static final OptimizedRealtimeService _instance =
      OptimizedRealtimeService._internal();
  factory OptimizedRealtimeService() => _instance;
  OptimizedRealtimeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // 🚀 TESLA OPTIMIZATION: Single event stream instead of 6+ controllers
  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();

  // Connection management
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, DateTime> _lastActivity = {};
  bool _isConnected = false;
  Timer? _connectionTimer;

  // Cache management - LRU with TTL
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int _maxCacheEntries = 1000;
  static const Duration _cacheTTL = Duration(minutes: 10);

  // Getters
  Stream<RealtimeEvent> get eventStream => _eventController.stream;
  bool get isConnected => _isConnected;

  /// 🚀 SUBSCRIBE to specific event types
  Stream<RealtimeEvent> subscribeToEvent(RealtimeEventType type,
      [String? contextId]) {
    return _eventController.stream.where((event) {
      if (event.type != type) return false;
      if (contextId != null && event.contextId != contextId) return false;
      return true;
    });
  }

  /// 🚀 CONNECT to real-time channel with smart management
  Future<void> connectToRoom(String roomId, String userId) async {
    final channelId = 'room_$roomId';

    try {
      // Cleanup old channels if too many
      if (_channels.length >= 5) {
        await _cleanupOldChannels();
      }

      if (_channels.containsKey(channelId)) {
        _updateActivity(channelId);
        return; // Already connected
      }

      final channel = _supabase
          .channel(channelId)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (payload) => _handleMessageChange(payload, roomId),
          )
          // TODO: Implement presence for typing indicators when available
          .subscribe();

      _channels[channelId] = channel;
      _updateActivity(channelId);
      _isConnected = true;

      _eventController.add(RealtimeEvent(
        type: RealtimeEventType.connection,
        contextId: roomId,
        data: {'status': 'connected'},
      ));

      if (kDebugMode) {
        // REMOVED: print('✅ Connected to room: $roomId');
      }
    } catch (e) {
      _eventController.add(RealtimeEvent(
        type: RealtimeEventType.connection,
        contextId: roomId,
        data: {'status': 'error', 'error': e.toString()},
      ));

      if (kDebugMode) {
        // REMOVED: print('❌ Failed to connect to room $roomId: $e');
      }
    }
  }

  /// 🚀 HANDLE message changes efficiently
  void _handleMessageChange(PostgresChangePayload payload, String roomId) {
    // Use payload data directly instead of requerying database
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _eventController.add(RealtimeEvent(
          type: RealtimeEventType.message,
          contextId: roomId,
          data: {
            'action': 'insert',
            'message': payload.newRecord,
          },
        ));
        break;

      case PostgresChangeEvent.update:
        _eventController.add(RealtimeEvent(
          type: RealtimeEventType.message,
          contextId: roomId,
          data: {
            'action': 'update',
            'message': payload.newRecord,
            'oldMessage': payload.oldRecord,
          },
        ));
        break;

      case PostgresChangeEvent.delete:
        _eventController.add(RealtimeEvent(
          type: RealtimeEventType.message,
          contextId: roomId,
          data: {
            'action': 'delete',
            'messageId': payload.oldRecord['id'],
          },
        ));
        break;

      default:
        break;
    }

    _updateActivity('room_$roomId');
  }

  /// 🚀 SEND typing indicator
  Future<void> sendTypingIndicator(
      String roomId, String userId, bool isTyping) async {
    final channelId = 'room_$roomId';
    final channel = _channels[channelId];

    if (channel != null) {
      if (isTyping) {
        await channel.track({
          'user_id': userId,
          'typing': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        await channel.untrack();
      }
    }
  }

  /// 🚀 UPDATE activity timestamp
  void _updateActivity(String channelId) {
    _lastActivity[channelId] = DateTime.now();
  }

  /// 🚀 CLEANUP old channels (LRU eviction)
  Future<void> _cleanupOldChannels() async {
    if (_channels.isEmpty) return;

    // Sort by last activity, remove oldest
    final sortedChannels = _lastActivity.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final toRemove = sortedChannels.take(2).map((e) => e.key).toList();

    for (final channelId in toRemove) {
      await _disconnectChannel(channelId);
    }

    if (kDebugMode) {
      // REMOVED: print('🧹 Cleaned up channels: $toRemove');
    }
  }

  /// 🚀 DISCONNECT specific channel
  Future<void> _disconnectChannel(String channelId) async {
    final channel = _channels[channelId];
    if (channel != null) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        // REMOVED: if (kDebugMode) print('⚠️ Error unsubscribing $channelId: $e');
      }

      _channels.remove(channelId);
      _lastActivity.remove(channelId);
    }
  }

  /// 🚀 DISCONNECT from room
  Future<void> disconnectFromRoom(String roomId) async {
    await _disconnectChannel('room_$roomId');

    _eventController.add(RealtimeEvent(
      type: RealtimeEventType.connection,
      contextId: roomId,
      data: {'status': 'disconnected'},
    ));
  }

  /// 🚀 CACHE operations with TTL
  void cacheData(String key, dynamic data) {
    if (_cache.length >= _maxCacheEntries) {
      _cleanupExpiredCache();
    }

    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  dynamic getCachedData(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheTTL) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _cache[key];
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheTTL) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    // If still too many, remove oldest
    if (_cache.length >= _maxCacheEntries) {
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final toRemove = sortedEntries
          .take(_cache.length - _maxCacheEntries ~/ 2)
          .map((e) => e.key)
          .toList();

      for (final key in toRemove) {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }

  /// 🚀 DISPOSE everything properly
  Future<void> dispose() async {
    _connectionTimer?.cancel();

    // Disconnect all channels with timeout
    final futures =
        _channels.keys.map((channelId) => _disconnectChannel(channelId).timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                // REMOVED: debugPrint('⏰ Timeout disconnecting $channelId');
              },
            ));

    await Future.wait(futures);

    if (!_eventController.isClosed) {
      _eventController.close();
    }

    _cache.clear();
    _cacheTimestamps.clear();
    _channels.clear();
    _lastActivity.clear();

    if (kDebugMode) {
      // REMOVED: print('🚀 OptimizedRealtimeService disposed');
    }
  }
}
