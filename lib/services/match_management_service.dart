import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/error_handling/standardized_error_handler.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎯 MATCH MANAGEMENT SERVICE
/// Service for club owners to manage matches at their club
/// Features:
/// - Get matches for club (scheduled/in-progress/completed)
/// - Start match (pending → in_progress)
/// - Update match score (real-time)
/// - Complete match and declare winner
/// - Enable/disable live streaming
/// - Real-time subscriptions for match updates

class MatchManagementService {
  final _supabase = Supabase.instance.client;

  // Real-time channel for match updates
  RealtimeChannel? _matchChannel;

  /// Get all challenges for a specific club
  /// [clubId] - The club ID
  /// [status] - Optional filter: 'accepted', 'in_progress', 'completed'
  /// Note: Only shows accepted/in-progress/completed challenges (not pending)
  Future<List<Map<String, dynamic>>> getClubMatches({
    required String clubId,
    String? status,
  }) async {
    try {
      ProductionLogger.debug('Fetching challenges for club: $clubId, status: $status', tag: 'MatchManagement');

      var query = _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!challenger_id(id, display_name, full_name, avatar_url, rank, is_online),
            challenged:users!challenged_id(id, display_name, full_name, avatar_url, rank, is_online)
          ''')
          .eq('club_id', clubId)
          .not('challenged_id', 'is', null); // ✅ Chỉ lấy challenges đã có người chấp nhận (challenged_id NOT NULL)
      
      // Note: Không thể dùng .neq('challenger_id', 'challenged_id') để so sánh 2 cột
      // Sẽ filter self-challenges sau khi lấy dữ liệu nếu cần

      // Only show accepted, in_progress, or completed matches (not pending invites)
      if (status == null) {
        query = query.inFilter('status', ['accepted', 'in_progress', 'completed']);
      } else {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      // ✅ Filter out self-challenges (where challenger_id == challenged_id)
      final filteredResponse = response.where((challenge) {
        final challengerId = challenge['challenger_id'];
        final challengedId = challenge['challenged_id'];
        return challengerId != challengedId;
      }).toList();

      ProductionLogger.info('Found ${filteredResponse.length} challenges (filtered ${response.length - filteredResponse.length} self-challenges)', tag: 'MatchManagement');
      return List<Map<String, dynamic>>.from(filteredResponse);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getClubMatches',
          context: 'Error fetching club challenges',
        ),
      );
      ProductionLogger.error('Error fetching club challenges', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      rethrow;
    }
  }

  /// Get matches scheduled for today
  Future<List<Map<String, dynamic>>> getTodayMatches(String clubId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey(id, display_name, full_name, avatar_url, rank),
            player2:users!matches_player2_id_fkey(id, display_name, full_name, avatar_url, rank),
            reservation:table_reservations!table_reservations_match_id_fkey(
              table_number,
              start_time,
              end_time
            )
          ''')
          .eq('club_id', clubId)
          .gte('scheduled_time', startOfDay.toIso8601String())
          .lt('scheduled_time', endOfDay.toIso8601String())
          .order('scheduled_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getTodayMatches',
          context: 'Error fetching today matches',
        ),
      );
      ProductionLogger.error('Error fetching today matches', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      rethrow;
    }
  }

  /// Start a challenge (change status from accepted/pending to in_progress)
  Future<void> startMatch(String matchId) async {
    try {
      ProductionLogger.info('Starting challenge: $matchId', tag: 'MatchManagement');

      await _supabase.from('challenges').update({
        'status': 'in_progress',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);

      ProductionLogger.info('Challenge started successfully', tag: 'MatchManagement');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'startMatch',
          context: 'Error starting challenge',
        ),
      );
      ProductionLogger.error('Error starting challenge', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      rethrow;
    }
  }

  /// Update challenge score (real-time scoring)
  /// Automatically completes challenge if race condition is met
  Future<void> updateMatchScore({
    required String matchId,
    required int player1Score,
    required int player2Score,
  }) async {
    try {
      ProductionLogger.debug('Updating score: $matchId -> $player1Score:$player2Score', tag: 'MatchManagement');

      // First, get challenge details to check race_to value
      final challengeData = await _supabase
          .from('challenges')
          .select('challenger_id, challenged_id, race_to')
          .eq('id', matchId)
          .single();

      final raceTo = challengeData['race_to'] as int? ?? 7;
      final challengerId = challengeData['challenger_id'] as String;
      final challengedId = challengeData['challenged_id'] as String;

      // Update scores (player1 = challenger, player2 = challenged)
      await _supabase.from('challenges').update({
        'player1_score': player1Score,
        'player2_score': player2Score,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);

      ProductionLogger.info('Score updated successfully', tag: 'MatchManagement');

      // 🎯 AUTO-COMPLETE: Check if either player reached race_to
      if (player1Score >= raceTo || player2Score >= raceTo) {
        final winnerId = player1Score >= raceTo ? challengerId : challengedId;
        ProductionLogger.info('Challenge complete! Winner: $winnerId (Race to $raceTo reached)', tag: 'MatchManagement');
        
        // Auto-complete the challenge
        await completeMatch(
          matchId: matchId,
          winnerId: winnerId,
          finalPlayer1Score: player1Score,
          finalPlayer2Score: player2Score,
        );
        
        ProductionLogger.info('Challenge auto-completed and moved to completed tab', tag: 'MatchManagement');
      }
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'updateMatchScore',
          context: 'Error updating score',
        ),
      );
      ProductionLogger.error('Error updating score', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      rethrow;
    }
  }

  /// Complete a challenge and declare winner
  Future<void> completeMatch({
    required String matchId,
    required String winnerId,
    int? finalPlayer1Score,
    int? finalPlayer2Score,
  }) async {
    try {
      ProductionLogger.info('Completing challenge: $matchId, winner: $winnerId', tag: 'MatchManagement');

      final updates = <String, dynamic>{
        'status': 'completed',
        'winner_id': winnerId,
        'end_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (finalPlayer1Score != null) {
        updates['player1_score'] = finalPlayer1Score;
      }

      if (finalPlayer2Score != null) {
        updates['player2_score'] = finalPlayer2Score;
      }

      // Update challenge
      await _supabase.from('challenges').update(updates).eq('id', matchId);

      ProductionLogger.info('Challenge completed successfully', tag: 'MatchManagement');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'completeMatch',
          context: 'Error completing challenge',
        ),
      );
      ProductionLogger.error('Error completing challenge', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      rethrow;
    }
  }

  /// Enable live streaming for a match
  Future<void> enableLiveStream({
    required String matchId,
    required String videoUrl,
  }) async {
    try {
      ProductionLogger.info('Enabling live stream for match: $matchId', tag: 'MatchManagement');

      await _supabase.from('matches').update({
        'is_live': true,
        'video_urls': [videoUrl],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);

      ProductionLogger.info('Live stream enabled', tag: 'MatchManagement');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'enableLiveStream',
          context: 'Error enabling live stream',
        ),
      );
      ProductionLogger.error('Error enabling live stream', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      rethrow;
    }
  }

  /// Disable live streaming for a match
  Future<void> disableLiveStream(String matchId) async {
    try {
      ProductionLogger.info('Disabling live stream for match: $matchId', tag: 'MatchManagement');

      await _supabase.from('matches').update({
        'is_live': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);

      ProductionLogger.info('Live stream disabled', tag: 'MatchManagement');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'disableLiveStream',
          context: 'Error disabling live stream',
        ),
      );
      ProductionLogger.error('Error disabling live stream', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      rethrow;
    }
  }

  /// Subscribe to real-time updates for club matches
  /// Returns a stream of match updates
  /// TODO: Implement real-time subscription
  Stream<Map<String, dynamic>> subscribeToClubMatches(String clubId) {
    ProductionLogger.debug('Subscribing to matches for club: $clubId', tag: 'MatchManagement');
    
    // TODO: Implement Supabase Realtime subscription
    // For now, return empty stream
    return const Stream.empty();
  }

  /// Subscribe to real-time score updates for a specific match
  /// TODO: Implement real-time subscription  
  Stream<Map<String, dynamic>> subscribeToMatchScore(String matchId) {
    ProductionLogger.debug('Subscribing to score updates for match: $matchId', tag: 'MatchManagement');
    
    // TODO: Implement Supabase Realtime subscription
    // For now, return empty stream
    return const Stream.empty();
  }

  /// Unsubscribe from real-time updates
  Future<void> unsubscribe() async {
    if (_matchChannel != null) {
      ProductionLogger.debug('Unsubscribing from match updates', tag: 'MatchManagement');
      await _supabase.removeChannel(_matchChannel!);
      _matchChannel = null;
    }
  }

  /// Get match details by ID
  Future<Map<String, dynamic>?> getMatchById(String matchId) async {
    try {
      ProductionLogger.debug('Fetching match details: $matchId', tag: 'MatchManagement');

      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey(id, full_name, avatar_url, username),
            player2:users!matches_player2_id_fkey(id, full_name, avatar_url, username),
            club:clubs(id, name, address, logo_url),
            reservation:table_reservations!table_reservations_match_id_fkey(
              table_number,
              start_time,
              end_time,
              status,
              price_per_hour,
              total_price
            )
          ''')
          .eq('id', matchId)
          .single();

      return response;
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'getMatchById',
          context: 'Error fetching match details',
        ),
      );
      ProductionLogger.error('Error fetching match details', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      return null;
    }
  }

  /// Get statistics for club owner dashboard
  Future<Map<String, dynamic>> getClubMatchStats(String clubId) async {
    try {
      ProductionLogger.debug('Fetching match statistics for club: $clubId', tag: 'MatchManagement');

      // Get all matches
      final allMatches = await _supabase
          .from('matches')
          .select('status')
          .eq('club_id', clubId);

      final total = allMatches.length;
      final pending =
          allMatches.where((m) => m['status'] == 'pending').length;
      final inProgress =
          allMatches.where((m) => m['status'] == 'in_progress').length;
      final completed =
          allMatches.where((m) => m['status'] == 'completed').length;

      // Get today's matches
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todayMatches = await _supabase
          .from('matches')
          .select('id')
          .eq('club_id', clubId)
          .gte('scheduled_time', startOfDay.toIso8601String())
          .lt('scheduled_time', endOfDay.toIso8601String());

      return {
        'total_matches': total,
        'pending': pending,
        'in_progress': inProgress,
        'completed': completed,
        'today_matches': todayMatches.length,
      };
    } catch (e) {
      ProductionLogger.warning('Error fetching match stats', error: e, tag: 'MatchManagement');
      return {
        'total_matches': 0,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
        'today_matches': 0,
      };
    }
  }

  /// Cancel a match (for club owner)
  Future<void> cancelMatch(String matchId, String reason) async {
    try {
      ProductionLogger.info('Cancelling match: $matchId', tag: 'MatchManagement');

      // Update match status
      await _supabase.from('matches').update({
        'status': 'completed', // Mark as completed with no winner
        'notes': 'Cancelled: $reason',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchId);

      // Update reservation status
      await _supabase.from('table_reservations').update({
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelled_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('match_id', matchId);

      ProductionLogger.info('Match cancelled successfully', tag: 'MatchManagement');
    } catch (e, stackTrace) {
      StandardizedErrorHandler.handleError(
        e,
        context: ErrorContext(
          category: ErrorCategory.database,
          operation: 'cancelMatch',
          context: 'Error cancelling match',
        ),
      );
      ProductionLogger.error('Error cancelling match', error: e, stackTrace: stackTrace, tag: 'MatchManagement');
      rethrow;
    }
  }
}

