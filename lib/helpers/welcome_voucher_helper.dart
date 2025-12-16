import 'package:flutter/material.dart';
import '../services/welcome_voucher_service.dart';
import '../widgets/welcome_voucher_popup.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Helper class để check và hiển thị welcome voucher popup
class WelcomeVoucherHelper {
  static final WelcomeVoucherService _service = WelcomeVoucherService();

  /// Check và show welcome voucher popup sau khi user login/signup
  /// Gọi function này sau khi user verify email hoặc login thành công
  static Future<void> checkAndShowWelcomeVoucher(
    BuildContext context,
    String userId,
  ) async {
    try {
      // Check xem user đã nhận welcome voucher chưa
      final voucher = await _service.getUserWelcomeVoucher(userId);

      if (voucher != null && context.mounted) {
        // Show popup với animation
        await Future.delayed(const Duration(milliseconds: 500));

        if (context.mounted) {
          WelcomeVoucherPopup.show(
            context,
            voucher: voucher,
            onViewVoucher: () {
              // Navigate to My Vouchers screen
              // User sẽ tự navigate bằng cách tap vào bottom nav
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          );
        }
      }
    } catch (e) {
      // Bỏ qua lỗi để không ảnh hưởng user experience
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Manually trigger welcome voucher issuance (for testing/recovery)
  static Future<void> manuallyIssueWelcomeVoucher(String userId) async {
    try {
      await _service.manuallyIssueWelcomeVoucher(userId);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Check user eligibility for welcome voucher
  static Future<bool> checkEligibility(String userId) async {
    try {
      final result = await _service.checkUserEligibility(userId);
      return result['eligible'] == true;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return false;
    }
  }
}

