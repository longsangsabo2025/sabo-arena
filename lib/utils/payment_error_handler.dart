import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Payment Error Handler
/// Provides user-friendly error messages and retry logic
class PaymentErrorHandler {
  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'Kết nối quá chậm. Vui lòng thử lại sau.';
    }

    // MoMo specific errors
    if (errorString.contains('momo')) {
      if (errorString.contains('invalid signature')) {
        return 'Lỗi xác thực với MoMo. Vui lòng liên hệ hỗ trợ.';
      }
      if (errorString.contains('insufficient balance')) {
        return 'Số dư MoMo không đủ. Vui lòng nạp thêm tiền.';
      }
      if (errorString.contains('transaction limit')) {
        return 'Vượt quá giới hạn giao dịch. Vui lòng thử lại sau.';
      }
      return 'Lỗi thanh toán MoMo. Vui lòng thử lại.';
    }

    // Database errors
    if (errorString.contains('database') || errorString.contains('supabase')) {
      return 'Lỗi hệ thống. Vui lòng thử lại sau.';
    }

    // Authentication errors
    if (errorString.contains('not logged in') ||
        errorString.contains('unauthorized')) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }

    // File upload errors
    if (errorString.contains('upload') || errorString.contains('storage')) {
      return 'Lỗi tải ảnh lên. Vui lòng thử lại.';
    }

    // Payment errors
    if (errorString.contains('payment')) {
      if (errorString.contains('already exists')) {
        return 'Bạn đã đăng ký giải đấu này rồi.';
      }
      if (errorString.contains('not found')) {
        return 'Không tìm thấy thông tin thanh toán.';
      }
      return 'Lỗi thanh toán. Vui lòng thử lại.';
    }

    // Generic error
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }

  /// Show error dialog with retry option
  static Future<bool> showErrorDialog({
    required BuildContext context,
    required String title,
    required dynamic error,
    bool showRetry = true,
  }) async {
    final message = getUserFriendlyMessage(error);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chi tiết lỗi: ${error.toString()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Đóng'),
              ),
              if (showRetry)
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thử lại'),
                ),
            ],
          ),
        ) ??
        false;
  }

  /// Show error snackbar
  static void showErrorSnackBar({
    required BuildContext context,
    required dynamic error,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = getUserFriendlyMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Chi tiết',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Chi tiết lỗi'),
                content: SelectableText(
                  error.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Retry logic with exponential backoff
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (e) {
        if (attempt >= maxAttempts) {
          rethrow;
        }

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors are retryable
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return true;
    }

    // Temporary server errors are retryable
    if (errorString.contains('503') ||
        errorString.contains('502') ||
        errorString.contains('504')) {
      return true;
    }

    return false;
  }

  /// Show loading dialog with timeout
  static Future<T?> showLoadingDialog<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String message = 'Đang xử lý...',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );

    try {
      // Execute operation with timeout
      final result = await operation().timeout(timeout);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      return result;
    } on TimeoutException {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      throw 'Timeout: Thao tác mất quá nhiều thời gian';
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      rethrow;
    }
  }
}

