import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service xử lý thanh toán thực tế với Supabase
class RealPaymentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Lưu thông tin thanh toán vào database
  static Future<Map<String, dynamic>> createPaymentRecord({
    required String clubId,
    required String paymentMethod, // 'bank', 'momo', 'zalopay', etc.
    required Map<String, dynamic> paymentInfo,
    required double amount,
    required String description,
    String? invoiceId,
    String? userId,
  }) async {
    try {
      final paymentData = {
        'club_id': clubId,
        'user_id': userId,
        'invoice_id': invoiceId,
        'payment_method': paymentMethod,
        'payment_info': json.encode(paymentInfo),
        'amount': amount,
        'description': description,
        'status': 'pending', // pending, completed, failed
        'qr_data': null, // Sẽ update sau khi tạo QR
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('payments')
          .insert(paymentData)
          .select()
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error creating payment record: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Cập nhật QR data cho payment record
  static Future<void> updatePaymentQR({
    required String paymentId,
    required String qrData,
    String? qrImageUrl,
  }) async {
    try {
      await _supabase.from('payments').update(
          {'qr_data': qrData, 'qr_image_url': qrImageUrl}).eq('id', paymentId);
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error updating payment QR: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Xác nhận thanh toán (webhook từ ngân hàng/ví)
  static Future<void> confirmPayment({
    required String paymentId,
    required String transactionId,
    Map<String, dynamic>? webhookData,
  }) async {
    try {
      await _supabase.from('payments').update({
        'status': 'completed',
        'transaction_id': transactionId,
        'webhook_data': webhookData != null ? json.encode(webhookData) : null,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

      // Cập nhật số dư CLB nếu cần
      await _updateClubBalance(paymentId);
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error confirming payment: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Cập nhật số dư CLB sau khi thanh toán thành công
  static Future<void> _updateClubBalance(String paymentId) async {
    try {
      // Lấy thông tin payment
      final payment = await _supabase
          .from('payments')
          .select('club_id, amount')
          .eq('id', paymentId)
          .single();

      // Cập nhật balance CLB
      await _supabase.rpc(
        'update_club_balance',
        params: {
          'p_club_id': payment['club_id'],
          'p_amount': payment['amount'],
        },
      );
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error updating club balance: $e',
            tag: 'real_payment_service');
      }
    }
  }

  /// Lấy lịch sử thanh toán
  static Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String clubId,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase.from('payments').select('''
            id, amount, description, status, payment_method,
            created_at, completed_at, transaction_id,
            users:user_id(full_name, phone)
          ''').eq('club_id', clubId);

      if (userId != null) {
        queryBuilder = queryBuilder.eq('user_id', userId);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error getting payment history: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Lấy thống kê thanh toán
  static Future<Map<String, dynamic>> getPaymentStats({
    required String clubId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final from = fromDate?.toIso8601String() ??
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final to = toDate?.toIso8601String() ?? DateTime.now().toIso8601String();

      final response = await _supabase.rpc(
        'get_payment_stats',
        params: {'p_club_id': clubId, 'p_from_date': from, 'p_to_date': to},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error getting payment stats: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Lưu cấu hình thanh toán CLB
  static Future<void> saveClubPaymentSettings({
    required String clubId,
    required bool cashEnabled,
    required bool bankEnabled,
    required bool ewalletEnabled,
    required bool vnpayEnabled,
    List<Map<String, dynamic>>? bankAccounts,
    List<Map<String, dynamic>>? ewalletAccounts,
    Map<String, dynamic>? vnpayConfig,
  }) async {
    try {
      final settingsData = {
        'club_id': clubId,
        'cash_enabled': cashEnabled,
        'bank_enabled': bankEnabled,
        'ewallet_enabled': ewalletEnabled,
        'vnpay_enabled': vnpayEnabled,
        'bank_accounts':
            bankAccounts != null ? json.encode(bankAccounts) : '[]',
        'ewallet_accounts':
            ewalletAccounts != null ? json.encode(ewalletAccounts) : '[]',
        'vnpay_config': vnpayConfig != null ? json.encode(vnpayConfig) : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Use upsert with onConflict to handle duplicate club_id
      await _supabase.from('club_payment_settings').upsert(
            settingsData,
            onConflict: 'club_id', // Specify the unique constraint column
          );
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error saving payment settings: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Lấy cấu hình thanh toán CLB
  static Future<Map<String, dynamic>?> getClubPaymentSettings(
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('club_payment_settings')
          .select()
          .eq('club_id', clubId)
          .maybeSingle();

      if (response == null) return null;

      // Parse JSON fields
      if (response['bank_accounts'] is String) {
        response['bank_accounts'] = json.decode(response['bank_accounts']);
      }
      if (response['ewallet_accounts'] is String) {
        response['ewallet_accounts'] = json.decode(
          response['ewallet_accounts'],
        );
      }
      if (response['vnpay_config'] != null &&
          response['vnpay_config'] is String) {
        response['vnpay_config'] = json.decode(response['vnpay_config']);
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error getting payment settings: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Tạo invoice cho booking
  static Future<Map<String, dynamic>> createBookingInvoice({
    required String clubId,
    required String userId,
    required String bookingId,
    required double amount,
    required String description,
    DateTime? dueDate,
  }) async {
    try {
      final invoiceData = {
        'club_id': clubId,
        'user_id': userId,
        'booking_id': bookingId,
        'amount': amount,
        'description': description,
        'status': 'pending',
        'due_date': dueDate?.toIso8601String() ??
            DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('invoices')
          .insert(invoiceData)
          .select()
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error creating booking invoice: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Webhook handler cho MoMo
  static Future<bool> handleMoMoWebhook(
    Map<String, dynamic> webhookData,
  ) async {
    try {
      final partnerRefId = webhookData['partnerRefId']; // Payment ID
      final resultCode = webhookData['resultCode']; // 0 = success
      final transId = webhookData['transId']; // MoMo transaction ID

      if (resultCode == 0) {
        await confirmPayment(
          paymentId: partnerRefId,
          transactionId: transId,
          webhookData: webhookData,
        );
        return true;
      } else {
        // Payment failed
        await _supabase.from('payments').update({
          'status': 'failed',
          'webhook_data': json.encode(webhookData),
        }).eq('id', partnerRefId);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error handling MoMo webhook: $e',
            tag: 'real_payment_service');
      }
      return false;
    }
  }

  /// Webhook handler cho ZaloPay
  static Future<bool> handleZaloPayWebhook(
    Map<String, dynamic> webhookData,
  ) async {
    try {
      final appTransId = webhookData['app_trans_id']; // Payment ID
      final status = webhookData['status']; // 1 = success
      final zaloTransId = webhookData['zp_trans_id']; // ZaloPay transaction ID

      if (status == 1) {
        await confirmPayment(
          paymentId: appTransId,
          transactionId: zaloTransId,
          webhookData: webhookData,
        );
        return true;
      } else {
        await _supabase.from('payments').update({
          'status': 'failed',
          'webhook_data': json.encode(webhookData),
        }).eq('id', appTransId);
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error handling ZaloPay webhook: $e',
            tag: 'real_payment_service');
      }
      return false;
    }
  }

  /// Check trạng thái payment
  static Future<String> checkPaymentStatus(String paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('status')
          .eq('id', paymentId)
          .single();

      return response['status'];
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error checking payment status: $e',
            tag: 'real_payment_service');
      }
      return 'unknown';
    }
  }

  /// Hủy payment
  static Future<void> cancelPayment(String paymentId, String reason) async {
    try {
      await _supabase.from('payments').update({
        'status': 'cancelled',
        'metadata': json.encode({'cancel_reason': reason}),
        'cancelled_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error cancelling payment: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Upload QR code image to storage
  static Future<String> uploadQRImage({
    required String clubId,
    required String fileName,
    required String filePath,
  }) async {
    try {
      final path = '$clubId/$fileName';
      final file = File(filePath);

      await _supabase.storage.from('payment-qr-codes').upload(path, file);

      final url = _supabase.storage.from('payment-qr-codes').getPublicUrl(path);

      return url;
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error uploading QR image: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }

  /// Delete QR code image from storage
  static Future<void> deleteQRImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.last;

      await _supabase.storage.from('payment-qr-codes').remove([path]);
    } catch (e) {
      if (kDebugMode) {
        ProductionLogger.info('Error deleting QR image: $e',
            tag: 'real_payment_service');
      }
      rethrow;
    }
  }
}
