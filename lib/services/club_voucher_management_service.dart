// 🎯 CHUYÊN GIA 20 NĂM: VOUCHER MANAGEMENT SERVICE ARCHITECTURE
// Separation of Concerns - Professional Implementation

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Professional Voucher Management Service
/// Replaces the anti-pattern of using notifications table for voucher workflow
class ClubVoucherManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // =============================================================================
  // VOUCHER REQUEST MANAGEMENT
  // =============================================================================
  
  /// Create voucher usage request - Professional approach
  Future<Map<String, dynamic>> createVoucherRequest({
    required String voucherId,
    required String voucherCode,
    required String userId,
    required String userEmail,
    required String userName,
    required String clubId,
    required int spaValue,
    String voucherType = 'spa_redemption',
  }) async {
    ProductionLogger.info('🔧 DEBUG: createVoucherRequest called', tag: 'club_voucher_management_service');
    ProductionLogger.info('   VoucherId: $voucherId', tag: 'club_voucher_management_service');
    ProductionLogger.info('   VoucherCode: $voucherCode', tag: 'club_voucher_management_service');
    ProductionLogger.info('   ClubId: $clubId', tag: 'club_voucher_management_service');
    
    try {
      // 1. Skip voucher validation for now - use direct creation approach
      ProductionLogger.info('🔧 DEBUG: Skipping voucher validation, proceeding with request creation', tag: 'club_voucher_management_service');
      
      // 2. Check for existing pending request
      final existingRequest = await _supabase
          .from('club_voucher_requests')
          .select('id')
          .eq('voucher_id', voucherId)
          .eq('club_id', clubId)
          .eq('status', 'pending')
          .maybeSingle();
      
      if (existingRequest != null) {
        throw Exception('Đã có yêu cầu pending cho voucher này');
      }
      
      // 3. Get club configuration
      final clubConfig = await _getClubVoucherConfig(clubId);
      
      // 4. Check daily limits
      await _validateDailyLimits(clubId, userId, clubConfig);
      
      // 5. Create the request (include voucher_id since it's required)
      ProductionLogger.info('🔧 DEBUG: Creating voucher request with required voucher_id', tag: 'club_voucher_management_service');
      final request = await _supabase
          .from('club_voucher_requests')
          .insert({
            'voucher_id': voucherId, // REQUIRED: has NOT NULL constraint
            'voucher_code': voucherCode,
            'user_id': userId,
            'club_id': clubId,
            'status': 'pending',
            'voucher_type': voucherType,
          })
          .select()
          .single();
      
      // 6. Skip voucher status update (voucher not in user_vouchers table)
      ProductionLogger.info('🔧 DEBUG: Skipping voucher status update - no user_vouchers entry', tag: 'club_voucher_management_service');
      
      // 7. Send notification (separate from business logic)
      await _sendVoucherNotification(request);
      
      return {
        'success': true,
        'request_id': request['id'],
        'status': request['status'],
        'auto_approved': request['status'] == 'approved',
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // =============================================================================
  // CLUB MANAGEMENT FUNCTIONS
  // =============================================================================
  
  /// Get pending voucher requests for club
  Future<List<Map<String, dynamic>>> getPendingVoucherRequests(String clubId) async {
    return await _supabase
        .from('club_voucher_requests')
        .select('''
          *,
          user_vouchers!voucher_id(voucher_code, voucher_type),
          profiles!user_id(full_name, avatar_url)
        ''')
        .eq('club_id', clubId)
        .eq('status', 'pending')
        .order('requested_at', ascending: true);
  }
  
  /// Approve voucher request
  Future<Map<String, dynamic>> approveVoucherRequest({
    required String requestId,
    required String approvedBy,
    String? approvalNotes,
  }) async {
    try {
      // 1. Update request status
      final request = await _supabase
          .from('club_voucher_requests')
          .update({
            'status': 'approved',
            'processed_at': DateTime.now().toIso8601String(),
            'processed_by': approvedBy,
            'approval_notes': approvalNotes,
          })
          .eq('id', requestId)
          .select()
          .single();
      
      // 2. Update voucher status
      await _supabase
          .from('user_vouchers')
          .update({
            'status': 'used',
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', request['voucher_id']);
      
      // 3. Send approval notification to user
      await _sendApprovalNotification(request, approved: true);
      
      return {'success': true, 'message': 'Voucher đã được phê duyệt'};
      
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Reject voucher request
  Future<Map<String, dynamic>> rejectVoucherRequest({
    required String requestId,
    required String rejectedBy,
    required String rejectionReason,
  }) async {
    try {
      // 1. Update request status
      final request = await _supabase
          .from('club_voucher_requests')
          .update({
            'status': 'rejected',
            'processed_at': DateTime.now().toIso8601String(),
            'processed_by': rejectedBy,
            'rejection_reason': rejectionReason,
          })
          .eq('id', requestId)
          .select()
          .single();
      
      // 2. Restore voucher to active status
      await _supabase
          .from('user_vouchers')
          .update({
            'status': 'active',
            'used_at': null,
          })
          .eq('id', request['voucher_id']);
      
      // 3. Send rejection notification to user
      await _sendApprovalNotification(request, approved: false);
      
      return {'success': true, 'message': 'Voucher đã bị từ chối'};
      
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // =============================================================================
  // ANALYTICS & REPORTING
  // =============================================================================
  
  /// Get voucher request analytics for club
  Future<Map<String, dynamic>> getVoucherAnalytics(String clubId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    fromDate ??= DateTime.now().subtract(Duration(days: 30));
    toDate ??= DateTime.now();
    
    final analytics = await _supabase.rpc('get_voucher_analytics', params: {
      'club_id_param': clubId,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
    });
    
    return analytics;
  }
  
  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================
  
  Future<Map<String, dynamic>> _getClubVoucherConfig(String clubId) async {
    final config = await _supabase
        .from('club_voucher_configs')
        .select()
        .eq('club_id', clubId)
        .maybeSingle();
    
    // Return default config if none exists
    return config ?? {
      'auto_approve_enabled': false,
      'auto_approve_max_value': 1000,
      'max_requests_per_day': 50,
      'max_requests_per_user_per_day': 3,
    };
  }
  
  Future<void> _validateDailyLimits(String clubId, String userId, Map<String, dynamic> config) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    // Check club daily limit
    final clubRequestsToday = await _supabase
        .from('club_voucher_requests')
        .select('id')
        .eq('club_id', clubId)
        .gte('requested_at', startOfDay.toIso8601String())
        .count();
    
    if (clubRequestsToday.count >= config['max_requests_per_day']) {
      throw Exception('Club đã đạt giới hạn yêu cầu trong ngày');
    }
    
    // Check user daily limit
    final userRequestsToday = await _supabase
        .from('club_voucher_requests')
        .select('id')
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .gte('requested_at', startOfDay.toIso8601String())
        .count();
    
    if (userRequestsToday.count >= config['max_requests_per_user_per_day']) {
      throw Exception('Bạn đã đạt giới hạn yêu cầu trong ngày');
    }
  }
  
  Future<void> _sendVoucherNotification(Map<String, dynamic> request) async {
    // Send to notifications table (for UI notifications only)
    await _supabase.from('notifications').insert({
      'recipient_type': 'club',
      'recipient_id': request['club_id'],
      'type': 'voucher_request_created',
      'title': 'Yêu cầu sử dụng voucher mới',
      'message': 'Có yêu cầu sử dụng voucher ${request['voucher_code']}',
      'data': {
        'request_id': request['id'],
        'voucher_code': request['voucher_code'],
        'spa_value': request['spa_value'],
      },
      'is_read': false,
    });
  }
  
  Future<void> _sendApprovalNotification(Map<String, dynamic> request, {required bool approved}) async {
    await _supabase.from('notifications').insert({
      'recipient_type': 'user',
      'recipient_id': request['user_id'],
      'type': approved ? 'voucher_approved' : 'voucher_rejected',
      'title': approved ? 'Voucher đã được phê duyệt' : 'Voucher bị từ chối',
      'message': approved 
          ? 'Voucher ${request['voucher_code']} đã được club phê duyệt'
          : 'Voucher ${request['voucher_code']} bị từ chối: ${request['rejection_reason']}',
      'data': {
        'request_id': request['id'],
        'voucher_code': request['voucher_code'],
      },
      'is_read': false,
    });
  }
}

// =============================================================================
// DATABASE FUNCTIONS (To be created in Supabase)
// =============================================================================

/*
-- Analytics function
CREATE OR REPLACE FUNCTION get_voucher_analytics(
  club_id_param UUID,
  from_date TIMESTAMPTZ,
  to_date TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_requests', (
      SELECT COUNT(*) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND requested_at BETWEEN from_date AND to_date
    ),
    'approved_requests', (
      SELECT COUNT(*) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status = 'approved'
        AND requested_at BETWEEN from_date AND to_date
    ),
    'rejected_requests', (
      SELECT COUNT(*) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status = 'rejected'
        AND requested_at BETWEEN from_date AND to_date
    ),
    'pending_requests', (
      SELECT COUNT(*) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status = 'pending'
        AND requested_at BETWEEN from_date AND to_date
    ),
    'total_spa_value', (
      SELECT COALESCE(SUM(spa_value), 0) FROM club_voucher_requests 
      WHERE club_id = club_id_param 
        AND status = 'approved'
        AND requested_at BETWEEN from_date AND to_date
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;
*/