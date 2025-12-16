import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/core/error_handling/standardized_error_handler.dart';

void main() {
  group('StandardizedErrorHandler', () {
    test('classifies network errors correctly', () {
      final networkError = Exception('Network connection timeout');
      final category = StandardizedErrorHandler.classifyError(networkError);
      expect(category, ErrorCategory.network);
    });

    test('classifies auth errors correctly', () {
      final authError = Exception('Unauthorized access');
      final category = StandardizedErrorHandler.classifyError(authError);
      expect(category, ErrorCategory.auth);
    });

    test('classifies database errors correctly', () {
      final dbError = Exception('PostgreSQL relation does not exist');
      final category = StandardizedErrorHandler.classifyError(dbError);
      expect(category, ErrorCategory.database);
    });

    test('classifies validation errors correctly', () {
      final validationError = Exception('Invalid email format');
      final category = StandardizedErrorHandler.classifyError(validationError);
      expect(category, ErrorCategory.validation);
    });

    test('classifies API errors correctly', () {
      final apiError = Exception('API endpoint not found');
      final category = StandardizedErrorHandler.classifyError(apiError);
      expect(category, ErrorCategory.api);
    });

    test('handles unknown errors', () {
      final unknownError = Exception('Something went wrong');
      final category = StandardizedErrorHandler.classifyError(unknownError);
      expect(category, ErrorCategory.unknown);
    });

    test('handleError returns error info', () {
      final error = Exception('Test error');
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.network,
          operation: 'testOperation',
          context: 'Test context',
        ),
      );
      
      expect(errorInfo.message, isNotEmpty);
      expect(errorInfo.category, ErrorCategory.network);
    });
  });
}

