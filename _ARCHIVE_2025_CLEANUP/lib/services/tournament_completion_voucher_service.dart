import '../services/supabase_service.dart';
// ELON_MODE_AUTO_FIX

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

      // 1. Get tournament info
      final tournament = await _supabase
          .from('tournaments')
          .select('id, title, club_id, status')
          .eq('id', tournamentId)
          .single();


      if (tournament['status'] != 'completed') {
        return {
          'success': false,
          'error': 'Giải đấu chưa kết thúc',
        };
      }

      final clubId = tournament['club_id'] as String?;
      
      if (clubId == null) {
        return {
          'success': false,
          'error': 'Giải đấu không có ID câu lạc bộ',
        };
      }

      // 2. Get voucher configs
      final configs = await _supabase
          .from('tournament_prize_vouchers')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('position');

      if (configs.isNotEmpty) {
        final firstConfig = configs.first;
        firstConfig.forEach((key, value) {
        });
      }

      if (configs.isEmpty) {
        return {
          'success': true,
          'issued_count': 0,
          'message': 'Không có cấu hình voucher',
        };
      }

      // 3. Determine top 4 from bracket
      final topPlayers = await _determineTop4FromBracket(tournamentId);

      if (topPlayers.isEmpty) {
        return {
          'success': false,
          'error': 'Không thể xác định top 4 người chơi',
        };
      }

      topPlayers.forEach((position, userId) {
      });

      // 4. Issue vouchers for each position
      int issuedCount = 0;
      final List<Map<String, dynamic>> issuedVouchers = [];

      for (final config in configs) {
        final position = config['position'] as int;
        
        final isIssued = config['is_issued'] as bool? ?? false;

        if (isIssued) {
          continue;
        }

        // Get user for this position
        final userId = topPlayers[position];
        
        if (userId == null) {
          continue;
        }

        // Check if already has voucher
        final existing = await _supabase
            .from('user_vouchers')
            .select('id')
            .eq('user_id', userId)
            .eq('tournament_id', tournamentId)
            .maybeSingle();

        if (existing != null) {
          continue;
        }

        // Generate voucher code
        
        final voucherCode = _generateVoucherCode(
          position: position,
          tournamentTitle: tournament['title'] as String,
        );

        // Calculate expiry date
        final validDays = config['valid_days'] as int? ?? 365;
        final expiresAt = DateTime.now().add(Duration(days: validDays));

        // Insert voucher - with explicit type casting
        
        final voucherData = {
          'user_id': userId,
          'club_id': clubId,
          'tournament_id': tournamentId,
          'voucher_code': voucherCode,
          'voucher_value': (config['voucher_value'] as num).toDouble(),
          'status': 'active',
          'expires_at': expiresAt.toIso8601String(),
        };


        await _supabase.from('user_vouchers').insert(voucherData);

        // Mark config as issued
        
        await _supabase
            .from('tournament_prize_vouchers')
            .update({'is_issued': true})
            .eq('id', config['id'] as String);

        issuedCount++;
        issuedVouchers.add({
          'position': position,
          'user_id': userId,
          'voucher_code': voucherCode,
          'value': config['voucher_value'],
        });

      }


      return {
        'success': true,
        'issued_count': issuedCount,
        'vouchers': issuedVouchers,
      };
    } catch (e) {
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

      // Get all completed matches ordered by match_number DESC
      final matches = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .eq('status', 'completed')
          .order('match_number', ascending: false);


      if (matches.isEmpty) {
        return topPlayers;
      }

      // Final match is the one with highest match_number
      final finalMatch = matches.first;
      
      final championId = finalMatch['winner_id'] as String?;
      final runnerUpId = championId == finalMatch['player1_id']
          ? finalMatch['player2_id'] as String?
          : finalMatch['player1_id'] as String?;


      if (championId != null) {
        topPlayers[1] = championId; // Position 1: Champion
      }
      if (runnerUpId != null) {
        topPlayers[2] = runnerUpId; // Position 2: Runner-up
      }


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


    return topPlayers;
    
    } catch (e) {
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


      // Issue vouchers for each tournament
      for (final tournamentId in tournamentIds) {
        await autoIssueTournamentVouchers(tournamentId);
      }

    } catch (e) {
      // Ignore error
    }
  }
}

