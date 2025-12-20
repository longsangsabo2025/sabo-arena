import 'package:flutter/foundation.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Enhanced Input Validation Service
/// Provides comprehensive input validation and sanitization for security
class EnhancedValidationService {
  static EnhancedValidationService? _instance;
  static EnhancedValidationService get instance =>
      _instance ??= EnhancedValidationService._();

  EnhancedValidationService._();

  /// Enhanced email validation with comprehensive regex and length checks
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được trống';
    }

    // Trim whitespace
    value = value.trim();

    // Length check (max 254 characters per RFC 5321)
    if (value.length > 254) {
      return 'Email quá dài (tối đa 254 ký tự)';
    }

    // Enhanced regex pattern - more strict than basic validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&' +
          "'" +
          r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }

    // Check for consecutive dots
    if (value.contains('..')) {
      return 'Email không được chứa hai dấu chấm liên tiếp';
    }

    // Check for leading/trailing dots in local part
    final localPart = value.split('@')[0];
    if (localPart.startsWith('.') || localPart.endsWith('.')) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  /// Enhanced password validation with multiple security requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được trống';
    }

    // Length requirements - simplified to 6 characters minimum
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    if (value.length > 128) {
      return 'Mật khẩu quá dài (tối đa 128 ký tự)';
    }

    return null;
  }

  /// Enhanced phone validation with international format support
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại không được trống';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Length check (minimum 8, maximum 15 digits for international)
    if (digitsOnly.length < 8) {
      return 'Số điện thoại quá ngắn (tối thiểu 8 chữ số)';
    }

    if (digitsOnly.length > 15) {
      return 'Số điện thoại quá dài (tối đa 15 chữ số)';
    }

    // Basic format validation - should start with country code or area code
    if (!RegExp(
      r'^(\+[1-9][0-9]{0,3})?[1-9][0-9]{6,13}$',
    ).hasMatch(digitsOnly)) {
      return 'Định dạng số điện thoại không hợp lệ';
    }

    return null;
  }

  /// Enhanced username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên người dùng không được trống';
    }

    // Length requirements
    if (value.length < 3) {
      return 'Tên người dùng phải có ít nhất 3 ký tự';
    }

    if (value.length > 30) {
      return 'Tên người dùng quá dài (tối đa 30 ký tự)';
    }

    // Character requirements - only alphanumeric, underscore, hyphen
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Tên người dùng chỉ được chứa chữ cái, số, gạch dưới và gạch ngang';
    }

    // Cannot start or end with special characters
    if (value.startsWith('_') ||
        value.startsWith('-') ||
        value.endsWith('_') ||
        value.endsWith('-')) {
      return 'Tên người dùng không được bắt đầu hoặc kết thúc bằng ký tự đặc biệt';
    }

    // Cannot have consecutive special characters
    if (RegExp(r'[_-]{2,}').hasMatch(value)) {
      return 'Tên người dùng không được chứa nhiều ký tự đặc biệt liên tiếp';
    }

    return null;
  }

  /// Input sanitization to prevent XSS and injection attacks
  static String? sanitizeInput(String? value) {
    if (value == null) return null;

    // Remove potential XSS characters and HTML tags
    String sanitized = value
        .replaceAll(
          RegExp(r'[<>"' + "'" + r'`]'),
          '',
        ) // Remove dangerous characters
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'javascript:'), '') // Remove javascript: protocol
        .replaceAll(RegExp(r'on\w+\s*='), '') // Remove event handlers
        .trim();

    // Limit length to prevent DoS
    if (sanitized.length > 10000) {
      sanitized = sanitized.substring(0, 10000);
    }

    return sanitized;
  }

  /// Validate and sanitize full name
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Họ và tên không được trống';
    }

    // Length check
    if (value.length < 2) {
      return 'Họ và tên quá ngắn';
    }

    if (value.length > 100) {
      return 'Họ và tên quá dài (tối đa 100 ký tự)';
    }

    // Character validation - allow letters, spaces, hyphens, apostrophes
    if (!RegExp(r"^[a-zA-ZÀ-ỹ\s\-.']+$").hasMatch(value)) {
      return 'Họ và tên chỉ được chứa chữ cái, khoảng trắng và dấu gạch ngang';
    }

    // Check for excessive spaces
    if (value.trim().split(RegExp(r'\s+')).length < 2) {
      return 'Vui lòng nhập đầy đủ họ và tên';
    }

    return null;
  }

  /// Validate tournament entry fee
  static String? validateEntryFee(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập phí tham gia';
    }

    final fee = double.tryParse(value);
    if (fee == null) {
      return 'Phí tham gia phải là một số hợp lệ';
    }

    if (fee < 0) {
      return 'Phí tham gia không được âm';
    }

    if (fee > 1000000) {
      return 'Phí tham gia quá cao (tối đa 1,000,000 VND)';
    }

    return null;
  }

  /// Validate tournament max participants
  static String? validateMaxParticipants(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số lượng người chơi tối đa';
    }

    final maxParticipants = int.tryParse(value);
    if (maxParticipants == null) {
      return 'Số lượng người chơi phải là một số nguyên hợp lệ';
    }

    if (maxParticipants < 2) {
      return 'Số lượng người chơi tối đa phải ít nhất là 2';
    }

    if (maxParticipants > 1000) {
      return 'Số lượng người chơi tối đa quá lớn (tối đa 1000)';
    }

    // Check if it's a power of 2 for bracket tournaments (optional but recommended)
    if (maxParticipants > 0 && (maxParticipants & (maxParticipants - 1)) != 0) {
      if (kDebugMode) {
        ProductionLogger.info(
            '⚠️ Warning: $maxParticipants is not a power of 2, bracket generation may have byes',
            tag: 'enhanced_validation_service');
      }
    }

    return null;
  }
}

/// Input Sanitization Utilities
class InputSanitizer {
  /// Comprehensive input sanitization for all user inputs
  static String sanitizeAll(String input) {
    return EnhancedValidationService.sanitizeInput(input) ?? '';
  }

  /// Sanitize for database insertion (remove SQL injection vectors)
  static String sanitizeForDatabase(String input) {
    String sanitized = input
        .replaceAll('\'', '\'\'') // Escape single quotes
        .replaceAll('--', '') // Remove SQL comments
        .replaceAll('/*', '') // Remove SQL comments
        .replaceAll('*/', '') // Remove SQL comments
        .replaceAll(';', '') // Remove statement terminators
        .replaceAll('xp_', '') // Remove dangerous stored procedures
        .replaceAll('sp_', ''); // Remove dangerous stored procedures

    return sanitized;
  }

  /// Sanitize for display (HTML entity encoding)
  static String sanitizeForDisplay(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll('\'', '&#x27;');
  }
}
