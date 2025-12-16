import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 UNIFIED CACHE SERVICE
/// 
/// Consolidates all caching functionality into one service:
/// - app_cache_service.dart
/// - tournament_cache_service.dart
/// - dashboard_cache_service.dart
/// - cached_tournament_service.dart
/// - resilient_cache_service.dart
/// - cache_manager.dart
/// 
/// Features:
/// - Memory cache (fast, volatile)
/// - Persistent cache (SharedPreferences)
/// - TTL support
/// - Automatic cleanup
/// - Cache invalidation
class UnifiedCacheService {
  static UnifiedCacheService? _instance;
  static UnifiedCacheService get instance =>
      _instance ??= UnifiedCacheService._();

  UnifiedCacheService._();

  static const String _tag = 'UnifiedCache';

  // Memory cache
  final Map<String, _CacheEntry> _memoryCache = {};
  
  // Default TTL
  static const Duration defaultTTL = Duration(minutes: 5);
  static const Duration longTTL = Duration(hours: 1);
  static const Duration shortTTL = Duration(minutes: 1);

  // Cache keys
  static const String keyTournaments = 'cache_tournaments';
  static const String keyUserProfile = 'cache_user_profile';
  static const String keyClubs = 'cache_clubs';
  static const String keyLeaderboard = 'cache_leaderboard';
  static const String keyNotifications = 'cache_notifications';
  static const String keyDashboard = 'cache_dashboard';

  /// Initialize cache service
  Future<void> initialize() async {
    ProductionLogger.info('$_tag: Initializing cache service');
    await _cleanupExpiredCache();
  }

  // ============================================================================
  // MEMORY CACHE (Fast, volatile)
  // ============================================================================

  /// Get from memory cache
  T? getMemory<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }

  /// Set to memory cache
  void setMemory<T>(String key, T data, {Duration? ttl}) {
    _memoryCache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(ttl ?? defaultTTL),
    );
  }

  /// Remove from memory cache
  void removeMemory(String key) {
    _memoryCache.remove(key);
  }

  /// Clear all memory cache
  void clearMemory() {
    _memoryCache.clear();
    ProductionLogger.debug('$_tag: Memory cache cleared');
  }

  // ============================================================================
  // PERSISTENT CACHE (SharedPreferences)
  // ============================================================================

  /// Get from persistent cache
  Future<T?> getPersistent<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;

      final cached = json.decode(jsonString) as Map<String, dynamic>;
      final expiry = DateTime.parse(cached['expiry'] as String);
      
      if (DateTime.now().isAfter(expiry)) {
        await prefs.remove(key);
        return null;
      }

      return cached['data'] as T?;
    } catch (e) {
      ProductionLogger.warning('$_tag: Error reading persistent cache: $e');
      return null;
    }
  }

  /// Set to persistent cache
  Future<void> setPersistent<T>(String key, T data, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = {
        'data': data,
        'expiry': DateTime.now().add(ttl ?? defaultTTL).toIso8601String(),
      };
      await prefs.setString(key, json.encode(cached));
    } catch (e) {
      ProductionLogger.warning('$_tag: Error writing persistent cache: $e');
    }
  }

  /// Remove from persistent cache
  Future<void> removePersistent(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      ProductionLogger.warning('$_tag: Error removing persistent cache: $e');
    }
  }

  // ============================================================================
  // CONVENIENCE METHODS
  // ============================================================================

  /// Get with fallback - tries memory first, then persistent
  Future<T?> get<T>(String key) async {
    // Try memory first
    final memoryData = getMemory<T>(key);
    if (memoryData != null) return memoryData;

    // Try persistent
    final persistentData = await getPersistent<T>(key);
    if (persistentData != null) {
      // Populate memory cache
      setMemory(key, persistentData);
    }
    return persistentData;
  }

  /// Set to both memory and persistent cache
  Future<void> set<T>(String key, T data, {Duration? ttl, bool persistOnly = false}) async {
    if (!persistOnly) {
      setMemory(key, data, ttl: ttl);
    }
    await setPersistent(key, data, ttl: ttl);
  }

  /// Remove from both caches
  Future<void> remove(String key) async {
    removeMemory(key);
    await removePersistent(key);
  }

  /// Clear all caches
  Future<void> clearAll() async {
    clearMemory();
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    ProductionLogger.info('$_tag: All caches cleared');
  }

  // ============================================================================
  // DOMAIN-SPECIFIC METHODS
  // ============================================================================

  /// Cache tournaments list
  Future<void> cacheTournaments(List<Map<String, dynamic>> tournaments) async {
    await set(keyTournaments, tournaments, ttl: defaultTTL);
  }

  /// Get cached tournaments
  Future<List<Map<String, dynamic>>?> getCachedTournaments() async {
    final data = await get<List<dynamic>>(keyTournaments);
    return data?.cast<Map<String, dynamic>>();
  }

  /// Cache user profile
  Future<void> cacheUserProfile(String oderId, Map<String, dynamic> profile) async {
    await set('${keyUserProfile}_$oderId', profile, ttl: longTTL);
  }

  /// Get cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile(String userId) async {
    return await get<Map<String, dynamic>>('${keyUserProfile}_$userId');
  }

  /// Cache dashboard data
  Future<void> cacheDashboard(String clubId, Map<String, dynamic> data) async {
    await set('${keyDashboard}_$clubId', data, ttl: shortTTL);
  }

  /// Get cached dashboard
  Future<Map<String, dynamic>?> getCachedDashboard(String clubId) async {
    return await get<Map<String, dynamic>>('${keyDashboard}_$clubId');
  }

  /// Invalidate tournament cache
  Future<void> invalidateTournamentCache() async {
    await remove(keyTournaments);
    // Also remove specific tournament caches
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.contains('tournament'));
    for (final key in keys) {
      await prefs.remove(key);
      _memoryCache.remove(key);
    }
  }

  /// Invalidate user cache
  Future<void> invalidateUserCache(String userId) async {
    await remove('${keyUserProfile}_$userId');
  }

  // ============================================================================
  // MAINTENANCE
  // ============================================================================

  /// Cleanup expired cache entries
  Future<void> _cleanupExpiredCache() async {
    // Memory cache
    _memoryCache.removeWhere((_, entry) => entry.isExpired);

    // Persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
      
      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final cached = json.decode(jsonString) as Map<String, dynamic>;
            final expiry = DateTime.parse(cached['expiry'] as String);
            if (DateTime.now().isAfter(expiry)) {
              await prefs.remove(key);
            }
          } catch (_) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      ProductionLogger.warning('$_tag: Error during cache cleanup: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'memory_entries': _memoryCache.length,
      'memory_valid': _memoryCache.values.where((e) => !e.isExpired).length,
    };
  }
}

/// Internal cache entry class
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}

