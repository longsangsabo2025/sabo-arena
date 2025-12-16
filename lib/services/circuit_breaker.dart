import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Circuit Breaker Pattern
/// Prevents cascading failures by stopping requests to failing services
/// 
/// States:
/// - CLOSED: Normal operation, requests pass through
/// - OPEN: Service failing, requests blocked, return cached/fallback data
/// - HALF_OPEN: Testing if service recovered, allow limited requests
class CircuitBreaker {
  final String name;
  final Duration timeout;
  final int failureThreshold;
  final Duration resetTimeout;
  
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;

  CircuitBreaker({
    required this.name,
    this.timeout = const Duration(seconds: 5),
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 60),
  });

  /// Execute function with circuit breaker protection
  Future<T> execute<T>(
    Future<T> Function() operation, {
    Future<T> Function()? fallback,
  }) async {
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitState.halfOpen;
        if (kDebugMode) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      } else {
        // Circuit is open, use fallback
        if (fallback != null) {
          if (kDebugMode) {
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
          }
          return await fallback();
        }
        throw CircuitBreakerOpenException('Circuit breaker $name is OPEN');
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      if (fallback != null && _state == CircuitState.open) {
        if (kDebugMode) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
        return await fallback();
      }
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    
    if (_state == CircuitState.halfOpen) {
      _successCount++;
      if (_successCount >= 2) {
        _state = CircuitState.closed;
        _successCount = 0;
        if (kDebugMode) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = CircuitState.open;
      _successCount = 0;
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      
      // Schedule reset attempt
      _resetTimer?.cancel();
      _resetTimer = Timer(resetTimeout, () {
        if (_state == CircuitState.open) {
          _state = CircuitState.halfOpen;
          if (kDebugMode) {
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
          }
        }
      });
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return true;
    return DateTime.now().difference(_lastFailureTime!) >= resetTimeout;
  }

  CircuitState get state => _state;
  int get failureCount => _failureCount;
  
  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
    _resetTimer?.cancel();
    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  void dispose() {
    _resetTimer?.cancel();
  }
}

enum CircuitState {
  closed,
  open,
  halfOpen,
}

class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => message;
}

/// Circuit Breaker Manager
/// Manages multiple circuit breakers
class CircuitBreakerManager {
  static CircuitBreakerManager? _instance;
  static CircuitBreakerManager get instance =>
      _instance ??= CircuitBreakerManager._();

  CircuitBreakerManager._();

  final Map<String, CircuitBreaker> _breakers = {};

  CircuitBreaker getBreaker(String name) {
    if (!_breakers.containsKey(name)) {
      _breakers[name] = CircuitBreaker(name: name);
    }
    return _breakers[name]!;
  }

  void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
  }

  void dispose() {
    for (final breaker in _breakers.values) {
      breaker.dispose();
    }
    _breakers.clear();
  }
}


