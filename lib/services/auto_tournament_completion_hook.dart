// ==================================================================
// AUTO TOURNAMENT COMPLETION HOOK
// Hook tự động để trigger full completion workflow khi tournament kết thúc
// ==================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'tournament/tournament_completion_orchestrator.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service để tự động trigger tournament completion workflow
class AutoTournamentCompletionHook {
  static AutoTournamentCompletionHook? _instance;
  static AutoTournamentCompletionHook get instance =>
      _instance ??= AutoTournamentCompletionHook._();
  AutoTournamentCompletionHook._();

  /// Trigger khi tournament được mark là completed
  /// Gọi hàm này từ bất kỳ service nào khi tournament hoàn thành
  static Future<void> onTournamentCompleted({
    required String tournamentId,
    String? championId,
    bool sendNotifications = true,
    bool postToSocial = true,
    bool distributePrizes = true,
    bool updateElo = true,
  }) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Cập nhật basic tournament status nếu champion có
      if (championId != null) {
        await Supabase.instance.client
            .from('tournaments')
            .update({
              'status': 'completed',
              'winner_id': championId,
              'end_date': DateTime.now().toIso8601String(),
            })
            .eq('id', tournamentId);

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // 🆕 Trigger full completion workflow via Orchestrator (migrated from legacy service)
      final result = await TournamentCompletionOrchestrator.instance
          .completeTournament(
            tournamentId: tournamentId,
            distributePrizes: distributePrizes,
            sendNotifications: sendNotifications,
            updateElo: updateElo,
            issueVouchers: true, // Always issue vouchers to top 4
            executeRewards: false, // 🆕 DON'T execute rewards - let admin use "Gửi Quà" button
          );

      if (result['success']) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Log lỗi để debug
        await _logCompletionError(tournamentId, result['error']);
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      await _logCompletionError(tournamentId, e.toString());
    }
  }

  /// Log lỗi completion để tracking
  static Future<void> _logCompletionError(
    String tournamentId,
    String error,
  ) async {
    try {
      await Supabase.instance.client.from('tournament_completion_logs').insert({
        'tournament_id': tournamentId,
        'error_message': error,
        'error_type': 'auto_completion_failed',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Kiểm tra và auto-complete các tournament cần hoàn thành
  static Future<void> checkPendingCompletions() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Tìm tournaments có status completed nhưng chưa có trong tournament_results
      final pending = await Supabase.instance.client
          .from('tournaments')
          .select('id, title, status, winner_id')
          .eq('status', 'completed')
          .not(
            'id',
            'in',
            Supabase.instance.client
                .from('tournament_results')
                .select('tournament_id'),
          );

      if (pending.isNotEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        for (final tournament in pending) {
          await onTournamentCompleted(
            tournamentId: tournament['id'],
            championId: tournament['winner_id'],
            sendNotifications:
                false, // Không gửi notification cho các tournament cũ
            postToSocial: false, // Không post social cho tournament cũ
          );

          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Helper để các services khác gọi dễ dàng
  static Future<void> triggerCompletion(
    String tournamentId, [
    String? championId,
  ]) async {
    await onTournamentCompleted(
      tournamentId: tournamentId,
      championId: championId,
    );
  }

  /// Trigger completion với các options tùy chỉnh
  static Future<void> triggerCompletionWithOptions({
    required String tournamentId,
    String? championId,
    bool sendNotifications = true,
    bool postToSocial = true,
    bool distributePrizes = true,
    bool updateElo = true,
  }) async {
    await onTournamentCompleted(
      tournamentId: tournamentId,
      championId: championId,
      sendNotifications: sendNotifications,
      postToSocial: postToSocial,
      distributePrizes: distributePrizes,
      updateElo: updateElo,
    );
  }
}

