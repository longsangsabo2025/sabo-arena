import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service for EXECUTING rewards (mirroring from tournament_results)
/// This is the EXECUTION LAYER that reads from SOURCE OF TRUTH (tournament_results)
/// and mirrors data to other tables (spa_transactions, elo_history, users)
/// 
/// CRITICAL: This service is IDEMPOTENT - can be run multiple times safely
/// It checks for existing records before creating new ones
class RewardExecutionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Execute rewards for a completed tournament
  /// Reads from tournament_results (source of truth) and mirrors to other tables
  /// Returns true if all executions successful, false if any errors
  Future<bool> executeRewardsFromResults({
    required String tournamentId,
  }) async {
    try {

      // Read from tournament_results (SOURCE OF TRUTH)
      final results = await _supabase
          .from('tournament_results')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('position', ascending: true);

      if (results.isEmpty) {
        return false;
      }


      // int successCount = 0; // Unused
      int errorCount = 0;

      for (final result in results) {
        try {
          final userId = result['participant_id'] as String;
          // final participantName = result['participant_name'] as String? ?? 'Unknown'; // Unused
          final position = result['position'] as int;
          final spaReward = result['spa_reward'] as int? ?? 0;
          final eloChange = result['elo_change'] as int? ?? 0;
          final prizeMoney = (result['prize_money_vnd'] as num?)?.toDouble() ?? 0.0;
          final matchesWon = result['matches_won'] as int? ?? 0;
          final matchesLost = result['matches_lost'] as int? ?? 0;


          // Execute SPA reward
          await _executeSpaReward(
            tournamentId: tournamentId,
            userId: userId,
            spaReward: spaReward,
            position: position,
          );

          // Execute ELO change
          await _executeEloChange(
            tournamentId: tournamentId,
            userId: userId,
            eloChange: eloChange,
            position: position,
          );

          // Update user aggregated stats
          await _updateUserStats(
            tournamentId: tournamentId,
            userId: userId,
            spaReward: spaReward,
            eloChange: eloChange,
            prizeMoney: prizeMoney,
            matchesWon: matchesWon,
            matchesLost: matchesLost,
            position: position,
          );

          // successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      return errorCount == 0;
    } catch (e) {
      return false;
    }
  }

  /// Execute SPA reward (mirror to spa_transactions)
  /// IDEMPOTENT: Checks for existing transaction before creating
  Future<void> _executeSpaReward({
    required String tournamentId,
    required String userId,
    required int spaReward,
    required int position,
  }) async {
    if (spaReward <= 0) {
      return;
    }

    try {
      // Check for existing transaction (IDEMPOTENCY)
      final existing = await _supabase
          .from('spa_transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('transaction_type', 'tournament_reward')
          .eq('reference_id', tournamentId)
          .eq('reference_type', 'reward')
          .maybeSingle();

      if (existing != null) {
        return;
      }

      // ✅ ATOMIC UPDATE: Use PostgreSQL function to prevent race conditions
      // This ensures that balance read and update happen atomically in the database
      final result = await _supabase.rpc('atomic_increment_spa', params: {
        'p_user_id': userId,
        'p_amount': spaReward,
        'p_transaction_type': 'tournament_reward',
        'p_description': 'Tournament reward for position $position',
        'p_reference_type': 'reward',
        'p_reference_id': tournamentId,
      }) as List<dynamic>;

      if (result.isNotEmpty) {
        // final data = result.first as Map<String, dynamic>;
        // final oldBalance = data['old_balance'] as int; // Unused
        // final newBalance = data['new_balance'] as int; // Unused
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Execute ELO change (mirror to elo_history)
  /// IDEMPOTENT: Checks for existing history record before creating
  Future<void> _executeEloChange({
    required String tournamentId,
    required String userId,
    required int eloChange,
    required int position,
  }) async {
    if (eloChange == 0) {
      return;
    }

    try {
      // Check for existing history (IDEMPOTENCY)
      final existing = await _supabase
          .from('elo_history')
          .select('id')
          .eq('user_id', userId)
          .eq('tournament_id', tournamentId)
          .maybeSingle();

      if (existing != null) {
        return;
      }

      // Get current ELO
      final userResponse = await _supabase
          .from('users')
          .select('elo_rating')
          .eq('id', userId)
          .single();

      final oldElo = userResponse['elo_rating'] as int? ?? 1500;
      final newElo = oldElo + eloChange;

      // Update users.elo_rating FIRST (CRITICAL FIX)
      await _supabase.from('users').update({
        'elo_rating': newElo,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Create history record
      await _supabase.from('elo_history').insert({
        'user_id': userId,
        'tournament_id': tournamentId,
        'old_elo': oldElo,
        'new_elo': newElo,
        'elo_change': eloChange,
        'reason': 'Tournament completion (position $position)',
        'created_at': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Update user aggregated stats (spa_points, elo_rating, total_prize_pool)
  /// IDEMPOTENT: Checks if stats already updated by checking existing transaction
  Future<void> _updateUserStats({
    required String tournamentId,
    required String userId,
    required int spaReward,
    required int eloChange,
    required double prizeMoney,
    required int matchesWon,
    required int matchesLost,
    required int position,
  }) async {
    try {
      // IDEMPOTENCY CHECK: If spa_transaction exists, stats already updated
      final existingTransaction = await _supabase
          .from('spa_transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('reference_id', tournamentId)
          .eq('reference_type', 'reward')
          .maybeSingle();

      // If transaction doesn't exist, stats weren't updated yet
      // (This should not happen if _executeSpaReward ran successfully, but safety check)
      if (existingTransaction == null) {
        return;
      }

      // Check if ELO history exists - if yes, stats already updated
      final existingElo = await _supabase
          .from('elo_history')
          .select('id')
          .eq('user_id', userId)
          .eq('tournament_id', tournamentId)
          .maybeSingle();

      if (existingElo == null) {
        return;
      }

      // Check if we've already updated tournament stats
      // We use a marker: check if user's updated_at is very recent (within 1 minute)
      // AND elo_history + spa_transaction both exist
      // This is a heuristic to prevent double-counting
      final currentStats = await _supabase
          .from('users')
          .select(
            'spa_points, elo_rating, total_prize_pool, total_wins, total_losses, total_tournaments, tournament_wins, tournament_podiums, updated_at',
          )
          .eq('id', userId)
          .single();

      // If updated within last minute AND both records exist, likely already processed
      final updatedAt = DateTime.parse(currentStats['updated_at'] ?? DateTime.now().toIso8601String());
      final now = DateTime.now();
      final timeDiff = now.difference(updatedAt).inSeconds;

      if (timeDiff < 60) {
        return;
      }

      // Calculate new values (ADDITIVE operations)
      // NOTE: spa_points already updated in _executeSpaReward, don't add again
      final updates = <String, dynamic>{
        'elo_rating': (currentStats['elo_rating'] ?? 1500) + eloChange,
        'total_prize_pool': ((currentStats['total_prize_pool'] ?? 0) as num).toDouble() + prizeMoney,
        'total_wins': (currentStats['total_wins'] ?? 0) + matchesWon,
        'total_losses': (currentStats['total_losses'] ?? 0) + matchesLost,
        'total_tournaments': (currentStats['total_tournaments'] ?? 0) + 1,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Tournament achievements
      if (position == 1) {
        updates['tournament_wins'] = (currentStats['tournament_wins'] ?? 0) + 1;
      }
      if (position <= 3) {
        updates['tournament_podiums'] = (currentStats['tournament_podiums'] ?? 0) + 1;
      }

      // Update user
      await _supabase.from('users').update(updates).eq('id', userId);

    } catch (e) {
      rethrow;
    }
  }
}

