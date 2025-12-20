/// Dashboard Cache Service
///
/// Provides caching functionality for dashboard data to improve performance
/// Implements TTL (Time To Live) for automatic cache invalidation

import 'dart:async';
// ELON_MODE_AUTO_FIX

class CacheEntry<T> {
  final T data;
  final DateTime expiry;

  CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class DashboardCacheService {
  DashboardCacheService._internal();
  static final DashboardCacheService instance =
      DashboardCacheService._internal();

  final Map<String, CacheEntry> _cache = {};
  Timer? _cleanupTimer;

  /// Default cache duration
  static const Duration defaultTTL = Duration(minutes: 5);

  /// Initialize cache service with periodic cleanup
  void initialize() {
    // Run cleanup every minute
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanup();
    });
  }

  /// Store data in cache with TTL
  void set<T>(String key, T data, {Duration? ttl}) {
    final expiry = DateTime.now().add(ttl ?? defaultTTL);
    _cache[key] = CacheEntry<T>(data, expiry);
  }

  /// Get data from cache if not expired
  T? get<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove specific key from cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Clear cache for specific club
  void clearClubCache(String clubId) {
    final keysToRemove =
        _cache.keys.where((key) => key.startsWith('club_$clubId')).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Get or fetch data with caching
  Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetchFunction,
    Duration? ttl,
  }) async {
    // Try to get from cache first
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    // Fetch fresh data
    final data = await fetchFunction();

    // Store in cache
    set(key, data, ttl: ttl);

    return data;
  }

  /// Remove expired entries
  void _cleanup() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {}
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int active = 0;
    int expired = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expired++;
      } else {
        active++;
      }
    }

    return {
      'total': _cache.length,
      'active': active,
      'expired': expired,
      'timestamp': now.toIso8601String(),
    };
  }

  /// Dispose cache service
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

// ============================================================================
// Cache Key Constants
// ============================================================================

class CacheKeys {
  CacheKeys._();

  // Dashboard
  static String clubDashboard(String clubId) => 'club_${clubId}_dashboard';
  static String clubStats(String clubId) => 'club_${clubId}_stats';
  static String clubActivities(String clubId) => 'club_${clubId}_activities';

  // Members
  static String clubMembers(String clubId) => 'club_${clubId}_members';
  static String memberProfile(String userId) => 'user_${userId}_profile';
  static String memberStats(String userId) => 'user_${userId}_stats';

  // Tournaments
  static String clubTournaments(String clubId) => 'club_${clubId}_tournaments';
  static String tournamentDetail(String tournamentId) =>
      'tournament_${tournamentId}_detail';
  static String tournamentMatches(String tournamentId) =>
      'tournament_${tournamentId}_matches';

  // Analytics
  static String memberGrowth(String clubId) => 'club_${clubId}_member_growth';
  static String revenueData(String clubId) => 'club_${clubId}_revenue';
  static String tournamentStats(String clubId) =>
      'club_${clubId}_tournament_stats';
}

// ============================================================================
// Cache TTL Presets
// ============================================================================

class CacheTTL {
  CacheTTL._();

  static const Duration short = Duration(minutes: 2);
  static const Duration medium = Duration(minutes: 5);
  static const Duration long = Duration(minutes: 15);
  static const Duration veryLong = Duration(hours: 1);

  // Specific durations
  static const Duration dashboardStats = Duration(minutes: 5);
  static const Duration memberList = Duration(minutes: 10);
  static const Duration tournamentList = Duration(minutes: 5);
  static const Duration profileData = Duration(minutes: 15);
  static const Duration analyticsData = Duration(minutes: 30);
}
