import 'package:supabase_flutter/supabase_flutter.dart';
import 'cached_tournament_service.dart';
import 'unified_bracket_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service for production bracket management with Supabase integration
class ProductionBracketService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Convert tournament creation format to Unified Bracket Service format
  String _mapToUnifiedFormat(String tournamentFormat) {
    // UnifiedBracketService expects: single_elimination, double_elimination, sabo_de16, etc.
    // If the DB format matches these, we are good.
    // If DB has 'swiss_system', Unified expects 'swiss'.
    switch (tournamentFormat) {
      case 'swiss_system':
        return 'swiss';
      default:
        return tournamentFormat;
    }
  }

  /// Get tournament information including format
  Future<Map<String, dynamic>?> getTournamentInfo(String tournamentId) async {
    try {
      final response = await _supabase
          .from('tournaments')
          .select('id, name, bracket_format, max_participants, status, start_date')
          .eq('id', tournamentId)
          .single();

      return response;
    } catch (e) {
      ProductionLogger.info('❌ Error loading tournament info: $e', tag: 'production_bracket_service');
      return null;
    }
  }

  /// Get tournaments that are ready for bracket creation
  Future<List<Map<String, dynamic>>> getTournamentsReadyForBracket() async {
    try {
      final response = await _supabase
          .from('tournaments')
          .select('''
            id,
            name,
            description,
            start_date,
            end_date,
            format,
            max_participants,
            tournament_participants!inner (
              id,
              users!inner (
                id,
                full_name,
                avatar_url
              ),
              registration_date,
              payment_status,
              seed_number
            )
          ''')
          .gte('start_date', DateTime.now().toIso8601String())
          .order('start_date');

      // Filter tournaments with enough participants

      // Filter tournaments with enough participants for bracket creation
      final tournamentList = (response as List).where((tournament) {
        final participants =
            tournament['tournament_participants'] as List? ?? [];
        final paidParticipants = participants
            .where((p) => p['payment_status'] == 'completed')
            .length;
        return paidParticipants >= 4; // Minimum for bracket
      }).toList();

      return tournamentList.cast<Map<String, dynamic>>();
    } catch (e) {
      ProductionLogger.info('❌ Error loading tournaments: $e', tag: 'production_bracket_service');
      return [];
    }
  }

  /// Get tournament participants ready for bracket
  Future<List<Map<String, dynamic>>> getTournamentParticipants(
    String tournamentId,
  ) async {
    try {
      final response = await _supabase
          .from('tournament_participants')
          .select('''
            id,
            seed_number,
            registration_date,
            payment_status,
            users!inner (
              id,
              full_name,
              avatar_url,
              ranking_points
            )
          ''')
          .eq('tournament_id', tournamentId)
          .eq('payment_status', 'completed')
          .order('seed_number');

      return (response as List? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      ProductionLogger.info('❌ Error loading participants: $e', tag: 'production_bracket_service');
      return [];
    }
  }

  /// Create bracket for tournament
  Future<Map<String, dynamic>?> createTournamentBracket({
    required String tournamentId,
    required String format,
    List<Map<String, dynamic>>? customParticipants,
  }) async {
    try {
      // Get tournament info
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('*')
          .eq('id', tournamentId)
          .single();

      // Tournament found, proceed with bracket creation

      // Get participants
      List<Map<String, dynamic>> participants =
          customParticipants ?? await getTournamentParticipants(tournamentId);

      if (participants.length < 4) {
        throw Exception('Cần ít nhất 4 người chơi để tạo bảng đấu');
      }

      // Auto-seed participants if no seed numbers
      participants = _autoSeedParticipants(participants);

      // Check both format and bracket_format fields for sabo_de16
      final bracketFormat = tournamentResponse['bracket_format'];
      // NOTE: Database uses 'game_format' not 'format'! This was the bug causing all conditionals to fail
      final gameFormat = tournamentResponse['game_format'];

      ProductionLogger.info('🔍 Tournament formats: game_format=$gameFormat, bracket_format=$bracketFormat',  tag: 'production_bracket_service');

      // Use Unified Bracket Service for ALL formats
      // This consolidates logic and removes the need for multiple hardcoded services here
      final formatToUse = bracketFormat ?? gameFormat ?? 'single_elimination';
      final unifiedFormat = _mapToUnifiedFormat(formatToUse);
      
      ProductionLogger.info('🎯 Delegating to UnifiedBracketService with format: $unifiedFormat', tag: 'production_bracket_service');

      // Extract participant IDs
      final participantIds = participants
          .map((p) {
            final users = p['users'];
            if (users == null) return null;
            return users['id'] as String?;
          })
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (participantIds.length != participants.length) {
        throw Exception('Failed to extract all participant IDs');
      }

      final result = await UnifiedBracketService.instance.createBracket(
        tournamentId: tournamentId,
        format: unifiedFormat,
        participantIds: participantIds,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create bracket via Unified Service');
      }

      ProductionLogger.info('✅ Bracket created successfully via Unified Service', tag: 'production_bracket_service');

      // Update tournament status
      await _supabase
          .from('tournaments')
          .update({
            'status': 'bracket_created',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tournamentId);

      // Force refresh cache to ensure UI shows fresh data
      try {
        await CachedTournamentService.refreshTournamentData(tournamentId);
        ProductionLogger.info('✅ Refreshed cache after bracket creation', tag: 'production_bracket_service');
      } catch (e) {
        ProductionLogger.info('⚠️ Failed to refresh cache: $e', tag: 'production_bracket_service');
      }

      return {
        'tournament': tournamentResponse,
        'participants': participants,
        'success': true,
        'message': '✅ Bảng đấu đã được tạo thành công!',
      };
    } catch (e) {
      ProductionLogger.info('❌ Error creating bracket: $e', tag: 'production_bracket_service');
      return {
        'success': false,
        'error': e.toString(),
        'message': '❌ Lỗi tạo bảng đấu: ${e.toString()}',
      };
    }
  }

  /// Auto-seed participants based on ranking points or registration order
  List<Map<String, dynamic>> _autoSeedParticipants(
    List<Map<String, dynamic>> participants,
  ) {
    // Sort by ranking points (desc) or registration date (asc)
    participants.sort((a, b) {
      final pointsA = a['users']['ranking_points'] ?? 0;
      final pointsB = b['users']['ranking_points'] ?? 0;

      if (pointsA != pointsB) {
        return pointsB.compareTo(pointsA); // Higher points = better seed
      }

      // Fallback to registration date
      final dateA = DateTime.parse(a['registration_date']);
      final dateB = DateTime.parse(b['registration_date']);
      return dateA.compareTo(dateB); // Earlier registration = better seed
    });

    // Assign seed numbers
    for (int i = 0; i < participants.length; i++) {
      participants[i]['seed_number'] = i + 1;
    }

    return participants;
  }



  /// Load existing tournament bracket
  Future<Map<String, dynamic>?> loadTournamentBracket(
    String tournamentId,
  ) async {
    try {
      // Get tournament
      final tournament = await _supabase
          .from('tournaments')
          .select('*')
          .eq('id', tournamentId)
          .single();

      // Get matches
      final matches = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey(id, full_name, avatar_url),
            player2:users!matches_player2_id_fkey(id, full_name, avatar_url),
            winner:users!matches_winner_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');

      // Get participants
      final participants = await getTournamentParticipants(tournamentId);

      return {
        'tournament': tournament,
        'matches': matches,
        'participants': participants,
        'hasExistingBracket': (matches as List).isNotEmpty,
      };
    } catch (e) {
      ProductionLogger.info('❌ Error loading bracket: $e', tag: 'production_bracket_service');
      return null;
    }
  }

  /// Update match result
  Future<bool> updateMatchResult({
    required String matchId,
    required String winnerId,
    required int player1Score,
    required int player2Score,
  }) async {
    try {
      final result = await UnifiedBracketService.instance.processMatchResult(
        matchId: matchId,
        winnerId: winnerId,
        scores: {
          'player1': player1Score,
          'player2': player2Score,
        },
      );

      return result['success'] == true;
    } catch (e) {
      ProductionLogger.info('❌ Error updating match result: $e', tag: 'production_bracket_service');
      return false;
    }
  }

  /// Get tournament statistics
  Future<Map<String, dynamic>> getTournamentStats(String tournamentId) async {
    try {
      final matches = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId);

      final totalMatches = (matches as List).length;
      final completedMatches = matches
          .where((m) => m['status'] == 'completed')
          .length;
      final pendingMatches = totalMatches - completedMatches;

      return {
        'total_matches': totalMatches,
        'completed_matches': completedMatches,
        'pending_matches': pendingMatches,
        'completion_percentage': totalMatches > 0
            ? (completedMatches / totalMatches * 100).round()
            : 0,
      };
    } catch (e) {
      ProductionLogger.info('❌ Error getting tournament stats: $e', tag: 'production_bracket_service');
      return {
        'total_matches': 0,
        'completed_matches': 0,
        'pending_matches': 0,
        'completion_percentage': 0,
      };
    }
  }
}
