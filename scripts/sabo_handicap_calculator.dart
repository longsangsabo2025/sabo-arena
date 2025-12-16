// 🎯 SABO ARENA - Handicap Calculator Implementation
// Precise handicap calculation based on SABO official system

void main() async {
  print('🎯 SABO HANDICAP CALCULATION SYSTEM');
  print('=' * 60);

  await testHandicapCalculations();

  print('\n✅ Handicap Calculator Implementation completed!');
}

Future<void> testHandicapCalculations() async {
  print('\n📊 HANDICAP CALCULATION TESTS');
  print('-' * 40);

  // Rank values mapping (K=1, K+=2, I=3, etc.)
  final Map<String, int> rankValues = {
    'K': 1,
    'K+': 2,
    'I': 3,
    'I+': 4,
    'H': 5,
    'H+': 6,
    'G': 7,
    'G+': 8,
    'F': 9,
    'F+': 10,
    'E': 11,
    'E+': 12,
  };

  // Challenge bet configurations
  final List<Map<String, dynamic>> betConfigs = [
    {
      'bet_points': 100,
      'race_to': 8,
      'handicap_1_rank': 1.0,
      'handicap_05_rank': 0.5,
    },
    {
      'bet_points': 200,
      'race_to': 12,
      'handicap_1_rank': 1.5,
      'handicap_05_rank': 1.0,
    },
    {
      'bet_points': 300,
      'race_to': 14,
      'handicap_1_rank': 2.0,
      'handicap_05_rank': 1.5,
    },
    {
      'bet_points': 400,
      'race_to': 16,
      'handicap_1_rank': 2.5,
      'handicap_05_rank': 1.5,
    },
    {
      'bet_points': 500,
      'race_to': 18,
      'handicap_1_rank': 3.0,
      'handicap_05_rank': 2.0,
    },
    {
      'bet_points': 600,
      'race_to': 22,
      'handicap_1_rank': 3.5,
      'handicap_05_rank': 2.5,
    },
  ];

  // Test cases
  final List<Map<String, dynamic>> testCases = [
    {'challenger': 'H', 'opponent': 'H', 'bet': 300, 'expected_diff': 0},
    {'challenger': 'K', 'opponent': 'K+', 'bet': 300, 'expected_diff': 1},
    {'challenger': 'K', 'opponent': 'I', 'bet': 300, 'expected_diff': 2},
    {'challenger': 'K', 'opponent': 'I+', 'bet': 300, 'expected_diff': 3},
    {'challenger': 'K', 'opponent': 'H', 'bet': 300, 'expected_diff': 4},
    {'challenger': 'H', 'opponent': 'G+', 'bet': 500, 'expected_diff': 3},
    {'challenger': 'G', 'opponent': 'E', 'bet': 600, 'expected_diff': 4},
  ];

  print('🧮 Testing Handicap Calculations:');
  print('');

  for (var testCase in testCases) {
    final result = calculateSaboHandicap(
      testCase['challenger'],
      testCase['opponent'],
      testCase['bet'],
      rankValues,
      betConfigs,
    );

    print(
      '📋 Test: ${testCase['challenger']} vs ${testCase['opponent']} (${testCase['bet']} SPA)',
    );
    print('   Sub-rank difference: ${result['sub_rank_diff']}');
    print('   Handicap challenger: ${result['handicap_challenger']}');
    print('   Handicap opponent: ${result['handicap_opponent']}');
    print('   Race to: ${result['race_to']}');
    print('   Explanation: ${result['explanation']}');
    print('   Valid: ${result['is_valid']}');
    print('');
  }
}

Map<String, dynamic> calculateSaboHandicap(
  String challengerRank,
  String opponentRank,
  int betPoints,
  Map<String, int> rankValues,
  List<Map<String, dynamic>> betConfigs,
) {
  final challengerValue = rankValues[challengerRank] ?? 0;
  final opponentValue = rankValues[opponentRank] ?? 0;
  final subRankDiff =
      opponentValue - challengerValue; // Positive = opponent stronger

  // Find bet configuration
  final config = betConfigs.firstWhere(
    (c) => c['bet_points'] == betPoints,
    orElse: () => betConfigs[0],
  );

  double handicapChallenger = 0;
  double handicapOpponent = 0;
  bool isValid = true;
  String errorMessage = '';
  String explanation = '';

  // Validate max difference (±4 sub-ranks = ±2 main ranks)
  if (subRankDiff.abs() > 4) {
    isValid = false;
    errorMessage =
        'Chênh lệch hạng quá lớn. Chỉ được thách đấu trong phạm vi ±2 hạng chính.';
  }

  if (isValid) {
    final absSubRankDiff = subRankDiff.abs();

    if (absSubRankDiff == 0) {
      // Same rank - no handicap
      explanation = 'Cùng hạng $challengerRank - Không có handicap';
    } else if (absSubRankDiff == 1) {
      // 1 sub-rank difference
      final handicapAmount = config['handicap_05_rank'];
      if (subRankDiff > 0) {
        handicapChallenger = handicapAmount; // Challenger weaker
      } else {
        handicapOpponent = handicapAmount; // Opponent weaker
      }
      explanation =
          '${subRankDiff > 0 ? challengerRank : opponentRank} được cộng $handicapAmount bàn ban đầu (chênh 1 sub-rank)';
    } else if (absSubRankDiff == 2) {
      // 1 main rank difference
      final handicapAmount = config['handicap_1_rank'];
      if (subRankDiff > 0) {
        handicapChallenger = handicapAmount; // Challenger weaker
      } else {
        handicapOpponent = handicapAmount; // Opponent weaker
      }
      explanation =
          '${subRankDiff > 0 ? challengerRank : opponentRank} được cộng $handicapAmount bàn ban đầu (chênh 1 main rank)';
    } else if (absSubRankDiff == 3) {
      // 1 main rank + 1 sub-rank
      final handicapAmount =
          config['handicap_1_rank'] + config['handicap_05_rank'];
      if (subRankDiff > 0) {
        handicapChallenger = handicapAmount; // Challenger weaker
      } else {
        handicapOpponent = handicapAmount; // Opponent weaker
      }
      explanation =
          '${subRankDiff > 0 ? challengerRank : opponentRank} được cộng $handicapAmount bàn ban đầu (chênh 1 main rank + 1 sub-rank)';
    } else if (absSubRankDiff == 4) {
      // 2 main ranks difference
      final handicapAmount = config['handicap_1_rank'] * 2;
      if (subRankDiff > 0) {
        handicapChallenger = handicapAmount; // Challenger weaker
      } else {
        handicapOpponent = handicapAmount; // Opponent weaker
      }
      explanation =
          '${subRankDiff > 0 ? challengerRank : opponentRank} được cộng $handicapAmount bàn ban đầu (chênh 2 main rank)';
    }
  }

  return {
    'is_valid': isValid,
    'error_message': errorMessage,
    'sub_rank_diff': subRankDiff.abs(),
    'handicap_challenger': handicapChallenger,
    'handicap_opponent': handicapOpponent,
    'challenger_rank': challengerRank,
    'opponent_rank': opponentRank,
    'bet_points': betPoints,
    'race_to': config['race_to'],
    'explanation': explanation,
    'initial_challenger_score': handicapChallenger.toInt(),
    'initial_opponent_score': handicapOpponent.toInt(),
  };
}

// SQL function for database handicap calculation
String getHandicapCalculationSQL() {
  return '''
-- 🎯 SABO HANDICAP CALCULATION FUNCTION

CREATE OR REPLACE FUNCTION calculate_sabo_handicap(
  challenger_rank VARCHAR(5),
  opponent_rank VARCHAR(5),
  bet_points INTEGER
) RETURNS JSONB AS \$\$
DECLARE
  rank_values JSONB := '{
    "K": 1, "K+": 2, "I": 3, "I+": 4, "H": 5, "H+": 6,
    "G": 7, "G+": 8, "F": 9, "F+": 10, "E": 11, "E+": 12
  }';
  challenger_value INTEGER;
  opponent_value INTEGER;
  sub_rank_diff INTEGER;
  abs_sub_rank_diff INTEGER;
  config RECORD;
  handicap_challenger DECIMAL(3,1) := 0;
  handicap_opponent DECIMAL(3,1) := 0;
  handicap_amount DECIMAL(3,1);
  is_valid BOOLEAN := true;
  error_message TEXT := '';
  explanation TEXT := '';
BEGIN
  -- Get rank values
  challenger_value := (rank_values->>challenger_rank)::INTEGER;
  opponent_value := (rank_values->>opponent_rank)::INTEGER;
  sub_rank_diff := opponent_value - challenger_value;
  abs_sub_rank_diff := ABS(sub_rank_diff);
  
  -- Get bet configuration
  SELECT * INTO config FROM challenge_configurations WHERE bet_amount = bet_points;
  IF NOT FOUND THEN
    SELECT * INTO config FROM challenge_configurations WHERE bet_amount = 100;
  END IF;
  
  -- Validate max difference (±4 sub-ranks)
  IF abs_sub_rank_diff > 4 THEN
    is_valid := false;
    error_message := 'Chênh lệch hạng quá lớn. Chỉ được thách đấu trong phạm vi ±2 hạng chính.';
  END IF;
  
  -- Calculate handicap
  IF is_valid THEN
    IF abs_sub_rank_diff = 0 THEN
      explanation := 'Cùng hạng ' || challenger_rank || ' - Không có handicap';
    ELSIF abs_sub_rank_diff = 1 THEN
      handicap_amount := config.handicap_sub;
      IF sub_rank_diff > 0 THEN
        handicap_challenger := handicap_amount;
      ELSE
        handicap_opponent := handicap_amount;
      END IF;
      explanation := CASE WHEN sub_rank_diff > 0 THEN challenger_rank ELSE opponent_rank END 
                   || ' được cộng ' || handicap_amount || ' bàn ban đầu (chênh 1 sub-rank)';
    ELSIF abs_sub_rank_diff = 2 THEN
      handicap_amount := config.handicap_full;
      IF sub_rank_diff > 0 THEN
        handicap_challenger := handicap_amount;
      ELSE
        handicap_opponent := handicap_amount;
      END IF;
      explanation := CASE WHEN sub_rank_diff > 0 THEN challenger_rank ELSE opponent_rank END 
                   || ' được cộng ' || handicap_amount || ' bàn ban đầu (chênh 1 main rank)';
    ELSIF abs_sub_rank_diff = 3 THEN
      handicap_amount := config.handicap_full + config.handicap_sub;
      IF sub_rank_diff > 0 THEN
        handicap_challenger := handicap_amount;
      ELSE
        handicap_opponent := handicap_amount;
      END IF;
      explanation := CASE WHEN sub_rank_diff > 0 THEN challenger_rank ELSE opponent_rank END 
                   || ' được cộng ' || handicap_amount || ' bàn ban đầu (chênh 1 main rank + 1 sub-rank)';
    ELSIF abs_sub_rank_diff = 4 THEN
      handicap_amount := config.handicap_full * 2;
      IF sub_rank_diff > 0 THEN
        handicap_challenger := handicap_amount;
      ELSE
        handicap_opponent := handicap_amount;
      END IF;
      explanation := CASE WHEN sub_rank_diff > 0 THEN challenger_rank ELSE opponent_rank END 
                   || ' được cộng ' || handicap_amount || ' bàn ban đầu (chênh 2 main rank)';
    END IF;
  END IF;
  
  RETURN jsonb_build_object(
    'is_valid', is_valid,
    'error_message', error_message,
    'sub_rank_diff', abs_sub_rank_diff,
    'handicap_challenger', handicap_challenger,
    'handicap_opponent', handicap_opponent,
    'challenger_rank', challenger_rank,
    'opponent_rank', opponent_rank,
    'bet_points', bet_points,
    'race_to', config.race_to,
    'explanation', explanation,
    'initial_challenger_score', handicap_challenger::INTEGER,
    'initial_opponent_score', handicap_opponent::INTEGER
  );
END;
\$\$ LANGUAGE plpgsql;

-- Test function
SELECT calculate_sabo_handicap('K', 'I+', 300);
SELECT calculate_sabo_handicap('H', 'G+', 500);
SELECT calculate_sabo_handicap('G', 'E', 600);
''';
}
