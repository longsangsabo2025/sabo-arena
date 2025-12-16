import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'circuit_breaker.dart';
import 'redis_cache_service.dart';
import 'app_cache_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Resilient Cache Service
/// Multi-layer cache with automatic fallback and circuit breakers
/// 
/// Cache Strategy (in order):
/// 1. Memory Cache (instant, limited size)
/// 2. Redis Cache (server-side, shared)
/// 3. Database (fallback if Redis fails)
/// 4. Network (last resort)
/// 
/// Features:
/// - Circuit breaker protection
/// - Automatic fallback between layers
/// - Graceful degradation
class ResilientCacheService {
  static ResilientCacheService? _instance;
  static ResilientCacheService get instance =>
      _instance ??= ResilientCacheService._();

  ResilientCacheService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CircuitBreaker _redisBreaker = CircuitBreakerManager.instance.getBreaker('redis');
  final CircuitBreaker _databaseBreaker = CircuitBreakerManager.instance.getBreaker('database');

  /// Get tournament with multi-layer cache and fallback
  Future<Map<String, dynamic>?> getTournament(String tournamentId) async {
    // Layer 1: Memory cache (AppCacheService)
    final memoryCache = await AppCacheService.instance.getCache('tournament:$tournamentId');
    if (memoryCache != null) {
      if (kDebugMode) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      return memoryCache as Map<String, dynamic>?;
    }

    // Layer 2: Redis cache (with circuit breaker)
    return await _redisBreaker.execute(
      () async {
        final redisCache = await RedisCacheService.instance.getTournament(tournamentId);
        if (redisCache != null) {
          // Store in memory cache for next time
          await AppCacheService.instance.setCache(
            key: 'tournament:$tournamentId',
            data: redisCache,
            ttl: const Duration(minutes: 5),
          );
          return redisCache;
        }
        throw Exception('Redis cache miss');
      },
      fallback: () async {
        // Layer 3: Database (with circuit breaker)
        return await _databaseBreaker.execute(
          () async {
            if (kDebugMode) {
              ProductionLogger.debug('Debug log', tag: 'AutoFix');
            }
            final response = await _supabase
                .from('tournaments')
                .select()
                .eq('id', tournamentId)
                .single();
            
            final data = response as Map<String, dynamic>?;
            
            // Cache in memory and Redis for next time
            if (data != null) {
              await AppCacheService.instance.setCache(
                key: 'tournament:$tournamentId',
                data: data,
                ttl: const Duration(minutes: 5),
              );
              // Try to cache in Redis (non-blocking)
              RedisCacheService.instance.setTournament(tournamentId, data).catchError((e) {
                if (kDebugMode) {
                  ProductionLogger.debug('Debug log', tag: 'AutoFix');
                }
              });
            }
            
            return data;
          },
          fallback: () async {
            // Layer 4: Return null (network/error)
            if (kDebugMode) {
              ProductionLogger.debug('Debug log', tag: 'AutoFix');
            }
            return null as Map<String, dynamic>?;
          },
        );
      },
    );
  }

  /// Get user profile with multi-layer cache and fallback
  Future<Map<String, dynamic>?> getUser(String userId) async {
    // Layer 1: Memory cache
    final memoryCache = await AppCacheService.instance.getCache('user:$userId');
    if (memoryCache != null) {
      return memoryCache as Map<String, dynamic>?;
    }

    // Layer 2: Redis cache
    return await _redisBreaker.execute(
      () async {
        final redisCache = await RedisCacheService.instance.getUser(userId);
        if (redisCache != null) {
          await AppCacheService.instance.setCache(
            key: 'user:$userId',
            data: redisCache,
            ttl: const Duration(minutes: 15),
          );
          return redisCache;
        }
        throw Exception('Redis cache miss');
      },
      fallback: () async {
        // Layer 3: Database
        return await _databaseBreaker.execute(
          () async {
            final response = await _supabase
                .from('profiles')
                .select()
                .eq('id', userId)
                .single();
            
            final data = response as Map<String, dynamic>?;
            
            if (data != null) {
              await AppCacheService.instance.setCache(
                key: 'user:$userId',
                data: data,
                ttl: const Duration(minutes: 15),
              );
              RedisCacheService.instance.setUser(userId, data).catchError((e) {
                if (kDebugMode) {
                  ProductionLogger.debug('Debug log', tag: 'AutoFix');
                }
              });
            }
            
            return data;
          },
          fallback: () async => null as Map<String, dynamic>?,
        );
      },
    );
  }

  /// Get club data with multi-layer cache and fallback
  Future<Map<String, dynamic>?> getClub(String clubId) async {
    // Layer 1: Memory cache
    final memoryCache = await AppCacheService.instance.getCache('club:$clubId');
    if (memoryCache != null) {
      return memoryCache as Map<String, dynamic>?;
    }

    // Layer 2: Redis cache
    return await _redisBreaker.execute(
      () async {
        final redisCache = await RedisCacheService.instance.getClub(clubId);
        if (redisCache != null) {
          await AppCacheService.instance.setCache(
            key: 'club:$clubId',
            data: redisCache,
            ttl: const Duration(minutes: 30),
          );
          return redisCache;
        }
        throw Exception('Redis cache miss');
      },
      fallback: () async {
        // Layer 3: Database
        return await _databaseBreaker.execute(
          () async {
            final response = await _supabase
                .from('clubs')
                .select()
                .eq('id', clubId)
                .single();
            
            final data = response as Map<String, dynamic>?;
            
            if (data != null) {
              await AppCacheService.instance.setCache(
                key: 'club:$clubId',
                data: data,
                ttl: const Duration(minutes: 30),
              );
              RedisCacheService.instance.setClub(clubId, data).catchError((e) {
                if (kDebugMode) {
                  ProductionLogger.debug('Debug log', tag: 'AutoFix');
                }
              });
            }
            
            return data;
          },
          fallback: () async => null as Map<String, dynamic>?,
        );
      },
    );
  }

  /// Invalidate cache across all layers
  Future<void> invalidateTournament(String tournamentId) async {
    await AppCacheService.instance.removeCache('tournament:$tournamentId');
    await RedisCacheService.instance.invalidateTournament(tournamentId);
  }

  /// Invalidate user cache across all layers
  Future<void> invalidateUser(String userId) async {
    await AppCacheService.instance.removeCache('user:$userId');
    await RedisCacheService.instance.invalidateUser(userId);
  }

  /// Invalidate club cache across all layers
  Future<void> invalidateClub(String clubId) async {
    await AppCacheService.instance.removeCache('club:$clubId');
    await RedisCacheService.instance.invalidateClub(clubId);
  }
}


