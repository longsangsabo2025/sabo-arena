import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to record tournament completion results for audit trail
class TournamentResultHistoryService {
  final _supabase = Supabase.instance.client;

  /// Record complete tournament results after completion
  Future<void> recordTournamentResult({
    required String tournamentId,
    required String tournamentName,
    required String tournamentFormat,
    required int totalParticipants,
    required int totalMatches,
    required int prizePoolVnd,
    required List<Map<String, dynamic>> standings,
    required List<Map<String, dynamic>> eloUpdates,
    required List<Map<String, dynamic>> spaDistribution,
    List<Map<String, dynamic>>? prizeDistribution,
    List<Map<String, dynamic>>? vouchersIssued,
    required Map<String, bool> options,
    List<String>? errors,
    int? processingTimeMs,
  }) async {
    try {
      final completedBy = _supabase.auth.currentUser?.id;

      await _supabase.from('tournament_result_history').insert({
        'tournament_id': tournamentId,
        'tournament_name': tournamentName,
        'tournament_format': tournamentFormat,
        'completed_at': DateTime.now().toIso8601String(),
        'completed_by': completedBy,
        'total_participants': totalParticipants,
        'total_matches': totalMatches,
        'prize_pool_vnd': prizePoolVnd,
        'standings': standings,
        'elo_updates': eloUpdates,
        'spa_distribution': spaDistribution,
        'prize_distribution': prizeDistribution,
        'vouchers_issued': vouchersIssued,
        'elo_updated': options['updateElo'] ?? false,
        'spa_distributed': options['distributePrizes'] ?? false,
        'prizes_recorded': prizeDistribution != null && prizeDistribution.isNotEmpty,
        'vouchers_issued_flag': vouchersIssued != null && vouchersIssued.isNotEmpty,
        'options': options,
        'errors': errors,
        'processing_time_ms': processingTimeMs,
      });

      ProductionLogger.info('✅ Tournament result history recorded: $tournamentName', tag: 'tournament_result_history_service');
    } catch (e) {
      ProductionLogger.info('❌ Failed to record tournament result history: $e', tag: 'tournament_result_history_service');
      // Don't throw - history recording is not critical
    }
  }

  /// Get tournament result history for a specific tournament
  Future<Map<String, dynamic>?> getTournamentResultHistory(String tournamentId) async {
    try {
      final response = await _supabase
          .from('tournament_result_history')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      ProductionLogger.info('❌ Error fetching tournament result history: $e', tag: 'tournament_result_history_service');
      return null;
    }
  }

  /// Get all tournament results (admin only)
  Future<List<Map<String, dynamic>>> getAllTournamentResults({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('tournament_result_history')
          .select('*')
          .order('completed_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.info('❌ Error fetching all tournament results: $e', tag: 'tournament_result_history_service');
      return [];
    }
  }

  /// Get user's tournament history
  Future<List<Map<String, dynamic>>> getUserTournamentResults(String userId) async {
    try {
      final response = await _supabase
          .from('tournament_result_history')
          .select('*')
          .or('standings.@>.[{"participant_id":"$userId"}]')
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ProductionLogger.info('❌ Error fetching user tournament results: $e', tag: 'tournament_result_history_service');
      return [];
    }
  }

  /// Get statistics from result history
  Future<Map<String, dynamic>> getTournamentStatistics(String tournamentId) async {
    try {
      final result = await getTournamentResultHistory(tournamentId);
      if (result == null) return {};

      final standings = result['standings'] as List<dynamic>? ?? [];
      final eloUpdates = result['elo_updates'] as List<dynamic>? ?? [];
      final spaDistribution = result['spa_distribution'] as List<dynamic>? ?? [];

      // Calculate stats
      int totalEloGained = 0;
      int totalEloLost = 0;
      int totalSpaDistributed = 0;

      for (var update in eloUpdates) {
        final change = update['change'] as int? ?? 0;
        if (change > 0) {
          totalEloGained += change;
        } else {
          totalEloLost += change.abs();
        }
      }

      for (var spa in spaDistribution) {
        totalSpaDistributed += spa['bonus_spa'] as int? ?? 0;
      }

      return {
        'total_participants': standings.length,
        'total_elo_gained': totalEloGained,
        'total_elo_lost': totalEloLost,
        'net_elo_change': totalEloGained - totalEloLost,
        'total_spa_distributed': totalSpaDistributed,
        'processing_time_ms': result['processing_time_ms'],
        'completed_at': result['completed_at'],
      };
    } catch (e) {
      ProductionLogger.info('❌ Error calculating tournament statistics: $e', tag: 'tournament_result_history_service');
      return {};
    }
  }
}
