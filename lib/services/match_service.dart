import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_stats_update_service.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

import 'package:sabo_arena/models/match.dart';
export 'package:sabo_arena/models/match.dart';

class MatchService {
  static MatchService? _instance;
  static MatchService get instance => _instance ??= MatchService._();
  MatchService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get a single match by ID
  Future<Match?> getMatchById(String matchId) async {
    try {
      final response = await _supabase.from('matches').select('''
            *,
            player1:users!matches_player1_id_fkey (id, display_name, full_name, username, avatar_url, rank),
            player2:users!matches_player2_id_fkey (id, display_name, full_name, username, avatar_url, rank),
            winner:users!matches_winner_id_fkey (display_name, full_name, username),
            tournament:tournaments (title)
          ''').eq('id', matchId).maybeSingle();

      if (response == null) return null;
      return Match.fromJson(response);
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getMatchById',
          context: 'Failed to fetch match by ID',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<List<Match>> getTournamentMatches(String tournamentId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey (display_name, full_name, username),
            player2:users!matches_player2_id_fkey (display_name, full_name, username),
            winner:users!matches_winner_id_fkey (display_name, full_name, username),
            tournament:tournaments (title, club_id)
          ''')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');

      return response.map<Match>((json) => Match.fromJson(json)).toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getTournamentMatches',
          context: 'Failed to fetch tournament matches',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<List<Match>> getUserMatches(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey (id, display_name, full_name, username, avatar_url, rank),
            player2:users!matches_player2_id_fkey (id, display_name, full_name, username, avatar_url, rank),
            winner:users!matches_winner_id_fkey (display_name, full_name, username),
            tournament:tournaments (title, club_id)
          ''')
          .or('player1_id.eq.$userId,player2_id.eq.$userId')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<Match>((json) => Match.fromJson(json)).toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getUserMatches',
          context: 'Failed to fetch user matches',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<List<Match>> getLiveMatches({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey (display_name, full_name),
            player2:users!matches_player2_id_fkey (display_name, full_name),
            winner:users!matches_winner_id_fkey (display_name, full_name),
            tournament:tournaments (title, club_id)
          ''')
          .eq('status', 'in_progress')
          .order('start_time', ascending: false)
          .limit(limit);

      return response.map<Match>((json) => Match.fromJson(json)).toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getLiveMatches',
          context: 'Failed to fetch live matches',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<List<Match>> getUpcomingMatches({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey (display_name, full_name),
            player2:users!matches_player2_id_fkey (display_name, full_name),
            winner:users!matches_winner_id_fkey (display_name, full_name),
            tournament:tournaments (title, club_id)
          ''')
          .eq(
            'status',
            'pending',
          ) // REVERT: scheduled -> pending (correct enum)
          .gte(
            'scheduled_time',
            DateTime.now().toIso8601String(),
          ) // REVERT: scheduled_at -> scheduled_time
          .order('scheduled_time') // REVERT: scheduled_at -> scheduled_time
          .limit(limit);

      return response.map<Match>((json) => Match.fromJson(json)).toList();
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getUpcomingMatches',
          context: 'Failed to fetch upcoming matches',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<Match> updateMatchScore({
    required String matchId,
    required int player1Score,
    required int player2Score,
    String? winnerId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = {
        'player1_score': player1Score,
        'player2_score': player2Score,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (winnerId != null) {
        updateData['winner_id'] = winnerId;
        updateData['status'] = 'completed';
        updateData['end_time'] = DateTime.now().toIso8601String();

        // Cập nhật thống kê user khi trận đấu kết thúc
        try {
          // Lấy thông tin trận đấu để cập nhật thống kê cho cả 2 người chơi
          final matchInfo = await _supabase
              .from('matches')
              .select('player1_id, player2_id')
              .eq('id', matchId)
              .single();

          final player1Id = matchInfo['player1_id'] as String;
          final player2Id = matchInfo['player2_id'] as String;

          // Cập nhật thống kê cho cả 2 người chơi
          await UserStatsUpdateService.instance.updateUserStats(player1Id);
          await UserStatsUpdateService.instance.updateUserStats(player2Id);

          ProductionLogger.info('✅ Updated stats for match players',
              tag: 'match_service');
        } catch (e) {
          ProductionLogger.info('⚠️ Could not update player stats: $e',
              tag: 'match_service');
        }
      }

      final response = await _supabase
          .from('matches')
          .update(updateData)
          .eq('id', matchId)
          .select('''
            *,
            player1:users!matches_player1_id_fkey (display_name, full_name),
            player2:users!matches_player2_id_fkey (display_name, full_name),
            winner:users!matches_winner_id_fkey (display_name, full_name),
            tournament:tournaments (title)
          ''').single();

      return Match.fromJson(response);
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'updateMatchScore',
          context: 'Failed to update match score',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }

  Future<Match> startMatch(String matchId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('matches')
          .update({
            'status': 'in_progress',
            'start_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId)
          .select('''
            *,
            player1:users!matches_player1_id_fkey (display_name, full_name),
            player2:users!matches_player2_id_fkey (display_name, full_name),
            winner:users!matches_winner_id_fkey (display_name, full_name),
            tournament:tournaments (title)
          ''')
          .single();

      return Match.fromJson(response);
    } catch (error) {
      final errorInfo = StandardizedErrorHandler.handleError(
        error,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'startMatch',
          context: 'Failed to start match',
        ),
      );
      throw Exception(errorInfo.message);
    }
  }
}
