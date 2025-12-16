import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX // For debugPrint

class AdminRankApprovalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Approve or reject rank request using stored functions (bypasses RLS issues)
  Future<Map<String, dynamic>> approveRankRequest({
    required String requestId,
    required bool approved,
    String? comments,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      if (approved) {
        // Use stored function to approve rank request
        final response = await _supabase.rpc(
          'admin_approve_rank_change_request',
          params: {
            'p_request_id': requestId,
            'p_approved': true,
            'p_comments': comments,
          },
        );

        if (response is Map && response['success'] == true) {
          return {
            'success': true,
            'message': response['message'] ?? 'Request approved successfully',
            'status': response['status'],
          };
        } else {
          return {
            'success': false,
            'error': response['error'] ?? 'Failed to approve request',
          };
        }
      } else {
        // Use stored function to reject rank request
        final response = await _supabase.rpc(
          'admin_approve_rank_change_request',
          params: {
            'p_request_id': requestId,
            'p_approved': false,
            'p_comments': comments ?? 'No reason provided',
          },
        );

        if (response is Map && response['success'] == true) {
          return {
            'success': true,
            'message': response['message'] ?? 'Request rejected successfully',
          };
        } else {
          return {
            'success': false,
            'error': response['error'] ?? 'Failed to reject request',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Database error: ${e.toString()}'};
    }
  }

  /// Get pending rank requests for the current club owner or admin
  Future<List<Map<String, dynamic>>> getPendingRankRequests() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Check if user is system admin
      final userResponse = await _supabase
          .from('users')
          .select('role')
          .eq('id', currentUserId)
          .single();

      final isSystemAdmin = userResponse['role'] == 'admin';

      if (isSystemAdmin) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        // System admin: Get ALL pending requests from rank_requests table
        final response = await _supabase
            .from('rank_requests')
            .select('''
              *,
              users!rank_requests_user_id_fkey (
                id,
                full_name,
                display_name,
                email,
                avatar_url,
                rank
              ),
              clubs!rank_requests_club_id_fkey (
                id,
                name
              )
            ''')
            .eq('status', 'pending')
            .order('requested_at', ascending: false);

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return List<Map<String, dynamic>>.from(response);
      } else {
        // Club owner: Get requests for their club
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        // First, find which club this user owns
        final clubResponse = await _supabase
            .from('clubs')
            .select('id, name')
            .eq('owner_id', currentUserId)
            .maybeSingle();

        if (clubResponse == null) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          return []; // Not a club owner
        }

        final clubId = clubResponse['id'];
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Get pending rank_requests for this club
        final response = await _supabase
            .from('rank_requests')
            .select('''
              *,
              users!rank_requests_user_id_fkey (
                id,
                full_name,
                display_name,
                email,
                avatar_url,
                rank
              )
            ''')
            .eq('club_id', clubId)
            .eq('status', 'pending')
            .order('requested_at', ascending: false);

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Failed to load rank requests: $e');
    }
  }

  /// Get the current user's club information
  Future<Map<String, dynamic>?> getCurrentUserClub() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('club_members')
          .select('''
            role,
            clubs!inner(
              id,
              name,
              description
            )
          ''')
          .eq('user_id', currentUserId)
          .eq('role', 'owner')
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get approved/rejected rank requests for the current club owner or admin
  Future<List<Map<String, dynamic>>> getApprovedRankRequests() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Check if user is system admin
      final userResponse = await _supabase
          .from('users')
          .select('role')
          .eq('id', currentUserId)
          .single();

      final isSystemAdmin = userResponse['role'] == 'admin';

      if (isSystemAdmin) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        // System admin: Get ALL approved/rejected requests
        final response = await _supabase
            .from('rank_requests')
            .select('''
              *,
              users!rank_requests_user_id_fkey (
                id,
                full_name,
                display_name,
                email,
                avatar_url,
                rank
              ),
              clubs!rank_requests_club_id_fkey (
                id,
                name
              )
            ''')
            .inFilter('status', ['approved', 'rejected'])
            .order('reviewed_at', ascending: false);

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return List<Map<String, dynamic>>.from(response);
      } else {
        // Club owner: Get requests for their club
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        // First, find which club this user owns
        final clubResponse = await _supabase
            .from('clubs')
            .select('id, name')
            .eq('owner_id', currentUserId)
            .maybeSingle();

        if (clubResponse == null) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          return []; // Not a club owner
        }

        final clubId = clubResponse['id'];
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Get approved/rejected rank_requests for this club
        final response = await _supabase
            .from('rank_requests')
            .select('''
              *,
              users!rank_requests_user_id_fkey (
                id,
                full_name,
                display_name,
                email,
                avatar_url,
                rank
              )
            ''')
            .eq('club_id', clubId)
            .inFilter('status', ['approved', 'rejected'])
            .order('reviewed_at', ascending: false);

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Failed to load approved rank requests: $e');
    }
  }
}

