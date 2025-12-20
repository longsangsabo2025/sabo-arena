import 'package:supabase_flutter/supabase_flutter.dart';
import 'tournament_cache_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class CachedTournamentService {
  static const Duration _cacheMaxAge = Duration(minutes: 5);

  /// Load tournament with cache-first strategy
  static Future<Map<String, dynamic>?> loadTournament(
    String tournamentId, {
    bool forceRefresh = false,
  }) async {
    // Check if we should use cache
    if (!forceRefresh && !TournamentCacheService.isOfflineMode) {
      final hasCached = await TournamentCacheService.hasCachedTournament(
        tournamentId,
      );
      if (hasCached) {
        final cacheKey = 'tournament_$tournamentId';
        final isStale = await TournamentCacheService.isCacheStale(
          cacheKey,
          maxAge: _cacheMaxAge,
        );

        if (!isStale) {
          // Return fresh cached data
          final cached = await TournamentCacheService.getCachedTournament(
            tournamentId,
          );
          if (cached != null) {
            ProductionLogger.info('⚡ Using fresh cached tournament data',
                tag: 'cached_tournament_service');
            return cached;
          }
        }
      }
    }

    // If offline, use cache regardless of age
    if (TournamentCacheService.isOfflineMode) {
      final cached = await TournamentCacheService.getCachedTournament(
        tournamentId,
      );
      if (cached != null) {
        ProductionLogger.info('📴 Using cached data (offline mode)',
            tag: 'cached_tournament_service');
        return cached;
      } else {
        ProductionLogger.info('❌ No cached data available offline',
            tag: 'cached_tournament_service');
        return null;
      }
    }

    // Fetch from Supabase
    try {
      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*')
          .eq('id', tournamentId)
          .single();

      // Cache the fresh data
      await TournamentCacheService.cacheTournament(tournamentId, response);
      await TournamentCacheService.setCacheTimestamp(
        'tournament_$tournamentId',
      );

      ProductionLogger.info('🌐 Fetched fresh tournament data from Supabase',
          tag: 'cached_tournament_service');
      return response;
    } catch (e) {
      ProductionLogger.info('❌ Failed to fetch tournament from Supabase: $e',
          tag: 'cached_tournament_service');

      // Fallback to cache if network fails
      final cached = await TournamentCacheService.getCachedTournament(
        tournamentId,
      );
      if (cached != null) {
        ProductionLogger.info('⚡ Using stale cached data as fallback',
            tag: 'cached_tournament_service');
        return cached;
      }

      return null;
    }
  }

  /// Load matches with cache-first strategy
  static Future<List<Map<String, dynamic>>> loadMatches(
    String tournamentId, {
    bool forceRefresh = false,
  }) async {
    // Check if we should use cache
    if (!forceRefresh && !TournamentCacheService.isOfflineMode) {
      final hasCached = await TournamentCacheService.hasCachedMatches(
        tournamentId,
      );
      if (hasCached) {
        final cacheKey = 'matches_$tournamentId';
        final isStale = await TournamentCacheService.isCacheStale(
          cacheKey,
          maxAge: _cacheMaxAge,
        );

        if (!isStale) {
          // Return fresh cached data
          final cached = await TournamentCacheService.getCachedMatches(
            tournamentId,
          );
          if (cached != null) {
            ProductionLogger.info('⚡ Using fresh cached matches data',
                tag: 'cached_tournament_service');
            // Ensure matchId is available for compatibility in cached data
            final processedCache = cached.map((match) {
              final matchData = Map<String, dynamic>.from(match);
              if (matchData['matchId'] == null && matchData['id'] != null) {
                matchData['matchId'] = matchData['id'];
              }
              return matchData;
            }).toList();
            return processedCache;
          }
        }
      }
    }

    // If offline, use cache regardless of age
    if (TournamentCacheService.isOfflineMode) {
      final cached = await TournamentCacheService.getCachedMatches(
        tournamentId,
      );
      if (cached != null) {
        ProductionLogger.info('📴 Using cached matches (offline mode)',
            tag: 'cached_tournament_service');
        // Ensure matchId is available for compatibility in cached data
        final processedCache = cached.map((match) {
          final matchData = Map<String, dynamic>.from(match);
          if (matchData['matchId'] == null && matchData['id'] != null) {
            matchData['matchId'] = matchData['id'];
          }
          return matchData;
        }).toList();
        return processedCache;
      } else {
        ProductionLogger.info('❌ No cached matches available offline',
            tag: 'cached_tournament_service');
        return [];
      }
    }

    // Fetch from Supabase
    try {
      final response = await Supabase.instance.client
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');

      final matches = response as List<dynamic>;
      final matchList = matches.map((match) {
        final matchData = Map<String, dynamic>.from(match);
        // Ensure matchId is available for compatibility
        matchData['matchId'] = matchData['id'];
        return matchData;
      }).toList();

      // Cache the fresh data
      await TournamentCacheService.cacheMatches(tournamentId, matchList);
      await TournamentCacheService.setCacheTimestamp('matches_$tournamentId');

      ProductionLogger.info('🌐 Fetched fresh matches data from Supabase',
          tag: 'cached_tournament_service');
      return matchList;
    } catch (e) {
      ProductionLogger.info('❌ Failed to fetch matches from Supabase: $e',
          tag: 'cached_tournament_service');

      // Fallback to cache if network fails
      final cached = await TournamentCacheService.getCachedMatches(
        tournamentId,
      );
      if (cached != null) {
        ProductionLogger.info('⚡ Using stale cached matches as fallback',
            tag: 'cached_tournament_service');
        return cached;
      }

      return [];
    }
  }

  /// Update match score with offline support
  static Future<bool> updateMatchScore(
    String tournamentId,
    String matchId, {
    required int player1Score,
    required int player2Score,
    String? winnerId,
    required String status,
  }) async {
    final updateData = {
      'player1_score': player1Score,
      'player2_score': player2Score,
      'winner_id': winnerId,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // If offline, store pending action
    if (TournamentCacheService.isOfflineMode) {
      await TournamentCacheService.storePendingAction({
        'type': 'update_match',
        'tournament_id': tournamentId,
        'match_id': matchId,
        'data': updateData,
      });

      // Update local cache immediately for UI
      await _updateMatchInCache(tournamentId, matchId, updateData);

      ProductionLogger.info('📝 Stored match update for offline sync',
          tag: 'cached_tournament_service');
      return true;
    }

    // Try to update in Supabase
    try {
      await Supabase.instance.client
          .from('matches')
          .update(updateData)
          .eq('id', matchId);

      // Update cache with fresh data
      await _updateMatchInCache(tournamentId, matchId, updateData);

      // ❌ REMOVED: Advancement logic moved to dedicated services
      // - SABO DE32: Uses DatabaseFieldAdvancementService
      // - Other formats: Uses AutoAdvancementService via UniversalMatchProgressionService
      // This method is now ONLY for cache synchronization, not business logic
      // Callers should invoke advancement services separately if needed

      ProductionLogger.info(
          '🌐 Updated match in Supabase and cache (no advancement here)',
          tag: 'cached_tournament_service');
      return true;
    } catch (e) {
      ProductionLogger.info('❌ Failed to update match in Supabase: $e',
          tag: 'cached_tournament_service');

      // Store as pending action for later sync
      await TournamentCacheService.storePendingAction({
        'type': 'update_match',
        'tournament_id': tournamentId,
        'match_id': matchId,
        'data': updateData,
      });

      // Update local cache for immediate UI update
      await _updateMatchInCache(tournamentId, matchId, updateData);

      ProductionLogger.info('📝 Stored match update as pending action',
          tag: 'cached_tournament_service');
      return true; // Return true so UI updates immediately
    }
  }

  /// Helper to update match in cache
  static Future<void> _updateMatchInCache(
    String tournamentId,
    String matchId,
    Map<String, dynamic> updateData,
  ) async {
    final cachedMatches = await TournamentCacheService.getCachedMatches(
      tournamentId,
    );
    if (cachedMatches != null) {
      final matchIndex = cachedMatches.indexWhere((m) => m['id'] == matchId);
      if (matchIndex != -1) {
        // Merge update data into existing match
        cachedMatches[matchIndex] = {
          ...cachedMatches[matchIndex],
          ...updateData,
        };
        await TournamentCacheService.cacheMatches(tournamentId, cachedMatches);
        ProductionLogger.info('🔄 Updated match in cache',
            tag: 'cached_tournament_service');
      }
    }
  }

  /// Sync pending actions when back online
  static Future<void> syncPendingActions() async {
    if (TournamentCacheService.isOfflineMode) {
      ProductionLogger.info('📴 Cannot sync - still offline',
          tag: 'cached_tournament_service');
      return;
    }

    final pendingActions = await TournamentCacheService.getPendingActions();
    if (pendingActions.isEmpty) {
      ProductionLogger.info('✅ No pending actions to sync',
          tag: 'cached_tournament_service');
      return;
    }

    ProductionLogger.info(
        '🔄 Syncing ${pendingActions.length} pending actions...',
        tag: 'cached_tournament_service');

    int successCount = 0;
    List<Map<String, dynamic>> failedActions = [];

    for (final action in pendingActions) {
      try {
        if (action['type'] == 'update_match') {
          await Supabase.instance.client
              .from('matches')
              .update(action['data'])
              .eq('id', action['match_id']);

          successCount++;
          ProductionLogger.info('✅ Synced match update: ${action['match_id']}',
              tag: 'cached_tournament_service');
        } else if (action['type'] == 'create_match') {
          await Supabase.instance.client.from('matches').insert(action['data']);

          successCount++;
          ProductionLogger.info('✅ Synced match creation',
              tag: 'cached_tournament_service');
        }
      } catch (e) {
        ProductionLogger.info('❌ Failed to sync action ${action['type']}: $e',
            tag: 'cached_tournament_service');
        failedActions.add(action);
      }
    }

    // Clear successfully synced actions, keep failed ones
    if (failedActions.isEmpty) {
      await TournamentCacheService.clearPendingActions();
      ProductionLogger.info('🎉 All $successCount actions synced successfully',
          tag: 'cached_tournament_service');
    } else {
      // Store only failed actions back
      await TournamentCacheService.clearPendingActions();
      for (final failed in failedActions) {
        await TournamentCacheService.storePendingAction(failed);
      }
      ProductionLogger.info(
          '⚠️ $successCount synced, ${failedActions.length} failed',
          tag: 'cached_tournament_service');
    }
  }

  /// Force refresh data from server and update cache
  static Future<void> refreshTournamentData(String tournamentId) async {
    ProductionLogger.info('🔄 Force refreshing tournament data...',
        tag: 'cached_tournament_service');
    await loadTournament(tournamentId, forceRefresh: true);
    await loadMatches(tournamentId, forceRefresh: true);
  }

  /// Get cache status for debugging
  static Future<Map<String, dynamic>> getCacheStatus(
    String tournamentId,
  ) async {
    final stats = await TournamentCacheService.getCacheStats();
    final pendingActions = await TournamentCacheService.getPendingActions();
    final syncList = await TournamentCacheService.getSyncList();

    final hasTournament = await TournamentCacheService.hasCachedTournament(
      tournamentId,
    );
    final hasMatches = await TournamentCacheService.hasCachedMatches(
      tournamentId,
    );

    DateTime? tournamentCacheTime;
    DateTime? matchesCacheTime;

    if (hasTournament) {
      tournamentCacheTime = await TournamentCacheService.getCacheTimestamp(
        'tournament_$tournamentId',
      );
    }

    if (hasMatches) {
      matchesCacheTime = await TournamentCacheService.getCacheTimestamp(
        'matches_$tournamentId',
      );
    }

    return {
      'offline_mode': TournamentCacheService.isOfflineMode,
      'cache_stats': stats,
      'pending_actions': pendingActions.length,
      'sync_queue': syncList.length,
      'tournament_cached': hasTournament,
      'matches_cached': hasMatches,
      'tournament_cache_time': tournamentCacheTime?.toIso8601String(),
      'matches_cache_time': matchesCacheTime?.toIso8601String(),
    };
  }
}
