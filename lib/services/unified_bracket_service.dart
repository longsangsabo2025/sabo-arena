import 'package:sabo_arena/services/universal_match_progression_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart';
import 'package:sabo_arena/services/bracket/formats/single_elimination_format.dart';
import 'package:sabo_arena/services/bracket/formats/double_elimination_format.dart';
import 'package:sabo_arena/services/bracket/formats/sabo_de16_format.dart';
import 'package:sabo_arena/services/bracket/formats/sabo_de24_format.dart';
import 'package:sabo_arena/services/bracket/formats/sabo_de32_format.dart';
import 'package:sabo_arena/services/bracket/formats/sabo_de64_format.dart';

/// 🎯 UNIFIED BRACKET SERVICE
///
/// Single entry point for ALL bracket operations.
/// Consolidates 12+ bracket services into one clean interface.
///
/// Supported formats:
/// - single_elimination (2-64 players)
/// - double_elimination (4-32 players)
/// - sabo_de16 (16 players)
/// - sabo_de24 (24 players)
/// - sabo_de32 (32 players)
/// - sabo_de64 (64 players)
/// - round_robin (2-16 players)
/// - swiss (4-32 players)
class UnifiedBracketService {
  static UnifiedBracketService? _instance;
  static UnifiedBracketService get instance =>
      _instance ??= UnifiedBracketService._();

  UnifiedBracketService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tag = 'UnifiedBracket';

  // Delegate services (lazy initialization)
  CompleteSingleEliminationService? _singleElimination;
  HardcodedDoubleEliminationService? _doubleElimination;
  HardcodedSaboDE16Service? _saboDe16;
  HardcodedSaboDE24Service? _saboDe24;
  HardcodedSaboDE32Service? _saboDe32;
  HardcodedSaboDE64Service? _saboDe64;

  CompleteSingleEliminationService get singleElimination =>
      _singleElimination ??= CompleteSingleEliminationService.instance;
  HardcodedDoubleEliminationService get doubleElimination =>
      _doubleElimination ??= HardcodedDoubleEliminationService();
  HardcodedSaboDE16Service get saboDe16 =>
      _saboDe16 ??= HardcodedSaboDE16Service();
  HardcodedSaboDE24Service get saboDe24 =>
      _saboDe24 ??= HardcodedSaboDE24Service(_supabase);
  HardcodedSaboDE32Service get saboDe32 =>
      _saboDe32 ??= HardcodedSaboDE32Service(_supabase);
  HardcodedSaboDE64Service get saboDe64 =>
      _saboDe64 ??= HardcodedSaboDE64Service(_supabase);

  /// Process match result and handle advancement
  Future<Map<String, dynamic>> processMatchResult({
    required String matchId,
    required String winnerId,
    required Map<String, int> scores,
    String? tournamentFormat,
  }) async {
    ProductionLogger.info('$_tag: Processing match result for $matchId');

    try {
      // 1. Fetch match details to identify tournament and players
      final match = await _supabase
          .from('matches')
          .select('tournament_id, player1_id, player2_id')
          .eq('id', matchId)
          .single();

      final tournamentId = match['tournament_id'] as String;
      final player1Id = match['player1_id'] as String;
      final player2Id = match['player2_id'] as String;
      final loserId = (winnerId == player1Id) ? player2Id : player1Id;

      // 2. Fetch tournament format if not provided
      String format = tournamentFormat ?? '';
      if (format.isEmpty) {
        final tournament = await _supabase
            .from('tournaments')
            .select('bracket_format')
            .eq('id', tournamentId)
            .single();
        format =
            tournament['bracket_format'] as String? ?? 'single_elimination';
      }

      // 3. Delegate based on format
      if (format == 'single_elimination') {
        return await singleElimination.processMatchResult(
          matchId: matchId,
          winnerId: winnerId,
          scores: scores,
        );
      } else {
        // Use UniversalMatchProgressionService for formats with explicit advancement paths
        // (Double Elimination, SABO DE16/24/32/64)
        return await UniversalMatchProgressionService.instance
            .updateMatchResultWithImmediateAdvancement(
          matchId: matchId,
          tournamentId: tournamentId,
          winnerId: winnerId,
          loserId: loserId,
          scores: scores,
        );
      }
    } catch (e) {
      ProductionLogger.error('$_tag: Error processing match result', error: e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create bracket for any tournament format
  Future<Map<String, dynamic>> createBracket({
    required String tournamentId,
    required String format,
    required List<String> participantIds,
  }) async {
    ProductionLogger.info(
        '$_tag: Creating bracket - format: $format, players: ${participantIds.length}');

    try {
      switch (format.toLowerCase()) {
        case 'single_elimination':
          return await singleElimination.createBracket(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );

        case 'double_elimination':
          return await doubleElimination.createBracketWithAdvancement(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );

        case 'sabo_de16':
          return await saboDe16.createBracketWithAdvancement(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );

        case 'sabo_de24':
          return await saboDe24.createBracketWithAdvancement(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );

        case 'sabo_de32':
          return await saboDe32.createBracketWithAdvancement(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );

        case 'sabo_de64':
          return await saboDe64.createBracketWithAdvancement(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );

        case 'round_robin':
          return await _createRoundRobinBracket(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );

        case 'swiss':
        case 'swiss_system':
          return await _createSwissBracket(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );

        default:
          ProductionLogger.warning(
              '$_tag: Unknown format $format, using single elimination');
          return await singleElimination.createBracket(
            tournamentId: tournamentId,
            participantIds: participantIds,
          );
      }
    } catch (e, stackTrace) {
      ProductionLogger.error(
        '$_tag: Error creating bracket',
        error: e,
        stackTrace: stackTrace,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create Round Robin bracket
  Future<Map<String, dynamic>> _createRoundRobinBracket({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    final matches = <Map<String, dynamic>>[];

    // Simple round robin generation
    int matchCount = 0;
    for (int i = 0; i < participantIds.length; i++) {
      for (int j = i + 1; j < participantIds.length; j++) {
        matchCount++;
        matches.add({
          'tournament_id': tournamentId,
          'round_number': 1,
          'match_number': matchCount,
          'player1_id': participantIds[i],
          'player2_id': participantIds[j],
          'status': 'pending',
          'is_completed': false,
          'bracket_type': 'round_robin',
        });
      }
    }

    if (matches.isNotEmpty) {
      await _supabase.from('matches').insert(matches);
    }

    return {
      'success': true,
      'total_matches': matches.length,
      'format': 'round_robin',
    };
  }

  /// Create Swiss bracket (Round 1)
  Future<Map<String, dynamic>> _createSwissBracket({
    required String tournamentId,
    required List<String> participantIds,
  }) async {
    final shuffled = List<String>.from(participantIds)..shuffle();
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < shuffled.length; i += 2) {
      if (i + 1 < shuffled.length) {
        matches.add({
          'tournament_id': tournamentId,
          'round_number': 1,
          'match_number': (i ~/ 2) + 1,
          'player1_id': shuffled[i],
          'player2_id': shuffled[i + 1],
          'status': 'pending',
          'is_completed': false,
          'bracket_type': 'swiss',
        });
      }
    }

    if (matches.isNotEmpty) {
      await _supabase.from('matches').insert(matches);
    }

    return {
      'success': true,
      'total_matches': matches.length,
      'round': 1,
      'format': 'swiss',
    };
  }

  /// Generic match result processing
  // Future<Map<String, dynamic>> _processGenericMatchResult({ // Unused
  //   required String matchId,
  //   required String winnerId,
  //   required Map<String, int> scores,
  // }) async {
  //   await _supabase
  //       .from('matches')
  //       .update({
  //         'winner_id': winnerId,
  //         'player1_score': scores['player1'] ?? 0,
  //         'player2_score': scores['player2'] ?? 0,
  //         'is_completed': true,
  //         'status': 'completed',
  //         'updated_at': DateTime.now().toIso8601String(),
  //       })
  //       .eq('id', matchId);

  //   return {
  //     'success': true,
  //     'match_id': matchId,
  //     'winner_id': winnerId,
  //   };
  // }

  /// Get supported formats
  static List<String> get supportedFormats => [
        'single_elimination',
        'double_elimination',
        'sabo_de16',
        'sabo_de24',
        'sabo_de32',
        'sabo_de64',
        'round_robin',
        'swiss',
      ];

  /// Validate format and participant count
  static bool isValidConfiguration(String format, int participantCount) {
    switch (format.toLowerCase()) {
      case 'single_elimination':
        return participantCount >= 2 && participantCount <= 64;
      case 'double_elimination':
        return participantCount >= 4 && participantCount <= 32;
      case 'sabo_de16':
        return participantCount == 16;
      case 'sabo_de24':
        return participantCount == 24;
      case 'sabo_de32':
        return participantCount == 32;
      case 'sabo_de64':
        return participantCount == 64;
      case 'round_robin':
        return participantCount >= 2 && participantCount <= 16;
      case 'swiss':
        return participantCount >= 4 && participantCount <= 32;
      default:
        return false;
    }
  }

  /// Check if tournament bracket is complete
  bool isTournamentComplete(List<Map<String, dynamic>> matches) {
    if (matches.isEmpty) return false;

    // For single elimination: final match is completed
    // For double elimination: grand final is completed
    // For round robin: all matches are completed

    final finalMatches = matches
        .where(
          (m) =>
              m['bracket_type'] == 'grand_final' ||
              (m['bracket_type'] == null &&
                  m['round_number'] ==
                      matches
                          .map((match) => match['round_number'])
                          .reduce((a, b) => a > b ? a : b)),
        )
        .toList();

    return finalMatches.isNotEmpty &&
        finalMatches.every((m) => m['status'] == 'completed');
  }

  /// Get tournament standings
  List<Map<String, dynamic>> getTournamentStandings(
    List<Map<String, dynamic>> matches,
    List<Map<String, dynamic>> participants,
  ) {
    Map<String, Map<String, dynamic>> standings = {};

    // Initialize standings
    for (var participant in participants) {
      standings[participant['user_id']] = {
        'user_id': participant['user_id'],
        'user': participant['user'],
        'wins': 0,
        'losses': 0,
        'matches_played': 0,
        'points': 0,
        'position': 0,
        'eliminated_in_round': null,
      };
    }

    // Calculate stats from matches
    for (var match in matches) {
      if (match['status'] == 'completed' && match['winner_id'] != null) {
        final winnerId = match['winner_id'];
        final loserId = winnerId == match['player1_id']
            ? match['player2_id']
            : match['player1_id'];

        if (standings.containsKey(winnerId)) {
          standings[winnerId]!['wins']++;
          standings[winnerId]!['matches_played']++;
          standings[winnerId]!['points'] += 3; // 3 points for win
        }

        if (standings.containsKey(loserId)) {
          standings[loserId]!['losses']++;
          standings[loserId]!['matches_played']++;
          standings[loserId]!['eliminated_in_round'] = match['round_number'];
        }
      }
    }

    // Sort by points (wins), then by losses (ascending)
    List<Map<String, dynamic>> sortedStandings = standings.values.toList();
    sortedStandings.sort((a, b) {
      int pointsComparison = b['points'].compareTo(a['points']);
      if (pointsComparison != 0) return pointsComparison;
      return a['losses'].compareTo(b['losses']);
    });

    // Assign positions
    for (int i = 0; i < sortedStandings.length; i++) {
      sortedStandings[i]['position'] = i + 1;
    }

    return sortedStandings;
  }
}
