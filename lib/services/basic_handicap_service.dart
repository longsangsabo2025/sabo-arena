import 'package:supabase_flutter/supabase_flutter.dart';

/// Service để handle handicap cơ bản cho Race to 7 (không liên quan challenge/betting)
/// Đây là handicap đơn giản dựa HOÀN TOÀN trên rank difference
class BasicHandicapService {
  static BasicHandicapService? _instance;
  static BasicHandicapService get instance =>
      _instance ??= BasicHandicapService._();
  BasicHandicapService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🎯 SABO Rank System - 10 cấp từ K đến C
  static const Map<String, int> rankValues = {
    'K': 1,
    'I': 2,
    'H': 3,
    'H+': 4,
    'G': 5,
    'G+': 6,
    'F': 7,
    'E': 8,
    'D': 9,
    'C': 10,
  };

  /// ⚖️ HANDICAP CƠ BẢN CHO RACE TO 7
  /// Logic đơn giản: 1 rank difference = 1 ván handicap (constant)
  /// KHÔNG phụ thuộc vào bet amount hay race-to value
  ///
  /// Ví dụ:
  /// - K (1) vs K (1): diff=0 → handicap=0
  /// - K (1) vs I (2): diff=1 → handicap=1.0 (K gets +1 ván)
  /// - K (1) vs H (3): diff=2 → handicap=2.0 (K gets +2 ván)
  /// - I (2) vs G (5): diff=3 → handicap=3.0 (I gets +3 ván)
  static double calculateBasicHandicap(String rank1, String rank2) {
    final value1 = rankValues[rank1];
    final value2 = rankValues[rank2];

    if (value1 == null || value2 == null) {
      return 0.0; // Invalid rank
    }

    // Handicap = absolute rank difference
    return (value1 - value2).abs().toDouble();
  }

  /// 🎯 Determine who receives the handicap
  /// Lower ranked player always receives handicap
  static String? getHandicapRecipient(
      String rank1, String rank2, String userId1, String userId2) {
    final value1 = rankValues[rank1];
    final value2 = rankValues[rank2];

    if (value1 == null || value2 == null) {
      return null;
    }

    // Lower rank number = weaker player
    if (value1 < value2) {
      return userId1; // Player 1 is weaker, gets handicap
    } else if (value2 < value1) {
      return userId2; // Player 2 is weaker, gets handicap
    }

    return null; // Same rank, no handicap
  }

  /// 📊 Get handicap info for display
  static Map<String, dynamic> getHandicapInfo(String rank1, String rank2) {
    final handicap = calculateBasicHandicap(rank1, rank2);
    final value1 = rankValues[rank1] ?? 0;
    final value2 = rankValues[rank2] ?? 0;

    if (handicap == 0) {
      return {
        'handicap': 0.0,
        'description': 'Không chấp (cùng hạng)',
        'short': 'Không chấp',
        'recipient': null,
      };
    }

    final weakerRank = value1 < value2 ? rank1 : rank2;
    final strongerRank = value1 < value2 ? rank2 : rank1;
    final handicapInt = handicap.toStringAsFixed(0);

    return {
      'handicap': handicap,
      'description': '$weakerRank chấp $strongerRank $handicapInt ván',
      'short': 'Handicap $handicapInt ván',
      'ui_display': 'Handicap $handicapInt ván', // For UI widgets
      'recipient_rank': weakerRank,
    };
  }

  /// 🎨 Get formatted handicap string for UI display
  /// Returns user-friendly string like "Handicap 2 ván" or "Không chấp"
  static String getHandicapDisplayText(String rank1, String rank2) {
    final info = getHandicapInfo(rank1, rank2);
    return info['ui_display'] as String;
  }

  /// 🏁 RACE TO 7 - Apply handicap to starting scores
  /// For race to 7: weaker player starts with handicap advantage
  ///
  /// Example:
  /// - K vs I (handicap=1.0): K starts 1-0, first to 7 wins
  /// - K vs H (handicap=2.0): K starts 2-0, first to 7 wins
  static Map<String, dynamic> applyHandicapToRaceTo7({
    required String player1Rank,
    required String player2Rank,
    required String player1Id,
    required String player2Id,
  }) {
    final handicap = calculateBasicHandicap(player1Rank, player2Rank);
    final recipient =
        getHandicapRecipient(player1Rank, player2Rank, player1Id, player2Id);

    int player1StartingScore = 0;
    int player2StartingScore = 0;

    if (recipient == player1Id) {
      player1StartingScore = handicap.round();
    } else if (recipient == player2Id) {
      player2StartingScore = handicap.round();
    }

    return {
      'player1_starting_score': player1StartingScore,
      'player2_starting_score': player2StartingScore,
      'handicap_value': handicap,
      'handicap_recipient_id': recipient,
      'race_to': 7,
      'description': getHandicapInfo(player1Rank, player2Rank)['description'],
    };
  }

  /// 🎮 Create match with handicap applied
  /// This creates a basic match (not challenge) with race to 7 + handicap
  /// NOTE: Database handicap_rules table is for challenge system only
  /// Basic handicap is calculated in-memory (no DB dependency)
  Future<Map<String, dynamic>> createRaceTo7Match({
    required String player1Id,
    required String player2Id,
    required String player1Rank,
    required String player2Rank,
    String? tournamentId,
    Map<String, dynamic>? additionalMatchData,
  }) async {
    // Calculate handicap
    final handicapInfo = applyHandicapToRaceTo7(
      player1Rank: player1Rank,
      player2Rank: player2Rank,
      player1Id: player1Id,
      player2Id: player2Id,
    );

    // Prepare match data
    final matchData = {
      'player1_id': player1Id,
      'player2_id': player2Id,
      'player1_score': handicapInfo['player1_starting_score'],
      'player2_score': handicapInfo['player2_starting_score'],
      'status': 'scheduled',
      'match_conditions': {
        'race_to': 7,
        'handicap': handicapInfo['handicap_value'],
        'handicap_recipient_id': handicapInfo['handicap_recipient_id'],
        'description': handicapInfo['description'],
      },
      if (tournamentId != null) 'tournament_id': tournamentId,
      ...?additionalMatchData,
    };

    // Insert match
    final response =
        await _supabase.from('matches').insert(matchData).select().single();

    return response;
  }

  /// 🔍 Validate handicap logic
  /// For testing purposes
  static void validateHandicapLogic() {
    // print('=' * 60);
    // print('HANDICAP CƠ BẢN - RACE TO 7 VALIDATION');
    // print('=' * 60);

    final testCases = [
      ['K', 'K', 0.0],
      ['K', 'I', 1.0],
      ['K', 'H', 2.0],
      ['K', 'H+', 3.0],
      ['I', 'G', 3.0],
      ['H', 'F', 4.0],
      ['G+', 'C', 4.0],
    ];

    // Validation loop - commented for production
    // for (final testCase in testCases) {
    //   final rank1 = testCase[0] as String;
    //   final rank2 = testCase[1] as String;
    //   final expected = testCase[2] as double;
    //   final actual = calculateBasicHandicap(rank1, rank2);
    //   // Uncomment for testing:
    //   // final match = actual == expected ? '✅' : '❌';
    //   // final info = getHandicapInfo(rank1, rank2);
    //   // print('$match $rank1 vs $rank2 → handicap=$actual (expected=$expected)');
    //   // print('   ${info['description']}');
    // }

    // print('=' * 60);
  }
}
