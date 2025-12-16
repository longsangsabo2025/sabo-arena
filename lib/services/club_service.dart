import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club.dart';
import '../models/user_profile.dart';
import 'package:flutter/foundation.dart';
import 'auto_notification_hooks.dart';
import 'cache_manager.dart';
import 'database_replica_manager.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

class ClubService {
  static ClubService? _instance;
  static ClubService get instance => _instance ??= ClubService._();
  ClubService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get read client (uses replica if available)
  SupabaseClient get _readClient => DatabaseReplicaManager.instance.readClient;
  
  // Get write client (always uses primary)
  SupabaseClient get _writeClient => DatabaseReplicaManager.instance.writeClient;

  Future<List<Club>> getClubs({
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 50,
  }) async {
    try {
      // Use read replica for read operations
      var query = _readClient.from('clubs').select();

      // Add location-based filtering if coordinates provided
      if (latitude != null && longitude != null && radiusKm != null) {
        // Note: This is a simplified distance check
        // In production, you'd want to use PostGIS functions for accurate distance calculation
        query = query
            .gte('latitude', latitude - (radiusKm / 111.0))
            .lte('latitude', latitude + (radiusKm / 111.0))
            .gte('longitude', longitude - (radiusKm / 111.0))
            .lte('longitude', longitude + (radiusKm / 111.0));
      }

      final response = await query
          .eq('is_active', true)
          .eq('approval_status', 'approved')
          .order('rating', ascending: false)
          .limit(limit);

      return response.map<Club>((json) => Club.fromJson(json)).toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getClubs',
          context: 'Failed to fetch clubs list',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<Club> getClubById(String clubId) async {
    try {
      // Check cache first
      final cached = await CacheManager.instance.getClub(clubId);
      if (cached != null) {
        return Club.fromJson(cached);
      }

      // Use read replica for read operations
      final response = await _readClient
          .from('clubs')
          .select()
          .eq('id', clubId)
          .single();

      final club = Club.fromJson(response);
      
      // Cache the club data
      await CacheManager.instance.setClub(clubId, response);
      
      return club;
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getClubById',
          context: 'Failed to fetch club by ID',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  /// Tìm club mà user sở hữu (owner_id = user_id)
  Future<Club?> getClubByOwnerId(String userId) async {
    try {
      // Use read replica for read operations
      final response = await _readClient
          .from('clubs')
          .select()
          .eq('owner_id', userId)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return Club.fromJson(response.first);
    } catch (error) {
      ProductionLogger.error(
        'Error getting club by owner ID',
        error: error,
        tag: 'ClubService',
      );
      return null;
    }
  }

  /// Tìm club đầu tiên mà user là member hoặc owner
  Future<Club?> getFirstClubForUser(String userId) async {
    try {
      // Thử tìm club mà user sở hữu trước
      Club? ownedClub = await getClubByOwnerId(userId);
      if (ownedClub != null) {
        return ownedClub;
      }

      // Nếu không sở hữu club nào, tìm club mà user là member (use read replica)
      final memberResponse = await _readClient
          .from('club_members')
          .select('club_id, clubs(*)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .limit(1);

      if (memberResponse.isNotEmpty && memberResponse.first['clubs'] != null) {
        return Club.fromJson(memberResponse.first['clubs']);
      }

      return null;
    } catch (error) {
      ProductionLogger.error(
        'Error getting first club for user',
        error: error,
        tag: 'ClubService',
      );
      return null;
    }
  }

  Future<List<Club>> getAllClubs({int limit = 100}) async {
    try {
      // Use read replica for read operations
      final response = await _readClient
          .from('clubs')
          .select()
          .eq('is_active', true)
          .eq('approval_status', 'approved')
          .order('name', ascending: true)
          .limit(limit);

      return response.map<Club>((json) => Club.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get all clubs: $error');
    }
  }

  Future<List<UserProfile>> getClubMembers(String clubId) async {
    try {
      ProductionLogger.debug(
        'Fetching members for club $clubId',
        tag: 'ClubService',
      );

      // First try simple query without join to test basic access (use read replica)
      try {
        await _readClient
            .from('club_members')
            .select('user_id, joined_at')
            .eq('club_id', clubId)
            .limit(1);
      } catch (testError) {
        ProductionLogger.error(
          'Basic query failed - cannot access club_members table',
          error: testError,
          tag: 'ClubService',
        );
        throw Exception('Cannot access club_members table: $testError');
      }

      // Now try with users join - add timestamp to prevent caching (use read replica)
      final response = await _readClient
          .from('club_members')
          .select('''
            user_id,
            joined_at,
            users (
              id,
              full_name,
              username,
              bio,
              avatar_url,
              role,
              skill_level,
              ranking_points,
              is_verified,
              is_active,
              display_name,
              rank,
              elo_rating,
              spa_points,
              created_at
            )
          ''')
          .eq('club_id', clubId)
          .order('joined_at', ascending: false); // Show newest members first

      // Map to UserProfile objects
      final profiles = response
          .where((item) => item['users'] != null) // Filter out null users
          .map<UserProfile>((json) => UserProfile.fromJson(json['users']))
          .toList();

      ProductionLogger.debug(
        'Loaded ${profiles.length} members for club $clubId',
        tag: 'ClubService',
      );
      return profiles;
    } catch (error) {
      ProductionLogger.error(
        'Failed to get club members',
        error: error,
        tag: 'ClubService',
      );
      rethrow; // Rethrow original error for better debugging
    }
  }

  Future<bool> joinClub(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Use write client for write operations
      await _writeClient.from('club_members').insert({
        'club_id': clubId,
        'user_id': user.id,
      });

      return true;
    } catch (error) {
      throw Exception('Failed to join club: $error');
    }
  }

  Future<bool> leaveClub(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('club_members')
          .delete()
          .eq('club_id', clubId)
          .eq('user_id', user.id);

      return true;
    } catch (error) {
      throw Exception('Failed to leave club: $error');
    }
  }

  Future<bool> isClubMember(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (error) {
      throw Exception('Failed to check club membership: $error');
    }
  }

  Future<bool> toggleFavoriteClub(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if already a member
      final membership = await _supabase
          .from('club_members')
          .select()
          .eq('club_id', clubId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (membership != null) {
        // Toggle favorite status (use write client)
        await _writeClient
            .from('club_members')
            .update({'is_favorite': !membership['is_favorite']})
            .eq('id', membership['id']);
      } else {
        // Join club as favorite (use write client)
        await _writeClient.from('club_members').insert({
          'club_id': clubId,
          'user_id': user.id,
          'is_favorite': true,
        });
      }

      return true;
    } catch (error) {
      throw Exception('Failed to toggle favorite club: $error');
    }
  }

  Future<List<Club>> getUserFavoriteClubs() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('club_members')
          .select('''
            clubs (*)
          ''')
          .eq('user_id', user.id)
          .eq('is_favorite', true)
          .order('joined_at', ascending: false);

      return response
          .map<Club>((json) => Club.fromJson(json['clubs']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get favorite clubs: $error');
    }
  }

  Future<List<Club>> searchClubs(String query) async {
    try {
      final response = await _supabase
          .from('clubs')
          .select()
          .or(
            'name.ilike.%$query%,description.ilike.%$query%,address.ilike.%$query%',
          )
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(20);

      return response.map<Club>((json) => Club.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to search clubs: $error');
    }
  }

  Future<Club> createClub({
    required String name,
    required String description,
    required String address,
    String? phone,
    String? email,
    int totalTables = 1,
    double? pricePerHour,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final clubData = {
        'owner_id': user.id,
        'name': name,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
        'total_tables': totalTables,
        'price_per_hour': pricePerHour,
        'latitude': latitude,
        'longitude': longitude,
        'approval_status': 'pending', // New clubs need admin approval
        'is_verified': false,
        'is_active': false, // Inactive until approved
      };

      final response = await _supabase
          .from('clubs')
          .insert(clubData)
          .select()
          .single();

      final club = Club.fromJson(response);

      // Tạo club_members record cho owner ngay khi tạo club
      try {
        await _supabase
            .from('club_members')
            .insert({
              'club_id': club.id,
              'user_id': user.id,
              'role': 'owner',
              'status': 'pending', // Pending until club is approved
              'joined_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
      } catch (memberError) {
        ProductionLogger.warning(
          'Failed to create club_members record',
          error: memberError,
          tag: 'ClubService',
        );
        // Don't throw - club was created successfully
      }

      // 🔔 Gửi thông báo khi tạo CLB thành công
      await AutoNotificationHooks.onClubCreated(
        clubId: club.id,
        ownerId: user.id,
        clubName: name,
      );

      return club;
    } catch (error) {
      throw Exception('Failed to create club: $error');
    }
  }

  /// Get clubs owned by current user
  Future<List<Club>> getMyClubs() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Use read replica for read operations
      final response = await _readClient
          .from('clubs')
          .select('*')
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      return response.map<Club>((json) => Club.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get user clubs: $error');
    }
  }

  /// Check if current user is owner of a specific club
  Future<bool> isClubOwner(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Use read replica for read operations
      final response = await _readClient
          .from('clubs')
          .select('owner_id')
          .eq('id', clubId)
          .maybeSingle();

      return response != null && response['owner_id'] == user.id;
    } catch (error) {
      ProductionLogger.error(
        'Error checking club ownership',
        error: error,
        tag: 'ClubService',
      );
      return false;
    }
  }

  /// Get current user's primary club (first approved club they own)
  Future<Club?> getCurrentUserClub() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Use read replica for read operations
      final response = await _readClient
          .from('clubs')
          .select('*')
          .eq('owner_id', user.id)
          .eq('approval_status', 'approved')
          .eq('is_active', true)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      return response != null ? Club.fromJson(response) : null;
    } catch (error) {
      ProductionLogger.error(
        'Error getting current user club',
        error: error,
        tag: 'ClubService',
      );
      return null;
    }
  }

  /// Update club logo
  Future<Club> updateClubLogo(String clubId, String logoUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is club owner
      final isOwner = await isClubOwner(clubId);
      if (!isOwner) throw Exception('You are not the owner of this club');

      final response = await _supabase
          .from('clubs')
          .update({
            'logo_url': logoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clubId)
          .select()
          .single();

      return Club.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update club logo: $error');
    }
  }

  /// Upload club logo to storage and update database
  Future<Club> uploadAndUpdateClubLogo(
    String clubId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is club owner
      final isOwner = await isClubOwner(clubId);
      if (!isOwner) throw Exception('You are not the owner of this club');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'club_logo_${clubId}_$timestamp.png';

      // Upload file to storage
      await _supabase.storage
          .from('club-logos')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('club-logos')
          .getPublicUrl(uniqueFileName);

      // Update club logo in database
      return await updateClubLogo(clubId, publicUrl);
    } catch (error) {
      throw Exception('Failed to upload and update club logo: $error');
    }
  }

  /// Upload club cover image to storage and update database
  Future<Club> uploadAndUpdateClubCover(
    String clubId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is club owner
      final isOwner = await isClubOwner(clubId);
      if (!isOwner) throw Exception('You are not the owner of this club');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'club_cover_${clubId}_$timestamp.jpg';

      // Upload file to storage (using club-images bucket)
      await _supabase.storage
          .from('club-images')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('club-images')
          .getPublicUrl(uniqueFileName);

      // Update club cover in database
      return await updateClubCover(clubId, publicUrl);
    } catch (error) {
      throw Exception('Failed to upload and update club cover: $error');
    }
  }

  /// Update club cover URL
  Future<Club> updateClubCover(String clubId, String coverUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is club owner
      final isOwner = await isClubOwner(clubId);
      if (!isOwner) throw Exception('You are not the owner of this club');

      final response = await _supabase
          .from('clubs')
          .update({
            'cover_image_url': coverUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clubId)
          .select()
          .single();

      return Club.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update club cover: $error');
    }
  }

  /// Remove club logo
  Future<Club> removeClubLogo(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is club owner
      final isOwner = await isClubOwner(clubId);
      if (!isOwner) throw Exception('You are not the owner of this club');

      final response = await _supabase
          .from('clubs')
          .update({
            'logo_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clubId)
          .select()
          .single();

      return Club.fromJson(response);
    } catch (error) {
      throw Exception('Failed to remove club logo: $error');
    }
  }

  /// Update club basic information
  Future<Club> updateClub({
    required String clubId,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? websiteUrl,
    int? totalTables,
    double? pricePerHour,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is club owner
      final isOwner = await isClubOwner(clubId);
      if (!isOwner) throw Exception('You are not the owner of this club');

      // Build update data - only include non-null fields
      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (address != null) updateData['address'] = address;
      if (phone != null) updateData['phone'] = phone;
      if (email != null) updateData['email'] = email;
      if (websiteUrl != null) updateData['website_url'] = websiteUrl;
      if (totalTables != null) updateData['total_tables'] = totalTables;
      if (pricePerHour != null) updateData['price_per_hour'] = pricePerHour;

      final response = await _supabase
          .from('clubs')
          .update(updateData)
          .eq('id', clubId)
          .select()
          .single();

      return Club.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update club: $error');
    }
  }

  /// Upload profile image and update club
  Future<Club> uploadAndUpdateProfileImage(
    String clubId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is club owner
      final isOwner = await isClubOwner(clubId);
      if (!isOwner) throw Exception('You are not the owner of this club');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last;
      final uniqueFileName = 'club_profile_${clubId}_$timestamp.$extension';

      // Determine content type
      final contentType = _getContentType(extension);

      // Upload file to storage
      await _supabase.storage
          .from('club-images')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('club-images')
          .getPublicUrl(uniqueFileName);

      // Update club profile image in database
      final response = await _supabase
          .from('clubs')
          .update({
            'profile_image_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clubId)
          .select()
          .single();

      return Club.fromJson(response);
    } catch (error) {
      throw Exception('Failed to upload profile image: $error');
    }
  }

  /// Upload cover image and update club
  Future<Club> uploadAndUpdateCoverImage(
    String clubId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is club owner
      final isOwner = await isClubOwner(clubId);
      if (!isOwner) throw Exception('You are not the owner of this club');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last;
      final uniqueFileName = 'club_cover_${clubId}_$timestamp.$extension';

      // Determine content type
      final contentType = _getContentType(extension);

      // Upload file to storage
      await _supabase.storage
          .from('club-images')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('club-images')
          .getPublicUrl(uniqueFileName);

      // Update club cover image in database
      final response = await _supabase
          .from('clubs')
          .update({
            'cover_image_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clubId)
          .select()
          .single();

      return Club.fromJson(response);
    } catch (error) {
      throw Exception('Failed to upload cover image: $error');
    }
  }

  // Club Follow/Unfollow functionality
  Future<bool> followClub(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if already following
      final existingFollow = await _supabase
          .from('club_follows')
          .select()
          .eq('user_id', user.id)
          .eq('club_id', clubId)
          .maybeSingle();

      if (existingFollow != null) {
        return true; // Already following
      }

      // Add follow relationship (use write client)
      await _writeClient.from('club_follows').insert({
        'user_id': user.id,
        'club_id': clubId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (error) {
      ProductionLogger.error(
        'Failed to follow club',
        error: error,
        tag: 'ClubService',
      );
      return false;
    }
  }

  Future<bool> unfollowClub(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Remove follow relationship (use write client)
      await _writeClient
          .from('club_follows')
          .delete()
          .eq('user_id', user.id)
          .eq('club_id', clubId);

      return true;
    } catch (error) {
      ProductionLogger.error(
        'Failed to unfollow club',
        error: error,
        tag: 'ClubService',
      );
      return false;
    }
  }

  Future<bool> isFollowingClub(String clubId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Use read replica for read operations
      final follow = await _readClient
          .from('club_follows')
          .select()
          .eq('user_id', user.id)
          .eq('club_id', clubId)
          .maybeSingle();

      return follow != null;
    } catch (error) {
      ProductionLogger.error(
        'Failed to check follow status',
        error: error,
        tag: 'ClubService',
      );
      return false;
    }
  }

  Future<int> getClubFollowersCount(String clubId) async {
    try {
      // Use read replica for read operations
      final response = await _readClient
          .from('club_follows')
          .select()
          .eq('club_id', clubId);

      return response.length;
    } catch (error) {
      ProductionLogger.error(
        'Failed to get followers count',
        error: error,
        tag: 'ClubService',
      );
      return 0;
    }
  }

  /// 🎱 Check if user can post as club (owner or admin)
  Future<bool> canUserPostAsClub(String userId, String clubId) async {
    try {
      // Check if user is owner
      final club = await _supabase
          .from('clubs')
          .select('owner_id')
          .eq('id', clubId)
          .single();

      if (club['owner_id'] == userId) {
        return true;
      }

      // Check if user is admin
      final membership = await _supabase
          .from('club_members')
          .select('role')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      return membership != null && 
             (membership['role'] == 'admin' || membership['role'] == 'owner');
    } catch (error) {
      ProductionLogger.error(
        'Error checking user club permission',
        error: error,
        tag: 'ClubService',
      );
      return false;
    }
  }

  /// 🎱 Get all clubs that user can manage (owner or admin)
  Future<List<Club>> getUserManagedClubs(String userId) async {
    try {
      // Get clubs where user is owner
      final ownedClubs = await _supabase
          .from('clubs')
          .select()
          .eq('owner_id', userId)
          .eq('is_active', true);

      // Get clubs where user is admin
      final adminMemberships = await _supabase
          .from('club_members')
          .select('club_id, clubs(*)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .eq('role', 'admin');

      final List<Club> managedClubs = [];

      // Add owned clubs
      for (var clubData in ownedClubs) {
        managedClubs.add(Club.fromJson(clubData));
      }

      // Add admin clubs (avoid duplicates)
      for (var membership in adminMemberships) {
        final clubData = membership['clubs'];
        if (clubData != null) {
          final clubId = clubData['id'];
          // Check if not already in list
          if (!managedClubs.any((c) => c.id == clubId)) {
            managedClubs.add(Club.fromJson(clubData));
          }
        }
      }

      ProductionLogger.debug(
        'User manages ${managedClubs.length} clubs',
        tag: 'ClubService',
      );
      return managedClubs;
    } catch (error) {
      ProductionLogger.error(
        'Error getting managed clubs',
        error: error,
        tag: 'ClubService',
      );
      return [];
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
