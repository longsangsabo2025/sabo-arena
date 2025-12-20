import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Centralized service for managing direct messages
/// Single source of truth for room creation and duplicate prevention
class DirectMessagingService {
  static final DirectMessagingService instance = DirectMessagingService._();
  DirectMessagingService._();

  final _supabase = Supabase.instance.client;

  /// Get or create a direct message room between current user and another user
  ///
  /// This is the SINGLE SOURCE OF TRUTH - use this everywhere!
  ///
  /// Algorithm:
  /// 1. Find rooms where both users are members
  /// 2. Filter to type='direct' with exactly 2 members
  /// 3. Return existing room OR create new one
  ///
  /// Prevents duplicates by checking intersection of memberships
  Future<String> getOrCreateDirectRoom(String otherUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (currentUserId == otherUserId) {
      throw Exception('Cannot create conversation with yourself');
    }

    ProductionLogger.info(
        '[DirectMessaging] Finding room for: $currentUserId ↔ $otherUserId',
        tag: 'direct_messaging_service');

    // STEP 1: Get current user's rooms
    final myRooms = await _supabase
        .from('chat_room_members')
        .select('room_id')
        .eq('user_id', currentUserId);

    final myRoomIds = myRooms.map((r) => r['room_id'] as String).toList();
    ProductionLogger.info(
        '[DirectMessaging] Current user is in ${myRoomIds.length} rooms',
        tag: 'direct_messaging_service');

    if (myRoomIds.isNotEmpty) {
      // STEP 2: Get other user's rooms
      final otherUserRooms = await _supabase
          .from('chat_room_members')
          .select('room_id')
          .eq('user_id', otherUserId);

      final otherUserRoomIds =
          otherUserRooms.map((r) => r['room_id'] as String).toSet();

      ProductionLogger.info(
          '[DirectMessaging] Other user is in ${otherUserRoomIds.length} rooms',
          tag: 'direct_messaging_service');

      // STEP 3: Find common rooms
      final commonRoomIds =
          myRoomIds.where((id) => otherUserRoomIds.contains(id)).toList();

      ProductionLogger.info(
          '[DirectMessaging] Found ${commonRoomIds.length} common rooms',
          tag: 'direct_messaging_service');

      // STEP 4: Check each common room
      for (var roomId in commonRoomIds) {
        final roomData = await _supabase
            .from('chat_rooms')
            .select('type')
            .eq('id', roomId)
            .maybeSingle();

        if (roomData != null && roomData['type'] == 'direct') {
          // Verify exactly 2 members
          final members = await _supabase
              .from('chat_room_members')
              .select('user_id')
              .eq('room_id', roomId);

          if (members.length == 2) {
            ProductionLogger.info(
                '[DirectMessaging] ✅ Found existing room: $roomId',
                tag: 'direct_messaging_service');
            return roomId;
          }
        }
      }
    }

    // STEP 5: Create new room
    ProductionLogger.info('[DirectMessaging] Creating new room...',
        tag: 'direct_messaging_service');

    final room = await _supabase
        .from('chat_rooms')
        .insert({
          'type': 'direct',
          'name': null,
          'club_id': null,
          'created_by': currentUserId,
        })
        .select()
        .single();

    final roomId = room['id'] as String;
    ProductionLogger.info('[DirectMessaging] Created room: $roomId',
        tag: 'direct_messaging_service');

    // STEP 6: Add members
    await _supabase.from('chat_room_members').insert([
      {'room_id': roomId, 'user_id': currentUserId, 'role': 'member'},
      {'room_id': roomId, 'user_id': otherUserId, 'role': 'member'},
    ]);

    ProductionLogger.info('[DirectMessaging] Added members to room',
        tag: 'direct_messaging_service');

    // STEP 7: Wait for RLS commit
    await Future.delayed(const Duration(milliseconds: 500));

    ProductionLogger.info('[DirectMessaging] ✅ Room ready: $roomId',
        tag: 'direct_messaging_service');
    return roomId;
  }

  /// Get other user ID in a direct room
  Future<String?> getOtherUserId(String roomId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    final members = await _supabase
        .from('chat_room_members')
        .select('user_id')
        .eq('room_id', roomId);

    if (members.length != 2) return null;

    final otherMember = members.firstWhere(
      (m) => m['user_id'] != currentUserId,
      orElse: () => {},
    );

    return otherMember.isNotEmpty ? otherMember['user_id'] as String : null;
  }

  /// Mark conversation as read
  Future<void> markAsRead(String roomId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase
        .from('chat_room_members')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('room_id', roomId)
        .eq('user_id', currentUserId);
  }

  /// Get unread message count for a room
  Future<int> getUnreadCount(String roomId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return 0;

    final member = await _supabase
        .from('chat_room_members')
        .select('last_read_at')
        .eq('room_id', roomId)
        .eq('user_id', currentUserId)
        .maybeSingle();

    if (member == null) return 0;

    final lastReadAt = member['last_read_at'] as String?;
    if (lastReadAt == null) {
      final allMessages = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('room_id', roomId)
          .neq('sender_id', currentUserId);

      return allMessages.length;
    }

    final unreadMessages = await _supabase
        .from('chat_messages')
        .select('id')
        .eq('room_id', roomId)
        .gt('created_at', lastReadAt)
        .neq('sender_id', currentUserId);

    return unreadMessages.length;
  }
}
