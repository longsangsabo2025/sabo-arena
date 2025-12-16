import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../exceptions/rate_limit_exception.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Enhanced Error Handling Service
/// Provides comprehensive error handling with user-friendly messages and retry logic
class ErrorHandlingService {
  static ErrorHandlingService? _instance;
  static ErrorHandlingService get instance =>
      _instance ??= ErrorHandlingService._();

  ErrorHandlingService._();

  /// Get user-friendly error message from exception
  String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'Đã xảy ra lỗi không xác định';

    // Rate limiting errors
    if (error is RateLimitException) {
      return error.toString();
    }

    // Network errors
    if (error is DioException) {
      return _getNetworkErrorMessage(error);
    }

    // Auth errors
    if (error.toString().contains('AuthException')) {
      return _getAuthErrorMessage(error.toString());
    }

    // Database errors
    if (error.toString().contains('PostgrestException')) {
      return _getDatabaseErrorMessage(error.toString());
    }

    // Tournament errors
    if (error.toString().contains('tournament')) {
      return _getTournamentErrorMessage(error.toString());
    }

    // Generic error fallback
    return _getGenericErrorMessage(error.toString());
  }

  /// Get network-specific error messages
  String _getNetworkErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.';
      case DioExceptionType.sendTimeout:
        return 'Gửi yêu cầu quá thời gian. Vui lòng thử lại.';
      case DioExceptionType.receiveTimeout:
        return 'Nhận phản hồi quá thời gian. Vui lòng thử lại.';
      case DioExceptionType.badResponse:
        return _getResponseErrorMessage(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.badCertificate:
        return 'Lỗi chứng chỉ bảo mật. Vui lòng thử lại sau.';
      case DioExceptionType.unknown:
        return 'Lỗi mạng không xác định. Vui lòng kiểm tra kết nối và thử lại.';
    }
  }

  /// Get response-specific error messages based on status code
  String _getResponseErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ. Vui lòng kiểm tra thông tin và thử lại.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền thực hiện hành động này.';
      case 404:
        return 'Không tìm thấy dữ liệu yêu cầu.';
      case 409:
        return 'Dữ liệu đã tồn tại hoặc xung đột. Vui lòng thử lại.';
      case 422:
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra và thử lại.';
      case 429:
        return 'Quá nhiều yêu cầu. Vui lòng đợi một chút và thử lại.';
      case 500:
        return 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.';
      case 502:
        return 'Máy chủ tạm thời không khả dụng. Vui lòng thử lại sau.';
      case 503:
        return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
      case 504:
        return 'Máy chủ quá thời gian phản hồi. Vui lòng thử lại.';
      default:
        return 'Lỗi máy chủ (${statusCode ?? 'unknown'}). Vui lòng thử lại.';
    }
  }

  /// Get authentication-specific error messages
  String _getAuthErrorMessage(String error) {
    if (error.contains('invalid_credentials')) {
      return 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra và thử lại.';
    }
    if (error.contains('email_not_confirmed')) {
      return 'Vui lòng xác thực email trước khi đăng nhập.';
    }
    if (error.contains('user_not_found')) {
      return 'Không tìm thấy tài khoản với thông tin này.';
    }
    if (error.contains('weak_password')) {
      return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
    }
    if (error.contains('email_already_registered')) {
      return 'Email này đã được đăng ký. Vui lòng sử dụng email khác.';
    }
    if (error.contains('phone_already_registered')) {
      return 'Số điện thoại này đã được đăng ký. Vui lòng sử dụng số khác.';
    }
    if (error.contains('signup_disabled')) {
      return 'Đăng ký tạm thời không khả dụng. Vui lòng thử lại sau.';
    }
    if (error.contains('too_many_requests')) {
      return 'Quá nhiều yêu cầu đăng nhập. Vui lòng đợi một chút và thử lại.';
    }

    return 'Lỗi xác thực. Vui lòng thử lại.';
  }

  /// Get database-specific error messages
  String _getDatabaseErrorMessage(String error) {
    if (error.contains('duplicate key')) {
      return 'Dữ liệu đã tồn tại. Vui lòng thử với thông tin khác.';
    }
    if (error.contains('foreign key')) {
      return 'Không thể thực hiện vì có dữ liệu liên quan.';
    }
    if (error.contains('check constraint')) {
      return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra và thử lại.';
    }
    if (error.contains('permission denied')) {
      return 'Bạn không có quyền thực hiện hành động này.';
    }
    if (error.contains('row level security')) {
      return 'Bạn không có quyền truy cập dữ liệu này.';
    }

    return 'Lỗi cơ sở dữ liệu. Vui lòng thử lại sau.';
  }

  /// Get tournament-specific error messages
  String _getTournamentErrorMessage(String error) {
    if (error.contains('tournament full')) {
      return 'Giải đấu đã đầy. Vui lòng chọn giải đấu khác.';
    }
    if (error.contains('registration closed')) {
      return 'Đăng ký giải đấu đã đóng. Vui lòng chọn giải đấu khác.';
    }
    if (error.contains('already registered')) {
      return 'Bạn đã đăng ký giải đấu này rồi.';
    }
    if (error.contains('bracket not generated')) {
      return 'Giải đấu chưa được tạo nhánh. Vui lòng thử lại sau.';
    }
    if (error.contains('match not found')) {
      return 'Không tìm thấy trận đấu. Vui lòng thử lại.';
    }

    return 'Lỗi liên quan đến giải đấu. Vui lòng thử lại.';
  }

  /// Get generic error message with fallback
  String _getGenericErrorMessage(String error) {
    // Try to extract meaningful parts from error string
    if (error.contains('timeout')) {
      return 'Yêu cầu quá thời gian. Vui lòng thử lại.';
    }
    if (error.contains('network')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
    }
    if (error.contains('permission')) {
      return 'Bạn không có quyền thực hiện hành động này.';
    }
    if (error.contains('not found')) {
      return 'Không tìm thấy dữ liệu yêu cầu.';
    }
    if (error.contains('invalid')) {
      return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra và thử lại.';
    }

    return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại sau.';
  }

  /// Check if error is retryable
  bool isRetryableError(dynamic error) {
    if (error == null) return false;

    // Network errors are usually retryable
    if (error is DioException) {
      return error.type != DioExceptionType.cancel &&
          error.type != DioExceptionType.badCertificate;
    }

    // Server errors are retryable
    if (error.toString().contains('500') ||
        error.toString().contains('502') ||
        error.toString().contains('503') ||
        error.toString().contains('504')) {
      return true;
    }

    // Timeout errors are retryable
    if (error.toString().contains('timeout')) {
      return true;
    }

    // Rate limiting errors are not retryable immediately
    if (error is RateLimitException) {
      return false;
    }

    return false;
  }

  /// Get suggested retry delay in seconds
  int getRetryDelay(dynamic error, int attemptNumber) {
    if (error is RateLimitException) {
      return error.timeUntilReset.inSeconds;
    }

    // Exponential backoff for retryable errors
    return (1 << (attemptNumber - 1)).clamp(
      1,
      60,
    ); // 1, 2, 4, 8, 16, 32, 60 seconds max
  }

  /// Log error for debugging and monitoring
  void logError(dynamic error, String context) {
    if (kDebugMode) {
      ProductionLogger.info('🔥 Error in $context: $error', tag: 'error_handling_service');
      ProductionLogger.info('Stack trace: ${StackTrace.current}', tag: 'error_handling_service');
    }

    // In production, send to error tracking service like Sentry
    // _sendToErrorTracking(error, context);
  }

  /// Create error dialog configuration
  Map<String, dynamic> createErrorDialogConfig(dynamic error) {
    return {
      'title': 'Có lỗi xảy ra',
      'message': getUserFriendlyMessage(error),
      'isRetryable': isRetryableError(error),
      'icon': _getErrorIcon(error),
      'actions': _getErrorActions(error),
    };
  }

  /// Get appropriate icon for error type
  String _getErrorIcon(dynamic error) {
    if (error is RateLimitException) return 'rate_limit';
    if (error.toString().contains('network') || error is DioException)
      return 'network';
    if (error.toString().contains('auth')) return 'auth';
    if (error.toString().contains('permission')) return 'permission';
    return 'generic';
  }

  /// Get suggested actions for error
  List<String> _getErrorActions(dynamic error) {
    final actions = <String>[];

    if (isRetryableError(error)) {
      actions.add('retry');
    }

    if (error.toString().contains('auth') || error.toString().contains('401')) {
      actions.add('login');
    }

    if (error.toString().contains('network')) {
      actions.add('check_connection');
    }

    if (actions.isEmpty) {
      actions.add('contact_support');
    }

    return actions;
  }
}

/// Retry Handler for async operations
class RetryHandler {
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration baseDelay = const Duration(seconds: 1),
    bool Function(dynamic)? shouldRetry,
    String context = 'operation',
  }) async {
    final errorHandler = ErrorHandlingService.instance;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        errorHandler.logError(error, '$context - Attempt $attempt');

        // Check if should retry
        if (attempt == maxAttempts ||
            (shouldRetry != null && !shouldRetry(error))) {
          rethrow;
        }

        // Calculate delay with exponential backoff
        final delay = baseDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }

    throw Exception('Max retry attempts exceeded');
  }

  /// Retry with progressive delay for network operations
  static Future<T> networkRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    String context = 'network_operation',
  }) {
    return withRetry(
      operation,
      maxAttempts: maxAttempts,
      shouldRetry: (error) =>
          ErrorHandlingService.instance.isRetryableError(error),
      context: context,
    );
  }
}

/// Error State Widget with enhanced UX
class EnhancedErrorStateWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? title;
  final String? description;
  final bool showDetails;
  final bool showIcon;

  const EnhancedErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.description,
    this.showDetails = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final errorHandler = ErrorHandlingService.instance;
    final dialogConfig = errorHandler.createErrorDialogConfig(error);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            _buildErrorIcon(dialogConfig['icon'] as String),
            const SizedBox(height: 16),
          ],

          Text(
            title ?? dialogConfig['title'] as String,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            description ?? dialogConfig['message'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF8E8E93),
              height: 1.4,
            ),
          ),

          if (showDetails && error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],

          if (onRetry != null && (dialogConfig['isRetryable'] as bool)) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorIcon(String iconType) {
    IconData iconData;
    Color iconColor;

    switch (iconType) {
      case 'network':
        iconData = Icons.wifi_off;
        iconColor = const Color(0xFFFF9500);
        break;
      case 'auth':
        iconData = Icons.lock_outline;
        iconColor = const Color(0xFFFF3B30);
        break;
      case 'permission':
        iconData = Icons.block;
        iconColor = const Color(0xFFFF3B30);
        break;
      case 'rate_limit':
        iconData = Icons.timer;
        iconColor = const Color(0xFFFF9500);
        break;
      default:
        iconData = Icons.error_outline;
        iconColor = const Color(0xFF8E8E93);
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Icon(iconData, size: 32, color: iconColor),
    );
  }
}
