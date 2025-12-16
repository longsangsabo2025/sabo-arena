import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/payment_method.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class PaymentMethodService {
  static final PaymentMethodService _instance =
      PaymentMethodService._internal();
  static PaymentMethodService get instance => _instance;
  PaymentMethodService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  /// Get all payment methods for a club
  Future<List<PaymentMethod>> getClubPaymentMethods(String clubId) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select()
          .eq('club_id', clubId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => PaymentMethod.fromMap(data))
          .toList();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Get default payment method for a club
  Future<PaymentMethod?> getDefaultPaymentMethod(String clubId) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select()
          .eq('club_id', clubId)
          .eq('is_active', true)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;
      return PaymentMethod.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Upload QR code image to storage
  Future<Map<String, String>> uploadQRCode(
    String clubId,
    XFile imageFile,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName =
          'qr_${clubId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'payment_qr_codes/$clubId/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('club_assets')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      // Get public URL
      final url = _supabase.storage.from('club_assets').getPublicUrl(path);

      return {'url': url, 'path': path};
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Create or update bank transfer payment method with QR code
  Future<PaymentMethod> createBankTransferMethod({
    required String clubId,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required XFile qrCodeImage,
    bool setAsDefault = true,
  }) async {
    try {
      // 1. Upload QR code
      final qrData = await uploadQRCode(clubId, qrCodeImage);

      // 2. If setting as default, unset other defaults
      if (setAsDefault) {
        await _supabase
            .from('payment_methods')
            .update({'is_default': false})
            .eq('club_id', clubId)
            .eq('method_type', 'bank_transfer');
      }

      // 3. Create payment method
      final response = await _supabase
          .from('payment_methods')
          .insert({
            'club_id': clubId,
            'method_type': 'bank_transfer',
            'method_name': 'Chuyển khoản ngân hàng',
            'bank_name': bankName,
            'account_number': accountNumber,
            'account_holder': accountName,
            'qr_code_url': qrData['url'],
            'qr_code_path': qrData['path'],
            'config': '{"enabled": true}',
            'is_active': true,
            'is_default': setAsDefault,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return PaymentMethod.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Create QR Code payment method (simple - just upload QR image)
  Future<PaymentMethod> createQRCodeMethod({
    required String clubId,
    required XFile qrCodeImage,
    String? methodName,
    bool setAsDefault = false,
  }) async {
    try {
      // 1. Upload QR code
      final qrData = await uploadQRCode(clubId, qrCodeImage);

      // 2. If setting as default, unset other defaults
      if (setAsDefault) {
        await _supabase
            .from('payment_methods')
            .update({'is_default': false})
            .eq('club_id', clubId)
            .eq('method_type', 'qr_code');
      }

      // 3. Create payment method
      final response = await _supabase
          .from('payment_methods')
          .insert({
            'club_id': clubId,
            'method_type': 'qr_code',
            'method_name': methodName ?? 'Quét mã QR',
            'qr_code_url': qrData['url'],
            'qr_code_path': qrData['path'],
            'config': '{"enabled": true}',
            'is_active': true,
            'is_default': setAsDefault,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return PaymentMethod.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Update payment method
  Future<PaymentMethod> updatePaymentMethod({
    required String paymentMethodId,
    String? bankName,
    String? accountNumber,
    String? accountName,
    XFile? newQrCodeImage,
    bool? isActive,
    bool? isDefault,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (bankName != null) updates['bank_name'] = bankName;
      if (accountNumber != null) updates['account_number'] = accountNumber;
      if (accountName != null) updates['account_holder'] = accountName;
      if (isActive != null) updates['is_active'] = isActive;
      if (isDefault != null) updates['is_default'] = isDefault;

      // Upload new QR code if provided
      if (newQrCodeImage != null) {
        // Get club_id from existing payment method
        final existing = await _supabase
            .from('payment_methods')
            .select('club_id, qr_code_path')
            .eq('id', paymentMethodId)
            .single();

        final clubId = existing['club_id'] as String;
        final oldPath = existing['qr_code_path'] as String?;

        // Delete old QR code
        if (oldPath != null) {
          try {
            await _supabase.storage.from('club_assets').remove([oldPath]);
          } catch (e) {
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
          }
        }

        // Upload new QR code
        final qrData = await uploadQRCode(clubId, newQrCodeImage);
        updates['qr_code_url'] = qrData['url'];
        updates['qr_code_path'] = qrData['path'];
      }

      // If setting as default, unset others
      if (isDefault == true) {
        final existing = await _supabase
            .from('payment_methods')
            .select('club_id')
            .eq('id', paymentMethodId)
            .single();

        await _supabase
            .from('payment_methods')
            .update({'is_default': false})
            .eq('club_id', existing['club_id'])
            .neq('id', paymentMethodId);
      }

      final response = await _supabase
          .from('payment_methods')
          .update(updates)
          .eq('id', paymentMethodId)
          .select()
          .single();

      return PaymentMethod.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Delete payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      // Get payment method to delete QR code
      final paymentMethod = await _supabase
          .from('payment_methods')
          .select('qr_code_path')
          .eq('id', paymentMethodId)
          .single();

      final qrPath = paymentMethod['qr_code_path'] as String?;

      // Delete QR code from storage
      if (qrPath != null) {
        try {
          await _supabase.storage.from('club_assets').remove([qrPath]);
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }

      // Soft delete (set inactive)
      await _supabase
          .from('payment_methods')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentMethodId);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickQRCodeImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Take photo with camera
  Future<XFile?> takeQRCodePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  // ==================== Tournament Payment ====================

  /// Create tournament payment record
  Future<TournamentPayment> createTournamentPayment({
    required String tournamentId,
    required String userId,
    required String clubId,
    required String paymentMethodId,
    required double amount,
  }) async {
    try {
      final response = await _supabase
          .from('tournament_payments')
          .insert({
            'tournament_id': tournamentId,
            'user_id': userId,
            'club_id': clubId,
            'payment_method_id': paymentMethodId,
            'amount': amount,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return TournamentPayment.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Upload payment proof (screenshot)
  Future<TournamentPayment> uploadPaymentProof({
    required String paymentId,
    required XFile proofImage,
    String? transactionNote,
    String? transactionReference,
  }) async {
    try {
      // Get payment info
      final payment = await _supabase
          .from('tournament_payments')
          .select('user_id, tournament_id')
          .eq('id', paymentId)
          .single();

      final userId = payment['user_id'] as String;
      final tournamentId = payment['tournament_id'] as String;

      // Upload proof image
      final bytes = await proofImage.readAsBytes();
      final fileName =
          'proof_${paymentId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = 'payment_proofs/$tournamentId/$fileName';

      await _supabase.storage
          .from('tournament_assets')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      final url = _supabase.storage
          .from('tournament_assets')
          .getPublicUrl(path);

      // Update payment
      final response = await _supabase
          .from('tournament_payments')
          .update({
            'proof_image_url': url,
            'proof_image_path': path,
            'transaction_note': transactionNote,
            'transaction_reference': transactionReference,
            'status': 'verifying',
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId)
          .select()
          .single();

      return TournamentPayment.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Verify payment (by club admin)
  Future<TournamentPayment> verifyPayment({
    required String paymentId,
    required String verifiedBy,
  }) async {
    try {
      final response = await _supabase
          .from('tournament_payments')
          .update({
            'status': 'verified',
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': verifiedBy,
          })
          .eq('id', paymentId)
          .select()
          .single();

      return TournamentPayment.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Reject payment
  Future<TournamentPayment> rejectPayment({
    required String paymentId,
    required String rejectionReason,
    required String rejectedBy,
  }) async {
    try {
      final response = await _supabase
          .from('tournament_payments')
          .update({
            'status': 'rejected',
            'rejection_reason': rejectionReason,
            'verified_by': rejectedBy,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId)
          .select()
          .single();

      return TournamentPayment.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Get pending payments for club (for admin verification)
  Future<List<TournamentPayment>> getPendingPayments(String clubId) async {
    try {
      final response = await _supabase
          .from('tournament_payments')
          .select()
          .eq('club_id', clubId)
          .eq('status', 'verifying')
          .order('paid_at', ascending: false);

      return (response as List)
          .map((data) => TournamentPayment.fromMap(data))
          .toList();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Get user's payment for a tournament
  Future<TournamentPayment?> getUserTournamentPayment({
    required String tournamentId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('tournament_payments')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return TournamentPayment.fromMap(response);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Get all payments for a user (for payment history)
  Future<List<TournamentPayment>> getUserPayments(String userId) async {
    try {
      final response = await _supabase
          .from('tournament_payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => TournamentPayment.fromMap(data))
          .toList();
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }
}

