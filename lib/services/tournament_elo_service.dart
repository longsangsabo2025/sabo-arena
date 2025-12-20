// 🏆 SABO ARENA - Tournament ELO Integration Service
// Integrates ELO rating system with tournament results and ranking progression
// Implements advanced ELO calculations with tournament bonuses and modifiers

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/tournament_service.dart';
import '../services/ranking_service.dart';
import '../services/config_service.dart';
import '../models/user_profile.dart';
import 'dart:math' as math;
import 'auto_notification_hooks.dart';
// ELON_MODE_AUTO_FIX

/// Service tích hợp ELO rating với tournament system
class TournamentEloService {
  static TournamentEloService? _instance;
  static TournamentEloService get instance =>
      _instance ??= TournamentEloService._();
  TournamentEloService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final RankingService _rankingService = RankingService();
  final ConfigService _configService = ConfigService.instance;

  // ==================== TOURNAMENT ELO PROCESSING ====================

  /// Process ELO changes cho tất cả participants sau khi tournament kết thúc
  Future<List<EloUpdateResult>> processTournamentEloChanges({
    required String tournamentId,
    required List<TournamentResult> results,
    required String tournamentFormat,
  }) async {
    try {
      // Get ELO configuration từ database
      final eloConfig = await _configService.getEloConfig();

      // Calculate ELO changes cho từng participant
      final eloChanges = await _calculateDetailedEloChanges(
        tournamentId: tournamentId,
        results: results,
        tournamentFormat: tournamentFormat,
        eloConfig: eloConfig,
      );

      // Apply ELO changes to database
      List<EloUpdateResult> updateResults = [];
      for (final change in eloChanges) {
        final updateResult = await _applyEloChange(change);
        updateResults.add(updateResult);
      }

      // Log tournament ELO changes
      await _logTournamentEloChanges(tournamentId, updateResults);

      // Check for rank promotions/demotions
      await _checkRankingChanges(updateResults);

      return updateResults;
    } catch (error) {
      throw Exception('Failed to process tournament ELO changes: $error');
    }
  }

  /// Calculate ELO changes - Simple fixed rewards based on position only
  Future<List<DetailedEloChange>> _calculateDetailedEloChanges({
    required String tournamentId,
    required List<TournamentResult> results,
    required String tournamentFormat,
    required EloConfig eloConfig,
  }) async {
    List<DetailedEloChange> eloChanges = [];
    final participantCount = results.length;

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final position = i + 1;

      // Get participant details
      final participant = await _getParticipantProfile(result.participantId);
      if (participant == null) continue;

      // Simple fixed ELO change based on position only (NO BONUSES)
      final eloChange = _calculateBaseEloChange(
        position: position,
        totalParticipants: participantCount,
        currentElo: participant.eloRating ?? 1200,
        eloConfig: eloConfig,
      );

      // Apply ELO limits
      final newElo = math.max(
        eloConfig.minElo,
        math.min(eloConfig.maxElo, (participant.eloRating ?? 1200) + eloChange),
      );

      final actualChange = newElo - (participant.eloRating ?? 1200);

      eloChanges.add(
        DetailedEloChange(
          participantId: result.participantId,
          oldElo: participant.eloRating ?? 1200,
          newElo: newElo,
          totalChange: actualChange,
          baseChange: eloChange,
          bonuses: TournamentBonuses(
            sizeBonus: 0,
            formatBonus: 0,
            perfectRunBonus: 0,
            upsetBonus: 0,
            streakBonus: 0,
            participationBonus: 0,
          ),
          performanceModifier: 1.0,
          position: position,
          tournamentId: tournamentId,
          reason: _generateChangeReason(
            position,
            participantCount,
            tournamentFormat,
          ),
        ),
      );
    }

    return eloChanges;
  }

  /// Calculate base ELO change dựa trên position (Fixed rewards based on SABO Arena rules)
  int _calculateBaseEloChange({
    required int position,
    required int totalParticipants,
    required int currentElo,
    required EloConfig eloConfig,
  }) {
    // Fixed ELO rewards for Top positions
    if (position == 1) {
      return 75; // Winner (Vô địch): +75 ELO
    } else if (position == 2) {
      return 50; // Runner-up (Á quân): +50 ELO
    } else if (position == 3 || position == 4) {
      return 35; // Đồng hạng 3 (Both 3rd & 4th): +35 ELO
    }

    // Percentage-based rewards for remaining positions
    if (position <= totalParticipants * 0.25) {
      return 25; // Top 25%: +25 ELO
    } else if (position <= totalParticipants * 0.5) {
      return 15; // Top 50%: +15 ELO
    } else if (position <= totalParticipants * 0.75) {
      return 10; // Top 75%: +10 ELO
    } else {
      return -5; // Bottom 25%: -5 ELO (small penalty)
    }
  }

  /// Apply ELO change to database
  Future<EloUpdateResult> _applyEloChange(DetailedEloChange change) async {
    try {
      // Update user's ELO rating
      await _supabase.from('users').update({
        'elo_rating': change.newElo,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', change.participantId);

      // Log ELO history
      await _supabase.from('elo_history').insert({
        'user_id': change.participantId,
        'old_elo': change.oldElo,
        'new_elo': change.newElo,
        'elo_change': change.totalChange,
        'reason': change.reason,
        'change_reason': change.reason,
        'tournament_id': change.tournamentId,
        'metadata': change.bonuses.toJson(),
        'created_at': DateTime.now().toIso8601String(),
      });

      return EloUpdateResult(
        participantId: change.participantId,
        success: true,
        oldElo: change.oldElo,
        newElo: change.newElo,
        change: change.totalChange,
        reason: change.reason,
      );
    } catch (error) {
      return EloUpdateResult(
        participantId: change.participantId,
        success: false,
        oldElo: change.oldElo,
        newElo: change.oldElo,
        change: 0,
        reason: 'Failed to update: $error',
      );
    }
  }

  /// Log tournament ELO changes
  Future<void> _logTournamentEloChanges(
    String tournamentId,
    List<EloUpdateResult> results,
  ) async {
    try {
      await _supabase.from('tournament_elo_logs').insert({
        'tournament_id': tournamentId,
        'total_participants': results.length,
        'successful_updates': results.where((r) => r.success).length,
        'failed_updates': results.where((r) => !r.success).length,
        'total_elo_distributed': results
            .where((r) => r.success)
            .map((r) => r.change)
            .fold(0, (a, b) => a + b),
        'processed_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      // Log error but don't throw
    }
  }

  /// Check for ranking changes after ELO updates
  Future<void> _checkRankingChanges(List<EloUpdateResult> updateResults) async {
    for (final result in updateResults.where((r) => r.success)) {
      final oldRank = _rankingService.getRankFromElo(result.oldElo);
      final newRank = _rankingService.getRankFromElo(result.newElo);

      if (oldRank != newRank) {
        await _notifyRankingChange(result.participantId, oldRank, newRank);
      }
    }
  }

  /// Notify user of ranking change
  Future<void> _notifyRankingChange(
    String userId,
    String oldRank,
    String newRank,
  ) async {
    try {
      // 🔔 Gửi thông báo thay đổi rank qua AutoNotificationHooks
      // Determine if it's rank up or rank down based on rank order
      // MIGRATED 2025: Removed K+/I+, updated order
      final rankOrder = [
        'K',
        'I',
        'H',
        'H+',
        'G',
        'G+',
        'F',
        'F+',
        'E',
        'D',
        'C'
      ];
      final oldIndex = rankOrder.indexOf(oldRank);
      final newIndex = rankOrder.indexOf(newRank);

      if (newIndex > oldIndex) {
        // Rank Up
        await AutoNotificationHooks.onRankUp(
          userId: userId,
          oldRank: oldRank,
          newRank: newRank,
        );
      } else if (newIndex < oldIndex) {
        // Rank Down
        await AutoNotificationHooks.onRankDown(
          userId: userId,
          oldRank: oldRank,
          newRank: newRank,
        );
      }
    } catch (error) {
      // Ignore error
    }
  }

  /// Get participant profile
  Future<UserProfile?> _getParticipantProfile(String participantId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', participantId)
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      return null;
    }
  }

  /// Generate change reason string
  String _generateChangeReason(
    int position,
    int totalParticipants,
    String format,
  ) {
    return 'Tournament: ${_getPositionText(position)}/$totalParticipants in ${_getFormatDisplayName(format)}';
  }

  String _getPositionText(int position) {
    switch (position) {
      case 1:
        return '🥇 1st';
      case 2:
        return '🥈 2nd';
      case 3:
        return '🥉 3rd';
      default:
        return '${position}th';
    }
  }

  String _getFormatDisplayName(String format) {
    switch (format) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'round_robin':
        return 'Round Robin';
      case 'swiss':
        return 'Swiss System';
      default:
        return format;
    }
  }
}

// ==================== DATA MODELS ====================

/// Detailed ELO Change with all bonuses and modifiers
class DetailedEloChange {
  final String participantId;
  final int oldElo;
  final int newElo;
  final int totalChange;
  final int baseChange;
  final TournamentBonuses bonuses;
  final double performanceModifier;
  final int position;
  final String tournamentId;
  final String reason;

  DetailedEloChange({
    required this.participantId,
    required this.oldElo,
    required this.newElo,
    required this.totalChange,
    required this.baseChange,
    required this.bonuses,
    required this.performanceModifier,
    required this.position,
    required this.tournamentId,
    required this.reason,
  });
}

/// Tournament Bonuses breakdown
class TournamentBonuses {
  final int sizeBonus;
  final int formatBonus;
  final int perfectRunBonus;
  final int upsetBonus;
  final int streakBonus;
  final int participationBonus;

  TournamentBonuses({
    required this.sizeBonus,
    required this.formatBonus,
    required this.perfectRunBonus,
    required this.upsetBonus,
    required this.streakBonus,
    required this.participationBonus,
  });

  int get total =>
      sizeBonus +
      formatBonus +
      perfectRunBonus +
      upsetBonus +
      streakBonus +
      participationBonus;

  Map<String, int> toJson() {
    return {
      'size_bonus': sizeBonus,
      'format_bonus': formatBonus,
      'perfect_run_bonus': perfectRunBonus,
      'upset_bonus': upsetBonus,
      'streak_bonus': streakBonus,
      'participation_bonus': participationBonus,
      'total': total,
    };
  }
}

/// ELO Update Result
class EloUpdateResult {
  final String participantId;
  final bool success;
  final int oldElo;
  final int newElo;
  final int change;
  final String reason;

  EloUpdateResult({
    required this.participantId,
    required this.success,
    required this.oldElo,
    required this.newElo,
    required this.change,
    required this.reason,
  });
}
