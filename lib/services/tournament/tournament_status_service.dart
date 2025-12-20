import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service for managing tournament status
class TournamentStatusService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mark tournament as completed
  Future<void> markAsCompleted({
    required String tournamentId,
  }) async {
    try {
      // Update tournament status
      await _supabase.from('tournaments').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', tournamentId);

      // Update all matches to completed
      await _supabase
          .from('matches')
          .update({'status': 'completed'}).eq('tournament_id', tournamentId);
    } catch (e) {
      rethrow;
    }
  }

  /// Validate tournament can be completed
  Future<Map<String, dynamic>> validateCompletion({
    required String tournamentId,
  }) async {
    try {
      // Get tournament
      final tournament = await _supabase
          .from('tournaments')
          .select('*')
          .eq('id', tournamentId)
          .single();

      // Check if already completed
      if (tournament['status'] == 'completed') {
        return {
          'canComplete': false,
          'reason': 'Tournament already completed',
        };
      }

      // Check if all matches are completed
      final incompleteMatches = await _supabase
          .from('matches')
          .select('id')
          .eq('tournament_id', tournamentId)
          .neq('status', 'completed');

      if (incompleteMatches.isNotEmpty) {
        return {
          'canComplete': false,
          'reason': '${incompleteMatches.length} matches still incomplete',
        };
      }

      return {
        'canComplete': true,
        'tournament': tournament,
      };
    } catch (e) {
      return {
        'canComplete': false,
        'reason': 'Validation error: $e',
      };
    }
  }
}
