import 'package:flutter/foundation.dart';

/// 🔥 Development Error Handler - Tối ưu tốc độ làm việc 10X
///
/// Features:
/// - Lọc lỗi quan trọng vs không quan trọng
/// - Group lỗi giống nhau
/// - Tự động suggest fix
/// - Performance monitoring
class DevErrorHandler {
  static final DevErrorHandler _instance = DevErrorHandler._internal();
  static DevErrorHandler get instance => _instance;

  DevErrorHandler._internal();

  // Track errors to avoid duplicates
  final Set<String> _seenErrors = {};
  final Map<String, int> _errorCounts = {};

  // Whitelist - Bỏ qua những warning không quan trọng
  final List<String> _ignoredPatterns = [
    'Unused import',
    'unused_local_variable',
    'unused_field',
    'prefer_const',
    'avoid_print',
    'The value of the local variable',
    'The stack trace variable',
    'Dead code',
  ];

  // Critical errors cần fix ngay
  final List<String> _criticalPatterns = [
    'setState() or markNeedsBuild() called during build',
    'Assertion failed',
    'RenderBox was not laid out',
    'Duplicate GlobalKey',
    'There should be exactly one item',
    'The getter .* isn\'t defined',
    'Unexpected null value',
    'isn\'t a type',
  ];

  /// Check if error should be ignored
  bool shouldIgnore(String message) {
    for (var pattern in _ignoredPatterns) {
      if (message.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Check if error is critical
  bool isCritical(String message) {
    for (var pattern in _criticalPatterns) {
      if (RegExp(pattern).hasMatch(message)) {
        return true;
      }
    }
    return false;
  }

  /// Log error with smart filtering
  void logError(String context, dynamic error, [StackTrace? stack]) {
    if (!kDebugMode) return;

    final errorKey = '$context:${error.toString()}';

    // Ignore if seen too many times
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    if (_errorCounts[errorKey]! > 3) {
      // Only log first 3 times
      return;
    }

    final errorMessage = error.toString();

    // Check if should ignore
    if (shouldIgnore(errorMessage)) {
      return;
    }

    // Mark as seen
    if (_seenErrors.contains(errorKey)) {
      return;
    }
    _seenErrors.add(errorKey);

    // Determine severity
    final isCrit = isCritical(errorMessage);
    final icon = isCrit ? '🔴' : '⚠️';
    final severity = isCrit ? 'CRITICAL' : 'WARNING';

    // Log with context
    print('\n$icon [$severity] $context');
    print('Error: $errorMessage');

    // Suggest fix if possible
    _suggestFix(errorMessage);

    // Only print stack for critical errors
    if (isCrit && stack != null) {
      final stackLines = stack.toString().split('\n').take(5).join('\n');
      print('Stack (first 5 lines):\n$stackLines');
    }
    print('─' * 60);
  }

  /// Auto-suggest fixes
  void _suggestFix(String error) {
    if (error.contains('setState() or markNeedsBuild() called during build')) {
      print('💡 FIX: Wrap setState in SchedulerBinding.addPostFrameCallback()');
    } else if (error.contains('Duplicate GlobalKey')) {
      print('💡 FIX: Remove GlobalKey or ensure unique keys');
    } else if (error.contains('There should be exactly one item')) {
      print('💡 FIX: Check DropdownButton items for duplicate values');
    } else if (error.contains('isn\'t defined')) {
      print('💡 FIX: Check imports or add missing property/method');
    } else if (error.contains('Unexpected null value')) {
      print('💡 FIX: Add null check or provide default value');
    }
  }

  /// Log performance issue
  void logPerformance(String operation, Duration duration) {
    if (!kDebugMode) return;

    if (duration.inMilliseconds > 1000) {
      print('⏱️ SLOW OPERATION: $operation took ${duration.inMilliseconds}ms');
    } else if (duration.inMilliseconds > 100) {
      // Only log if > 100ms
      print('⏱️ $operation: ${duration.inMilliseconds}ms');
    }
  }

  /// Log success with minimal noise
  void logSuccess(String context, {String? detail}) {
    if (!kDebugMode) return;

    if (detail != null) {
      print('✅ $context: $detail');
    } else {
      print('✅ $context');
    }
  }

  /// Clear seen errors (useful for hot reload)
  void reset() {
    _seenErrors.clear();
    _errorCounts.clear();
  }

  /// Get error summary
  String getSummary() {
    final total = _errorCounts.length;
    final critical = _errorCounts.keys.where((k) => isCritical(k)).length;

    return '''
📊 Error Summary:
   Total unique errors: $total
   Critical errors: $critical
   Most common:
${_getMostCommon()}
''';
  }

  String _getMostCommon() {
    final sorted = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(3)
        .map((e) => '   - ${e.key.split(':')[0]} (${e.value}x)')
        .join('\n');
  }
}

/// Extension for easy logging
extension ErrorHandlerExtension on Object {
  void logError(String context, [StackTrace? stack]) {
    DevErrorHandler.instance.logError(context, this, stack);
  }
}

/// Measure performance
T measurePerformance<T>(String operation, T Function() fn) {
  final stopwatch = Stopwatch()..start();
  final result = fn();
  stopwatch.stop();
  DevErrorHandler.instance.logPerformance(operation, stopwatch.elapsed);
  return result;
}

Future<T> measurePerformanceAsync<T>(
  String operation,
  Future<T> Function() fn,
) async {
  final stopwatch = Stopwatch()..start();
  final result = await fn();
  stopwatch.stop();
  DevErrorHandler.instance.logPerformance(operation, stopwatch.elapsed);
  return result;
}
