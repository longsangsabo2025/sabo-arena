/// Exception thrown when rate limit is exceeded
class RateLimitException implements Exception {
  final String message;
  final Duration retryAfter;
  final int remainingRequests;
  final Duration timeWindow;
  final String? action;
  final String? identifier;

  const RateLimitException({
    required this.message,
    this.retryAfter = const Duration(minutes: 1),
    this.remainingRequests = 0,
    this.timeWindow = const Duration(minutes: 1),
    this.action,
    this.identifier,
  });

  /// Constructor for backward compatibility with auth_service.dart
  /// Usage: RateLimitException('login', clientIP, timeUntilReset)
  RateLimitException.legacy(
      String action, String identifier, Duration timeUntilReset)
      : this(
          message: 'Rate limit exceeded for $action',
          retryAfter: timeUntilReset,
          action: action,
          identifier: identifier,
          timeWindow: const Duration(minutes: 15),
        );

  /// Time until rate limit resets
  Duration get timeUntilReset => retryAfter;

  @override
  String toString() => 'RateLimitException: $message';

  /// Create a rate limit exception with retry information
  factory RateLimitException.withRetry({
    required String message,
    required Duration retryAfter,
    int remainingRequests = 0,
  }) {
    return RateLimitException(
      message: message,
      retryAfter: retryAfter,
      remainingRequests: remainingRequests,
    );
  }

  /// Create a standard rate limit exception
  factory RateLimitException.standard() {
    return const RateLimitException(
      message: 'Bạn đã thực hiện quá nhiều yêu cầu. Vui lòng thử lại sau.',
    );
  }
}
