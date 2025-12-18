/// STANDARDIZED ERROR HANDLING PATTERN FOR FLUTTER
/// 
/// Use this pattern across ALL services and UI for consistent error handling.
/// Compatible with existing ErrorHandlingService.
/// 
/// Usage:
/// ```dart
/// import 'package:sabo_arena/core/error_handling/standardized_error_handler.dart';
/// 
/// try {
///   await someOperation();
/// } catch (error) {
///   StandardizedErrorHandler.handleError(
///     error,
///     context: ErrorContext(
///       category: ErrorCategory.database,
///       operation: 'fetchTournaments',
///       userId: currentUser?.id,
///     ),
///   );
/// }
/// ```

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../services/error_handling_service.dart';
// ELON_MODE_AUTO_FIX

/// Error categories matching React pattern
enum ErrorCategory {
  network,
  auth,
  validation,
  database,
  api,
  unknown,
}

/// Error context for better error tracking
class ErrorContext {
  final ErrorCategory? category;
  final String? operation;
  final String? userId;
  final String? context;
  final Map<String, dynamic>? extra;

  const ErrorContext({
    this.category,
    this.operation,
    this.userId,
    this.context,
    this.extra,
  });
}

/// Standardized Error Handler for Flutter
/// 
/// Provides consistent error handling across the app:
/// 1. Classifies errors
/// 2. Gets user-friendly messages
/// 3. Reports to Sentry
/// 4. Reports to LongSangErrorReporter
class StandardizedErrorHandler {
  /// Classify error into category
  static ErrorCategory classifyError(dynamic error) {
    if (error == null) return ErrorCategory.unknown;

    final errorString = error.toString().toLowerCase();
    final errorMessage = error is Exception ? error.toString().toLowerCase() : '';

    // Network errors
    if (_containsAny(errorString, [
      'network',
      'connection',
      'timeout',
      'socket',
      'dioexception',
      'connectionerror',
    ]) || _containsAny(errorMessage, ['network', 'connection', 'timeout'])) {
      return ErrorCategory.network;
    }

    // Auth errors
    if (_containsAny(errorString, [
      'auth',
      'unauthorized',
      'forbidden',
      'token',
      'session',
      'authexception',
    ]) || _containsAny(errorMessage, ['auth', 'unauthorized', 'forbidden'])) {
      return ErrorCategory.auth;
    }

    // Validation errors
    if (_containsAny(errorString, [
      'validation',
      'invalid',
      'required',
      'format',
    ]) || _containsAny(errorMessage, ['validation', 'invalid', 'required'])) {
      return ErrorCategory.validation;
    }

    // Database errors (Supabase/PostgreSQL)
    if (_containsAny(errorString, [
      'database',
      'postgres',
      'supabase',
      'postgrest',
      'sql',
      'postgresterror',
      'postgresexception',
    ]) || _containsAny(errorMessage, [
      'database',
      'relation',
      'column',
      'constraint',
    ])) {
      return ErrorCategory.database;
    }

    // API errors
    if (_containsAny(errorString, [
      'api',
      'endpoint',
      'http',
    ]) || _containsAny(errorMessage, ['api', 'endpoint'])) {
      return ErrorCategory.api;
    }

    return ErrorCategory.unknown;
  }

  /// Helper to check if string contains any of the keywords
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Get user-friendly error message (Vietnamese)
  /// Uses existing ErrorHandlingService for consistency
  static String getUserFriendlyMessage(dynamic error, ErrorCategory category) {
    // Use existing ErrorHandlingService for message translation
    final errorHandler = ErrorHandlingService.instance;
    final message = errorHandler.getUserFriendlyMessage(error);

    // If ErrorHandlingService returns a generic message, use category-specific fallback
    if (message == 'Đã xảy ra lỗi không xác định' || message.isEmpty) {
      return _getCategoryMessage(category);
    }

    return message;
  }

  /// Get category-specific fallback message
  static String _getCategoryMessage(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      case ErrorCategory.auth:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case ErrorCategory.validation:
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.';
      case ErrorCategory.database:
        return 'Lỗi hệ thống. Vui lòng thử lại sau.';
      case ErrorCategory.api:
        return 'Lỗi kết nối server. Vui lòng thử lại sau.';
      case ErrorCategory.unknown:
        return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
    }
  }

  /// Handle error with standardized pattern
  /// 
  /// This function:
  /// 1. Classifies the error
  /// 2. Gets user-friendly message
  /// 3. Reports to Sentry (if initialized)
  /// 4. Reports to LongSangErrorReporter
  /// 5. Returns error info for UI display
  static ErrorInfo handleError(
    dynamic error, {
    ErrorContext? context,
  }) {
    final category = context?.category ?? classifyError(error);
    final message = getUserFriendlyMessage(error, category);

    // Report to Sentry
    _reportToSentry(error, category, context);

    // Report to LongSangErrorReporter (existing system)
    _reportToLongSang(error, category, context);

    // Log in debug mode
    if (kDebugMode) {
      if (context != null) {
      }
    }

    return ErrorInfo(
      category: category,
      message: message,
      originalError: error,
    );
  }

  /// Report error to Sentry
  static void _reportToSentry(
    dynamic error,
    ErrorCategory category,
    ErrorContext? context,
  ) {
    try {
      Sentry.captureException(
        error is Exception ? error : Exception(error.toString()),
        stackTrace: error is Error ? error.stackTrace : null,
        hint: Hint.withMap({
          'category': category.name,
          'operation': context?.operation ?? 'unknown',
          'userId': context?.userId,
          'context': context?.context,
          if (context?.extra != null) ...context!.extra!,
        }),
      );
    } catch (e) {
      // Don't fail if Sentry is not initialized
      if (kDebugMode) {
      }
    }
  }

  /// Report error to LongSangErrorReporter (existing system)
  /// LongSangErrorReporter automatically catches errors via FlutterError.onError
  /// So we just log here for debugging
  static void _reportToLongSang(
    dynamic error,
    ErrorCategory category,
    ErrorContext? context,
  ) {
    // LongSangErrorReporter automatically catches errors via FlutterError.onError
    // set up in main.dart, so we don't need to manually report here
    // Just log for debugging
    if (kDebugMode) {
    }
  }

  /// Retry handler with exponential backoff
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() fn, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        return await fn();
      } catch (error) {
        lastError = error is Exception ? error : Exception(error.toString());
        attempt++;

        if (attempt < maxRetries) {
          final delay = Duration(
            milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
          );
          await Future.delayed(delay);
        }
      }
    }

    throw lastError ?? Exception('Retry failed after $maxRetries attempts');
  }
}

/// Error information returned by handleError
class ErrorInfo {
  final ErrorCategory category;
  final String message;
  final dynamic originalError;

  const ErrorInfo({
    required this.category,
    required this.message,
    required this.originalError,
  });
}

/// Extension for easy error handling in services
extension ErrorHandlingExtension<T> on Future<T> {
  /// Handle errors with standardized pattern
  Future<T> handleErrors({
    ErrorContext? context,
    Function(ErrorInfo)? onError,
  }) async {
    try {
      return await this;
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: context,
      );

      if (onError != null) {
        onError(errorInfo);
      }

      rethrow;
    }
  }
}


