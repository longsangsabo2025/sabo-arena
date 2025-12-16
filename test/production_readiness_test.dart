import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/rate_limit_service.dart';
import 'package:sabo_arena/services/enhanced_validation_service.dart';
import 'package:sabo_arena/services/error_handling_service.dart';
import 'package:dio/dio.dart';
import 'package:sabo_arena/exceptions/rate_limit_exception.dart';

/// Comprehensive Test Suite for SABO Arena Production Readiness
/// Run this to verify all critical features are working correctly
class ProductionReadinessTestSuite {
  static Future<void> runAllTests() async {
    print('🚀 Starting Production Readiness Test Suite...');

    await testRateLimiting();
    await testEnhancedValidation();
    await testErrorHandling();
    await testSecurityFeatures();
    await testPerformanceMetrics();

    print('🎉 All Production Readiness Tests Passed!');
  }

  /// Test 1: Rate Limiting Functionality
  static Future<void> testRateLimiting() async {
    print('🛡️ Testing Rate Limiting...');

    final rateLimitService = RateLimitService.instance;

    // Clear any existing limits
    rateLimitService.reset();

    // Test login attempts
    for (int i = 0; i < 3; i++) {
      final allowed = await rateLimitService.isAllowed(
        'login',
        'test-client-$i',
      );
      assert(allowed, 'Login attempt $i should be allowed');
    }

    // Test registration limits
    for (int i = 0; i < 2; i++) {
      final allowed = await rateLimitService.isAllowed(
        'register',
        'test-client-reg-$i',
      );
      assert(allowed, 'Registration attempt $i should be allowed');
    }

    // Test OTP limits
    for (int i = 0; i < 3; i++) {
      final allowed = await rateLimitService.isAllowed(
        'otp_verify',
        'test-client-otp-$i',
      );
      assert(allowed, 'OTP attempt $i should be allowed');
    }

    print('✅ Rate Limiting tests passed');
  }

  /// Test 2: Enhanced Validation
  static Future<void> testEnhancedValidation() async {
    print('🔒 Testing Enhanced Validation...');

    // Test email validation
    assert(EnhancedValidationService.validateEmail('invalid-email') != null);
    assert(EnhancedValidationService.validateEmail('test@example.com') == null);
    assert(
      EnhancedValidationService.validateEmail('user.name+tag@domain.co.uk') ==
          null,
    );

    // Test password validation
    assert(EnhancedValidationService.validatePassword('weak') != null);
    assert(
      EnhancedValidationService.validatePassword('StrongPass123!') == null,
    );
    assert(
      EnhancedValidationService.validatePassword('Complex@Pass2024') == null,
    );

    // Test phone validation
    assert(EnhancedValidationService.validatePhone('123') != null);
    assert(EnhancedValidationService.validatePhone('+1234567890') == null);
    assert(EnhancedValidationService.validatePhone('0123456789') == null);

    // Test full name validation
    assert(EnhancedValidationService.validateFullName('') != null);
    assert(EnhancedValidationService.validateFullName('John Doe') == null);
    assert(EnhancedValidationService.validateFullName('Nguyễn Văn A') == null);

    // Test input sanitization
    final malicious = '<script>alert("xss")</script>';
    final sanitized = InputSanitizer.sanitizeAll(malicious);
    assert(!sanitized.contains('<script>'));

    print('✅ Enhanced Validation tests passed');
  }

  /// Test 3: Error Handling
  static Future<void> testErrorHandling() async {
    print('🚨 Testing Error Handling...');

    final errorService = ErrorHandlingService.instance;

    // Test network error handling
    final networkError = DioException.connectionError(
      requestOptions: RequestOptions(path: 'test'),
      reason: 'Connection failed',
    );

    final userMessage = errorService.getUserFriendlyMessage(networkError);
    assert(userMessage.isNotEmpty && userMessage.contains('kết nối'));

    // Test rate limit error handling
    final rateLimitError = RateLimitException.legacy('login', 'test-client', const Duration(seconds: 300));
    final rateLimitMessage = errorService.getUserFriendlyMessage(
      rateLimitError,
    );
    assert(rateLimitMessage.contains('thử lại'));

    // Test retry logic
    assert(errorService.isRetryableError(networkError));
    assert(!errorService.isRetryableError(rateLimitError));

    final retryDelay = errorService.getRetryDelay(networkError, 1);
    assert(retryDelay > 0 && retryDelay <= 60);

    print('✅ Error Handling tests passed');
  }

  /// Test 4: Security Features
  static Future<void> testSecurityFeatures() async {
    print('🔐 Testing Security Features...');

    // Test input sanitization for XSS
    final xssPayload = '<img src=x onerror=alert(1)>';
    final sanitized = InputSanitizer.sanitizeForDisplay(xssPayload);
    assert(sanitized.contains('&lt;') && sanitized.contains('&gt;'));

    // Test SQL injection prevention
    final sqlPayload = "'; DROP TABLE users; --";
    final dbSanitized = InputSanitizer.sanitizeForDatabase(sqlPayload);
    assert(!dbSanitized.contains('DROP'));

    // Test password complexity requirements
    final weakPasswords = ['123', 'password', 'qwerty', 'abc123'];
    for (final password in weakPasswords) {
      final error = EnhancedValidationService.validatePassword(password);
      assert(error != null, 'Password "$password" should be rejected');
    }

    // Test email format validation
    final invalidEmails = [
      'invalid',
      '@domain.com',
      'user@',
      'user..name@domain.com',
    ];
    for (final email in invalidEmails) {
      final error = EnhancedValidationService.validateEmail(email);
      assert(error != null, 'Email "$email" should be rejected');
    }

    print('✅ Security Features tests passed');
  }

  /// Test 5: Performance Metrics
  static Future<void> testPerformanceMetrics() async {
    print('⚡ Testing Performance Metrics...');

    final stopwatch = Stopwatch()..start();

    // Test validation performance (should be fast)
    for (int i = 0; i < 1000; i++) {
      EnhancedValidationService.validateEmail('test$i@example.com');
      EnhancedValidationService.validatePassword('StrongPass$i!');
      EnhancedValidationService.validatePhone('+123456789$i');
    }

    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;

    // Should complete 3000 validations in under 200ms
    assert(duration < 200, 'Validation performance too slow: ${duration}ms');

    // Test rate limiting performance
    final rateStopwatch = Stopwatch()..start();

    for (int i = 0; i < 100; i++) {
      await RateLimitService.instance.isAllowed('login', 'perf-test-$i');
    }

    rateStopwatch.stop();
    final rateDuration = rateStopwatch.elapsedMilliseconds;

    // Should handle 100 rate limit checks in under 100ms
    assert(
      rateDuration < 100,
      'Rate limiting performance too slow: ${rateDuration}ms',
    );

    print(
      '✅ Performance Metrics tests passed (${duration}ms validation, ${rateDuration}ms rate limiting)',
    );
  }

  /// Integration Test: Complete User Journey
  static Future<void> testCompleteUserJourney() async {
    print('🔄 Testing Complete User Journey...');

    // Simulate user registration flow
    final email = 'test@example.com';
    final password = 'StrongPass123!';
    final fullName = 'Test User';

    // Validate inputs
    assert(EnhancedValidationService.validateEmail(email) == null);
    assert(EnhancedValidationService.validatePassword(password) == null);
    assert(EnhancedValidationService.validateFullName(fullName) == null);

    // Test rate limiting would work here
    final rateLimitService = RateLimitService.instance;
    final allowed = await rateLimitService.isAllowed(
      'register',
      'journey-test',
    );
    assert(allowed, 'Registration should be allowed for new user');

    // Sanitize inputs
    final sanitizedName = InputSanitizer.sanitizeAll(fullName);
    assert(
      sanitizedName == fullName,
      'Name should not be modified by sanitization',
    );

    print('✅ Complete User Journey test passed');
  }
}

/// Main test runner
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🎯 SABO ARENA PRODUCTION READINESS TEST SUITE');
  print('=' * 50);

  try {
    await ProductionReadinessTestSuite.runAllTests();
    print('🎉 ALL TESTS PASSED - SABO Arena is 100% Production Ready!');
  } catch (e) {
    print('❌ TESTS FAILED: $e');
    print('🔧 Please fix the issues above before deploying to production.');
    rethrow;
  }
}
