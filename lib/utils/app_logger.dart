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
    if (kDebugMode) {
      // ignore: avoid_print
      print('🔍 $context: $message');
    }
  }

  /// Log critical error (always)
  static void error(String context, dynamic error, [StackTrace? stack]) {
    if (!kDebugMode) return;

    if (kDebugMode) {
      // ignore: avoid_print
      print('\n🔴 ERROR [$context]');
      // ignore: avoid_print
      print('   $error');

      if (stack != null) {
        final lines = stack.toString().split('\n').take(3).join('\n   ');
        // ignore: avoid_print
        print('   Stack:\n   $lines');
      }
      // ignore: avoid_print
      print('');
    }
  }

  /// Log success (minimal)
  static void success(String context, [String? detail]) {
    if (!kDebugMode || !_enableDebugLogs) return;
    if (kDebugMode) {
      if (detail != null) {
        // ignore: avoid_print
        print('✅ $context: $detail');
      } else {
        // ignore: avoid_print
        print('✅ $context');
      }
    }
  }

  /// Log performance warning (>100ms operations)
  static void performance(String operation, Duration duration) {
    if (!kDebugMode) return;

    final ms = duration.inMilliseconds;
    if (kDebugMode) {
      if (ms > 1000) {
        // ignore: avoid_print
        print('🐌 SLOW: $operation (${ms}ms)');
      } else if (ms > 100 && _enableDebugLogs) {
        // ignore: avoid_print
        print('⏱️ $operation: ${ms}ms');
      }
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
