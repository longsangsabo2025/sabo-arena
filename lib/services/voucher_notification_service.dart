import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class VoucherNotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Gửi yêu cầu sử dụng voucher đến club
  static Future<Map<String, dynamic>> requestVoucherUsage({
    required String voucherCode,
    required String clubId,
    required String userEmail,
    required String userName,
  }) async {
    try {
      // 1. Kiểm tra voucher có tồn tại và chưa sử dụng
      final voucherCheck = await _supabase
          .from('spa_reward_redemptions')
          .select('*')
          .eq('voucher_code', voucherCode)  // Fixed: use voucher_code not redemption_code
          .eq('club_id', clubId)
          .maybeSingle();

      if (voucherCheck == null) {
        return {
          'success': false,
          'message': 'Voucher không tồn tại hoặc đã được sử dụng'
        };
      }

      // 2. Tạo notification cho club (using correct table structure)
      await _supabase.from('notifications').insert({
        'club_id': clubId,  // Direct club_id column
        'type': 'voucher_usage_request', 
        'title': 'Yêu cầu sử dụng voucher',
        'message': '$userName muốn sử dụng voucher $voucherCode (${voucherCheck['spa_spent']} SPA)',
        'data': {
          'voucher_code': voucherCode,
          'user_email': userEmail,
          'user_name': userName,
          'redemption_id': voucherCheck['id'],
          'spa_spent': voucherCheck['spa_spent'],
          'voucher_value': voucherCheck['spa_spent'], // For display
          'voucher_type': 'spa_redemption',
        },
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3. Cập nhật trạng thái voucher - đánh dấu đã gửi yêu cầu đến club
      try {
        await _supabase
            .from('spa_reward_redemptions')
            .update({'status': 'approved'})  // Status: claimed -> approved (đã gửi, chờ club confirm)
            .eq('voucher_code', voucherCode);
      } catch (e) {
        // Ignore if status column doesn't exist yet - không ảnh hưởng notification
        ProductionLogger.info('Info: Could not update voucher status: $e', tag: 'voucher_notification_service');
      }

      return {
        'success': true,
        'message': 'Đã gửi yêu cầu đến club. Vui lòng chờ xác nhận.',
        'voucher_data': voucherCheck
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi gửi yêu cầu: $e'
      };
    }
  }

  /// Lấy danh sách yêu cầu voucher chưa xử lý cho club
  static Future<List<Map<String, dynamic>>> getPendingVoucherRequests(String clubId) async {
    try {
      // Fixed: Use correct table structure - notifications table uses club_id directly
      final notifications = await _supabase
          .from('notifications')
          .select('*')
          .eq('club_id', clubId)  // Use club_id instead of recipient_id
          .eq('type', 'voucher_usage_request')
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return notifications.cast<Map<String, dynamic>>();
    } catch (e) {
      ProductionLogger.info('Error getting pending voucher requests: $e', tag: 'voucher_notification_service');
      return [];
    }
  }

  /// Club xác nhận sử dụng voucher
  static Future<Map<String, dynamic>> approveVoucherUsage({
    required String voucherCode,
    required String clubId,
  }) async {
    try {
      // 1. Kiểm tra và lấy thông tin voucher
      final voucher = await _supabase
          .from('user_vouchers')
          .select('*, user_email, voucher_value')
          .eq('voucher_code', voucherCode)
          .eq('club_id', clubId)
          .eq('status', 'pending_approval')
          .single();

      final userEmail = voucher['user_email'] as String;
      final voucherValue = voucher['voucher_value'] as int;

      // 2. Đánh dấu voucher đã sử dụng (KHÔNG cộng SPA - user đã trả SPA để có voucher)
      await _supabase
          .from('user_vouchers')
          .update({
            'is_used': true,
            'used_at': DateTime.now().toIso8601String(),
            'status': 'used',
          })
          .eq('voucher_code', voucherCode);

      // 3. Cập nhật notification thành đã đọc  
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('club_id', clubId)
          .eq('type', 'voucher_usage_request')
          .contains('data', {'voucher_code': voucherCode});

      // 4. Tạo thông báo cho user
      await _supabase.from('user_notifications').insert({
        'user_email': userEmail,
        'notification_type': 'voucher_approved',
        'title': 'Voucher đã được xác nhận',
        'message': 'Voucher $voucherValue SPA đã được sử dụng thành công tại club',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Đã xác nhận sử dụng voucher thành công'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi xác nhận voucher: $e'
      };
    }
  }

  /// Club từ chối sử dụng voucher
  static Future<Map<String, dynamic>> rejectVoucherUsage({
    required String voucherCode,
    required String clubId,
    required String reason,
  }) async {
    try {
      // 1. Lấy thông tin voucher
      final voucher = await _supabase
          .from('user_vouchers')
          .select('*')
          .eq('voucher_code', voucherCode)
          .eq('club_id', clubId)
          .single();

      // 2. Đặt lại trạng thái voucher
      await _supabase
          .from('user_vouchers')
          .update({'status': 'active'})
          .eq('voucher_code', voucherCode);

      // 3. Cập nhật notification thành đã đọc
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('club_id', clubId)
          .eq('type', 'voucher_usage_request')
          .contains('data', {'voucher_code': voucherCode});

      // 4. Thông báo cho user
      await _supabase.from('user_notifications').insert({
        'user_email': voucher['user_email'],
        'notification_type': 'voucher_rejected',
        'title': 'Yêu cầu voucher bị từ chối',
        'message': 'Lý do: $reason',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Đã từ chối yêu cầu voucher'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi từ chối voucher: $e'
      };
    }
  }

  /// Lấy lịch sử voucher của club
  static Future<List<Map<String, dynamic>>> getClubVoucherHistory(String clubId) async {
    try {
      final response = await _supabase
          .from('user_vouchers')
          .select('*')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.info('Error getting club voucher history: $e', tag: 'voucher_notification_service');
      return [];
    }
  }
}