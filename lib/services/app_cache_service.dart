import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 🎯 FACEBOOK/INSTAGRAM APPROACH: Multi-layer Cache System
/// 
/// CACHE STRATEGY:
/// Layer 1: Memory Cache (instant access, lost on app restart)
/// Layer 2: Disk Cache (persistent, survives app restart)
/// Layer 3: Network (fallback)
/// 
/// BENEFITS:
/// ✅ Instant data display (no loading spinner)
/// ✅ Works offline
/// ✅ Reduces API calls
/// ✅ Better user experience
/// 
/// USAGE:
/// ```dart
/// // Save data
/// await AppCacheService.instance.setCache(
///   key: 'nearby_posts',
///   data: posts,
///   ttl: Duration(minutes: 5),
/// );
/// 
/// // Get data
/// final cachedPosts = await AppCacheService.instance.getCache('nearby_posts');
/// if (cachedPosts != null) {
///   // Use cached data immediately
///   setState(() => _posts = cachedPosts);
///   // Then fetch fresh data in background
///   _fetchFreshData();
/// }
/// ```
class AppCacheService {
  static AppCacheService? _instance;
  static AppCacheService get instance => _instance ??= AppCacheService._();
  AppCacheService._();

  // Layer 1: Memory Cache (fast access)
  final Map<String, _CacheEntry> _memoryCache = {};
  
  // Layer 2: Disk Cache (persistent)
  SharedPreferences? _prefs;
  
  static const String _cachePrefix = 'app_cache_';
  
  // 📊 PHASE 3: Performance Monitoring
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _memoryCacheHits = 0;
  int _diskCacheHits = 0;

  /// Initialize disk cache
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Save data to cache (both memory and disk)
  Future<void> setCache({
    required String key,
    required dynamic data,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    try {
      final now = DateTime.now();
      final expiry = now.add(ttl);
      
      // Layer 1: Memory cache
      _memoryCache[key] = _CacheEntry(data: data, expiry: expiry);
      
      // Layer 2: Disk cache
      if (_prefs == null) await initialize();
      final jsonData = jsonEncode({
        'data': data,
        'expiry': expiry.millisecondsSinceEpoch,
      });
      await _prefs!.setString('$_cachePrefix$key', jsonData);
      
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Get data from cache (memory first, then disk)
  Future<dynamic> getCache(String key) async {
    try {
      // Layer 1: Check memory cache first (fastest)
      final memoryEntry = _memoryCache[key];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        _cacheHits++;
        _memoryCacheHits++;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return memoryEntry.data;
      }
      
      // Layer 2: Check disk cache
      if (_prefs == null) await initialize();
      final jsonData = _prefs!.getString('$_cachePrefix$key');
      if (jsonData != null) {
        final decoded = jsonDecode(jsonData);
        final expiry = DateTime.fromMillisecondsSinceEpoch(decoded['expiry']);
        
        if (DateTime.now().isBefore(expiry)) {
          // Valid cache, restore to memory
          final data = decoded['data'];
          _memoryCache[key] = _CacheEntry(data: data, expiry: expiry);
          _cacheHits++;
          _diskCacheHits++;
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          return data;
        } else {
          // Expired, remove it
          await removeCache(key);
        }
      }
      
      _cacheMisses++;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    } catch (e) {
      _cacheMisses++;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Remove specific cache entry
  Future<void> removeCache(String key) async {
    _memoryCache.remove(key);
    if (_prefs == null) await initialize();
    await _prefs!.remove('$_cachePrefix$key');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Clear specific cache entry (alias for removeCache)
  Future<void> clearCache(String key) async {
    await removeCache(key);
  }

  /// Clear all cache
  Future<void> clearAll() async {
    _memoryCache.clear();
    if (_prefs == null) await initialize();
    
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await _prefs!.remove(key);
      }
    }
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Check if cache exists and is valid
  Future<bool> hasValidCache(String key) async {
    final data = await getCache(key);
    return data != null;
  }

  /// Get cache age (for debugging)
  Future<Duration?> getCacheAge(String key) async {
    try {
      if (_prefs == null) await initialize();
      final jsonData = _prefs!.getString('$_cachePrefix$key');
      if (jsonData != null) {
        final decoded = jsonDecode(jsonData);
        final expiry = DateTime.fromMillisecondsSinceEpoch(decoded['expiry']);
        return expiry.difference(DateTime.now());
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
    return null;
  }

  /// Cache specific data types with smart TTL
  
  /// Cache posts (5 minutes TTL)
  Future<void> cachePosts(String type, List<dynamic> posts) async {
    await setCache(
      key: 'posts_$type',
      data: posts,
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<dynamic>?> getCachedPosts(String type) async {
    final data = await getCache('posts_$type');
    return data != null ? List<dynamic>.from(data) : null;
  }

  /// Cache user profile (30 minutes TTL)
  Future<void> cacheUserProfile(String userId, Map<String, dynamic> profile) async {
    await setCache(
      key: 'profile_$userId',
      data: profile,
      ttl: const Duration(minutes: 30),
    );
  }

  Future<Map<String, dynamic>?> getCachedUserProfile(String userId) async {
    final data = await getCache('profile_$userId');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Cache club data (15 minutes TTL)
  Future<void> cacheClubData(String clubId, Map<String, dynamic> clubData) async {
    await setCache(
      key: 'club_$clubId',
      data: clubData,
      ttl: const Duration(minutes: 15),
    );
  }

  Future<Map<String, dynamic>?> getCachedClubData(String clubId) async {
    final data = await getCache('club_$clubId');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Cache tournament list (10 minutes TTL)
  Future<void> cacheTournaments(List<dynamic> tournaments) async {
    await setCache(
      key: 'tournaments',
      data: tournaments,
      ttl: const Duration(minutes: 10),
    );
  }

  Future<List<dynamic>?> getCachedTournaments() async {
    final data = await getCache('tournaments');
    return data != null ? List<dynamic>.from(data) : null;
  }
  
  /// 📊 PHASE 3: Performance Monitoring
  /// Print cache statistics for debugging and optimization
  void printCacheStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests * 100) : 0;
    
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }
  
  /// Reset cache statistics
  void resetStats() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _memoryCacheHits = 0;
    _diskCacheHits = 0;
    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }
}

/// Internal cache entry with expiry
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}

