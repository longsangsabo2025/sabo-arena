import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/storage_service.dart';
import 'package:sabo_arena/core/error_handling/standardized_error_handler.dart';

void main() {
  group('StorageService Error Handling', () {
    test('Error handler is integrated', () {
      // Verify that StandardizedErrorHandler is accessible
      expect(StandardizedErrorHandler.classifyError, isA<Function>());
      
      // Test error classification for API errors
      final apiError = Exception('API request failed');
      final category = StandardizedErrorHandler.classifyError(apiError);
      expect(category, ErrorCategory.api);
    });

    test('StorageService static methods exist', () {
      // Verify that static methods are accessible
      expect(StorageService.checkStorageConnection, isA<Function>());
    });
  });
}

