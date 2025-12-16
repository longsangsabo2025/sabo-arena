import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Ultra-simple service: Just get what UI is showing
/// NO re-calculation, NO duplicate logic
class UIDataCapture {
  
  /// Capture EXACTLY what UI is showing using same live calculation
  /// This is the SIMPLEST approach: UI calculates once, we capture it
  /// 🔧 ENHANCED: Guarantees ALL tournament participants are included
  static Future<List<Map<String, dynamic>>> captureUIRankings(String tournamentId) async {
    try {
      ProductionLogger.info('📸 [UI CAPTURE] Capturing exact UI ranking data for $tournamentId', tag: 'ui_data_capture');

      // 🎯 ROBUST: Get ALL tournament participants directly (bypass filtering)
      // This ensures we include even orphaned participants for complete results
      final participantsResponse = await Supabase.instance.client
          .from('tournament_participants')
          .select('''
            user_id,
            status,
            registered_at,
            users (
              id,
              display_name,
              full_name,
              email
            )
          ''')
          .eq('tournament_id', tournamentId)
          .order('registered_at');

      ProductionLogger.info('🔍 [UI CAPTURE] Got ${participantsResponse.length} participants from tournament_participants', tag: 'ui_data_capture');

      // 🛡️ FALLBACK: Create participant objects with graceful handling
      final participants = participantsResponse.map((participantData) {
        final userData = participantData['users'] as Map<String, dynamic>?;
        final userId = participantData['user_id'] as String;
        
        if (userData != null) {
          // ✅ Valid user data available
          return {
            'id': userData['id'] as String,
            'displayName': userData['display_name'] as String? ?? userData['full_name'] as String? ?? 'User',
            'isOrphaned': false,
          };
        } else {
          // ⚠️ Orphaned participant - create placeholder
          ProductionLogger.info('⚠️ [UI CAPTURE] Orphaned participant: $userId (creating placeholder)', tag: 'ui_data_capture');
          return {
            'id': userId,
            'displayName': 'Player_${userId.substring(0, 8)}', // Use first 8 chars of ID
            'isOrphaned': true,
          };
        }
      }).toList();

      ProductionLogger.info('📊 [UI CAPTURE] Processing ${participants.length} participants (including ${participants.where((p) => p['isOrphaned'] == true).length} orphaned)', tag: 'ui_data_capture');

      // Get matches to calculate stats
      final matchesResponse = await Supabase.instance.client
          .from('matches')
          .select('player1_id, player2_id, winner_id, status')
          .eq('tournament_id', tournamentId);

      final matches = matchesResponse as List<dynamic>;
      ProductionLogger.info('🎯 [UI CAPTURE] Got ${matches.length} matches', tag: 'ui_data_capture');

      // Calculate stats for each participant (EXACT UI logic + orphan handling)
      final rankings = participants.map((participant) {
        int wins = 0;
        int losses = 0;
        int totalGames = 0;
        
        for (final match in matches) {
          final player1Id = match['player1_id'] as String?;
          final player2Id = match['player2_id'] as String?;
          final winnerId = match['winner_id'] as String?;
          final status = match['status'] as String?;
          
          if (status != 'completed' || winnerId == null) continue;
          
          final participantId = participant['id'] as String;
          if (participantId == player1Id || participantId == player2Id) {
            totalGames++;
            if (participantId == winnerId) {
              wins++;
            } else {
              losses++;
            }
          }
        }
        
        double winRate = totalGames > 0 ? (wins / totalGames) * 100 : 0.0;
        
        return {
          'participant_id': participant['id'] as String, // For tournament_results
          'participant_name': participant['displayName'] as String,
          'wins': wins,
          'losses': losses,
          'total_games': totalGames,
          'win_rate': winRate,
          'points': wins * 3,
          'is_orphaned': participant['isOrphaned'] as bool,
        };
      }).toList();

      // Sort exactly like UI
      rankings.sort((a, b) {
        int pointsCompare = (b['points'] as int).compareTo(a['points'] as int);
        if (pointsCompare != 0) return pointsCompare;
        return (b['win_rate'] as double).compareTo(a['win_rate'] as double);
      });

      // Assign positions and calculate rewards (EXACT UI logic)
      final totalParticipants = rankings.length;
      int currentRank = 1;
      
      for (int i = 0; i < rankings.length; i++) {
        final position = i + 1;
        
        // Tie handling
        if (i > 0) {
          final prevPoints = rankings[i - 1]['points'] as int;
          final prevWinRate = rankings[i - 1]['win_rate'] as double;
          final currPoints = rankings[i]['points'] as int;
          final currWinRate = rankings[i]['win_rate'] as double;
          
          if (prevPoints != currPoints || prevWinRate != currWinRate) {
            currentRank = position;
          }
        }
        
        rankings[i]['position'] = position;
        rankings[i]['rank'] = currentRank;
        
        // ✅ EXACT UI calculation
        rankings[i]['elo_change'] = _calculateEloBonus(currentRank, totalParticipants);
        rankings[i]['spa_reward'] = _calculateSpaBonus(position, totalParticipants);
        
        // Additional fields for tournament_results
        rankings[i]['matches_won'] = rankings[i]['wins'] as int;
        rankings[i]['matches_lost'] = rankings[i]['losses'] as int;
        rankings[i]['matches_played'] = rankings[i]['total_games'] as int;
        rankings[i]['win_percentage'] = rankings[i]['win_rate'] as double;
        rankings[i]['prize_money_vnd'] = 0;
      }

      ProductionLogger.info('✅ [UI CAPTURE] Captured ${rankings.length} rankings with UI-identical logic', tag: 'ui_data_capture');
      
      int orphanedCount = 0;
      for (int i = 0; i < rankings.length; i++) {
        final r = rankings[i];
        final isOrphaned = r['is_orphaned'] as bool? ?? false;
        final orphanFlag = isOrphaned ? ' [ORPHANED]' : '';
        ProductionLogger.info('  ${i + 1}. ${r['participant_name']}$orphanFlag (ID: ${r['participant_id']}) → Position ${r['position']}, ${r['spa_reward']} SPA, ${r['elo_change']} ELO', tag: 'ui_data_capture');
        if (isOrphaned) orphanedCount++;
      }
      
      if (orphanedCount > 0) {
        ProductionLogger.info('⚠️ [UI CAPTURE] Included $orphanedCount orphaned participants with placeholder data', tag: 'ui_data_capture');
      }
      ProductionLogger.info('🎯 [UI CAPTURE] GUARANTEED: All ${rankings.length} tournament participants will be saved!', tag: 'ui_data_capture');
      
      return rankings;
    } catch (e) {
      ProductionLogger.info('❌ [UI CAPTURE] Error: $e', tag: 'ui_data_capture');
      rethrow;
    }
  }

  /// ELO calculation - EXACT copy from UI
  static int _calculateEloBonus(int position, int totalParticipants) {
    if (position == 1) return 75;
    if (position == 2) return 50;
    if (position == 3 || position == 4) return 35;
    if (position <= totalParticipants * 0.25) return 25;
    if (position <= totalParticipants * 0.5) return 15;
    if (position <= totalParticipants * 0.75) return 10;
    return -5;
  }

  /// SPA calculation - EXACT copy from UI
  static int _calculateSpaBonus(int position, int totalParticipants) {
    final top25 = (totalParticipants * 0.25).ceil();
    final top50 = (totalParticipants * 0.5).ceil();
    final top75 = (totalParticipants * 0.75).ceil();
    
    if (position == 1) return 1000;
    if (position == 2) return 800;
    if (position == 3 || position == 4) return 550;
    if (position <= top25) return 400;
    if (position <= top50) return 300;
    if (position <= top75) return 200;
    return 100;
  }
}