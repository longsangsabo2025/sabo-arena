import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/notification_service.dart';
import 'package:sabo_arena/core/error_handling/standardized_error_handler.dart';

void main() {
  group('NotificationService Error Handling', () {
    test('Error handler is integrated', () {
      // Verify that StandardizedErrorHandler is accessible
      expect(StandardizedErrorHandler.classifyError, isA<Function>());
      
      // Test error classification for database errors
      final dbError = Exception('Database connection failed');
      final category = StandardizedErrorHandler.classifyError(dbError);
      expect(category, ErrorCategory.database);
    });

    test('NotificationService instance exists', () {
      final service = NotificationService.instance;
      expect(service, isNotNull);
    });
  });
}

