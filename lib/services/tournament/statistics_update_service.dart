import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service for updating tournament statistics
class StatisticsUpdateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Update statistics after tournament completion
  Future<void> updateTournamentStatistics({
    required String tournamentId,
    required List<Map<String, dynamic>> standings,
    required Map<String, dynamic> tournament,
  }) async {

    try {
      // Update user statistics for all participants
      for (final standing in standings) {
        final participantId = standing['participant_id'] as String;
        final position = standing['position'] as int;

        await _updateUserStatistics(
          userId: participantId,
          position: position,
          matchesPlayed: standing['matches_played'] ?? 0,
          matchesWon: standing['matches_won'] ?? 0,
        );
      }

      // Update club statistics if tournament belongs to a club
      final clubId = tournament['club_id'] as String?;
      if (clubId != null) {
        await _updateClubStatistics(clubId: clubId);
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Update user tournament statistics
  Future<void> _updateUserStatistics({
    required String userId,
    required int position,
    required int matchesPlayed,
    required int matchesWon,
  }) async {
    try {
      // Get current stats
      final userStats = await _supabase
          .from('users')
          .select('total_tournaments, tournament_wins, tournament_podiums, total_wins, total_losses')
          .eq('id', userId)
          .single();

      final totalTournaments = (userStats['total_tournaments'] ?? 0) as int;
      final tournamentWins = (userStats['tournament_wins'] ?? 0) as int;
      final tournamentPodiums = (userStats['tournament_podiums'] ?? 0) as int;
      final totalWins = (userStats['total_wins'] ?? 0) as int;
      final totalLosses = (userStats['total_losses'] ?? 0) as int;

      // Calculate new values
      final newTotalTournaments = totalTournaments + 1;
      final newTournamentWins = position == 1 ? tournamentWins + 1 : tournamentWins;
      final newTournamentPodiums = position <= 4 ? tournamentPodiums + 1 : tournamentPodiums;
      final matchesLost = matchesPlayed - matchesWon;
      final newTotalWins = totalWins + matchesWon;
      final newTotalLosses = totalLosses + matchesLost;

      // Update the stats
      await _supabase.from('users').update({
        'total_tournaments': newTotalTournaments,
        'tournament_wins': newTournamentWins,
        'tournament_podiums': newTournamentPodiums,
        'total_wins': newTotalWins,
        'total_losses': newTotalLosses,
      }).eq('id', userId);

    } catch (e) {
      // Ignore error
    }
  }

  /// Update club tournament statistics
  Future<void> _updateClubStatistics({
    required String clubId,
  }) async {
    try {
      // Get current tournaments_hosted count
      final clubData = await _supabase
          .from('clubs')
          .select('tournaments_hosted')
          .eq('id', clubId)
          .single();

      final newCount = (clubData['tournaments_hosted'] ?? 0) + 1;
      
      await _supabase
          .from('clubs')
          .update({'tournaments_hosted': newCount})
          .eq('id', clubId);

    } catch (e) {
      // Ignore error
    }
  }
}

