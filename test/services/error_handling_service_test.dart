import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/error_handling_service.dart';
import 'package:sabo_arena/exceptions/rate_limit_exception.dart';
import 'package:dio/dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorHandlingService Tests', () {
    late ErrorHandlingService errorService;

    setUp(() {
      errorService = ErrorHandlingService.instance;
    });

    test('should return user-friendly message for network error', () {
      final networkError = DioException.connectionError(
        requestOptions: RequestOptions(path: '/test'),
        reason: 'Connection failed',
      );

      final message = errorService.getUserFriendlyMessage(networkError);

      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('kết nối'));
    });

    test('should return user-friendly message for rate limit error', () {
      final rateLimitError = RateLimitException.legacy('login', 'test-user', const Duration(seconds: 300));

      final message = errorService.getUserFriendlyMessage(rateLimitError);

      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('thử lại'));
    });

    test('should identify retryable errors', () {
      final networkError = DioException.connectionError(
        requestOptions: RequestOptions(path: '/test'),
        reason: 'Connection failed',
      );

      final isRetryable = errorService.isRetryableError(networkError);

      expect(isRetryable, isTrue);
    });

    test('should identify non-retryable errors', () {
      final rateLimitError = RateLimitException.legacy('login', 'test-user', const Duration(seconds: 300));

      final isRetryable = errorService.isRetryableError(rateLimitError);

      expect(isRetryable, isFalse);
    });

    test('should handle null error gracefully', () {
      final message = errorService.getUserFriendlyMessage(null);

      expect(message, isNotEmpty);
      expect(message, contains('lỗi'));
    });

    test('should handle generic error', () {
      final genericError = Exception('Something went wrong');

      final message = errorService.getUserFriendlyMessage(genericError);

      expect(message, isNotEmpty);
    });

    test('should create error dialog config', () {
      final networkError = DioException.connectionError(
        requestOptions: RequestOptions(path: '/test'),
        reason: 'Connection failed',
      );

      final config = errorService.createErrorDialogConfig(networkError);

      expect(config, isNotNull);
      expect(config['title'], isNotEmpty);
      expect(config['message'], isNotEmpty);
      expect(config['showRetry'], isTrue);
    });
  });
}

