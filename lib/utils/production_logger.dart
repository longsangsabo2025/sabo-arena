import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
// ignore_for_file: avoid_print

/// 🔍 Production-Safe Logger
///
/// Unlike `print()` which is stripped in release mode, this logger:
/// - Works in BOTH debug AND release builds
/// - Uses dart:developer log() which is visible in device logs
/// - Can be extended to send to remote logging services (Firebase, Sentry)
/// - Helps diagnose production issues
class ProductionLogger {
  static const String _tag = 'SABO';
  
  /// Set to true to enable console logs in debug mode
  static bool enableConsoleLogs = false;

  /// Log information (always visible, even in production)
  static void info(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    developer.log(
      message,
      name: logTag,
      level: 800, // INFO level
    );

    // Also print in debug mode for convenience
    if (kDebugMode && enableConsoleLogs) {
      print('ℹ️ [$logTag] $message');
    }
  }

  /// Log errors (always visible, even in production)
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    final logTag = tag ?? _tag;
    developer.log(
      message,
      name: logTag,
      level: 1000, // SEVERE level
      error: error,
      stackTrace: stackTrace,
    );

    // Also print in debug mode for convenience
    if (kDebugMode && enableConsoleLogs) {
      print('❌ [$logTag] $message');
      if (error != null) print('   Error: $error');
      if (stackTrace != null) print('   Stack: $stackTrace');
    }
  }

  /// Log warnings (always visible, even in production)
  static void warning(String message, {Object? error, String? tag}) {
    final logTag = tag ?? _tag;
    developer.log(
      message,
      name: logTag,
      level: 900, // WARNING level
      error: error,
    );

    // Also print in debug mode for convenience
    if (kDebugMode && enableConsoleLogs) {
      print('⚠️ [$logTag] $message');
      if (error != null) print('   Error: $error');
    }
  }

  /// Log debug info (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (!kDebugMode) return;

    final logTag = tag ?? _tag;
    developer.log(
      message,
      name: logTag,
      level: 700, // DEBUG level
    );
    
    if (enableConsoleLogs) {
      print('🐛 [$logTag] $message');
    }
  }

  /// Log network requests (critical for debugging production issues)
  static void network(
    String method,
    String url, {
    int? statusCode,
    String? error,
  }) {
    final message = statusCode != null
        ? '[$method] $url -> $statusCode'
        : '[$method] $url -> ERROR: $error';

    developer.log(
      message,
      name: 'SABO.Network',
      level: error != null ? 1000 : 800,
    );

    if (kDebugMode && enableConsoleLogs) {
      print(error != null ? '🌐❌ $message' : '🌐 $message');
    }
  }

  /// Log authentication events (critical for login debugging)
  static void auth(String event, {String? details, bool isError = false}) {
    final message = details != null ? '$event: $details' : event;

    developer.log(message, name: 'SABO.Auth', level: isError ? 1000 : 800);

    if (kDebugMode && enableConsoleLogs) {
      print(isError ? '🔐❌ $message' : '🔐 $message');
    }
  }
}
