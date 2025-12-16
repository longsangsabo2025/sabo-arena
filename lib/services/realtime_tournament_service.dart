// 🔥 SABO ARENA - Real-time Tournament Updates Service
// Phase 2: WebSocket integration for live tournament updates
// Handles real-time bracket updates, match results, and notifications

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'realtime_subscription_manager.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service quản lý real-time updates cho tournament system
class RealTimeTournamentService {
  static RealTimeTournamentService? _instance;
  static RealTimeTournamentService get instance =>
      _instance ??= RealTimeTournamentService._();
  RealTimeTournamentService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controllers for different types of updates
  final StreamController<Map<String, dynamic>> _tournamentUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _matchUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _participantUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Subscription management (now using RealtimeSubscriptionManager)
  final RealtimeSubscriptionManager _subscriptionManager = RealtimeSubscriptionManager.instance;

  // ==================== STREAM GETTERS ====================

  /// Stream for tournament status changes (active, completed, etc.)
  Stream<Map<String, dynamic>> get tournamentUpdates =>
      _tournamentUpdatesController.stream;

  /// Stream for match result updates and bracket progression
  Stream<Map<String, dynamic>> get matchUpdates =>
      _matchUpdatesController.stream;

  /// Stream for participant registration/withdrawal updates
  Stream<Map<String, dynamic>> get participantUpdates =>
      _participantUpdatesController.stream;

  // ==================== SUBSCRIPTION MANAGEMENT ====================

  /// Subscribe to real-time updates for a specific tournament
  /// Uses RealtimeSubscriptionManager for limit management
  Future<void> subscribeTournament(String tournamentId) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Use subscription manager (handles limits and cleanup)
      await _subscriptionManager.subscribeTournament(
        tournamentId,
        onUpdate: (data) {
          _handleTournamentUpdate(data);
        },
      );

      await _subscriptionManager.subscribeMatches(
        tournamentId,
        onUpdate: (data) {
          _handleMatchUpdate(data);
        },
      );

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Failed to subscribe to real-time updates: $e');
    }
  }

  /// Alias for subscribeTournament (for backward compatibility)
  Future<void> subscribeToTournamentUpdates(String tournamentId) async {
    return subscribeTournament(tournamentId);
  }

  /// Subscribe to specific table changes (generic subscription method)
  Stream<PostgresChangePayload> subscribeTo(String tableName) {
    final controller = StreamController<PostgresChangePayload>.broadcast();

    _supabase
        .channel('table_$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            controller.add(payload);
          },
        )
        .subscribe();

    return controller.stream;
  }

  /// Broadcast a tournament update to all listeners
  Future<void> broadcastTournamentUpdate(
    String tournamentId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      // Add metadata
      updateData['timestamp'] = DateTime.now().toIso8601String();
      updateData['tournament_id'] = tournamentId;

      // Broadcast to tournament updates stream
      _tournamentUpdatesController.add(updateData);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Unsubscribe from real-time updates for a specific tournament
  Future<void> unsubscribeTournament(String tournamentId) async {
    try {
      // Use subscription manager for cleanup
      await _subscriptionManager.unsubscribeTournament(tournamentId);
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Unsubscribe from all tournaments
  Future<void> unsubscribeAll() async {
    try {
      await _subscriptionManager.cleanupAll();
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  // ==================== UPDATE HANDLERS ====================

  /// Handle tournament table updates (status changes, etc.)
  void _handleTournamentUpdate(Map<String, dynamic> data) {
    try {
      final updateData = {
        'type': 'tournament_update',
        'tournament_id': data['id'],
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _tournamentUpdatesController.add(updateData);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Handle match updates (legacy method for compatibility)
  void _handleMatchUpdate(Map<String, dynamic> data) {
    try {
      final updateData = {
        'type': 'match_update',
        'match_id': data['id'],
        'tournament_id': data['tournament_id'],
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _matchUpdatesController.add(updateData);
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Detect specific changes between old and new records
  Map<String, Map<String, dynamic>> _detectChanges(
    Map<String, dynamic> oldRecord,
    Map<String, dynamic> newRecord,
  ) {
    final changes = <String, Map<String, dynamic>>{};

    for (final key in newRecord.keys) {
      if (oldRecord[key] != newRecord[key]) {
        changes[key] = {'old': oldRecord[key], 'new': newRecord[key]};
      }
    }

    return changes;
  }

  /// Check if tournament has active real-time subscriptions
  bool isSubscribed(String tournamentId) {
    // Check via subscription manager stats
    final stats = _subscriptionManager.getStats();
    final byType = stats['by_type'] as Map<String, dynamic>?;
    return byType?['tournament'] != null && (byType!['tournament'] as int) > 0;
  }

  /// Get list of currently subscribed tournament IDs
  List<String> getSubscribedTournaments() {
    // Subscription manager doesn't expose individual IDs
    // Return empty list for now - can be enhanced if needed
    return [];
  }

  // ==================== CLEANUP ====================

  /// Dispose of all streams and subscriptions
  Future<void> dispose() async {
    try {
      await unsubscribeAll();

      await _tournamentUpdatesController.close();
      await _matchUpdatesController.close();
      await _participantUpdatesController.close();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }
}

