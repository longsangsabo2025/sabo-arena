import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'app_cache_service.dart';
import 'tournament_cache_service.dart';
import 'redis_cache_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Unified Cache Manager
/// Provides a single interface for all caching layers
/// 
/// Cache Strategy:
/// 1. Memory Cache (instant, limited size)
/// 2. Disk Cache (persistent, SharedPreferences)
/// 3. Redis Cache (server-side, shared across devices)
/// 4. Network (fallback)
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._();

  CacheManager._();

  // Cache TTL configurations
  static const Duration tournamentTTL = Duration(minutes: 5);
  static const Duration userProfileTTL = Duration(minutes: 15);
  static const Duration clubInfoTTL = Duration(minutes: 30);
  static const Duration tournamentBracketTTL = Duration(hours: 1); // Until match update
  static const Duration leaderboardTTL = Duration(minutes: 1);
  static const Duration staticDataTTL = Duration(hours: 24);

  // LRU Cache for memory (max 100 entries)
  final LinkedHashMap<String, _CacheEntry> _lruCache = LinkedHashMap();
  static const int _maxMemoryCacheSize = 100;

  /// Initialize cache manager
  Future<void> initialize() async {
    await AppCacheService.instance.initialize();
    await TournamentCacheService.initialize();
    RedisCacheService.instance.initialize();
    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Get tournament data (multi-layer cache)
  Future<Map<String, dynamic>?> getTournament(String tournamentId) async {
    // 1. Check memory cache
    final memoryEntry = _lruCache['tournament:$tournamentId'];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      _promoteToFront('tournament:$tournamentId');
      return memoryEntry.data as Map<String, dynamic>?;
    }

    // 2. Check disk cache
    final diskCache = await TournamentCacheService.getCachedTournament(tournamentId);
    if (diskCache != null) {
      // Promote to memory cache
      _setMemoryCache('tournament:$tournamentId', diskCache, tournamentTTL);
      return diskCache;
    }

    // 3. Check Redis cache
    final redisCache = await RedisCacheService.instance.getTournament(tournamentId);
    if (redisCache != null) {
      // Promote to disk and memory cache
      await TournamentCacheService.cacheTournament(tournamentId, redisCache);
      _setMemoryCache('tournament:$tournamentId', redisCache, tournamentTTL);
      return redisCache;
    }

    return null;
  }

  /// Cache tournament data (all layers)
  Future<void> setTournament(
    String tournamentId,
    Map<String, dynamic> data,
  ) async {
    // 1. Memory cache
    _setMemoryCache('tournament:$tournamentId', data, tournamentTTL);

    // 2. Disk cache
    await TournamentCacheService.cacheTournament(tournamentId, data);

    // 3. Redis cache
    await RedisCacheService.instance.setTournament(tournamentId, data, ttl: tournamentTTL);
  }

  /// Invalidate tournament cache (all layers)
  Future<void> invalidateTournament(String tournamentId) async {
    _lruCache.remove('tournament:$tournamentId');
    await TournamentCacheService.clearTournamentCache(tournamentId);
    await RedisCacheService.instance.invalidateTournament(tournamentId);
  }

  /// Get user profile (multi-layer cache)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    // 1. Memory cache
    final memoryEntry = _lruCache['user:$userId'];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      _promoteToFront('user:$userId');
      return memoryEntry.data as Map<String, dynamic>?;
    }

    // 2. Check disk cache
    final diskCache = await AppCacheService.instance.getCache('user:$userId');
    if (diskCache != null) {
      _setMemoryCache('user:$userId', diskCache, userProfileTTL);
      return diskCache as Map<String, dynamic>?;
    }

    // 3. Check Redis cache
    final redisCache = await RedisCacheService.instance.getUser(userId);
    if (redisCache != null) {
      await AppCacheService.instance.setCache(
        key: 'user:$userId',
        data: redisCache,
        ttl: userProfileTTL,
      );
      _setMemoryCache('user:$userId', redisCache, userProfileTTL);
      return redisCache;
    }

    return null;
  }

  /// Cache user profile (all layers)
  Future<void> setUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    _setMemoryCache('user:$userId', data, userProfileTTL);
    await AppCacheService.instance.setCache(
      key: 'user:$userId',
      data: data,
      ttl: userProfileTTL,
    );
    await RedisCacheService.instance.setUser(userId, data, ttl: userProfileTTL);
  }

  /// Invalidate user cache
  Future<void> invalidateUser(String userId) async {
    _lruCache.remove('user:$userId');
    await AppCacheService.instance.clearCache('user:$userId');
    await RedisCacheService.instance.invalidateUser(userId);
  }

  /// Get club data (multi-layer cache)
  Future<Map<String, dynamic>?> getClub(String clubId) async {
    // 1. Memory cache
    final memoryEntry = _lruCache['club:$clubId'];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      _promoteToFront('club:$clubId');
      return memoryEntry.data as Map<String, dynamic>?;
    }

    // 2. Check disk cache
    final diskCache = await AppCacheService.instance.getCache('club:$clubId');
    if (diskCache != null) {
      _setMemoryCache('club:$clubId', diskCache, clubInfoTTL);
      return diskCache as Map<String, dynamic>?;
    }

    // 3. Check Redis cache
    final redisCache = await RedisCacheService.instance.getClub(clubId);
    if (redisCache != null) {
      await AppCacheService.instance.setCache(
        key: 'club:$clubId',
        data: redisCache,
        ttl: clubInfoTTL,
      );
      _setMemoryCache('club:$clubId', redisCache, clubInfoTTL);
      return redisCache;
    }

    return null;
  }

  /// Cache club data
  Future<void> setClub(String clubId, Map<String, dynamic> data) async {
    _setMemoryCache('club:$clubId', data, clubInfoTTL);
    await AppCacheService.instance.setCache(
      key: 'club:$clubId',
      data: data,
      ttl: clubInfoTTL,
    );
    await RedisCacheService.instance.setClub(clubId, data, ttl: clubInfoTTL);
  }

  /// Invalidate club cache
  Future<void> invalidateClub(String clubId) async {
    _lruCache.remove('club:$clubId');
    await AppCacheService.instance.clearCache('club:$clubId');
    await RedisCacheService.instance.invalidateClub(clubId);
  }

  /// Cache warming: Pre-load frequently accessed data
  Future<void> warmCache({
    List<String>? tournamentIds,
    List<String>? userIds,
    List<String>? clubIds,
  }) async {
    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }

    // Warm tournament cache
    if (tournamentIds != null) {
      for (final id in tournamentIds.take(10)) {
        // Trigger cache load (will fetch if not cached)
        await getTournament(id);
      }
    }

    // Warm user cache
    if (userIds != null) {
      for (final id in userIds.take(20)) {
        await getUserProfile(id);
      }
    }

    // Warm club cache
    if (clubIds != null) {
      for (final id in clubIds.take(10)) {
        await getClub(id);
      }
    }

    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Generic cache getter
  Future<dynamic> getCache(String key) async {
    // Check memory cache first
    final memoryEntry = _lruCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      _promoteToFront(key);
      return memoryEntry.data;
    }

    // Check disk cache
    final diskCache = await AppCacheService.instance.getCache(key);
    if (diskCache != null) {
      // Promote to memory cache
      final ttl = _getTTLForKey(key);
      _setMemoryCache(key, diskCache, ttl);
      return diskCache;
    }

    return null;
  }

  /// Generic cache setter
  Future<void> setCache(
    String key,
    dynamic data, {
    Duration? ttl,
  }) async {
    final cacheTTL = ttl ?? _getTTLForKey(key);
    
    // Memory cache
    _setMemoryCache(key, data, cacheTTL);
    
    // Disk cache
    await AppCacheService.instance.setCache(
      key: key,
      data: data,
      ttl: cacheTTL,
    );
  }

  /// Get TTL for key based on prefix
  Duration _getTTLForKey(String key) {
    if (key.startsWith('tournament:')) return tournamentTTL;
    if (key.startsWith('user:')) return userProfileTTL;
    if (key.startsWith('club:')) return clubInfoTTL;
    if (key.startsWith('leaderboard:')) return leaderboardTTL;
    return Duration(minutes: 5); // Default TTL
  }

  /// Clear all caches
  Future<void> clearAll() async {
    _lruCache.clear();
    await AppCacheService.instance.clearAll();
    await TournamentCacheService.clearAllCache();
    if (kDebugMode) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final memorySize = _lruCache.length;
    final expiredEntries = _lruCache.values.where((e) => e.isExpired).length;

    return {
      'memory_cache_size': memorySize,
      'memory_cache_max_size': _maxMemoryCacheSize,
      'expired_entries': expiredEntries,
      'memory_usage_percent': (memorySize / _maxMemoryCacheSize * 100).round(),
    };
  }

  // Private helper methods
  void _setMemoryCache(String key, dynamic data, Duration ttl) {
    // Remove oldest entries if cache is full
    if (_lruCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _lruCache.keys.first;
      _lruCache.remove(oldestKey);
    }

    _lruCache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(ttl),
    );
  }

  void _promoteToFront(String key) {
    final entry = _lruCache.remove(key);
    if (entry != null) {
      _lruCache[key] = entry;
    }
  }

  /// Clean expired entries from memory cache
  /// Called periodically to free up memory
  void cleanExpiredEntries() {
    _lruCache.removeWhere((key, entry) => entry.isExpired);
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}


