import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to handle friends relationships
/// A "friend" is when two users follow each other (mutual follow)
class FriendsService {
  static FriendsService? _instance;
  static FriendsService get instance => _instance ??= FriendsService._();

  FriendsService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if two users are friends (mutual follows)
  Future<bool> isFriend(String userId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Check if current user follows the other user
      final iFollowThem = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId)
          .maybeSingle();

      if (iFollowThem == null) return false;

      // Check if the other user follows current user
      final theyFollowMe = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', userId)
          .eq('following_id', currentUser.id)
          .maybeSingle();

      return theyFollowMe != null;
    } catch (e) {
      ProductionLogger.info('Error checking if friend: $e', tag: 'friends_service');
      return false;
    }
  }

  /// Get list of friends (mutual follows)
  Future<List<UserProfile>> getFriendsList() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      // Get users that current user follows
      final following = await _supabase
          .from('user_follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final followingIds = following
          .map((f) => f['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // Get users that follow current user AND are in the following list (mutual)
      final friends = await _supabase
          .from('user_follows')
          .select('''
            follower_id,
            users!user_follows_follower_id_fkey(
              id,
              email,
              full_name,
              display_name,
              username,
              bio,
              avatar_url,
              cover_photo_url,
              phone,
              date_of_birth,
              role,
              skill_level,
              rank,
              total_wins,
              total_losses,
              total_tournaments,
              elo_rating,
              spa_points,
              total_prize_pool,
              is_verified,
              is_active,
              location,
              created_at,
              updated_at
            )
          ''')
          .eq('following_id', currentUser.id)
          .inFilter('follower_id', followingIds);

      return friends
          .where((f) => f['users'] != null)
          .map((f) => UserProfile.fromJson(f['users']))
          .toList();
    } catch (e) {
      ProductionLogger.info('Error getting friends list: $e', tag: 'friends_service');
      return [];
    }
  }

  /// Get list of mutual follows (same as getFriendsList, but different implementation)
  Future<List<UserProfile>> getMutualFollows() async {
    return getFriendsList(); // Same as friends
  }

  /// Get count of friends
  Future<int> getFriendsCount() async {
    try {
      final friends = await getFriendsList();
      return friends.length;
    } catch (e) {
      ProductionLogger.info('Error getting friends count: $e', tag: 'friends_service');
      return 0;
    }
  }

  /// Get count of friends for a specific user
  Future<int> getFriendsCountForUser(String userId) async {
    try {
      // Get users that the target user follows
      final following = await _supabase
          .from('user_follows')
          .select('following_id')
          .eq('follower_id', userId);

      final followingIds = following
          .map((f) => f['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return 0;

      // Get users that follow the target user AND are in the following list (mutual)
      final friends = await _supabase
          .from('user_follows')
          .select('id')
          .eq('following_id', userId)
          .inFilter('follower_id', followingIds);

      return friends.length;
    } catch (e) {
      ProductionLogger.info('Error getting friends count for user: $e', tag: 'friends_service');
      return 0;
    }
  }

  /// Get relationship status between current user and another user
  /// Returns: 'friend', 'following', 'follower', 'none'
  Future<String> getRelationshipStatus(String userId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 'none';

      // Check if current user follows the other user
      final iFollowThem = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId)
          .maybeSingle();

      // Check if the other user follows current user
      final theyFollowMe = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', userId)
          .eq('following_id', currentUser.id)
          .maybeSingle();

      if (iFollowThem != null && theyFollowMe != null) {
        return 'friend'; // Mutual follow
      } else if (iFollowThem != null) {
        return 'following'; // I follow them
      } else if (theyFollowMe != null) {
        return 'follower'; // They follow me
      } else {
        return 'none'; // No relationship
      }
    } catch (e) {
      ProductionLogger.info('Error getting relationship status: $e', tag: 'friends_service');
      return 'none';
    }
  }

  /// Get list of followers (users who follow current user)
  Future<List<UserProfile>> getFollowersList() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final followers = await _supabase
          .from('user_follows')
          .select('''
            follower_id,
            users!user_follows_follower_id_fkey(
              id,
              email,
              full_name,
              display_name,
              username,
              bio,
              avatar_url,
              cover_photo_url,
              phone,
              date_of_birth,
              role,
              skill_level,
              rank,
              total_wins,
              total_losses,
              total_tournaments,
              elo_rating,
              spa_points,
              total_prize_pool,
              is_verified,
              is_active,
              location,
              created_at,
              updated_at
            )
          ''')
          .eq('following_id', currentUser.id);

      return followers
          .where((f) => f['users'] != null)
          .map((f) => UserProfile.fromJson(f['users']))
          .toList();
    } catch (e) {
      ProductionLogger.info('Error getting followers list: $e', tag: 'friends_service');
      return [];
    }
  }

  /// Get list of users that current user is following
  Future<List<UserProfile>> getFollowingList() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final following = await _supabase
          .from('user_follows')
          .select('''
            following_id,
            users!user_follows_following_id_fkey(
              id,
              email,
              full_name,
              display_name,
              username,
              bio,
              avatar_url,
              cover_photo_url,
              phone,
              date_of_birth,
              role,
              skill_level,
              rank,
              total_wins,
              total_losses,
              total_tournaments,
              elo_rating,
              spa_points,
              total_prize_pool,
              is_verified,
              is_active,
              location,
              created_at,
              updated_at
            )
          ''')
          .eq('follower_id', currentUser.id);

      return following
          .where((f) => f['users'] != null)
          .map((f) => UserProfile.fromJson(f['users']))
          .toList();
    } catch (e) {
      ProductionLogger.info('Error getting following list: $e', tag: 'friends_service');
      return [];
    }
  }
}
