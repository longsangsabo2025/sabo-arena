import 'package:flutter/foundation.dart';

/// 🚀 10X Performance Logger - Minimal noise, maximum signal
///
/// Usage:
/// - AppLogger.debug('Context', 'message'); // Only in debug mode
/// - AppLogger.error('Context', error, stack); // Always logged
/// - AppLogger.success('Context'); // Minimal success message
class AppLogger {
  // 🔥 TURN THIS OFF IN PRODUCTION OR WHEN NOT DEBUGGING
  static const bool _enableDebugLogs = false; // ← Change to true when debugging

  /// Log debug info (only if enabled)
  static void debug(String context, String message) {
    if (!kDebugMode || !_enableDebugLogs) return;
    print('🔍 $context: $message');
  }

  /// Log critical error (always)
  static void error(String context, dynamic error, [StackTrace? stack]) {
    if (!kDebugMode) return;

    print('\n🔴 ERROR [$context]');
    print('   $error');

    if (stack != null) {
      final lines = stack.toString().split('\n').take(3).join('\n   ');
      print('   Stack:\n   $lines');
    }
    print('');
  }

  /// Log success (minimal)
  static void success(String context, [String? detail]) {
    if (!kDebugMode || !_enableDebugLogs) return;
    if (detail != null) {
      print('✅ $context: $detail');
    } else {
      print('✅ $context');
    }
  }

  /// Log performance warning (>100ms operations)
  static void performance(String operation, Duration duration) {
    if (!kDebugMode) return;

    final ms = duration.inMilliseconds;
    if (ms > 1000) {
      print('🐌 SLOW: $operation (${ms}ms)');
    } else if (ms > 100 && _enableDebugLogs) {
      print('⏱️ $operation: ${ms}ms');
    }
  }
}

/// Quick measure helper
T measure<T>(String op, T Function() fn) {
  final sw = Stopwatch()..start();
  try {
    return fn();
  } finally {
    sw.stop();
    AppLogger.performance(op, sw.elapsed);
  }
}

Future<T> measureAsync<T>(String op, Future<T> Function() fn) async {
  final sw = Stopwatch()..start();
  try {
    return await fn();
  } finally {
    sw.stop();
    AppLogger.performance(op, sw.elapsed);
  }
}
