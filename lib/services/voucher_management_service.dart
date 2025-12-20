import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service quản lý voucher xác thực từ phía quán
/// Handles voucher verification and redemption by club staff
class VoucherManagementService {
  static final VoucherManagementService _instance =
      VoucherManagementService._internal();
  factory VoucherManagementService() => _instance;
  VoucherManagementService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Verify voucher code for club staff
  /// Kiểm tra voucher code có hợp lệ cho quán này không
  Future<Map<String, dynamic>> verifyVoucherCode(
    String voucherCode,
    String clubId,
  ) async {
    try {
      // Tìm voucher với code này cho quán này
      final response = await _supabase
          .from('user_vouchers')
          .select('''
            *,
            users!inner(
              id,
              username,
              email
            ),
            clubs!inner(
              id,
              name
            ),
            tournaments(
              id,
              name,
              status
            )
          ''')
          .eq('voucher_code', voucherCode)
          .eq('club_id', clubId)
          .eq('is_used', false) // Chỉ lấy voucher chưa sử dụng
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'error':
              'Mã voucher không tồn tại, đã được sử dụng, hoặc không thuộc quán này',
        };
      }

      // Kiểm tra hạn sử dụng
      if (response['expires_at'] != null) {
        final expiryDate = DateTime.parse(response['expires_at']);
        if (DateTime.now().isAfter(expiryDate)) {
          return {
            'success': false,
            'error': 'Mã voucher đã hết hạn sử dụng',
          };
        }
      }

      return {
        'success': true,
        'voucher': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi hệ thống khi kiểm tra mã voucher',
      };
    }
  }

  /// Use voucher - Mark as used and remove from system
  /// Sử dụng voucher - Đánh dấu đã dùng và cập nhật UI người dùng
  Future<Map<String, dynamic>> useVoucher(
    String voucherCode,
    String clubId,
  ) async {
    try {
      // Verify voucher trước khi sử dụng
      final verification = await verifyVoucherCode(voucherCode, clubId);
      if (verification['success'] != true) {
        return verification;
      }

      final voucherData = verification['voucher'];

      // Cập nhật voucher thành đã sử dụng
      await _supabase
          .from('user_vouchers')
          .update({
            'is_used': true,
            'used_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('voucher_code', voucherCode)
          .eq('club_id', clubId);

      // Tạo log sử dụng voucher (optional)
      try {
        await _supabase.from('voucher_usage_history').insert({
          'voucher_id': voucherData['id'],
          'user_id': voucherData['user_id'],
          'club_id': clubId,
          // 'voucher_code': voucherCode, // Column might not exist in history, check schema if needed
          // 'voucher_type': voucherData['voucher_type'],
          // 'voucher_value': voucherData['voucher_value'],
          // 'used_by_staff': true,
          'used_at': DateTime.now().toIso8601String(),
          'session_id': 'manual_redemption', // Required field based on schema
          'original_amount': 0, // Default values
          'discount_amount': 0,
          'final_amount': 0,
        });
      } catch (logError) {
        // Continue anyway - log failure shouldn't block voucher usage
      }

      return {
        'success': true,
        'message': 'Voucher đã được sử dụng thành công',
        'voucher': voucherData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi hệ thống khi sử dụng voucher',
      };
    }
  }

  /// Get pending vouchers for club
  /// Lấy danh sách voucher chưa sử dụng của quán
  Future<List<Map<String, dynamic>>> getPendingVouchers(String clubId) async {
    try {
      final response = await _supabase
          .from('user_vouchers')
          .select('''
            *,
            users!inner(
              id,
              username,
              email
            ),
            tournaments(
              id,
              name,
              status
            )
          ''')
          .eq('club_id', clubId)
          .eq('is_used', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get voucher usage history for club
  /// Lấy lịch sử sử dụng voucher của quán
  Future<List<Map<String, dynamic>>> getVoucherHistory(
    String clubId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('user_vouchers')
          .select('''
            *,
            users!inner(
              id,
              username,
              email
            ),
            tournaments(
              id,
              name,
              status
            )
          ''')
          .eq('club_id', clubId)
          .eq('is_used', true)
          .order('used_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get all vouchers for club (both used and unused)
  /// Lấy tất cả voucher của quán để thống kê
  Future<Map<String, dynamic>> getVoucherStats(String clubId) async {
    try {
      // Get all vouchers
      final allVouchers = await _supabase
          .from('user_vouchers')
          .select('*')
          .eq('club_id', clubId);

      // Calculate stats
      final total = allVouchers.length;
      final used = allVouchers.where((v) => v['is_used'] == true).length;
      final pending = total - used;

      // Calculate total value
      final totalValue = allVouchers.fold<double>(
        0.0,
        (sum, voucher) => sum + (voucher['voucher_value'] ?? 0.0),
      );

      final usedValue =
          allVouchers.where((v) => v['is_used'] == true).fold<double>(
                0.0,
                (sum, voucher) => sum + (voucher['voucher_value'] ?? 0.0),
              );

      return {
        'success': true,
        'stats': {
          'total_vouchers': total,
          'used_vouchers': used,
          'pending_vouchers': pending,
          'total_value': totalValue,
          'used_value': usedValue,
          'pending_value': totalValue - usedValue,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi khi lấy thống kê voucher',
      };
    }
  }
}
