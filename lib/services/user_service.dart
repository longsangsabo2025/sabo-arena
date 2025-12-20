import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/user_stats.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'user_stats_update_service.dart';
import 'auth_service.dart';
import 'cache_manager.dart';
import 'storage_service.dart';
import 'database_replica_manager.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  UserService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // 🚀 MUSK: Cache for follow status to improve performance
  static final Map<String, bool> _followStatusCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Get read client (uses replica if available)
  SupabaseClient get _readClient => DatabaseReplicaManager.instance.readClient;

  // Get write client (always uses primary)
  SupabaseClient get _writeClient =>
      DatabaseReplicaManager.instance.writeClient;

  /// Notifier for current user profile changes
  final ValueNotifier<UserProfile?> currentUserNotifier = ValueNotifier(null);

  /// 🚀 MUSK: Get cached follow status if available and not expired
  bool? getCachedFollowStatus(String userId) {
    if (!_followStatusCache.containsKey(userId)) return null;

    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null ||
        DateTime.now().difference(timestamp) > _cacheExpiry) {
      _followStatusCache.remove(userId);
      _cacheTimestamps.remove(userId);
      return null;
    }

    return _followStatusCache[userId];
  }

  /// Cache follow status with timestamp
  void _cacheFollowStatus(String userId, bool isFollowing) {
    _followStatusCache[userId] = isFollowing;
    _cacheTimestamps[userId] = DateTime.now();
  }

  /// Clear follow status cache (useful for logout)
  void clearFollowStatusCache() {
    _followStatusCache.clear();
    _cacheTimestamps.clear();
  }

  Future<UserProfile?> getCurrentUserProfile(
      {bool forceRefresh = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        currentUserNotifier.value = null;
        return null;
      }

      // Check cache first
      if (!forceRefresh) {
        final cached = await CacheManager.instance.getUserProfile(user.id);
        if (cached != null) {
          final profile = UserProfile.fromJson(cached);
          // Only update if different to avoid unnecessary rebuilds
          if (currentUserNotifier.value?.id != profile.id ||
              currentUserNotifier.value?.updatedAt != profile.updatedAt) {
            currentUserNotifier.value = profile;
          }
          return profile;
        }
      }

      // Use read replica for read operations
      final response = await _readClient
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      final profile = UserProfile.fromJson(response);

      // Cache the profile
      await CacheManager.instance.setUserProfile(user.id, response);

      currentUserNotifier.value = profile;

      return profile;
    } catch (error) {
      ProductionLogger.error(
        'Error getting current user profile',
        error: error,
        tag: 'UserService',
      );
      return null; // Return null instead of throwing to avoid app crash
    }
  }

  Future<UserProfile> getUserProfileById(String userId,
      {bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh) {
        final cached = await CacheManager.instance.getUserProfile(userId);
        if (cached != null) {
          return UserProfile.fromJson(cached);
        }
      }

      // Use read replica for read operations
      final response = await _readClient
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        // User profile not found - try to auto-create for legacy users
        ProductionLogger.debug(
          'User profile not found for ID: $userId, attempting auto-creation',
          tag: 'UserService',
        );

        try {
          // Get user from auth to extract metadata
          final authUser = _supabase.auth.currentUser;

          if (authUser != null && authUser.id == userId) {
            // Create profile for current authenticated user
            await AuthService.instance.upsertUserRecord(
              fullName: authUser.userMetadata?['full_name'] ??
                  authUser.email?.split('@')[0] ??
                  'User',
              email: authUser.email,
              phone: authUser.phone,
              role: 'player',
            );

            // Retry fetching the profile (use read replica)
            final retryResponse = await _readClient
                .from('users')
                .select()
                .eq('id', userId)
                .maybeSingle();

            if (retryResponse != null) {
              ProductionLogger.info(
                'Auto-created profile for user: $userId',
                tag: 'UserService',
              );
              return UserProfile.fromJson(retryResponse);
            }
          }
        } catch (e) {
          ProductionLogger.error(
            'Failed to auto-create profile',
            error: e,
            tag: 'UserService',
          );
        }

        throw Exception('User profile not found for ID: $userId');
      }

      return UserProfile.fromJson(response);
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getUserProfile',
          context: 'Failed to fetch user profile',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<List<UserProfile>> getTopRankedPlayers({int limit = 10}) async {
    try {
      // Use read replica for read operations
      final response = await _readClient
          .from('users')
          .select()
          .eq('is_active', true)
          .order('elo_rating', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getTopRankedPlayers',
          context: 'Failed to fetch top ranked players',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    try {
      // Use read replica for read operations
      final response = await _readClient
          .from('users')
          .select()
          .or('full_name.ilike.%$query%,username.ilike.%$query%,display_name.ilike.%$query%')
          .eq('is_active', true)
          .order('elo_rating', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'searchUsers',
          context: 'Failed to search users',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  /// 🚀 MUSK SEARCH OPTIMIZATION - Exact username match
  Future<List<UserProfile>> searchUsersByUsername(String query,
      {int limit = 5}) async {
    try {
      final response = await _readClient
          .from('users')
          .select()
          .ilike('username', '%$query%')
          .eq('is_active', true)
          .order('username')
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      ProductionLogger.error('🔍 Username search failed: $error',
          tag: 'user_search');
      return [];
    }
  }

  /// 🚀 MUSK SEARCH OPTIMIZATION - Name-based search
  Future<List<UserProfile>> searchUsersByName(String query,
      {int limit = 10}) async {
    try {
      final response = await _readClient
          .from('users')
          .select()
          .or('full_name.ilike.%$query%,display_name.ilike.%$query%')
          .eq('is_active', true)
          .order('elo_rating', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      ProductionLogger.error('🔍 Name search failed: $error',
          tag: 'user_search');
      return [];
    }
  }

  /// 🚀 MUSK SEARCH OPTIMIZATION - Similar rank suggestions
  Future<List<UserProfile>> searchUsersBySimilarRank(
      String userRank, String query,
      {int limit = 5}) async {
    try {
      final response = await _readClient
          .from('users')
          .select()
          .eq('rank', userRank)
          .or('full_name.ilike.%$query%,username.ilike.%$query%,display_name.ilike.%$query%')
          .eq('is_active', true)
          .order('elo_rating', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      ProductionLogger.error('🔍 Rank search failed: $error',
          tag: 'user_search');
      return [];
    }
  }

  Future<List<UserProfile>> getNearbyPlayers({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    try {
      // This is a simplified location search
      // In production, you'd want to use PostGIS functions for accurate distance calculation
      // Use read replica for read operations
      final response = await _readClient
          .from('users')
          .select()
          .not('location', 'is', null)
          .eq('is_active', true)
          .order('elo_rating', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getNearbyPlayers',
          context: 'Failed to fetch nearby players',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<UserProfile> updateUserProfile({
    String? username,
    String? fullName,
    String? displayName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? skillLevel,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (fullName != null) updateData['full_name'] = fullName;
      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (phone != null) updateData['phone'] = phone;
      if (dateOfBirth != null) {
        updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      }
      if (skillLevel != null) updateData['skill_level'] = skillLevel;
      if (location != null) updateData['location'] = location;
      if (avatarUrl != null) {
        if (avatarUrl == 'REMOVE_AVATAR') {
          updateData['avatar_url'] = null;
        } else {
          updateData['avatar_url'] = avatarUrl;
        }
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Use write client for write operations
      final response = await _writeClient
          .from('users')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      // 🚀 MUSK: Update cache with new data to avoid replica lag
      await CacheManager.instance.setUserProfile(user.id, response);

      // Update local notifier
      if (currentUserNotifier.value?.id == user.id) {
        currentUserNotifier.value = UserProfile.fromJson(response);
      }

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update user profile: $error');
    }
  }

  /// 🚀 MUSK: Atomic update for profile with avatar upload
  Future<UserProfile> updateProfileWithAvatarUpload({
    String? username,
    String? fullName,
    String? displayName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? skillLevel,
    String? location,
    List<int>? avatarBytes,
    String? avatarFileName,
    bool removeAvatar = false,
  }) async {
    String? avatarUrl;
    final oldUrl = currentUserNotifier.value?.avatarUrl;

    if (removeAvatar) {
      avatarUrl = 'REMOVE_AVATAR';
      if (oldUrl != null) {
        // Fire and forget deletion of old avatar
        StorageService.deleteOldAvatar(oldUrl);
      }
    } else if (avatarBytes != null && avatarFileName != null) {
      // 🚀 MUSK: Use atomic StorageService
      avatarUrl = await StorageService.uploadAvatar(
        Uint8List.fromList(avatarBytes),
        fileName: avatarFileName,
        oldUrl: oldUrl,
        skipDatabaseUpdate: true, // Let updateUserProfile handle the DB update
      );
      if (avatarUrl == null) throw Exception('Failed to upload avatar image');
    }

    return updateUserProfile(
      username: username,
      fullName: fullName,
      displayName: displayName,
      bio: bio,
      phone: phone,
      dateOfBirth: dateOfBirth,
      skillLevel: skillLevel,
      location: location,
      avatarUrl: avatarUrl,
    );
  }

  // Generic image upload method for evidence/documents
  Future<Map<String, dynamic>> uploadImage(
    File imageFile,
    String fileName,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final imageBytes = await imageFile.readAsBytes();
      final filePath =
          'evidence/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Determine content type based on extension
      String contentType = 'image/jpeg'; // Default
      final ext = fileName.split('.').last.toLowerCase();
      if (ext == 'png')
        contentType = 'image/png';
      else if (ext == 'webp')
        contentType = 'image/webp';
      else if (ext == 'jpg' || ext == 'jpeg') contentType = 'image/jpeg';

      await _supabase.storage.from('user-images').uploadBinary(
            filePath,
            Uint8List.fromList(imageBytes),
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final publicUrl =
          _supabase.storage.from('user-images').getPublicUrl(filePath);

      return {'success': true, 'url': publicUrl, 'path': filePath};
    } catch (error) {
      return {'success': false, 'error': error.toString()};
    }
  }

  Future<String?> uploadAvatar(dynamic imageFile,
      {String? oldUrl, String? fileName}) async {
    try {
      debugPrint('🚀 MUSK_DEBUG: UserService.uploadAvatar entry');
      final publicUrl = await StorageService.uploadAvatar(imageFile,
          oldUrl: oldUrl, fileName: fileName);

      if (publicUrl != null) {
        debugPrint(
            '🚀 MUSK_DEBUG: UserService.uploadAvatar SUCCESS: $publicUrl');
        final user = _supabase.auth.currentUser;
        if (user != null && currentUserNotifier.value?.id == user.id) {
          debugPrint(
              '🚀 MUSK_DEBUG: Updating currentUserNotifier with new avatar');
          currentUserNotifier.value =
              currentUserNotifier.value?.copyWith(avatarUrl: publicUrl);
        }
      } else {
        debugPrint('🚀 MUSK_DEBUG: UserService.uploadAvatar returned NULL');
      }

      return publicUrl;
    } catch (error) {
      debugPrint('🚀 MUSK_DEBUG: UserService.uploadAvatar EXCEPTION: $error');
      throw Exception('Failed to upload avatar: $error');
    }
  }

  Future<String?> uploadCoverPhoto(dynamic imageFile,
      {String? oldUrl, String? fileName}) async {
    try {
      debugPrint('🚀 MUSK_DEBUG: UserService.uploadCoverPhoto entry');
      final publicUrl = await StorageService.uploadCoverPhoto(imageFile,
          oldUrl: oldUrl, fileName: fileName);

      if (publicUrl != null) {
        debugPrint(
            '🚀 MUSK_DEBUG: UserService.uploadCoverPhoto SUCCESS: $publicUrl');
        final user = _supabase.auth.currentUser;
        if (user != null && currentUserNotifier.value?.id == user.id) {
          debugPrint(
              '🚀 MUSK_DEBUG: Updating currentUserNotifier with new cover photo');
          currentUserNotifier.value =
              currentUserNotifier.value?.copyWith(coverPhotoUrl: publicUrl);
        }
      } else {
        debugPrint('🚀 MUSK_DEBUG: UserService.uploadCoverPhoto returned NULL');
      }

      return publicUrl;
    } catch (error) {
      debugPrint(
          '🚀 MUSK_DEBUG: UserService.uploadCoverPhoto EXCEPTION: $error');
      throw Exception('Failed to upload cover photo: $error');
    }
  }

  Future<void> removeAvatar() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 🚀 MUSK: Atomic removal
      await _writeClient
          .from('users')
          .update({'avatar_url': null}).eq('id', user.id);

      await CacheManager.instance.invalidateUser(user.id);
      if (currentUserNotifier.value?.id == user.id) {
        currentUserNotifier.value =
            currentUserNotifier.value?.copyWith(avatarUrl: null);
      }
    } catch (error) {
      throw Exception('Failed to remove avatar: $error');
    }
  }

  Future<void> removeCoverPhoto() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 🚀 MUSK: Atomic removal
      await _writeClient
          .from('users')
          .update({'cover_photo_url': null}).eq('id', user.id);

      await CacheManager.instance.invalidateUser(user.id);
      if (currentUserNotifier.value?.id == user.id) {
        currentUserNotifier.value =
            currentUserNotifier.value?.copyWith(coverPhotoUrl: null);
      }
    } catch (error) {
      throw Exception('Failed to remove cover photo: $error');
    }
  }

  Future<UserStats> getUserStats(String userId) async {
    try {
      final userProfile = await getUserProfileById(userId);

      // Get additional stats from matches
      final matchesAsPlayer1 = await _supabase
          .from('matches')
          .select()
          .eq('player1_id', userId)
          .eq('status', 'completed');

      final matchesAsPlayer2 = await _supabase
          .from('matches')
          .select()
          .eq('player2_id', userId)
          .eq('status', 'completed');

      final totalMatches = matchesAsPlayer1.length + matchesAsPlayer2.length;

      // Tính win streak
      final winStreak =
          await UserStatsUpdateService.instance.calculateWinStreak(userId);

      // Get ranking
      final ranking = await getUserRanking(userId);

      return UserStats(
        totalWins: userProfile.totalWins,
        totalLosses: userProfile.totalLosses,
        totalTournaments: userProfile.totalTournaments,
        totalMatches: totalMatches,
        eloRating: userProfile.rankingPoints,
        winStreak: winStreak,
        ranking: ranking,
      );
    } catch (error) {
      throw Exception('Failed to get user stats: $error');
    }
  }

  Future<int> getUserRanking(String userId) async {
    try {
      // 🚀 MUSK_DEBUG: Attempting RPC call
      final response = await _supabase.rpc(
        'get_user_ranking',
        params: {'user_uuid': userId},
      );

      return response ?? 0;
    } catch (error) {
      // 🚀 MUSK_DEBUG: RPC failed (likely missing), falling back to manual calculation
      debugPrint(
          '🚀 MUSK_DEBUG: get_user_ranking RPC not found or failed. Using fallback. Error: $error');

      // Fallback: calculate ranking manually (Optimized)
      try {
        // Get user's current ELO
        final userRes = await _supabase
            .from('users')
            .select('elo_rating')
            .eq('id', userId)
            .maybeSingle();

        if (userRes == null) return 0;
        final userElo = userRes['elo_rating'] as int? ?? 0;

        // Count users with higher ELO
        final countRes = await _supabase
            .from('users')
            .count(CountOption.exact)
            .eq('is_active', true)
            .gt('elo_rating', userElo);

        return countRes + 1;
      } catch (fallbackError) {
        ProductionLogger.error('Failed to get user ranking (fallback)',
            error: fallbackError, tag: 'UserService');
        return 0;
      }
    }
  }

  Future<List<UserProfile>> getUserFollowers(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.from('user_follows').select('''
            follower:users!user_follows_follower_id_fkey (*)
          ''').eq('following_id', userId).limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json['follower']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get user followers: $error');
    }
  }

  Future<List<UserProfile>> getUserFollowing(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.from('user_follows').select('''
            following:users!user_follows_following_id_fkey (*)
          ''').eq('follower_id', userId).limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json['following']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get user following: $error');
    }
  }

  Future<Map<String, int>> getUserFollowCounts(String userId) async {
    try {
      final followersCount = await _supabase
          .from('user_follows')
          .select('*')
          .eq('following_id', userId)
          .count(CountOption.exact);

      final followingCount = await _supabase
          .from('user_follows')
          .select('*')
          .eq('follower_id', userId)
          .count(CountOption.exact);

      return {
        'followers': followersCount.count,
        'following': followingCount.count,
      };
    } catch (error) {
      throw Exception('Failed to get user follow counts: $error');
    }
  }

  Future<bool> followUser(String targetUserId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (user.id == targetUserId) {
        throw Exception('Cannot follow yourself');
      }

      // Use write client for write operations
      await _writeClient.from('user_follows').insert({
        'follower_id': user.id,
        'following_id': targetUserId,
      });

      // 🚀 MUSK: Update cache after successful follow
      _cacheFollowStatus(targetUserId, true);

      return true;
    } catch (error) {
      throw Exception('Failed to follow user: $error');
    }
  }

  Future<bool> unfollowUser(String targetUserId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Use write client for write operations
      await _writeClient
          .from('user_follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);

      // 🚀 MUSK: Update cache after successful unfollow
      _cacheFollowStatus(targetUserId, false);

      return true;
    } catch (error) {
      throw Exception('Failed to unfollow user: $error');
    }
  }

  Future<bool> isFollowingUser(String targetUserId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // 🚀 MUSK: Check cache first to avoid redundant API calls
      final cachedStatus = getCachedFollowStatus(targetUserId);
      if (cachedStatus != null) {
        return cachedStatus;
      }

      // Use read replica for read operations
      final response = await _readClient
          .from('user_follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId)
          .maybeSingle();

      final isFollowing = response != null;

      // Cache the result for future use
      _cacheFollowStatus(targetUserId, isFollowing);

      return isFollowing;
    } catch (error) {
      throw Exception('Failed to check follow status: $error');
    }
  }

  Future<List<UserProfile>> findOpponentsNearby({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    try {
      // First try using the get_nearby_players function if it exists
      try {
        final response = await _supabase.rpc(
          'get_nearby_players',
          params: {
            'center_lat': latitude,
            'center_lng': longitude,
            'radius_km': radiusInKm.round(),
          },
        );

        if (response is List && response.isNotEmpty) {
          // The response from get_nearby_players function doesn't return full user profile
          // We need to get full user profiles by user_ids
          List<String> userIds =
              response.map((item) => item['user_id'].toString()).toList();

          final usersResponse = await _supabase
              .from('users')
              .select()
              .filter('id', 'in', userIds)
              .order('created_at', ascending: false);

          return usersResponse
              .map<UserProfile>((json) => UserProfile.fromJson(json))
              .toList();
        }
      } catch (rpcError) {
        ProductionLogger.debug(
          'RPC function get_nearby_players not available, using fallback: $rpcError',
        );
      }

      // Fallback: Get active users (simplified approach without location filtering)
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      // Use read replica for read operations
      final response = await _readClient
          .from('users')
          .select()
          .neq('id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(20);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      // It's good practice to log the error for debugging
      ProductionLogger.error(
        'Error finding nearby opponents',
        error: error,
        tag: 'UserService',
      );
      throw Exception('Failed to find nearby opponents: $error');
    }
  }

  /// Request rank registration at a specific club
  /// This creates a pending request that club owners can approve or reject
  Future<Map<String, dynamic>> requestRankRegistration({
    required String clubId,
    String? notes,
    List<String>? evidenceUrls,
    String? requestedRank,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Allow unlimited rank requests - remove all blocking logic
      // Users can create as many requests as they want
      ProductionLogger.debug(
        'Creating new rank request - no restrictions',
        tag: 'UserService',
      );

      Map<String, dynamic> requestData = {
        'user_id': user.id,
        'club_id': clubId,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      };

      if (notes != null && notes.isNotEmpty) {
        requestData['notes'] = notes;
      }

      if (evidenceUrls != null && evidenceUrls.isNotEmpty) {
        requestData['evidence_urls'] = evidenceUrls;
      }

      if (requestedRank != null && requestedRank.isNotEmpty) {
        requestData['requested_rank'] = requestedRank;
      }

      ProductionLogger.debug(
        'Sending rank request - User: ${user.id}, Club: $clubId, Has notes: ${notes != null}, Evidence URLs: ${evidenceUrls?.length ?? 0}',
        tag: 'UserService',
      );

      // Try INSERT directly, handle constraint error by updating existing record
      try {
        final response = await _supabase
            .from('rank_requests')
            .insert(requestData)
            .select()
            .single();

        ProductionLogger.info(
          'Rank request created successfully - ID: ${response['id']}, Status: ${response['status']}',
          tag: 'UserService',
        );

        return {
          'success': true,
          'message': 'Yêu cầu đăng ký rank đã được gửi thành công',
          'request_id': response['id'],
          'status': response['status'],
          'evidence_count': evidenceUrls?.length ?? 0,
        };
      } catch (insertError) {
        ProductionLogger.warning(
          'INSERT failed, trying UPDATE',
          error: insertError,
          tag: 'UserService',
        );

        // If constraint violation, update existing record instead
        if (insertError.toString().contains('duplicate key') ||
            insertError.toString().contains('unique constraint')) {
          ProductionLogger.debug(
            'Updating existing request',
            tag: 'UserService',
          );

          // Update the existing record with new timestamp and data
          requestData['requested_at'] = DateTime.now().toIso8601String();

          final updateResponse = await _supabase
              .from('rank_requests')
              .update(requestData)
              .eq('user_id', user.id)
              .eq('club_id', clubId)
              .select()
              .single();

          ProductionLogger.info(
            'Rank request updated successfully - ID: ${updateResponse['id']}, Status: ${updateResponse['status']}',
            tag: 'UserService',
          );

          return {
            'success': true,
            'message': 'Yêu cầu đăng ký rank đã được cập nhật thành công',
            'request_id': updateResponse['id'],
            'status': updateResponse['status'],
            'evidence_count': evidenceUrls?.length ?? 0,
          };
        } else {
          // Re-throw if it's not a constraint error
          rethrow;
        }
      }
    } catch (error) {
      ProductionLogger.error(
        'Error requesting rank registration',
        error: error,
        stackTrace: StackTrace.current,
        tag: 'UserService',
      );
      throw Exception('Không thể gửi yêu cầu đăng ký rank: $error');
    }
  }

  /// Check if user has pending rank request for a specific club
  Future<Map<String, dynamic>?> getPendingRankRequest(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('rank_requests')
          .select('''
            *,
            club:clubs (
              id,
              name,
              address,
              logo_url
            )
          ''')
          .eq('user_id', user.id)
          .eq('club_id', clubId)
          .eq('status', 'pending')
          .maybeSingle();

      return response;
    } catch (error) {
      ProductionLogger.error(
        'Error checking pending rank request',
        error: error,
        tag: 'UserService',
      );
      return null;
    }
  }

  /// Get all rank requests for the current user
  Future<List<Map<String, dynamic>>> getUserRankRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.from('rank_requests').select('''
            *,
            club:clubs (
              id,
              name,
              address,
              logo_url
            )
          ''').eq('user_id', user.id).order('requested_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      ProductionLogger.error(
        'Error getting user rank requests',
        error: error,
        tag: 'UserService',
      );
      throw Exception('Không thể tải danh sách yêu cầu đăng ký rank: $error');
    }
  }

  /// Cancel a pending rank request
  Future<bool> cancelRankRequest(String requestId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('rank_requests')
          .delete()
          .eq('id', requestId)
          .eq('user_id', user.id)
          .eq('status', 'pending');

      return true;
    } catch (error) {
      ProductionLogger.error(
        'Error canceling rank request',
        error: error,
        tag: 'UserService',
      );
      throw Exception('Không thể hủy yêu cầu đăng ký rank: $error');
    }
  }

  /// Update user's SPA points
  Future<bool> updateSpaPoints(String userId, int points) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Only allow users to update their own points or admin role
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.role != 'admin' && user.id != userId) {
        throw Exception('Không có quyền cập nhật điểm SPA');
      }

      await _supabase
          .from('users')
          .update({'spa_points': points}).eq('id', userId);

      return true;
    } catch (error) {
      ProductionLogger.error(
        'Error updating SPA points',
        error: error,
        tag: 'UserService',
      );
      throw Exception('Không thể cập nhật điểm SPA: $error');
    }
  }

  /// Add SPA points to user (increment)
  Future<bool> addSpaPoints(String userId, int pointsToAdd) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current points
      final response = await _supabase
          .from('users')
          .select('spa_points')
          .eq('id', userId)
          .single();

      final currentPoints = response['spa_points'] as int? ?? 0;
      final newPoints = currentPoints + pointsToAdd;

      await _supabase
          .from('users')
          .update({'spa_points': newPoints}).eq('id', userId);

      return true;
    } catch (error) {
      ProductionLogger.error(
        'Error adding SPA points',
        error: error,
        tag: 'UserService',
      );
      throw Exception('Không thể thêm điểm SPA: $error');
    }
  }

  /// Update user's total prize pool
  Future<bool> updatePrizePool(String userId, double prizeAmount) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Only allow users to update their own prize pool or admin role
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.role != 'admin' && user.id != userId) {
        throw Exception('Không có quyền cập nhật prize pool');
      }

      await _supabase
          .from('users')
          .update({'total_prize_pool': prizeAmount}).eq('id', userId);

      return true;
    } catch (error) {
      ProductionLogger.error(
        'Error updating prize pool',
        error: error,
        tag: 'UserService',
      );
      throw Exception('Không thể cập nhật prize pool: $error');
    }
  }

  /// Add prize money to user's total prize pool (increment)
  Future<bool> addPrizePool(String userId, double prizeToAdd) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current prize pool
      final response = await _supabase
          .from('users')
          .select('total_prize_pool')
          .eq('id', userId)
          .single();

      final currentPrize = (response['total_prize_pool'] as double?) ?? 0.0;
      final newPrize = currentPrize + prizeToAdd;

      await _supabase
          .from('users')
          .update({'total_prize_pool': newPrize}).eq('id', userId);

      return true;
    } catch (error) {
      ProductionLogger.error(
        'Error adding to prize pool',
        error: error,
        tag: 'UserService',
      );
      throw Exception('Không thể thêm vào prize pool: $error');
    }
  }

  /// Get leaderboard by SPA points
  Future<List<UserProfile>> getTopSpaPointsPlayers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('is_active', true)
          .order('spa_points', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get top SPA points players: $error');
    }
  }

  /// Get leaderboard by prize pool
  Future<List<UserProfile>> getTopPrizePoolPlayers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('is_active', true)
          .order('total_prize_pool', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get top prize pool players: $error');
    }
  }
}
