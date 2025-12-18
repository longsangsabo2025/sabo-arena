import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service to handle payment refunds
class PaymentRefundService {
  static PaymentRefundService? _instance;
  static PaymentRefundService get instance =>
      _instance ??= PaymentRefundService._();
  PaymentRefundService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Request a refund for a payment transaction
  Future<Map<String, dynamic>> requestRefund({
    required String transactionId,
    required String reason,
    String? additionalNotes,
  }) async {
    try {

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get transaction details
      final transaction = await _supabase
          .from('payment_transactions')
          .select('*')
          .eq('id', transactionId)
          .single();

      // Validate refund eligibility
      final validationResult = _validateRefundEligibility(transaction);
      if (!validationResult['is_valid']) {
        throw Exception(validationResult['error']);
      }

      // Create refund request
      final refundRequest = await _supabase
          .from('refund_requests')
          .insert({
            'transaction_id': transactionId,
            'user_id': currentUser.id,
            'amount': transaction['amount'],
            'reason': reason,
            'additional_notes': additionalNotes,
            'status': 'pending',
            'requested_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return refundRequest;
    } catch (e) {
      rethrow;
    }
  }

  /// Validate if a transaction is eligible for refund
  Map<String, dynamic> _validateRefundEligibility(
    Map<String, dynamic> transaction,
  ) {
    // Check if already refunded
    if (transaction['status'] == 'refunded') {
      return {
        'is_valid': false,
        'error': 'This transaction has already been refunded',
      };
    }

    // Check if payment was successful
    if (transaction['status'] != 'completed') {
      return {
        'is_valid': false,
        'error': 'Only completed payments can be refunded',
      };
    }

    // Check refund window (30 days)
    final transactionDate = DateTime.parse(transaction['created_at'] as String);
    final daysSince = DateTime.now().difference(transactionDate).inDays;

    if (daysSince > 30) {
      return {
        'is_valid': false,
        'error': 'Refund window expired (30 days maximum)',
      };
    }

    return {'is_valid': true};
  }

  /// Get refund request status
  Future<Map<String, dynamic>?> getRefundStatus(String refundRequestId) async {
    try {
      final refund = await _supabase
          .from('refund_requests')
          .select('''
            *,
            transaction:payment_transactions(
              id,
              amount,
              payment_method,
              created_at
            ),
            reviewer:users!reviewed_by(
              display_name
            )
          ''')
          .eq('id', refundRequestId)
          .single();

      return refund;
    } catch (e) {
      return null;
    }
  }

  /// Get user's refund requests
  Future<List<Map<String, dynamic>>> getUserRefundRequests() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final refunds = await _supabase
          .from('refund_requests')
          .select('''
            *,
            transaction:payment_transactions(
              id,
              amount,
              payment_method,
              created_at
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('requested_at', ascending: false);

      return List<Map<String, dynamic>>.from(refunds);
    } catch (e) {
      return [];
    }
  }

  /// Admin: Get all pending refund requests
  Future<List<Map<String, dynamic>>> getPendingRefundRequests() async {
    try {
      final refunds = await _supabase
          .from('refund_requests')
          .select('''
            *,
            user:users!user_id(
              id,
              display_name,
              email
            ),
            transaction:payment_transactions(
              id,
              amount,
              payment_method,
              created_at
            )
          ''')
          .eq('status', 'pending')
          .order('requested_at', ascending: true);

      return List<Map<String, dynamic>>.from(refunds);
    } catch (e) {
      return [];
    }
  }

  /// Admin: Approve refund request
  Future<bool> approveRefund({
    required String refundRequestId,
    String? adminNotes,
  }) async {
    try {

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      // Get refund request details
      final refundRequest = await _supabase
          .from('refund_requests')
          .select('*, transaction:payment_transactions(*)')
          .eq('id', refundRequestId)
          .single();

      final transactionId = refundRequest['transaction_id'] as String;
      final amount = refundRequest['amount'] as num;
      final userId = refundRequest['user_id'] as String;

      // Process refund in transaction
      await _supabase.rpc(
        'process_refund',
        params: {
          'p_refund_request_id': refundRequestId,
          'p_transaction_id': transactionId,
          'p_user_id': userId,
          'p_amount': amount,
          'p_admin_id': currentUser.id,
          'p_admin_notes': adminNotes,
        },
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: Reject refund request
  Future<bool> rejectRefund({
    required String refundRequestId,
    required String rejectionReason,
  }) async {
    try {

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }

      await _supabase
          .from('refund_requests')
          .update({
            'status': 'rejected',
            'rejection_reason': rejectionReason,
            'reviewed_by': currentUser.id,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', refundRequestId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process VNPay refund (integration with VNPay API)
  Future<Map<String, dynamic>> processVNPayRefund({
    required String transactionId,
    required int amount,
    required String refundReason,
  }) async {
    try {
      // This is a placeholder for VNPay API integration
      // In production, you would call VNPay's refund API here


      // Simulated VNPay API response
      // Replace this with actual VNPay API call
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'refund_id': 'VNPAY_REFUND_${DateTime.now().millisecondsSinceEpoch}',
        'transaction_id': transactionId,
        'amount': amount,
        'status': 'processing',
        'message': 'Refund submitted to VNPay successfully',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Process MoMo refund (integration with MoMo API)
  Future<Map<String, dynamic>> processMoMoRefund({
    required String transactionId,
    required int amount,
    required String refundReason,
  }) async {
    try {

      // Placeholder for MoMo API integration
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'refund_id': 'MOMO_REFUND_${DateTime.now().millisecondsSinceEpoch}',
        'transaction_id': transactionId,
        'amount': amount,
        'status': 'processing',
        'message': 'Refund submitted to MoMo successfully',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Cancel refund request (before approval)
  Future<bool> cancelRefundRequest(String refundRequestId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Check if refund is still pending
      final refund = await _supabase
          .from('refund_requests')
          .select('status, user_id')
          .eq('id', refundRequestId)
          .single();

      if (refund['status'] != 'pending') {
        throw Exception('Can only cancel pending refund requests');
      }

      if (refund['user_id'] != currentUser.id) {
        throw Exception('Not authorized to cancel this refund');
      }

      await _supabase
          .from('refund_requests')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', refundRequestId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get refund statistics for admin dashboard
  Future<Map<String, dynamic>> getRefundStatistics() async {
    try {
      final allRefunds = await _supabase
          .from('refund_requests')
          .select('id, status, amount, requested_at');

      final totalRefunds = allRefunds.length;
      final pending = allRefunds.where((r) => r['status'] == 'pending').length;
      final approved = allRefunds
          .where((r) => r['status'] == 'approved')
          .length;
      final rejected = allRefunds
          .where((r) => r['status'] == 'rejected')
          .length;

      final totalAmount = allRefunds.fold<int>(
        0,
        (sum, r) => sum + ((r['amount'] as num?)?.toInt() ?? 0),
      );

      final approvedAmount = allRefunds
          .where((r) => r['status'] == 'approved')
          .fold<int>(
            0,
            (sum, r) => sum + ((r['amount'] as num?)?.toInt() ?? 0),
          );

      return {
        'total_refunds': totalRefunds,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'total_amount': totalAmount,
        'approved_amount': approvedAmount,
      };
    } catch (e) {
      return {};
    }
  }
}

