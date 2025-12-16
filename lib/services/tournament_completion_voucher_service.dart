import '../services/supabase_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service tự động phát voucher khi giải đấu kết thúc
/// Auto-issue vouchers when tournament is completed
class TournamentCompletionVoucherService {
  final _supabase = SupabaseService.instance.client;

  /// Auto-issue vouchers cho top 4 khi tournament complete
  /// Call this after tournament status changes to 'completed'
  Future<Map<String, dynamic>> autoIssueTournamentVouchers(
    String tournamentId,
  ) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // 1. Get tournament info
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      final tournament = await _supabase
          .from('tournaments')
          .select('id, title, club_id, status')
          .eq('id', tournamentId)
          .single();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (tournament['status'] != 'completed') {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {
          'success': false,
          'error': 'Tournament not completed yet',
        };
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      final clubId = tournament['club_id'] as String?;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      if (clubId == null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {
          'success': false,
          'error': 'Tournament has no club_id',
        };
      }

      // 2. Get voucher configs
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      final configs = await _supabase
          .from('tournament_prize_vouchers')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('position');

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (configs.isNotEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        final firstConfig = configs.first;
        firstConfig.forEach((key, value) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        });
      }

      if (configs.isEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {
          'success': true,
          'issued_count': 0,
          'message': 'No voucher configs',
        };
      }

      // 3. Determine top 4 from bracket
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      final topPlayers = await _determineTop4FromBracket(tournamentId);

      if (topPlayers.isEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return {
          'success': false,
          'error': 'Cannot determine top 4 players',
        };
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      topPlayers.forEach((position, userId) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      });

      // 4. Issue vouchers for each position
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      int issuedCount = 0;
      final List<Map<String, dynamic>> issuedVouchers = [];

      for (final config in configs) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        final position = config['position'] as int;
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        final isIssued = config['is_issued'] as bool? ?? false;

        if (isIssued) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          continue;
        }

        // Get user for this position
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        final userId = topPlayers[position];
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        if (userId == null) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          continue;
        }

        // Check if already has voucher
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        final existing = await _supabase
            .from('user_vouchers')
            .select('id')
            .eq('user_id', userId)
            .eq('tournament_id', tournamentId)
            .maybeSingle();

        if (existing != null) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          continue;
        }

        // Generate voucher code
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        final voucherCode = _generateVoucherCode(
          position: position,
          tournamentTitle: tournament['title'] as String,
        );
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Calculate expiry date
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        final validDays = config['valid_days'] as int? ?? 365;
        final expiresAt = DateTime.now().add(Duration(days: validDays));
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Insert voucher - with explicit type casting
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        final voucherData = {
          'user_id': userId,
          'club_id': clubId,
          'tournament_id': tournamentId,
          'voucher_code': voucherCode,
          'voucher_value': (config['voucher_value'] as num).toDouble(),
          'status': 'active',
          'expires_at': expiresAt.toIso8601String(),
        };

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        await _supabase.from('user_vouchers').insert(voucherData);
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Mark config as issued
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        await _supabase
            .from('tournament_prize_vouchers')
            .update({'is_issued': true})
            .eq('id', config['id'] as String);
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        issuedCount++;
        issuedVouchers.add({
          'position': position,
          'user_id': userId,
          'voucher_code': voucherCode,
          'value': config['voucher_value'],
        });

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      return {
        'success': true,
        'issued_count': issuedCount,
        'vouchers': issuedVouchers,
      };
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Determine top 4 players from tournament bracket
  /// Returns Map<position, userId> (1-indexed)
  Future<Map<int, String>> _determineTop4FromBracket(
    String tournamentId,
  ) async {
    final Map<int, String> topPlayers = {};

    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get all completed matches ordered by match_number DESC
      final matches = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .eq('status', 'completed')
          .order('match_number', ascending: false);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (matches.isEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return topPlayers;
      }

      // Final match is the one with highest match_number
      final finalMatch = matches.first;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      
      final championId = finalMatch['winner_id'] as String?;
      final runnerUpId = championId == finalMatch['player1_id']
          ? finalMatch['player2_id'] as String?
          : finalMatch['player1_id'] as String?;

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (championId != null) {
        topPlayers[1] = championId; // Position 1: Champion
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
      if (runnerUpId != null) {
        topPlayers[2] = runnerUpId; // Position 2: Runner-up
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

    // Find semi-final losers (positions 3-4)
    // These are matches where winner went to final
    final List<String> semiFinalLosers = [];

    for (final match in matches.skip(1)) {
      // Skip final match
      final winnerId = match['winner_id'] as String?;

      // Check if winner is in final match
      if (winnerId == finalMatch['player1_id'] ||
          winnerId == finalMatch['player2_id']) {
        // This is a semi-final match
        final loserId = winnerId == match['player1_id']
            ? match['player2_id'] as String?
            : match['player1_id'] as String?;

        if (loserId != null && !semiFinalLosers.contains(loserId)) {
          semiFinalLosers.add(loserId);
        }
      }
    }

    // Assign positions 3 and 4
    if (semiFinalLosers.isNotEmpty) {
      topPlayers[3] = semiFinalLosers[0];
    }
    if (semiFinalLosers.length > 1) {
      topPlayers[4] = semiFinalLosers[1];
    }

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    return topPlayers;
    
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return topPlayers;
    }
  }

  /// Generate unique voucher code
  String _generateVoucherCode({
    required int position,
    required String tournamentTitle,
  }) {
    final prefix = 'PRIZE$position';
    final tournamentCode = tournamentTitle
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .substring(0, tournamentTitle.length > 10 ? 10 : tournamentTitle.length);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');

    return '$prefix-$tournamentCode-$random';
  }

  /// Check if vouchers need to be issued for completed tournament
  /// Call this periodically or on app start
  Future<void> checkAndIssueVouchersForCompletedTournaments() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Find tournaments that are completed but have unissued vouchers
      final response = await _supabase
          .from('tournament_prize_vouchers')
          .select('''
            tournament_id,
            tournaments!inner(id, status, title)
          ''')
          .eq('is_issued', false)
          .eq('tournaments.status', 'completed');

      if (response.isEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        return;
      }

      // Get unique tournament IDs
      final Set<String> tournamentIds = {};
      for (final row in response) {
        final tournament = row['tournament_id'] as String?;
        if (tournament != null) {
          tournamentIds.add(tournament);
        }
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Issue vouchers for each tournament
      for (final tournamentId in tournamentIds) {
        await autoIssueTournamentVouchers(tournamentId);
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }
}

