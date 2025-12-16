import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club_permission.dart';
import '../models/club_role.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service for managing club permissions and roles
class ClubPermissionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all members of a club with their roles and permissions
  Future<List<ClubMemberWithPermissions>> getClubMembers(String clubId) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('''
            id,
            club_id,
            user_id,
            role,
            joined_at,
            users:user_id (
              id,
              full_name,
              avatar_url,
              rank
            )
          ''')
          .eq('club_id', clubId)
          .order('role', ascending: true)
          .order('joined_at', ascending: true);

      return (response as List).map((json) {
        final user = json['users'] as Map<String, dynamic>?;
        return ClubMemberWithPermissions(
          id: json['id'] as String,
          clubId: json['club_id'] as String,
          userId: json['user_id'] as String,
          userName: user?['display_name'] as String? ?? user?['full_name'] as String? ?? 'Unknown',
          userAvatar: user?['avatar_url'] as String?,
          userRank: user?['rank'] as String?,
          role: ClubRole.fromString(json['role'] as String? ?? 'member'),
          joinedAt: DateTime.parse(json['joined_at'] as String),
        );
      }).toList();
    } catch (e) {
      ProductionLogger.info('Error getting club members: $e', tag: 'club_permission_service');
      rethrow;
    }
  }

  /// Get user's permissions in a specific club
  Future<ClubPermission?> getUserPermissions(String userId, String clubId) async {
    try {
      final response = await _supabase
          .from('club_permissions')
          .select()
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .maybeSingle();

      if (response == null) {
        // Check if user is a member and get default permissions
        final member = await _supabase
            .from('club_members')
            .select('role')
            .eq('user_id', userId)
            .eq('club_id', clubId)
            .maybeSingle();

        if (member != null) {
          final role = ClubRole.fromString(member['role'] as String? ?? 'member');
          return ClubPermission.defaultForRole(
            clubId: clubId,
            userId: userId,
            role: role,
          );
        }
        return null;
      }

      return ClubPermission.fromJson(response);
    } catch (e) {
      ProductionLogger.info('Error getting user permissions: $e', tag: 'club_permission_service');
      rethrow;
    }
  }

  /// Update member role (will automatically update permissions based on role)
  Future<void> updateMemberRole({
    required String clubId,
    required String userId,
    required ClubRole newRole,
    required String grantedBy,
  }) async {
    try {
      // DEBUG: Log current auth user
      final currentUser = _supabase.auth.currentUser;
      ProductionLogger.info('🔑 [DEBUG] Current authenticated user: ${currentUser?.id}', tag: 'club_permission_service');
      ProductionLogger.info('🔑 [DEBUG] User email: ${currentUser?.email}', tag: 'club_permission_service');
      ProductionLogger.info('🎯 [DEBUG] Attempting to update:', tag: 'club_permission_service');
      ProductionLogger.info('   Club ID: $clubId', tag: 'club_permission_service');
      ProductionLogger.info('   Target User ID: $userId', tag: 'club_permission_service');
      ProductionLogger.info('   New Role: ${newRole.value}', tag: 'club_permission_service');
      ProductionLogger.info('   Granted By: $grantedBy', tag: 'club_permission_service');
      
      // Update role in club_members
      ProductionLogger.info('📝 [DEBUG] Executing UPDATE query...', tag: 'club_permission_service');
      final updateResponse = await _supabase
          .from('club_members')
          .update({'role': newRole.value})
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .select();  // Add .select() to get response data
      
      ProductionLogger.info('✅ [DEBUG] UPDATE response: $updateResponse', tag: 'club_permission_service');
      
      // Check if update actually happened
      if (updateResponse.isEmpty) {
        ProductionLogger.info('⚠️  [DEBUG] WARNING: Update returned empty response!', tag: 'club_permission_service');
        ProductionLogger.info('   This usually means RLS policy blocked the update.', tag: 'club_permission_service');
        throw Exception('Failed to update role - RLS policy may have blocked the operation');
      }
      
      ProductionLogger.info('✅ [DEBUG] Role updated successfully in club_members', tag: 'club_permission_service');

      // Update or insert permissions
      final existingPermission = await getUserPermissions(userId, clubId);
      
      final permissionData = ClubPermission.defaultForRole(
        clubId: clubId,
        userId: userId,
        role: newRole,
        grantedBy: grantedBy,
      ).toJson();

      if (existingPermission != null) {
        await _supabase
            .from('club_permissions')
            .update({
              ...permissionData,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('club_id', clubId)
            .eq('user_id', userId);
      } else {
        await _supabase.from('club_permissions').insert(permissionData);
      }
    } catch (e) {
      ProductionLogger.info('Error updating member role: $e', tag: 'club_permission_service');
      rethrow;
    }
  }

  /// Grant custom permissions to a user (override role defaults)
  Future<void> grantCustomPermissions({
    required String clubId,
    required String userId,
    required Map<String, bool> permissions,
    required String grantedBy,
  }) async {
    try {
      final existingPermission = await getUserPermissions(userId, clubId);
      
      if (existingPermission == null) {
        throw Exception('User is not a member of this club');
      }

      final updatedPermission = existingPermission.copyWith(
        canVerifyRank: permissions['can_verify_rank'],
        canInputScore: permissions['can_input_score'],
        canManageTables: permissions['can_manage_tables'],
        canViewReports: permissions['can_view_reports'],
        canManageMembers: permissions['can_manage_members'],
        canManagePermissions: permissions['can_manage_permissions'],
        grantedBy: grantedBy,
        updatedAt: DateTime.now(),
      );

      // Use update instead of upsert with filters
      await _supabase
          .from('club_permissions')
          .update(updatedPermission.toJson())
          .eq('club_id', clubId)
          .eq('user_id', userId);
    } catch (e) {
      ProductionLogger.info('Error granting custom permissions: $e', tag: 'club_permission_service');
      rethrow;
    }
  }

  /// Revoke specific permissions from a user
  Future<void> revokePermissions({
    required String clubId,
    required String userId,
    required List<String> permissionKeys,
  }) async {
    try {
      final existingPermission = await getUserPermissions(userId, clubId);
      
      if (existingPermission == null) {
        throw Exception('User has no permissions to revoke');
      }

      final updatedPermissions = Map<String, bool>.from({
        'can_verify_rank': existingPermission.canVerifyRank,
        'can_input_score': existingPermission.canInputScore,
        'can_manage_tables': existingPermission.canManageTables,
        'can_view_reports': existingPermission.canViewReports,
        'can_manage_members': existingPermission.canManageMembers,
        'can_manage_permissions': existingPermission.canManagePermissions,
      });

      for (final key in permissionKeys) {
        updatedPermissions[key] = false;
      }

      await _supabase
          .from('club_permissions')
          .update({
            ...updatedPermissions,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('club_id', clubId)
          .eq('user_id', userId);
    } catch (e) {
      ProductionLogger.info('Error revoking permissions: $e', tag: 'club_permission_service');
      rethrow;
    }
  }

  /// Remove member from club (cascades to permissions)
  Future<void> removeMember({
    required String clubId,
    required String userId,
  }) async {
    try {
      // Delete from club_members (permissions will be deleted via FK cascade)
      await _supabase
          .from('club_members')
          .delete()
          .eq('club_id', clubId)
          .eq('user_id', userId);
    } catch (e) {
      ProductionLogger.info('Error removing member: $e', tag: 'club_permission_service');
      rethrow;
    }
  }

  /// Check if current user can perform an action
  Future<bool> canPerformAction({
    required String clubId,
    required String permissionKey,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final permission = await getUserPermissions(userId, clubId);
      if (permission == null) return false;

      switch (permissionKey) {
        case 'verify_rank':
          return permission.canVerifyRank;
        case 'input_score':
          return permission.canInputScore;
        case 'manage_tables':
          return permission.canManageTables;
        case 'view_reports':
          return permission.canViewReports;
        case 'manage_members':
          return permission.canManageMembers;
        case 'manage_permissions':
          return permission.canManagePermissions;
        default:
          return false;
      }
    } catch (e) {
      ProductionLogger.info('Error checking permission: $e', tag: 'club_permission_service');
      return false;
    }
  }

  /// Get members by role
  Future<List<ClubMemberWithPermissions>> getMembersByRole({
    required String clubId,
    required ClubRole role,
  }) async {
    try {
      final allMembers = await getClubMembers(clubId);
      return allMembers.where((member) => member.role == role).toList();
    } catch (e) {
      ProductionLogger.info('Error getting members by role: $e', tag: 'club_permission_service');
      rethrow;
    }
  }

  /// Check if user is club owner
  Future<bool> isClubOwner(String clubId, String userId) async {
    try {
      final member = await _supabase
          .from('club_members')
          .select('role')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .maybeSingle();

      return member?['role'] == 'owner';
    } catch (e) {
      ProductionLogger.info('Error checking club owner: $e', tag: 'club_permission_service');
      return false;
    }
  }

  /// Check if user can manage tournaments
  Future<bool> canManageTournaments(String clubId, String userId) async {
    try {
      final permission = await getUserPermissions(userId, clubId);
      if (permission == null) return false;

      // Owners and admins can manage tournaments
      return permission.role == ClubRole.owner || 
             permission.role == ClubRole.admin;
    } catch (e) {
      ProductionLogger.info('Error checking tournament management permission: $e', tag: 'club_permission_service');
      return false;
    }
  }

  /// Clear permission cache for a user or club
  Future<void> clearCache({String? clubId, String? userId}) async {
    // This is a placeholder for future caching implementation
    // Currently no caching is implemented, so this is a no-op
    ProductionLogger.info('Cache cleared for clubId: $clubId, userId: $userId', tag: 'club_permission_service');
  }

  /// Debug membership information
  Future<Map<String, dynamic>> debugMembership(String clubId, String userId) async {
    try {
      final member = await _supabase
          .from('club_members')
          .select('*')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .maybeSingle();

      final permission = await getUserPermissions(userId, clubId);

      return {
        'member': member,
        'permission': permission?.toJson(),
        'exists': member != null,
        'role': member?['role'],
      };
    } catch (e) {
      ProductionLogger.info('Error debugging membership: $e', tag: 'club_permission_service');
      return {'error': e.toString()};
    }
  }

  /// Refresh user role from database
  Future<ClubRole?> refreshUserRole(String clubId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final member = await _supabase
          .from('club_members')
          .select('role')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .maybeSingle();

      if (member == null) return null;

      return ClubRole.fromString(member['role'] as String? ?? 'member');
    } catch (e) {
      ProductionLogger.info('Error refreshing user role: $e', tag: 'club_permission_service');
      return null;
    }
  }

  /// Generic permission check
  Future<bool> hasPermission(
    String clubId,
    String userId,
    String permissionType,
  ) async {
    try {
      final permission = await getUserPermissions(userId, clubId);
      if (permission == null) return false;

      switch (permissionType) {
        case 'verify_rank':
          return permission.canVerifyRank;
        case 'input_score':
          return permission.canInputScore;
        case 'manage_tables':
          return permission.canManageTables;
        case 'view_reports':
          return permission.canViewReports;
        case 'manage_members':
          return permission.canManageMembers;
        case 'manage_permissions':
          return permission.canManagePermissions;
        case 'manage_tournaments':
          return permission.role == ClubRole.owner || 
                 permission.role == ClubRole.admin;
        default:
          return false;
      }
    } catch (e) {
      ProductionLogger.info('Error checking permission: $e', tag: 'club_permission_service');
      return false;
    }
  }

  /// Check if user has management access to any club (owner, admin, or moderator)
  Future<bool> hasClubManagementAccess(String userId) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('role')
          .eq('user_id', userId)
          .eq('status', 'active')
          .inFilter('role', ['owner', 'admin', 'moderator']);

      return response.isNotEmpty;
    } catch (e) {
      ProductionLogger.info('Error checking club management access: $e', tag: 'club_permission_service');
      return false;
    }
  }
}
