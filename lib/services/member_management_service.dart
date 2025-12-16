import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class MemberManagementService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ====================================
  // CLUB MEMBERSHIPS MANAGEMENT
  // ====================================

  /// Get all members for a specific club
  static Future<List<Map<String, dynamic>>> getClubMembers({
    required String clubId,
    String? status,
    String? membershipType,
    int? limit,
    int? offset,
  }) async {
    try {
      ProductionLogger.info('🔍 MemberManagementService: Getting members for club $clubId', tag: 'member_management_service');
      ProductionLogger.info('🔍 Status filter: $status, Role filter: $membershipType', tag: 'member_management_service');

      var query = _supabase.from('club_members').select('*, users(*)');

      query = query.eq('club_id', clubId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (membershipType != null) {
        query = query.eq(
          'role',
          membershipType,
        ); // Use role instead of membership_type
      }

      final response = await query;
      ProductionLogger.info('✅ MemberManagementService: Found ${response.length} members', tag: 'member_management_service');

      if (limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = startIndex + limit;
        if (response.length > startIndex) {
          return List<Map<String, dynamic>>.from(
            response.sublist(startIndex, endIndex.clamp(0, response.length)),
          );
        }
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching club members: $e');
    }
  }

  /// Add a new member to the club
  static Future<Map<String, dynamic>> addClubMember({
    required String clubId,
    required String userId,
    String membershipType = 'regular',
    String status = 'active',
    bool autoRenewal = false,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final data = {
        'club_id': clubId,
        'user_id': userId,
        'membership_type': membershipType,
        'status': status,
        'auto_renewal': autoRenewal,
        'permissions':
            permissions ??
            {
              'tournaments': true,
              'posts': true,
              'chat': true,
              'invite': false,
              'contact': false,
            },
        'joined_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('club_members')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error adding club member: $e');
    }
  }

  /// Update an existing member's information
  static Future<Map<String, dynamic>> updateClubMember({
    required String membershipId,
    String? membershipType,
    String? status,
    bool? autoRenewal,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (membershipType != null) data['membership_type'] = membershipType;
      if (status != null) data['status'] = status;
      if (autoRenewal != null) data['auto_renewal'] = autoRenewal;
      if (permissions != null) data['permissions'] = permissions;

      final response = await _supabase
          .from('club_members')
          .update(data)
          .eq('id', membershipId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error updating club member: $e');
    }
  }

  /// Remove a member from the club
  static Future<void> removeClubMember(String membershipId) async {
    try {
      await _supabase.from('club_members').delete().eq('id', membershipId);
    } catch (e) {
      throw Exception('Error removing club member: $e');
    }
  }

  /// Get membership requests for a club
  static Future<List<Map<String, dynamic>>> getMembershipRequests({
    required String clubId,
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('membership_requests')
          .select('*, users(*)')
          .eq('club_id', clubId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;

      if (limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = startIndex + limit;
        if (response.length > startIndex) {
          return List<Map<String, dynamic>>.from(
            response.sublist(startIndex, endIndex.clamp(0, response.length)),
          );
        }
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching membership requests: $e');
    }
  }

  /// Approve a membership request
  static Future<Map<String, dynamic>> approveMembershipRequest({
    required String requestId,
    String membershipType = 'regular',
  }) async {
    try {
      // First get the request details
      final request = await _supabase
          .from('membership_requests')
          .select('*')
          .eq('id', requestId)
          .single();

      // Create club membership
      final membership = await addClubMember(
        clubId: request['club_id'],
        userId: request['user_id'],
        membershipType: membershipType,
      );

      // Update request status
      await _supabase
          .from('membership_requests')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      return membership;
    } catch (e) {
      throw Exception('Error approving membership request: $e');
    }
  }

  /// Reject a membership request
  static Future<void> rejectMembershipRequest(String requestId) async {
    try {
      await _supabase
          .from('membership_requests')
          .update({
            'status': 'rejected',
            'rejected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Error rejecting membership request: $e');
    }
  }

  /// Get member analytics for a club
  static Future<Map<String, dynamic>> getMemberAnalytics(String clubId) async {
    try {
      final members = await getClubMembers(clubId: clubId);

      final totalMembers = members.length;
      final activeMembers = members
          .where((m) => m['status'] == 'active')
          .length;

      // Calculate new members this month
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final newThisMonth = members.where((m) {
        final joinedAt = DateTime.parse(
          m['joined_at'] ?? now.toIso8601String(),
        );
        return joinedAt.isAfter(thisMonthStart);
      }).length;

      return {
        'total_members': totalMembers,
        'active_members': activeMembers,
        'new_this_month': newThisMonth,
        'growth_rate': totalMembers > 0
            ? (newThisMonth / totalMembers * 100)
            : 0.0,
      };
    } catch (e) {
      throw Exception('Error fetching member analytics: $e');
    }
  }

  /// Search members by name or email
  static Future<List<Map<String, dynamic>>> searchMembers({
    required String clubId,
    required String searchQuery,
    int? limit,
  }) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .or(
            'users.display_name.ilike.%$searchQuery%,users.email.ilike.%$searchQuery%',
          );

      if (limit != null && response.length > limit) {
        return List<Map<String, dynamic>>.from(response.sublist(0, limit));
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error searching members: $e');
    }
  }

  /// Get member count by role/type
  static Future<Map<String, int>> getMemberCountByType(String clubId) async {
    try {
      final members = await getClubMembers(clubId: clubId);

      final counts = <String, int>{};
      for (final member in members) {
        final type = member['membership_type'] ?? 'regular';
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Error fetching member count by type: $e');
    }
  }

  // ====================================
  // MISSING METHODS IMPLEMENTATION
  // ====================================

  /// Bulk update multiple members
  static Future<Map<String, dynamic>> bulkUpdateMembers(
    List<String> memberIds,
    Map<String, dynamic> updates,
  ) async {
    try {
      final results = <String, dynamic>{};

      for (String memberId in memberIds) {
        try {
          final member = await updateClubMember(
            membershipId: memberId,
            membershipType: updates['membershipType'],
            status: updates['status'],
            autoRenewal: updates['autoRenewal'],
          );
          results[memberId] = member;
        } catch (e) {
          results[memberId] = {'error': e.toString()};
        }
      }

      return results;
    } catch (e) {
      throw Exception('Error bulk updating members: $e');
    }
  }

  /// Create membership request
  static Future<Map<String, dynamic>> createMembershipRequest({
    required String clubId,
    required String requestedBy,
    required String membershipType,
    String? message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final data = {
        'club_id': clubId,
        'requested_by': requestedBy,
        'membership_type': membershipType,
        'message': message,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'additional_data': additionalData,
      };

      final response = await _supabase
          .from('membership_requests')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error creating membership request: $e');
    }
  }

  /// Update membership request status
  static Future<bool> updateMembershipRequestStatus(
    String requestId,
    String status, {
    String? processedBy,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'processed_at': DateTime.now().toIso8601String(),
      };

      if (processedBy != null) data['processed_by'] = processedBy;
      if (notes != null) data['notes'] = notes;

      await _supabase
          .from('membership_requests')
          .update(data)
          .eq('id', requestId);

      return true;
    } catch (e) {
      throw Exception('Error updating membership request status: $e');
    }
  }

  /// Get user notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching user notifications: $e');
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for user
  static Future<bool> markAllNotificationsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .isFilter('read_at', null);

      return true;
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  /// Create notification
  static Future<void> createNotification({
    required String clubId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
    List<String>? recipientIds,
  }) async {
    try {
      final baseData = {
        'club_id': clubId,
        'type': type,
        'title': title,
        'message': message,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (recipientIds != null && recipientIds.isNotEmpty) {
        // Send to specific users
        final notifications = recipientIds
            .map((userId) => {...baseData, 'user_id': userId})
            .toList();

        await _supabase.from('notifications').insert(notifications);
      } else {
        // Send to all club members
        final members = await getClubMembers(clubId: clubId);
        final notifications = members
            .map((member) => {...baseData, 'user_id': member['user_id']})
            .toList();

        await _supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  /// Get member activities
  static Future<List<Map<String, dynamic>>> getMemberActivities(
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('member_activities')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching member activities: $e');
    }
  }

  /// Create member activity log
  static Future<void> createMemberActivity({
    required String clubId,
    required String userId,
    required String action,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final data = {
        'club_id': clubId,
        'user_id': userId,
        'action': action,
        'description': description,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('member_activities').insert(data);
    } catch (e) {
      throw Exception('Error creating member activity: $e');
    }
  }

  /// Register current user as member of a club
  Future<Map<String, dynamic>> registerMember({
    required String clubId,
    String membershipType = 'premium',
  }) async {
    try {
      // Get current user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to register as member');
      }

      // Check if user is already a member
      final existingMember = await _supabase
          .from('club_members')
          .select()
          .eq('club_id', clubId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('You are already a member of this club');
      }

      // Add as new member - only use columns that exist in the table
      final memberData = {
        'club_id': clubId,
        'user_id': currentUser.id,
        'role': membershipType,
        'status': 'active',
        'joined_at': DateTime.now().toIso8601String(),
        'is_favorite': false,
      };

      final response = await _supabase
          .from('club_members')
          .insert(memberData)
          .select('*, users(*)')
          .single();

      ProductionLogger.info('✅ MemberManagementService: Successfully registered member for club $clubId',  tag: 'member_management_service');

      try {
        final club = await _supabase
            .from('clubs')
            .select('name')
            .eq('id', clubId)
            .maybeSingle();
        final clubName = (club != null
            ? (club['name'] as String? ?? 'CLB')
            : 'CLB');
        await NotificationService.instance.sendJoinedClubNotification(
          userId: currentUser.id,
          clubId: clubId,
          clubName: clubName,
        );
      } catch (_) {
        // ignore notification errors
      }
      return response;
    } catch (e) {
      ProductionLogger.info('❌ MemberManagementService: Error registering member: $e', tag: 'member_management_service');
      throw Exception('Error registering as member: $e');
    }
  }
}
