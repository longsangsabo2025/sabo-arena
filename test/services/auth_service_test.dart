import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/auth_service.dart';
import 'package:sabo_arena/core/error_handling/standardized_error_handler.dart';

void main() {
  group('AuthService Error Handling', () {
    test('Error handler is integrated', () {
      // Verify that StandardizedErrorHandler is accessible
      expect(StandardizedErrorHandler.classifyError, isA<Function>());
      
      // Test error classification
      final networkError = Exception('Network connection failed');
      final category = StandardizedErrorHandler.classifyError(networkError);
      expect(category, ErrorCategory.network);
    });

    test('AuthService instance exists', () {
      final service = AuthService.instance;
      expect(service, isNotNull);
    });
  });
}

