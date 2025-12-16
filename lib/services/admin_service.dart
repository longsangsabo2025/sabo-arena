import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club.dart';
import '../models/user_profile.dart';
import '../models/admin_user_view.dart';
import '../models/voucher_campaign.dart';
import 'auto_notification_hooks.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class AdminService {
  static AdminService? _instance;
  static AdminService get instance => _instance ??= AdminService._();
  AdminService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // CLUB MANAGEMENT
  // ==========================================

  /// Get all clubs pending approval
  Future<List<Club>> getPendingClubs() async {
    try {
      final response = await _supabase
          .from('clubs')
          .select('''
            *,
            owner:users!owner_id (
              id,
              display_name,
              email,
              avatar_url
            )
          ''')
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);

      return response.map<Club>((json) => Club.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get pending clubs: $error');
    }
  }

  /// Get all clubs (with filters)
  Future<List<Club>> getClubsForAdmin({
    String? status, // 'pending', 'approved', 'rejected'
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('clubs').select('''
            *,
            owner:users!owner_id (
              id,
              display_name,
              email,
              avatar_url,
              phone
            )
          ''');

      if (status != null) {
        query = query.eq('approval_status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map<Club>((json) {
        if (json is! Map<String, dynamic>) {
          throw Exception('Invalid club data type: ${json.runtimeType}');
        }
        return Club.fromJson(json);
      }).toList();
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Failed to get clubs for admin: $error');
    }
  }

  /// Approve a club
  Future<Club> approveClub(String clubId, {String? adminNotes}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      // First, get the club to find the owner_id
      final clubData = await _supabase
          .from('clubs')
          .select('owner_id')
          .eq('id', clubId)
          .single();

      final ownerId = clubData['owner_id'];
      if (ownerId == null) {
        throw Exception('Club owner not found');
      }

      // Update club status and activate it
      final clubResponse = await _supabase
          .from('clubs')
          .update({
            'approval_status': 'approved',
            'is_active': true, // Auto-activate when approved
            'approved_at': DateTime.now().toIso8601String(),
            'approved_by': user.id,
            'rejection_reason': null, // Clear any previous rejection reason
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clubId)
          .select()
          .single();

      // Update user role to club_owner (with verification)
      final userUpdateResponse = await _supabase
          .from('users')
          .update({
            'role': 'club_owner',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ownerId)
          .select()
          .maybeSingle();

      if (userUpdateResponse == null) {
        throw Exception(
          'Failed to update user role - user not found: $ownerId',
        );
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Create or update club_members record with owner role
      try {
        // Check if club_members record exists
        final existingMember = await _supabase
            .from('club_members')
            .select('id')
            .eq('club_id', clubId)
            .eq('user_id', ownerId)
            .maybeSingle();

        if (existingMember != null) {
          // Update existing record
          await _supabase
              .from('club_members')
              .update({
                'role': 'owner',
                'status': 'active',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('club_id', clubId)
              .eq('user_id', ownerId)
              .select()
              .single();
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } else {
          // Create new record
          await _supabase
              .from('club_members')
              .insert({
                'club_id': clubId,
                'user_id': ownerId,
                'role': 'owner',
                'status': 'active',
                'joined_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      } catch (memberError) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        // Don't throw - this is not critical if user role was updated
      }

      // Log admin action
      await _logAdminAction(
        adminId: user.id,
        action: 'approve_club',
        targetId: clubId,
        details: {
          'admin_notes': adminNotes,
          'owner_id': ownerId,
          'auto_activated': true,
          'role_updated': 'club_owner',
        },
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final club = Club.fromJson(clubResponse);

      // 🔔 Gửi thông báo khi CLB được phê duyệt
      await AutoNotificationHooks.onClubApproved(
        clubId: clubId,
        ownerId: ownerId,
        clubName: club.name,
        approvedBy: user.id,
      );

      return club;
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Failed to approve club: $error');
    }
  }

  /// Reject a club
  Future<Club> rejectClub(
    String clubId,
    String reason, {
    String? adminNotes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      // Get club data first (owner_id and name)
      final clubData = await _supabase
          .from('clubs')
          .select('owner_id, name')
          .eq('id', clubId)
          .single();

      final response = await _supabase
          .from('clubs')
          .update({
            'approval_status': 'rejected',
            'rejection_reason': reason,
            'approved_at': null,
            'approved_by': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clubId)
          .select()
          .single();

      // Log admin action
      await _logAdminAction(
        adminId: user.id,
        action: 'reject_club',
        targetId: clubId,
        details: {'rejection_reason': reason, 'admin_notes': adminNotes},
      );

      final club = Club.fromJson(response);

      // 🔔 Gửi thông báo khi CLB bị từ chối
      await AutoNotificationHooks.onClubRejected(
        clubId: clubId,
        ownerId: clubData['owner_id'],
        clubName: clubData['name'] ?? club.name,
        reason: reason,
        rejectedBy: user.id,
      );

      return club;
    } catch (error) {
      throw Exception('Failed to reject club: $error');
    }
  }

  // ==========================================
  // ADMIN DASHBOARD STATS
  // ==========================================

  /// Get admin dashboard statistics
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Get counts by fetching data and counting
      final pendingClubs = await _supabase
          .from('clubs')
          .select('id')
          .eq('approval_status', 'pending');
      final pendingClubsCount = (pendingClubs as List).length;

      final approvedClubs = await _supabase
          .from('clubs')
          .select('id')
          .eq('approval_status', 'approved');
      final approvedClubsCount = (approvedClubs as List).length;

      final rejectedClubs = await _supabase
          .from('clubs')
          .select('id')
          .eq('approval_status', 'rejected');
      final rejectedClubsCount = (rejectedClubs as List).length;

      final users = await _supabase.from('users').select('id');
      final usersCount = (users as List).length;

      final tournaments = await _supabase.from('tournaments').select('id');
      final tournamentsCount = (tournaments as List).length;

      final matches = await _supabase
          .from('matches')
          .select('id')
          .eq('status', 'completed');
      final matchesCount = (matches as List).length;

      return {
        'clubs': {
          'pending': pendingClubsCount,
          'approved': approvedClubsCount,
          'rejected': rejectedClubsCount,
          'total': pendingClubsCount + approvedClubsCount + rejectedClubsCount,
        },
        'users': {'total': usersCount},
        'tournaments': {'total': tournamentsCount},
        'matches': {'completed': matchesCount},
      };
    } catch (error) {
      throw Exception('Failed to get admin stats: $error');
    }
  }

  /// Get recent activities for admin dashboard
  Future<List<Map<String, dynamic>>> getRecentActivities({
    int limit = 20,
  }) async {
    try {
      // Get recent club registrations
      final clubActivities = await _supabase
          .from('clubs')
          .select('''
            id,
            name,
            approval_status,
            created_at,
            owner:users!owner_id (display_name)
          ''')
          .order('created_at', ascending: false)
          .limit(limit);

      // Convert to activity format
      List<Map<String, dynamic>> activities = [];

      for (final club in clubActivities) {
        activities.add({
          'id': club['id'],
          'type': 'club_registration',
          'title': 'Đăng ký CLB mới',
          'description':
              '${club['owner']['display_name']} đăng ký CLB "${club['name']}"',
          'status': club['approval_status'],
          'timestamp': DateTime.parse(club['created_at']),
          'target_id': club['id'],
        });
      }

      // Sort by timestamp descending
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      return activities.take(limit).toList();
    } catch (error) {
      throw Exception('Failed to get recent activities: $error');
    }
  }

  // ==========================================
  // TOURNAMENT MANAGEMENT
  // ==========================================

  /// Add all users to a tournament (for testing purposes)
  /// Uses RPC function to bypass RLS restrictions
  Future<Map<String, dynamic>> addAllUsersToTournament(
    String tournamentId,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      // Check if user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) throw Exception('Only admins can perform this action');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Call RPC function instead of direct table operations
      final result = await _supabase.rpc(
        'admin_add_all_users_to_tournament',
        params: {'p_tournament_id': tournamentId},
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // The RPC function returns a JSON object with all necessary information
      if (result is Map<String, dynamic>) {
        return Map<String, dynamic>.from(result);
      } else {
        // Handle case where result might be a JSON string
        return {
          'success': true,
          'tournament_id': tournamentId,
          'message': 'Users added successfully via RPC',
          'raw_result': result,
        };
      }
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Failed to add all users to tournament: $error');
    }
  }

  /// Remove all users from a tournament (for testing cleanup)
  /// Uses RPC function to bypass RLS restrictions
  Future<Map<String, dynamic>> removeAllUsersFromTournament(
    String tournamentId,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      // Check if user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) throw Exception('Only admins can perform this action');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Call RPC function instead of direct table operations
      final result = await _supabase.rpc(
        'admin_remove_all_users_from_tournament',
        params: {'p_tournament_id': tournamentId},
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // The RPC function returns a JSON object with all necessary information
      if (result is Map<String, dynamic>) {
        return Map<String, dynamic>.from(result);
      } else {
        // Handle case where result might be a JSON string
        return {
          'success': true,
          'tournament_id': tournamentId,
          'message': 'Users removed successfully via RPC',
          'raw_result': result,
        };
      }
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Failed to remove all users from tournament: $error');
    }
  }

  /// Get tournaments for admin management
  Future<List<Map<String, dynamic>>> getTournamentsForAdmin({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('tournaments').select('''
            *,
            club:clubs (name, id),
            participants_count:tournament_participants(count)
          ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response;
    } catch (error) {
      throw Exception('Failed to get tournaments for admin: $error');
    }
  }

  // ==========================================
  // USER MANAGEMENT (FUTURE)
  // ==========================================

  /// Get users for admin management (returns AdminUserView with status field)
  Future<List<AdminUserView>> getAdminUsersView({
    String? search,
    String? role,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('users').select();

      if (search != null && search.isNotEmpty) {
        query = query.or('display_name.ilike.%$search%,email.ilike.%$search%');
      }

      if (role != null) {
        query = query.eq('role', role);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<AdminUserView>((json) => AdminUserView.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get users for admin: $error');
    }
  }

  /// Get users for admin management (legacy - returns UserProfile)
  Future<List<UserProfile>> getUsersForAdmin({
    String? search,
    String? role,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('users').select();

      if (search != null && search.isNotEmpty) {
        query = query.or('display_name.ilike.%$search%,email.ilike.%$search%');
      }

      if (role != null) {
        query = query.eq('role', role);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get users for admin: $error');
    }
  }

  // ==========================================
  // ADMIN UTILITIES
  // ==========================================

  /// Block a user
  Future<void> blockUser(String userId, {String? reason}) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) throw Exception('Admin not authenticated');

      await _supabase
          .from('users')
          .update({
            'status': 'blocked',
            'blocked_at': DateTime.now().toIso8601String(),
            'blocked_reason': reason,
          })
          .eq('id', userId);

      await _logAdminAction(
        adminId: admin.id,
        action: 'block_user',
        targetId: userId,
        details: {'reason': reason},
      );
    } catch (error) {
      throw Exception('Failed to block user: $error');
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) throw Exception('Admin not authenticated');

      await _supabase
          .from('users')
          .update({
            'status': 'active',
            'blocked_at': null,
            'blocked_reason': null,
          })
          .eq('id', userId);

      await _logAdminAction(
        adminId: admin.id,
        action: 'unblock_user',
        targetId: userId,
      );
    } catch (error) {
      throw Exception('Failed to unblock user: $error');
    }
  }

  /// Delete a user (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) throw Exception('Admin not authenticated');

      await _supabase
          .from('users')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'status': 'deleted',
          })
          .eq('id', userId);

      await _logAdminAction(
        adminId: admin.id,
        action: 'delete_user',
        targetId: userId,
      );
    } catch (error) {
      throw Exception('Failed to delete user: $error');
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) throw Exception('Admin not authenticated');

      // Validate role
      if (!['user', 'admin', 'moderator'].contains(newRole)) {
        throw Exception('Invalid role: $newRole');
      }

      await _supabase.from('users').update({'role': newRole}).eq('id', userId);

      await _logAdminAction(
        adminId: admin.id,
        action: 'update_user_role',
        targetId: userId,
        details: {'new_role': newRole},
      );
    } catch (error) {
      throw Exception('Failed to update user role: $error');
    }
  }

  /// Verify a user
  Future<void> verifyUser(String userId) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) throw Exception('Admin not authenticated');

      await _supabase
          .from('users')
          .update({
            'is_verified': true,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await _logAdminAction(
        adminId: admin.id,
        action: 'verify_user',
        targetId: userId,
      );
    } catch (error) {
      throw Exception('Failed to verify user: $error');
    }
  }

  /// Unverify a user
  Future<void> unverifyUser(String userId) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) throw Exception('Admin not authenticated');

      await _supabase
          .from('users')
          .update({'is_verified': false, 'verified_at': null})
          .eq('id', userId);

      await _logAdminAction(
        adminId: admin.id,
        action: 'unverify_user',
        targetId: userId,
      );
    } catch (error) {
      throw Exception('Failed to unverify user: $error');
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] == 'admin';
    } catch (error) {
      return false;
    }
  }

  /// Log admin actions for audit trail
  Future<void> _logAdminAction({
    required String adminId,
    required String action,
    required String targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _supabase.from('admin_logs').insert({
        'admin_id': adminId,
        'action': action,
        'target_id': targetId,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      // Log error but don't throw - logging failure shouldn't break main action
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Get admin logs for audit
  Future<List<Map<String, dynamic>>> getAdminLogs({
    String? adminId,
    String? action,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('admin_logs').select('''
        *,
        admin:users!admin_id (
          display_name,
          email
        )
      ''');

      if (adminId != null) {
        query = query.eq('admin_id', adminId);
      }

      if (action != null) {
        query = query.eq('action', action);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  /// Get user statistics for admin
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // User basic info
      final user = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      // Clubs owned
      final clubsOwned = await _supabase
          .from('clubs')
          .select('id')
          .eq('owner_id', userId);
      final clubsCount = (clubsOwned as List).length;

      // Tournaments participated
      final tournaments = await _supabase
          .from('tournament_participants')
          .select('id')
          .eq('user_id', userId);
      final tournamentsCount = (tournaments as List).length;

      // Matches played
      final matches = await _supabase
          .from('matches')
          .select('id')
          .or('player1_id.eq.$userId,player2_id.eq.$userId');
      final matchesCount = (matches as List).length;

      return {
        'user': user,
        'clubs_owned': clubsCount,
        'tournaments_participated': tournamentsCount,
        'matches_played': matchesCount,
        'win_rate': user['total_wins'] > 0
            ? (user['total_wins'] /
                      (user['total_wins'] + user['total_losses']) *
                      100)
                  .toStringAsFixed(1)
            : '0.0',
      };
    } catch (error) {
      throw Exception('Failed to get user statistics: $error');
    }
  }

  /// Send notification to user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    String? actionUrl,
  }) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) throw Exception('Admin not authenticated');

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'action_url': actionUrl,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      await _logAdminAction(
        adminId: admin.id,
        action: 'send_notification',
        targetId: userId,
        details: {'title': title, 'message': message},
      );
    } catch (error) {
      throw Exception('Failed to send notification: $error');
    }
  }

  /// Bulk update users
  Future<Map<String, dynamic>> bulkUpdateUsers({
    required List<String> userIds,
    Map<String, dynamic>? updates,
  }) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) throw Exception('Admin not authenticated');

      int successCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      for (final userId in userIds) {
        try {
          if (updates != null) {
            await _supabase.from('users').update(updates).eq('id', userId);
          }
          successCount++;
        } catch (e) {
          failedCount++;
          errors.add('User $userId: $e');
        }
      }

      await _logAdminAction(
        adminId: admin.id,
        action: 'bulk_update_users',
        targetId: 'multiple',
        details: {
          'user_count': userIds.length,
          'updates': updates,
          'success': successCount,
          'failed': failedCount,
        },
      );

      return {'success': successCount, 'failed': failedCount, 'errors': errors};
    } catch (error) {
      throw Exception('Failed to bulk update users: $error');
    }
  }

  // ==========================================
  // VOUCHER CAMPAIGN MANAGEMENT
  // ==========================================

  /// Get all voucher campaigns (with filters)
  Future<List<VoucherCampaign>> getVoucherCampaigns({
    String? status, // 'pending', 'approved', 'rejected'
    String? clubId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('voucher_campaigns').select('''
        *,
        club:clubs!club_id (
          name,
          owner:users!owner_id (
            display_name
          )
        )
      ''');

      if (status != null) {
        query = query.eq('approval_status', status);
      }

      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => VoucherCampaign.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Failed to get voucher campaigns: $error');
    }
  }

  /// Get pending voucher campaigns
  Future<List<VoucherCampaign>> getPendingVoucherCampaigns() async {
    return getVoucherCampaigns(status: 'pending');
  }

  /// Get voucher campaign by ID
  Future<VoucherCampaign> getVoucherCampaignById(String campaignId) async {
    try {
      final response = await _supabase
          .from('voucher_campaigns')
          .select('''
            *,
            club:clubs!club_id (
              name,
              owner:users!owner_id (
                display_name,
                email
              )
            )
          ''')
          .eq('id', campaignId)
          .single();

      return VoucherCampaign.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get voucher campaign: $error');
    }
  }

  /// Approve voucher campaign
  Future<VoucherCampaign> approveVoucherCampaign(
    String campaignId, {
    String? adminNotes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      final response = await _supabase
          .from('voucher_campaigns')
          .update({
            'approval_status': 'approved',
            'approved_by': user.id,
            'approved_at': DateTime.now().toIso8601String(),
            'admin_notes': adminNotes,
          })
          .eq('id', campaignId)
          .select('''
            *,
            club:clubs!club_id (
              name,
              owner:users!owner_id (
                display_name
              )
            )
          ''')
          .single();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return VoucherCampaign.fromJson(response);
    } catch (error) {
      throw Exception('Failed to approve voucher campaign: $error');
    }
  }

  /// Reject voucher campaign
  Future<VoucherCampaign> rejectVoucherCampaign(
    String campaignId, {
    required String reason,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Admin not authenticated');

      final response = await _supabase
          .from('voucher_campaigns')
          .update({
            'approval_status': 'rejected',
            'approved_by': user.id,
            'approved_at': DateTime.now().toIso8601String(),
            'admin_notes': reason,
          })
          .eq('id', campaignId)
          .select('''
            *,
            club:clubs!club_id (
              name,
              owner:users!owner_id (
                display_name
              )
            )
          ''')
          .single();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return VoucherCampaign.fromJson(response);
    } catch (error) {
      throw Exception('Failed to reject voucher campaign: $error');
    }
  }

  /// Get voucher campaigns statistics
  Future<Map<String, int>> getVoucherCampaignStats() async {
    try {
      final response = await _supabase.rpc('get_voucher_campaign_stats');
      
      // If RPC doesn't exist, calculate manually
      if (response == null) {
        final allCampaigns = await getVoucherCampaigns(limit: 1000);
        return {
          'total': allCampaigns.length,
          'pending': allCampaigns.where((c) => c.isPending).length,
          'approved': allCampaigns.where((c) => c.isApproved).length,
          'rejected': allCampaigns.where((c) => c.isRejected).length,
        };
      }
      
      // Function returns array with single row, extract first element
      if (response is List && response.isNotEmpty) {
        final stats = response[0] as Map<String, dynamic>;
        return {
          'pending': (stats['pending_count'] ?? 0) as int,
          'approved': (stats['approved_count'] ?? 0) as int,
          'rejected': (stats['rejected_count'] ?? 0) as int,
          'total': ((stats['pending_count'] ?? 0) as int) + 
                   ((stats['approved_count'] ?? 0) as int) + 
                   ((stats['rejected_count'] ?? 0) as int),
        };
      }
      
      throw Exception('Unexpected response format');
    } catch (error) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      final allCampaigns = await getVoucherCampaigns(limit: 1000);
      return {
        'total': allCampaigns.length,
        'pending': allCampaigns.where((c) => c.isPending).length,
        'approved': allCampaigns.where((c) => c.isApproved).length,
        'rejected': allCampaigns.where((c) => c.isRejected).length,
      };
    }
  }
}

