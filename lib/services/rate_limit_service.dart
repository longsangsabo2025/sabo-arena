import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'dart:async';
// ELON_MODE_AUTO_FIX

/// Rate Limit Service
/// Prevents abuse by limiting API calls, tournament creation, and image uploads
///
/// Limits:
/// - API calls: 100 requests/minute per user
/// - Tournament creation: 5 per hour per user
/// - Image uploads: 20 per minute per user
class RateLimitService {
  static RateLimitService? _instance;
  static RateLimitService get instance => _instance ??= RateLimitService._();

  RateLimitService._();

  // Rate limit configurations
  static const int apiCallsPerMinute = 100;
  static const int tournamentCreationPerHour = 5;
  static const int imageUploadsPerMinute = 20;

  // Tracking maps: userId -> List of timestamps
  final Map<String, Queue<DateTime>> _apiCalls = {};
  final Map<String, Queue<DateTime>> _tournamentCreations = {};
  final Map<String, Queue<DateTime>> _imageUploads = {};

  // Action-based rate limiting (for auth actions like login, register, etc.)
  // Map: action -> Map: identifier (IP/userId) -> Queue of timestamps
  final Map<String, Map<String, Queue<DateTime>>> _actionLimits = {};

  // Rate limit configurations for actions
  static Map<String, Map<String, dynamic>> get _actionConfigs => {
        'login': {'max': 5, 'window': const Duration(minutes: 15)},
        'register': {'max': 3, 'window': const Duration(hours: 1)},
        'otp_send': {'max': 5, 'window': const Duration(minutes: 15)},
        'otp_verify': {'max': 10, 'window': const Duration(minutes: 15)},
        'password_reset': {'max': 3, 'window': const Duration(hours: 1)},
      };

  // Cleanup timer
  Timer? _cleanupTimer;

  /// Initialize rate limit service
  void initialize() {
    // Cleanup old entries every 5 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupOldEntries();
    });

    if (kDebugMode) {}
  }

  /// Check if API call is allowed
  Future<bool> checkApiCall(String userId) async {
    return _checkRateLimit(
      userId,
      _apiCalls,
      apiCallsPerMinute,
      const Duration(minutes: 1),
    );
  }

  /// Record API call
  void recordApiCall(String userId) {
    _recordAction(userId, _apiCalls);
  }

  /// Check if tournament creation is allowed
  Future<bool> checkTournamentCreation(String userId) async {
    return _checkRateLimit(
      userId,
      _tournamentCreations,
      tournamentCreationPerHour,
      const Duration(hours: 1),
    );
  }

  /// Record tournament creation
  void recordTournamentCreation(String userId) {
    _recordAction(userId, _tournamentCreations);
  }

  /// Check if image upload is allowed
  Future<bool> checkImageUpload(String userId) async {
    return _checkRateLimit(
      userId,
      _imageUploads,
      imageUploadsPerMinute,
      const Duration(minutes: 1),
    );
  }

  /// Record image upload
  void recordImageUpload(String userId) {
    _recordAction(userId, _imageUploads);
  }

  /// Check rate limit for a specific action
  bool _checkRateLimit(
    String userId,
    Map<String, Queue<DateTime>> actionMap,
    int maxActions,
    Duration timeWindow,
  ) {
    final now = DateTime.now();
    final queue = actionMap.putIfAbsent(userId, () => Queue<DateTime>());

    // Remove old entries outside time window
    while (queue.isNotEmpty && now.difference(queue.first) > timeWindow) {
      queue.removeFirst();
    }

    // Check if limit exceeded
    if (queue.length >= maxActions) {
      if (kDebugMode) {}
      return false;
    }

    return true;
  }

  /// Record an action
  void _recordAction(String userId, Map<String, Queue<DateTime>> actionMap) {
    final queue = actionMap.putIfAbsent(userId, () => Queue<DateTime>());
    queue.add(DateTime.now());
  }

  /// Get remaining quota for API calls
  int getRemainingApiCalls(String userId) {
    return _getRemainingQuota(
      userId,
      _apiCalls,
      apiCallsPerMinute,
      const Duration(minutes: 1),
    );
  }

  /// Get remaining quota for tournament creation
  int getRemainingTournamentCreations(String userId) {
    return _getRemainingQuota(
      userId,
      _tournamentCreations,
      tournamentCreationPerHour,
      const Duration(hours: 1),
    );
  }

  /// Get remaining quota for image uploads
  int getRemainingImageUploads(String userId) {
    return _getRemainingQuota(
      userId,
      _imageUploads,
      imageUploadsPerMinute,
      const Duration(minutes: 1),
    );
  }

  /// Get remaining quota
  int _getRemainingQuota(
    String userId,
    Map<String, Queue<DateTime>> actionMap,
    int maxActions,
    Duration timeWindow,
  ) {
    final now = DateTime.now();
    final queue = actionMap[userId];
    if (queue == null) {
      return maxActions;
    }

    // Remove old entries
    while (queue.isNotEmpty && now.difference(queue.first) > timeWindow) {
      queue.removeFirst();
    }

    return maxActions - queue.length;
  }

  /// Cleanup old entries
  void _cleanupOldEntries() {
    final now = DateTime.now();
    final maxAge = const Duration(hours: 1);

    for (final queue in _apiCalls.values) {
      while (queue.isNotEmpty && now.difference(queue.first) > maxAge) {
        queue.removeFirst();
      }
    }

    for (final queue in _tournamentCreations.values) {
      while (queue.isNotEmpty && now.difference(queue.first) > maxAge) {
        queue.removeFirst();
      }
    }

    for (final queue in _imageUploads.values) {
      while (queue.isNotEmpty && now.difference(queue.first) > maxAge) {
        queue.removeFirst();
      }
    }

    // Remove empty queues
    _apiCalls.removeWhere((key, queue) => queue.isEmpty);
    _tournamentCreations.removeWhere((key, queue) => queue.isEmpty);
    _imageUploads.removeWhere((key, queue) => queue.isEmpty);
  }

  /// Get rate limit statistics
  Map<String, dynamic> getStats() {
    return {
      'api_calls_tracked': _apiCalls.length,
      'tournament_creations_tracked': _tournamentCreations.length,
      'image_uploads_tracked': _imageUploads.length,
      'limits': {
        'api_calls_per_minute': apiCallsPerMinute,
        'tournament_creation_per_hour': tournamentCreationPerHour,
        'image_uploads_per_minute': imageUploadsPerMinute,
      },
    };
  }

  /// Check if an action is allowed for an identifier (IP address or user ID)
  Future<bool> isAllowed(String action, String identifier) async {
    final config = _actionConfigs[action];
    if (config == null) {
      // Unknown action, allow by default
      return true;
    }

    final maxActions = config['max'] as int;
    final timeWindow = config['window'] as Duration;

    // Get or create action map
    final actionMap =
        _actionLimits.putIfAbsent(action, () => <String, Queue<DateTime>>{});
    final queue = actionMap.putIfAbsent(identifier, () => Queue<DateTime>());

    final now = DateTime.now();

    // Remove old entries outside time window
    while (queue.isNotEmpty && now.difference(queue.first) > timeWindow) {
      queue.removeFirst();
    }

    // Check if limit exceeded
    if (queue.length >= maxActions) {
      if (kDebugMode) {}
      return false;
    }

    // Record this attempt
    queue.add(now);
    return true;
  }

  /// Get time until rate limit resets for an action
  Future<Duration> getTimeUntilReset(String action, String identifier) async {
    final config = _actionConfigs[action];
    if (config == null) {
      return Duration.zero;
    }

    final actionMap = _actionLimits[action];
    if (actionMap == null) {
      return Duration.zero;
    }

    final queue = actionMap[identifier];
    if (queue == null || queue.isEmpty) {
      return Duration.zero;
    }

    final timeWindow = config['window'] as Duration;
    final now = DateTime.now();
    final oldestEntry = queue.first;
    final elapsed = now.difference(oldestEntry);
    final remaining = timeWindow - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Reset all limits (for testing)
  @visibleForTesting
  void reset() {
    _apiCalls.clear();
    _tournamentCreations.clear();
    _imageUploads.clear();
    _actionLimits.clear();
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _apiCalls.clear();
    _tournamentCreations.clear();
    _imageUploads.clear();
    _actionLimits.clear();
  }
}
