import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rank_request.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class RankVerificationService {
  static RankVerificationService? _instance;
  static RankVerificationService get instance =>
      _instance ??= RankVerificationService._();

  RankVerificationService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Lấy danh sách các yêu cầu xác minh hạng cho club
  Future<List<RankRequest>> getPendingRankRequests(String clubId) async {
    try {
      final response = await _supabase
          .from('rank_requests')
          .select('''
            *,
            user:users!rank_requests_user_id_fkey (
              id,
              full_name,
              username,
              avatar_url,
              email,
              skill_level,
              ranking_points,
              elo_rating
            )
          ''')
          .eq('club_id', clubId)
          .eq('status', 'pending')
          .order('requested_at', ascending: false);

      return response
          .map<RankRequest>((json) => RankRequest.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get pending rank requests: $error');
    }
  }

  /// Lấy tổng số yêu cầu đang chờ xử lý cho club
  Future<int> getPendingRequestsCount(String clubId) async {
    try {
      final response = await _supabase
          .from('rank_requests')
          .select('id')
          .eq('club_id', clubId)
          .eq('status', 'pending');

      return response.length;
    } catch (error) {
      return 0;
    }
  }

  /// Duyệt yêu cầu xác minh hạng
  Future<RankRequest> approveRankRequest(
    String requestId, {
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First, get the rank request details to extract club_id and user_id
      final rankRequest = await _supabase
          .from('rank_requests')
          .select('club_id, user_id')
          .eq('id', requestId)
          .single();

      final clubId = rankRequest['club_id'] as String;
      final targetUserId = rankRequest['user_id'] as String;

      // Update rank request status to approved
      final response = await _supabase
          .from('rank_requests')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': user.id,
            'notes': notes,
          })
          .eq('id', requestId)
          .select('''
            *,
            user:users!rank_requests_user_id_fkey (
              id,
              full_name,
              username,
              avatar_url,
              email,
              skill_level,
              ranking_points,
              elo_rating
            )
          ''')
          .single();

      // Auto-add user to club_members if not already a member
      try {
        // Check if user is already a member
        final existingMember = await _supabase
            .from('club_members')
            .select('id')
            .eq('club_id', clubId)
            .eq('user_id', targetUserId)
            .maybeSingle();

        if (existingMember == null) {
          // User is not a member yet, add them as a regular member
          await _supabase.from('club_members').insert({
            'club_id': clubId,
            'user_id': targetUserId,
            'role': 'member', // Regular member role
            'status': 'active',
            'joined_at': DateTime.now().toIso8601String(),
            'permissions': {
              'view_tournaments': true,
              'join_tournaments': true,
              'view_members': true,
              'view_posts': true,
              'create_posts': true,
            },
          });

          ProductionLogger.info('✅ Auto-added user $targetUserId to club $clubId as member', tag: 'rank_verification_service');
        } else {
          ProductionLogger.info('ℹ️ User $targetUserId is already a member of club $clubId', tag: 'rank_verification_service');
        }
      } catch (memberError) {
        // Log error but don't fail the approval process
        ProductionLogger.info('⚠️ Failed to auto-add user to club: $memberError', tag: 'rank_verification_service');
      }

      return RankRequest.fromJson(response);
    } catch (error) {
      throw Exception('Failed to approve rank request: $error');
    }
  }

  /// Từ chối yêu cầu xác minh hạng
  Future<RankRequest> rejectRankRequest(
    String requestId,
    String rejectionReason,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('rank_requests')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': user.id,
            'rejection_reason': rejectionReason,
          })
          .eq('id', requestId)
          .select('''
            *,
            user:users!rank_requests_user_id_fkey (
              id,
              full_name,
              username,
              avatar_url,
              email,
              skill_level,
              ranking_points,
              elo_rating
            )
          ''')
          .single();

      return RankRequest.fromJson(response);
    } catch (error) {
      throw Exception('Failed to reject rank request: $error');
    }
  }

  /// Lấy tất cả yêu cầu xác minh hạng cho club (bao gồm cả đã xử lý)
  Future<List<RankRequest>> getAllRankRequests(String clubId) async {
    try {
      final response = await _supabase
          .from('rank_requests')
          .select('''
            *,
            user:users!rank_requests_user_id_fkey (
              id,
              full_name,
              username,
              avatar_url,
              email,
              skill_level,
              ranking_points,
              elo_rating
            )
          ''')
          .eq('club_id', clubId)
          .order('requested_at', ascending: false);

      return response
          .map<RankRequest>((json) => RankRequest.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get all rank requests: $error');
    }
  }
}
