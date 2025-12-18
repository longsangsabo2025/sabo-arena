import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service quản lý kết quả tournament
class TournamentResultService {
  static TournamentResultService? _instance;
  static TournamentResultService get instance =>
      _instance ??= TournamentResultService._();
  TournamentResultService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Lưu kết quả tournament (SINGLE SOURCE OF TRUTH pattern)
  /// Accepts COMPLETE reward data from RankingService
  /// This is the PRIMARY WRITER to tournament_results table
  Future<void> saveTournamentResults({
    required String tournamentId,
    required List<Map<String, dynamic>> standings,
  }) async {
    try {

      for (final standing in standings) {
        // Extract data from enhanced standing (includes ALL reward data)
        final userId = standing['participant_id']?.toString() ?? '';
        final participantName = standing['participant_name']?.toString() ?? 'Unknown';
        final position = standing['position'] as int? ?? 0;
        final matchesWon = standing['wins'] as int? ?? 0;
        final matchesLost = standing['losses'] as int? ?? 0;
        
        // Reward data (calculated by RankingService - SINGLE SOURCE OF TRUTH)
        final spaReward = standing['spa_reward'] as int? ?? 0;
        final eloChange = standing['elo_change'] as int? ?? 0;
        final prizeMoney = standing['prize_money_vnd'] as double? ?? 0.0;

        // Validate required fields
        if (userId.isEmpty) {
          continue;
        }


        // Save to tournament_results (PRIMARY record - source of truth)
        await _saveTournamentResult(
          tournamentId: tournamentId,
          userId: userId,
          participantName: participantName,
          position: position,
          matchesWon: matchesWon,
          matchesLost: matchesLost,
          spaReward: spaReward,
          eloChange: eloChange,
          prizeMoney: prizeMoney,
        );
      }

    } catch (e) {
      throw Exception('Failed to save tournament results: $e');
    }
  }

  /// Lưu kết quả vào bảng tournament_results (PRIMARY SOURCE OF TRUTH)
  /// Accepts COMPLETE reward data (no calculation here)
  Future<void> _saveTournamentResult({
    required String tournamentId,
    required String userId,
    required String participantName,
    required int position,
    required int matchesWon,
    required int matchesLost,
    required int spaReward,
    required int eloChange,
    required double prizeMoney,
  }) async {
    try {

      // Get user's current ELO
      final userResponse = await _supabase
          .from('users')
          .select('elo_rating')
          .eq('id', userId)
          .maybeSingle();
      
      final oldElo = userResponse?['elo_rating'] as int? ?? 1500;
      final newElo = oldElo + eloChange;
      
      // Voucher eligibility (top 4 only)
      String? voucherCode;
      int? voucherDiscount;
      
      if (position == 1) {
        voucherCode = 'WINNER_50';
        voucherDiscount = 50;
      } else if (position == 2) {
        voucherCode = 'RUNNER_30';
        voucherDiscount = 30;
      } else if (position == 3) {
        voucherCode = 'THIRD_20';
        voucherDiscount = 20;
      } else if (position == 4) {
        voucherCode = 'FOURTH_10';
        voucherDiscount = 10;
      }

      // Check if result already exists (idempotency)
      final existingResult = await _supabase
          .from('tournament_results')
          .select('id')
          .eq('tournament_id', tournamentId)
          .eq('participant_id', userId)
          .maybeSingle();

      final dataToSave = {
        'participant_name': participantName,
        'position': position, // ✅ FIXED: position (not final_position)
        'matches_played': matchesWon + matchesLost,
        'matches_won': matchesWon,
        'matches_lost': matchesLost,
        'games_won': matchesWon * 2, // Estimate games
        'games_lost': matchesLost * 2, // Estimate games
        'win_percentage': matchesWon + matchesLost > 0
            ? ((matchesWon / (matchesWon + matchesLost)) * 100).round()
            : 0,
        'points': spaReward, // For compatibility
        'old_elo': oldElo,
        'new_elo': newElo,
        'elo_change': eloChange, // SOURCE OF TRUTH
        'spa_reward': spaReward, // SOURCE OF TRUTH
        'prize_money_vnd': prizeMoney, // SOURCE OF TRUTH
        'voucher_code': voucherCode,
        'voucher_discount_percent': voucherDiscount,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingResult != null) {
        // Update existing record (idempotent operation)
        await _supabase
            .from('tournament_results')
            .update(dataToSave)
            .eq('tournament_id', tournamentId)
            .eq('participant_id', userId); // ✅ FIXED: participant_id (not user_id)
      } else {
        // Create new record
        
        await _supabase.from('tournament_results').insert({
          'tournament_id': tournamentId,
          'participant_id': userId, // ✅ FIXED: participant_id (not user_id)
          ...dataToSave,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy lịch sử tournament của user
  Future<List<Map<String, dynamic>>> getUserTournamentHistory(
    String userId,
  ) async {
    try {
      final results = await _supabase
          .from('tournament_results')
          .select('''
            *,
            tournaments!inner(id, title, start_date, status)
          ''')
          .eq('participant_id', userId) // ✅ FIXED: participant_id (not user_id)
          .order('created_at', ascending: false);

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Lấy kết quả chi tiết của một tournament
  Future<List<Map<String, dynamic>>> getTournamentResults(
    String tournamentId,
  ) async {
    try {
      final results = await _supabase
          .from('tournament_results')
          .select('''
            *,
            users!tournament_results_participant_id_fkey(id, full_name, username, avatar_url)
          ''')
          .eq('tournament_id', tournamentId)
          .order('position', ascending: true); // ✅ FIXED: position (not final_position)

      return results;
    } catch (e) {
      return [];
    }
  }
}

