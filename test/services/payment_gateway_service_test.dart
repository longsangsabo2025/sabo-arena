import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/payment_gateway_service.dart';
import 'package:sabo_arena/core/error_handling/standardized_error_handler.dart';

void main() {
  group('PaymentGatewayService Error Handling', () {
    test('Error handler is integrated', () {
      // Verify that StandardizedErrorHandler is accessible
      expect(StandardizedErrorHandler.classifyError, isA<Function>());
      
      // Test error classification for validation errors
      final validationError = Exception('Invalid signature');
      final category = StandardizedErrorHandler.classifyError(validationError);
      expect(category, ErrorCategory.validation);
    });

    test('PaymentGatewayService instance exists', () {
      final service = PaymentGatewayService.instance;
      expect(service, isNotNull);
    });
  });
}

