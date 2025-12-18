import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

class MemberRealtimeService {
  static final MemberRealtimeService _instance =
      MemberRealtimeService._internal();
  factory MemberRealtimeService() => _instance;
  MemberRealtimeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for real-time data
  final StreamController<List<Map<String, dynamic>>> _membersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _requestsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _chatMessagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _notificationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _activitiesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Subscription references
  RealtimeChannel? _membersSubscription;
  RealtimeChannel? _requestsSubscription;
  RealtimeChannel? _chatMessagesSubscription;
  RealtimeChannel? _notificationsSubscription;
  RealtimeChannel? _activitiesSubscription;

  // Current data cache with size limit (SpaceX-grade memory management)
  final Map<String, List<Map<String, dynamic>>> _dataCache = {};
  static const int _maxCacheSize = 1000; // Limit cache entries

  // Connection status
  bool _isConnected = false;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // Getters for streams
  Stream<List<Map<String, dynamic>>> get membersStream =>
      _membersController.stream;
  Stream<List<Map<String, dynamic>>> get requestsStream =>
      _requestsController.stream;
  Stream<List<Map<String, dynamic>>> get chatMessagesStream =>
      _chatMessagesController.stream;
  Stream<List<Map<String, dynamic>>> get notificationsStream =>
      _notificationsController.stream;
  Stream<List<Map<String, dynamic>>> get activitiesStream =>
      _activitiesController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get connectionStatusStream =>
      _connectionController.stream; // Alias for compatibility

  bool get isConnected => _isConnected;

  // ====================================
  // CONNECTION MANAGEMENT
  // ====================================

  /// Initialize real-time connections (alias for compatibility)
  Future<void> initialize({
    required String clubId,
    required String userId,
  }) async {
    await initializeForClub(clubId);
  }

  /// Initialize real-time connections for a specific club
  Future<void> initializeForClub(String clubId) async {
    try {
      if (kDebugMode) {
      }

      // Disconnect existing connections
      await disconnect();

      // Subscribe to club memberships
      await _subscribeToMembers(clubId);

      // Subscribe to membership requests
      await _subscribeToRequests(clubId);

      // Subscribe to activities
      await _subscribeToActivities(clubId);

      _isConnected = true;
      _connectionController.add(true);

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Initialize real-time connections for a specific user
  Future<void> initializeForUser(String userId) async {
    try {
      if (kDebugMode) {
      }

      // Subscribe to user notifications
      await _subscribeToNotifications(userId);

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }

  /// Initialize chat room real-time connections
  Future<void> initializeForChatRoom(String roomId) async {
    try {
      if (kDebugMode) {
      }

      await _subscribeToChatMessages(roomId);

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }

  /// Disconnect all real-time subscriptions
  Future<void> disconnect() async {
    try {
      if (kDebugMode) {
      }

      // Unsubscribe from all channels
      await _membersSubscription?.unsubscribe();
      await _requestsSubscription?.unsubscribe();
      await _chatMessagesSubscription?.unsubscribe();
      await _notificationsSubscription?.unsubscribe();
      await _activitiesSubscription?.unsubscribe();

      // Clear subscriptions
      _membersSubscription = null;
      _requestsSubscription = null;
      _chatMessagesSubscription = null;
      _notificationsSubscription = null;
      _activitiesSubscription = null;

      _isConnected = false;
      _connectionController.add(false);

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // ====================================
  // SUBSCRIPTION METHODS
  // ====================================

  /// Subscribe to club members changes - TESLA FIX: Load data first
  Future<void> _subscribeToMembers(String clubId) async {
    try {
      // 🚀 SPACEX FIX: Load initial data FIRST to prevent race conditions
      await _loadInitialMembers(clubId);
      
      _membersSubscription = _supabase
          .channel('club_memberships_$clubId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'club_memberships',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'club_id',
              value: clubId,
            ),
            callback: (payload) => _handleMembersChange(payload, clubId),
          )
          .subscribe();

      if (kDebugMode) {
        // REMOVED: print('✅ Members subscription active for club: $clubId');
      }
    } catch (e) {
      if (kDebugMode) {
        // REMOVED: print('❌ Failed to subscribe to members: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to membership requests changes
  Future<void> _subscribeToRequests(String clubId) async {
    try {
      // 🚀 TESLA FIX: Load initial data FIRST
      await _loadInitialRequests(clubId);
      
      _requestsSubscription = _supabase
          .channel('membership_requests_$clubId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'membership_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'club_id',
              value: clubId,
            ),
            callback: (payload) => _handleRequestsChange(payload, clubId),
          )
          .subscribe();

      if (kDebugMode) {
        // REMOVED: print('✅ [MemberRealtimeService] Requests subscription active for club: $clubId');
      }
    } catch (e) {
      if (kDebugMode) {
        // REMOVED: print('❌ [MemberRealtimeService] Failed to subscribe to requests: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to chat messages changes
  Future<void> _subscribeToChatMessages(String roomId) async {
    try {
      _chatMessagesSubscription = _supabase
          .channel('chat_messages_$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (payload) => _handleChatMessagesChange(payload, roomId),
          )
          .subscribe();

      // Load initial data
      await _loadInitialChatMessages(roomId);

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }

  /// Subscribe to user notifications changes
  Future<void> _subscribeToNotifications(String userId) async {
    try {
      _notificationsSubscription = _supabase
          .channel('notifications_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _handleNotificationsChange(payload, userId),
          )
          .subscribe();

      // Load initial data
      await _loadInitialNotifications(userId);

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }

  /// Subscribe to member activities changes
  Future<void> _subscribeToActivities(String clubId) async {
    try {
      _activitiesSubscription = _supabase
          .channel('member_activities_$clubId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'member_activities',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'club_id',
              value: clubId,
            ),
            callback: (payload) => _handleActivitiesChange(payload, clubId),
          )
          .subscribe();

      // Load initial data
      await _loadInitialActivities(clubId);

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }

  // ====================================
  // CHANGE HANDLERS
  // ====================================

  void _handleMembersChange(PostgresChangePayload payload, String clubId) {
    if (kDebugMode) {
      // REMOVED: print('🔄 [MemberRealtimeService] Members change: ${payload.eventType}');
    }

    final cacheKey = 'members_$clubId';
    final currentData = List<Map<String, dynamic>>.from(
      _dataCache[cacheKey] ?? [],
    );

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.add(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere(
          (item) => item['id'] == payload.newRecord['id'],
        );
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
        break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere(
          (item) => item['id'] == payload.oldRecord['id'],
        );
        break;
      default:
        // Handle other event types or ignore
        break;
    }

    _dataCache[cacheKey] = currentData;
    
    // 🚀 TESLA OPTIMIZATION: Limit cache size
    _cleanupCacheIfNeeded();
    
    if (!_membersController.isClosed) {
      _membersController.add(currentData);
    }
  }

  void _handleRequestsChange(PostgresChangePayload payload, String clubId) {
    if (kDebugMode) {
    }

    final cacheKey = 'requests_$clubId';
    final currentData = List<Map<String, dynamic>>.from(
      _dataCache[cacheKey] ?? [],
    );

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.insert(
          0,
          payload.newRecord,
        ); // Add to beginning for latest first
        break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere(
          (item) => item['id'] == payload.newRecord['id'],
        );
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
        break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere(
          (item) => item['id'] == payload.oldRecord['id'],
        );
        break;
      default:
        // Handle other event types or ignore
        break;
    }

    _dataCache[cacheKey] = currentData;
    
    // 🚀 TESLA OPTIMIZATION: Limit cache size
    _cleanupCacheIfNeeded();
    
    if (!_membersController.isClosed) {
      _membersController.add(currentData);
    }
  }

  void _handleChatMessagesChange(PostgresChangePayload payload, String roomId) {
    if (kDebugMode) {
    }

    final cacheKey = 'messages_$roomId';
    final currentData = List<Map<String, dynamic>>.from(
      _dataCache[cacheKey] ?? [],
    );

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.insert(0, payload.newRecord); // New messages at top
        break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere(
          (item) => item['id'] == payload.newRecord['id'],
        );
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
        break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere(
          (item) => item['id'] == payload.oldRecord['id'],
        );
        break;
      default:
        // Handle other event types or ignore
        break;
    }

    _dataCache[cacheKey] = currentData;
    _chatMessagesController.add(currentData);
  }

  void _handleNotificationsChange(
    PostgresChangePayload payload,
    String userId,
  ) {
    if (kDebugMode) {
    }

    final cacheKey = 'notifications_$userId';
    final currentData = List<Map<String, dynamic>>.from(
      _dataCache[cacheKey] ?? [],
    );

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.insert(0, payload.newRecord); // New notifications at top
        // Show local notification for new items
        _showLocalNotification(payload.newRecord);
        break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere(
          (item) => item['id'] == payload.newRecord['id'],
        );
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
        break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere(
          (item) => item['id'] == payload.oldRecord['id'],
        );
        break;
      default:
        // Handle other event types or ignore
        break;
    }

    _dataCache[cacheKey] = currentData;
    _notificationsController.add(currentData);
  }

  void _handleActivitiesChange(PostgresChangePayload payload, String clubId) {
    if (kDebugMode) {
    }

    final cacheKey = 'activities_$clubId';
    final currentData = List<Map<String, dynamic>>.from(
      _dataCache[cacheKey] ?? [],
    );

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.insert(0, payload.newRecord); // New activities at top
        break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere(
          (item) => item['id'] == payload.newRecord['id'],
        );
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
        break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere(
          (item) => item['id'] == payload.oldRecord['id'],
        );
        break;
      default:
        // Handle other event types or ignore
        break;
    }

    _dataCache[cacheKey] = currentData;
    _activitiesController.add(currentData);
  }

  // ====================================
  // INITIAL DATA LOADING
  // ====================================

  Future<void> _loadInitialMembers(String clubId) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .order('joined_at', ascending: false);

      final cacheKey = 'members_$clubId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _membersController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  Future<void> _loadInitialRequests(String clubId) async {
    try {
      final response = await _supabase
          .from('membership_requests')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      final cacheKey = 'requests_$clubId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _requestsController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  Future<void> _loadInitialChatMessages(String roomId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*, users(*)')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(50); // Load last 50 messages

      final cacheKey = 'messages_$roomId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _chatMessagesController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  Future<void> _loadInitialNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      final cacheKey = 'notifications_$userId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _notificationsController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  Future<void> _loadInitialActivities(String clubId) async {
    try {
      final response = await _supabase
          .from('member_activities')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(100);

      final cacheKey = 'activities_$clubId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _activitiesController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // ====================================
  // UTILITY METHODS
  // ====================================

  /// Show local notification for new items
  void _showLocalNotification(Map<String, dynamic> notification) {
    // This would integrate with flutter_local_notifications
    // For now, just log it
    if (kDebugMode) {
    }
  }

  /// Get cached data for a specific key
  List<Map<String, dynamic>>? getCachedData(String key) {
    return _dataCache[key];
  }

  /// Clear all cached data
  void clearCache() {
    _dataCache.clear();
  }

  /// Get connection status
  bool getConnectionStatus() {
    return _isConnected;
  }

  /// 🚀 SPACEX METHOD: Clean cache when it grows too large  
  void _cleanupCacheIfNeeded() {
    if (_dataCache.length > _maxCacheSize) {
      // Remove oldest entries (simple LRU)
      final keys = _dataCache.keys.take(_dataCache.length - _maxCacheSize ~/ 2);
      for (final key in keys) {
        _dataCache.remove(key);
      }
      if (kDebugMode) {
        // REMOVED: print('🧹 Cache cleaned, entries: ${_dataCache.length}');
      }
    }
  }

  /// Force refresh data for a specific subscription
  Future<void> refreshData(String type, String id) async {
    switch (type) {
      case 'members':
        await _loadInitialMembers(id);
        break;
      case 'requests':
        await _loadInitialRequests(id);
        break;
      case 'messages':
        await _loadInitialChatMessages(id);
        break;
      case 'notifications':
        await _loadInitialNotifications(id);
        break;
      case 'activities':
        await _loadInitialActivities(id);
        break;
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    
    // Close controllers with null checks to prevent multiple disposal
    if (!_membersController.isClosed) _membersController.close();
    if (!_requestsController.isClosed) _requestsController.close();
    if (!_chatMessagesController.isClosed) _chatMessagesController.close();
    if (!_notificationsController.isClosed) _notificationsController.close();
    if (!_activitiesController.isClosed) _activitiesController.close();
    if (!_connectionController.isClosed) _connectionController.close();
    
    // Clear cache to prevent memory leaks
    _dataCache.clear();
  }
}

