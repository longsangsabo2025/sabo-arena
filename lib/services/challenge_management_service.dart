import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service to manage challenge lifecycle
/// Handles: accepting, starting, completing challenges
/// Independent from matches table (used for tournaments only)
class ChallengeManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Accept a challenge
  Future<void> acceptChallenge({
    required String challengeId,
    String? responseMessage,
  }) async {
    try {

      await _supabase.from('challenges').update({
        'status': 'accepted',
        'responded_at': DateTime.now().toIso8601String(),
        'response_message': responseMessage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', challengeId);

    } catch (e) {
      rethrow;
    }
  }

  /// Start a challenge (change status to in_progress)
  Future<void> startChallenge({
    required String challengeId,
  }) async {
    try {

      await _supabase.from('challenges').update({
        'status': 'in_progress',
        'start_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', challengeId);

    } catch (e) {
      rethrow;
    }
  }

  /// Complete a challenge with final scores
  Future<void> completeChallenge({
    required String challengeId,
    required String winnerId,
    required int player1Score,
    required int player2Score,
  }) async {
    try {

      final updates = {
        'status': 'completed',
        'winner_id': winnerId,
        'player1_score': player1Score,
        'player2_score': player2Score,
        'end_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('challenges').update(updates).eq('id', challengeId);

    } catch (e) {
      rethrow;
    }
  }

  /// Update challenge scores (for live scoring)
  Future<void> updateScores({
    required String challengeId,
    required int player1Score,
    required int player2Score,
  }) async {
    try {

      await _supabase.from('challenges').update({
        'player1_score': player1Score,
        'player2_score': player2Score,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', challengeId);

    } catch (e) {
      rethrow;
    }
  }

  /// Reject a challenge
  Future<void> rejectChallenge({
    required String challengeId,
    String? responseMessage,
  }) async {
    try {

      await _supabase.from('challenges').update({
        'status': 'rejected',
        'responded_at': DateTime.now().toIso8601String(),
        'response_message': responseMessage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', challengeId);

    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a challenge (by challenger)
  Future<void> cancelChallenge({
    required String challengeId,
  }) async {
    try {

      await _supabase.from('challenges').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', challengeId);

    } catch (e) {
      rethrow;
    }
  }

  /// Get challenge details
  Future<Map<String, dynamic>?> getChallengeDetails({
    required String challengeId,
  }) async {
    try {

      final response = await _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!fk_challenges_challenger_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating
            ),
            challenged:users!fk_challenges_challenged_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating
            ),
            club:clubs(
              id,
              name,
              logo_url
            )
          ''')
          .eq('id', challengeId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }
}

