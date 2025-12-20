import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/production_logger.dart';

/// Represents a blocked user relationship
class BlockedUser {
  final String blockId;
  final String blockedUserId;
  final String blockedUserName;
  final String? blockedUserAvatar;
  final String? blockReason;
  final DateTime blockedAt;

  const BlockedUser({
    required this.blockId,
    required this.blockedUserId,
    required this.blockedUserName,
    this.blockedUserAvatar,
    this.blockReason,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      blockId: json['id'],
      blockedUserId: json['blocked_user_id'],
      blockedUserName: json['users']?['full_name'] ?? 'Unknown User',
      blockedUserAvatar: json['users']?['avatar_url'],
      blockReason: json['reason'],
      blockedAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Service for managing user blocks
class UserBlocksService {
  static final UserBlocksService instance = UserBlocksService._internal();
  factory UserBlocksService() => instance;
  UserBlocksService._internal();

  final _supabase = Supabase.instance.client;

  /// Block a user
  Future<void> blockUser(String userId, {String? reason}) async {
    try {
      ProductionLogger.info('Blocking user: $userId', tag: 'UserBlocks');

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (currentUserId == userId) {
        throw Exception('Cannot block yourself');
      }

      // Check if already blocked
      final existing = await _supabase
          .from('user_blocks')
          .select('id')
          .eq('blocker_user_id', currentUserId)
          .eq('blocked_user_id', userId)
          .maybeSingle();

      if (existing != null) {
        ProductionLogger.warning('User already blocked: $userId',
            tag: 'UserBlocks');
        return;
      }

      await _supabase.from('user_blocks').insert({
        'blocker_user_id': currentUserId,
        'blocked_user_id': userId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      ProductionLogger.info('User blocked successfully: $userId',
          tag: 'UserBlocks');
    } catch (error) {
      ProductionLogger.error(
        'Failed to block user',
        error: error,
        tag: 'UserBlocks',
      );
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    try {
      ProductionLogger.info('Unblocking user: $userId', tag: 'UserBlocks');

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('user_blocks')
          .delete()
          .eq('blocker_user_id', currentUserId)
          .eq('blocked_user_id', userId);

      ProductionLogger.info('User unblocked successfully: $userId',
          tag: 'UserBlocks');
    } catch (error) {
      ProductionLogger.error(
        'Failed to unblock user',
        error: error,
        tag: 'UserBlocks',
      );
      rethrow;
    }
  }

  /// Get list of blocked users
  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      ProductionLogger.info('Fetching blocked users', tag: 'UserBlocks');

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_blocks')
          .select('''
            id,
            blocked_user_id,
            reason,
            created_at,
            users!blocked_user_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('blocker_user_id', currentUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BlockedUser.fromJson(json))
          .toList();
    } catch (error) {
      ProductionLogger.error(
        'Failed to fetch blocked users',
        error: error,
        tag: 'UserBlocks',
      );
      rethrow;
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        return false;
      }

      final response = await _supabase
          .from('user_blocks')
          .select('id')
          .eq('blocker_user_id', currentUserId)
          .eq('blocked_user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      ProductionLogger.error(
        'Failed to check if user is blocked',
        error: error,
        tag: 'UserBlocks',
      );
      return false;
    }
  }

  /// Check if current user is blocked BY another user
  Future<bool> isBlockedBy(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        return false;
      }

      final response = await _supabase
          .from('user_blocks')
          .select('id')
          .eq('blocker_user_id', userId)
          .eq('blocked_user_id', currentUserId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      ProductionLogger.error(
        'Failed to check if blocked by user',
        error: error,
        tag: 'UserBlocks',
      );
      return false;
    }
  }

  /// Get count of blocked users
  Future<int> getBlockedUsersCount() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        return 0;
      }

      final response = await _supabase
          .from('user_blocks')
          .select('id')
          .eq('blocker_user_id', currentUserId)
          .count(CountOption.exact);

      return response.count;
    } catch (error) {
      ProductionLogger.error(
        'Failed to get blocked users count',
        error: error,
        tag: 'UserBlocks',
      );
      return 0;
    }
  }
}
