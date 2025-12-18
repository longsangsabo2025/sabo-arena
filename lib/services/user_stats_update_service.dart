import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service để cập nhật thống kê user sau các trận đấu/giải đấu
class UserStatsUpdateService {
  static UserStatsUpdateService? _instance;
  static UserStatsUpdateService get instance =>
      _instance ??= UserStatsUpdateService._();
  UserStatsUpdateService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Cập nhật toàn bộ thống kê của user từ database
  Future<void> updateUserStats(String userId) async {
    try {

      // 1. Đếm số trận thắng
      final winsResponse = await _supabase
          .from('matches')
          .select('id')
          .eq('winner_id', userId)
          .eq('status', 'completed');

      final totalWins = winsResponse.length;

      // 2. Đếm tổng số trận đã chơi
      final matchesAsPlayer1 = await _supabase
          .from('matches')
          .select('id')
          .eq('player1_id', userId)
          .eq('status', 'completed');

      final matchesAsPlayer2 = await _supabase
          .from('matches')
          .select('id')
          .eq('player2_id', userId)
          .eq('status', 'completed');

      final totalMatches = matchesAsPlayer1.length + matchesAsPlayer2.length;
      final totalLosses = totalMatches - totalWins;

      // 3. Đếm số giải đấu đã tham gia
      final tournamentsResponse = await _supabase
          .from('tournament_participants')
          .select('tournament_id')
          .eq('user_id', userId);

      final totalTournaments = tournamentsResponse.length;

      // 4. Tính tổng SPA Points từ matches và tournaments
      final spaFromMatches = await _calculateSpaFromMatches(userId);
      final spaFromTournaments = await _calculateSpaFromTournaments(userId);
      final totalSpaPoints = spaFromMatches + spaFromTournaments;

      // 5. Tính tổng Prize Pool đã nhận
      final totalPrizePool = await _calculateTotalPrizePool(userId);

      // 6. Tính win streak hiện tại
      // final currentWinStreak = await calculateWinStreak(userId); // Unused

      // 7. Cập nhật vào database
      await _supabase
          .from('users')
          .update({
            'total_wins': totalWins.toInt(),
            'total_losses': totalLosses.toInt(),
            'total_tournaments': totalTournaments.toInt(),
            'spa_points': totalSpaPoints.toInt(),
            'total_prize_pool': totalPrizePool.toInt(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  /// Cập nhật thống kê cho nhiều user cùng lúc
  Future<void> updateMultipleUserStats(List<String> userIds) async {
    for (final userId in userIds) {
      try {
        await updateUserStats(userId);
      } catch (e) {
        // Ignore error
      }
    }
  }

  /// Cập nhật thống kê cho tất cả participants của một tournament
  Future<void> updateTournamentParticipantsStats(String tournamentId) async {
    try {
      final participantsResponse = await _supabase
          .from('tournament_participants')
          .select('user_id')
          .eq('tournament_id', tournamentId);

      final userIds = participantsResponse
          .map((p) => p['user_id'] as String)
          .toList();

      await updateMultipleUserStats(userIds);
    } catch (e) {
      // Ignore error
    }
  }

  /// Tính tổng SPA Points từ matches và tournaments thông qua transactions
  Future<int> _calculateSpaFromMatches(String userId) async {
    try {
      // Lấy SPA từ spa_transactions thay vì transactions
      final spaTransactions = await _supabase
          .from('spa_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('transaction_type', 'spa_bonus');

      int totalSpa = 0;
      for (final transaction in spaTransactions) {
        totalSpa += (transaction['amount'] as num).toInt();
      }

      return totalSpa;
    } catch (e) {
      return 0;
    }
  }

  /// Tính tổng SPA Points từ các giải đấu - KHÔNG DÙNG, chỉ lấy từ transactions
  Future<int> _calculateSpaFromTournaments(String userId) async {
    try {
      // Không tính toán ở đây nữa, SPA được cộng qua transactions khi tournament hoàn thành
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Tính tổng Prize Pool đã nhận
  Future<double> _calculateTotalPrizePool(String userId) async {
    try {
      // TODO: Implement prize pool calculation from tournament results
      // Hiện tại return 0.0, cần implement logic tính prize pool từ tournament standings
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Tính win streak hiện tại
  Future<int> calculateWinStreak(String userId) async {
    try {
      // Lấy 20 trận gần nhất của user
      final recentMatches = await _supabase
          .from('matches')
          .select('winner_id, created_at')
          .or('player1_id.eq.$userId,player2_id.eq.$userId')
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(20);

      int streak = 0;
      for (final match in recentMatches) {
        if (match['winner_id'] == userId) {
          streak++;
        } else {
          break; // Streak bị đứt
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }
}

