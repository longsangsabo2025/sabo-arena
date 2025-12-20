import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// Complete Single Elimination Service - Clean Implementation
///
/// Mathematical advancement formula: nextMatch = ((currentMatch - 1) ~/ 2) + 1
/// For n players: n-1 total matches, log2(n) rounds
class CompleteSingleEliminationService {
  static CompleteSingleEliminationService? _instance;
  static CompleteSingleEliminationService get instance =>
      _instance ??= CompleteSingleEliminationService._();

  CompleteSingleEliminationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tag = 'CompleteSE';

  /// Process match result with mathematical advancement
  Future<Map<String, dynamic>> processMatchResult({
    required String matchId,
    required String winnerId,
    required Map<String, int> scores,
  }) async {
    ProductionLogger.debug(
        '$_tag: Processing match $matchId with winner $winnerId');

    try {
      // 1. Get match details
      final matchResponse = await _supabase
          .from('matches')
          .select(
              'id, tournament_id, round_number, match_number, player1_id, player2_id, is_completed')
          .eq('id', matchId)
          .single();

      if (matchResponse['is_completed'] == true) {
        return {
          'success': false,
          'error': 'Match already completed',
        };
      }

      final tournamentId = matchResponse['tournament_id'] as String;
      final roundNumber = matchResponse['round_number'] as int;
      final matchNumber = matchResponse['match_number'] as int;
      final player1Id = matchResponse['player1_id'] as String?;
      final player2Id = matchResponse['player2_id'] as String?;

      // 2. Validate
      if (player1Id == null || player2Id == null) {
        return {
          'success': false,
          'error': 'Match not ready - missing players',
        };
      }

      if (winnerId != player1Id && winnerId != player2Id) {
        return {
          'success': false,
          'error': 'Winner must be one of the match participants',
        };
      }

      // 3. Update match result
      await _supabase.from('matches').update({
        'winner_id': winnerId,
        'player1_score': scores['player1'] ?? 0,
        'player2_score': scores['player2'] ?? 0,
        'is_completed': true,
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);

      ProductionLogger.debug(
          '$_tag: Match $matchId updated with winner $winnerId');

      // 4. Calculate and advance winner to next match
      final advanceResult = await _advanceWinnerToNextMatch(
        tournamentId: tournamentId,
        currentRound: roundNumber,
        currentMatchNumber: matchNumber,
        winnerId: winnerId,
      );

      // 5. Check if tournament is complete
      final isComplete = await _checkTournamentComplete(tournamentId);

      return {
        'success': true,
        'match_id': matchId,
        'winner_id': winnerId,
        'advanced': advanceResult['advanced'] ?? false,
        'next_match_id': advanceResult['next_match_id'],
        'tournament_complete': isComplete,
      };
    } catch (e, stackTrace) {
      ProductionLogger.error(
        '$_tag: Error processing match result',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Advance winner to next match using position-based logic
  Future<Map<String, dynamic>> _advanceWinnerToNextMatch({
    required String tournamentId,
    required int currentRound,
    required int currentMatchNumber,
    required String winnerId,
  }) async {
    try {
      // Get tournament info to determine total rounds
      final tournament = await _supabase
          .from('tournaments')
          .select('max_participants')
          .eq('id', tournamentId)
          .single();

      final maxParticipants = tournament['max_participants'] as int;
      final totalRounds = _calculateTotalRounds(maxParticipants);

      // Check if this was the final
      if (currentRound >= totalRounds) {
        ProductionLogger.debug(
            '$_tag: This was the final match - no advancement needed');
        return {'advanced': false, 'reason': 'final_match'};
      }

      final nextRound = currentRound + 1;

      // 1. Get all matches in current round to find index
      final currentRoundMatches = await _supabase
          .from('matches')
          .select('id, match_number')
          .eq('tournament_id', tournamentId)
          .eq('round_number', currentRound)
          .order('match_number');

      // 2. Find index of current match in this round (0-based)
      final currentIndex = currentRoundMatches
          .indexWhere((m) => m['match_number'] == currentMatchNumber);
      if (currentIndex == -1) {
        throw Exception(
            'Current match $currentMatchNumber not found in round $currentRound');
      }

      // 3. Calculate next index (e.g., match 0 and 1 go to next match 0)
      final nextIndex = currentIndex ~/ 2;

      // 4. Get next round matches
      final nextRoundMatches = await _supabase
          .from('matches')
          .select('id, match_number')
          .eq('tournament_id', tournamentId)
          .eq('round_number', nextRound)
          .order('match_number');

      if (nextIndex >= nextRoundMatches.length) {
        ProductionLogger.warning(
            '$_tag: Next match not found at index $nextIndex in round $nextRound');
        return {'advanced': false, 'reason': 'next_match_not_found'};
      }

      final nextMatch = nextRoundMatches[nextIndex];

      // 5. Determine slot (Even index -> Player 1, Odd index -> Player 2)
      // Example: Index 0 -> P1 of Next Match 0
      //          Index 1 -> P2 of Next Match 0
      final isPlayer1Slot = (currentIndex % 2) == 0;
      final slotField = isPlayer1Slot ? 'player1_id' : 'player2_id';

      ProductionLogger.debug(
          '$_tag: Advancing winner to Round $nextRound, Match ${nextMatch['match_number']}, Slot: $slotField');

      // 6. Update next match with winner
      await _supabase.from('matches').update({
        slotField: winnerId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', nextMatch['id']);

      // 7. Check if next match is now ready (both players present)
      final updatedNextMatch = await _supabase
          .from('matches')
          .select('player1_id, player2_id')
          .eq('id', nextMatch['id'])
          .single();

      final p1 = updatedNextMatch['player1_id'] as String?;
      final p2 = updatedNextMatch['player2_id'] as String?;

      // ⚡ ELON FIX: Prevent players from facing themselves
      if (p1 != null && p2 != null && p1 == p2) {
        ProductionLogger.error(
          'CRITICAL BUG: Player $p1 would face themselves in next match! This should NEVER happen.',
          tag: _tag,
        );
        throw Exception('Invalid bracket state: Player cannot face themselves');
      }

      if (p1 != null && p2 != null) {
        await _supabase
            .from('matches')
            .update({'status': 'pending'}) // Ready to play
            .eq('id', nextMatch['id']);
      }

      ProductionLogger.debug(
          '$_tag: Winner advanced to match ${nextMatch['id']}');

      return {
        'advanced': true,
        'next_match_id': nextMatch['id'],
        'next_round': nextRound,
        'slot': slotField,
      };
    } catch (e) {
      ProductionLogger.error('$_tag: Error advancing winner', error: e);
      return {'advanced': false, 'error': e.toString()};
    }
  }

  /// Check if tournament is complete (final match has winner)
  Future<bool> _checkTournamentComplete(String tournamentId) async {
    try {
      final tournament = await _supabase
          .from('tournaments')
          .select('max_participants')
          .eq('id', tournamentId)
          .single();

      final maxParticipants = tournament['max_participants'] as int;
      final totalRounds = _calculateTotalRounds(maxParticipants);

      // Check final match
      final finalMatch = await _supabase
          .from('matches')
          .select('winner_id')
          .eq('tournament_id', tournamentId)
          .eq('round_number', totalRounds)
          .maybeSingle();

      return finalMatch != null && finalMatch['winner_id'] != null;
    } catch (e) {
      ProductionLogger.error('$_tag: Error checking tournament complete',
          error: e);
      return false;
    }
  }

  /// Calculate total rounds for n participants
  int _calculateTotalRounds(int participants) {
    if (participants <= 1) return 0;
    int rounds = 0;
    int n = participants;
    while (n > 1) {
      n = (n / 2).ceil();
      rounds++;
    }
    return rounds;
  }

  /// Calculate next match number using mathematical formula
  /// Formula: ((currentMatch - 1) ~/ 2) + 1
  /// Currently unused - logic moved inline but keeping for reference
  int _calculateNextMatchNumber(int currentMatchNumber) {
    return ((currentMatchNumber - 1) ~/ 2) + 1;
  }

  /// Create bracket for single elimination tournament
  Future<Map<String, dynamic>> createBracket({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    try {
      ProductionLogger.debug(
          '$_tag: Creating bracket for $tournamentId with ${participantIds.length} players');

      if (participantIds.length < 2) {
        return {'success': false, 'error': 'Need at least 2 participants'};
      }

      final totalRounds = _calculateTotalRounds(participantIds.length);
      final totalMatches = participantIds.length - 1;

      final matches = <Map<String, dynamic>>[];
      int matchCounter = 1;

      // Shuffle participants for random seeding
      final shuffled = List<String>.from(participantIds)..shuffle();

      for (int round = 1; round <= totalRounds; round++) {
        final matchesInRound =
            _calculateMatchesInRound(participantIds.length, round);

        for (int m = 1; m <= matchesInRound; m++) {
          final match = {
            'tournament_id': tournamentId,
            'round_number': round,
            'match_number': matchCounter,
            'player1_id': null,
            'player2_id': null,
            'status': 'pending',
            'is_completed': false,
          };

          // Assign players to round 1
          if (round == 1) {
            final idx = (matchCounter - 1) * 2;
            if (idx < shuffled.length) {
              match['player1_id'] = shuffled[idx];
            }
            if (idx + 1 < shuffled.length) {
              match['player2_id'] = shuffled[idx + 1];
            }
          }

          matches.add(match);
          matchCounter++;
        }
      }

      // Insert matches
      await _supabase.from('matches').insert(matches);

      ProductionLogger.debug(
          '$_tag: Created $totalMatches matches in $totalRounds rounds');

      return {
        'success': true,
        'total_matches': totalMatches,
        'total_rounds': totalRounds,
      };
    } catch (e, stackTrace) {
      ProductionLogger.error('$_tag: Error creating bracket',
          error: e, stackTrace: stackTrace);
      return {'success': false, 'error': e.toString()};
    }
  }

  int _calculateMatchesInRound(int totalParticipants, int round) {
    return totalParticipants ~/ (1 << round); // totalParticipants / 2^round
  }
}
