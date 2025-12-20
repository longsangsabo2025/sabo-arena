import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/rank_migration_helper.dart';

/// Service để handle tất cả các quy tắc thách đấu SABO Arena
/// Bao gồm: rank eligibility, SPA betting, handicap calculation
class ChallengeRulesService {
  static ChallengeRulesService? _instance;
  static ChallengeRulesService get instance =>
      _instance ??= ChallengeRulesService._();
  ChallengeRulesService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🎯 SABO Rank System - 10 cấp từ K đến C (đã loại bỏ K+ và I+)
  /// Migration 2025: Đã loại K+ và I+, tất cả rank dịch xuống theo ELO mới
  static const Map<String, int> rankValues = {
    'K': 1,
    'I': 2,
    'H': 3,
    'H+': 4,
    'G': 5,
    'G+': 6,
    'F': 7,
    'F+': 8,
    'E': 9,
    'D': 10,
    'C': 11,
  };

  /// 💰 SPA Betting Configuration
  static const Map<int, Map<String, dynamic>> spaBettingConfig = {
    100: {'raceTo': 8, 'description': 'Thách đấu sơ cấp'},
    200: {'raceTo': 12, 'description': 'Thách đấu cơ bản'},
    300: {'raceTo': 14, 'description': 'Thách đấu trung bình'},
    400: {'raceTo': 16, 'description': 'Thách đấu trung cấp'},
    500: {'raceTo': 18, 'description': 'Thách đấu trung cao'},
    600: {'raceTo': 22, 'description': 'Thách đấu cao cấp'},
  };

  /// ⚖️ Handicap Matrix - [chênh lệch rank][mức cược] = handicap
  static const Map<String, Map<int, double>> handicapMatrix = {
    '1_sub': {100: 0.5, 200: 1.0, 300: 1.5, 400: 1.5, 500: 2.0, 600: 2.5},
    '1_main': {100: 1.0, 200: 1.5, 300: 2.0, 400: 2.5, 500: 3.0, 600: 3.5},
    '1.5_main': {100: 1.5, 200: 2.5, 300: 3.5, 400: 4.0, 500: 5.0, 600: 6.0},
    '2_main': {100: 2.0, 200: 3.0, 300: 4.0, 400: 5.0, 500: 6.0, 600: 7.0},
  };

  /// 🔢 Kiểm tra ai có thể thách đấu ai (±1 hạng chính)
  /// K chỉ chơi với I tối đa, I chơi với K và H, H chơi với I và G
  /// Note: Sau khi loại bỏ K+ và I+, logic này vẫn giữ nguyên
  bool canChallenge(String challengerRank, String challengedRank) {
    final challengerValue = rankValues[challengerRank];
    final challengedValue = rankValues[challengedRank];

    if (challengerValue == null || challengedValue == null) {
      return false;
    }

    // Chênh lệch tối đa 1 hạng chính (ví dụ: K→I, I→H, H→H+)
    // Ví dụ: K(1) → I(2) OK | K(1) → H(3) KHÔNG OK
    final difference = (challengerValue - challengedValue).abs();
    return difference <= 1;
  }

  /// 📊 Lấy danh sách rank có thể thách đấu
  /// Note: Sau khi loại K+ và I+, danh sách này đã được cập nhật
  List<String> getEligibleRanks(String currentRank) {
    final currentValue = rankValues[currentRank];
    if (currentValue == null) return [];

    final eligibleRanks = <String>[];

    for (final entry in rankValues.entries) {
      final rankName = entry.key;
      final rankValue = entry.value;

      // Kiểm tra trong phạm vi ±1 hạng chính
      // Ví dụ: K(1) → [K, I] | I(2) → [K, I, H]
      if ((currentValue - rankValue).abs() <= 1) {
        eligibleRanks.add(rankName);
      }
    }

    return eligibleRanks;
  }

  /// 💰 Validate SPA bet amount
  bool isValidSpaBet(int amount) {
    return spaBettingConfig.containsKey(amount);
  }

  /// 🎯 Get race-to value for bet amount
  int getRaceToForBet(int betAmount) {
    return spaBettingConfig[betAmount]?['raceTo'] ?? 8;
  }

  /// ⚖️ Tính handicap dựa trên rank difference và bet amount
  ChallengeHandicapResult calculateHandicap({
    required String challengerRank,
    required String challengedRank,
    required int spaBetAmount,
  }) {
    final challengerValue = rankValues[challengerRank];
    final challengedValue = rankValues[challengedRank];

    if (challengerValue == null || challengedValue == null) {
      return ChallengeHandicapResult(
        isValid: false,
        errorMessage: 'Invalid rank values',
      );
    }

    if (!isValidSpaBet(spaBetAmount)) {
      return ChallengeHandicapResult(
        isValid: false,
        errorMessage: 'Invalid SPA bet amount',
      );
    }

    final difference =
        challengedValue - challengerValue; // Positive = challenger weaker
    final absDifference = difference.abs();

    // Check eligibility
    if (absDifference > 4) {
      return ChallengeHandicapResult(
        isValid: false,
        errorMessage: 'Rank difference too large (max ±2 main ranks)',
      );
    }

    // No handicap if same rank
    if (difference == 0) {
      return ChallengeHandicapResult(
        isValid: true,
        challengerHandicap: 0.0,
        challengedHandicap: 0.0,
        raceTo: getRaceToForBet(spaBetAmount),
        explanation: 'Same rank - no handicap applied',
      );
    }

    // Determine handicap category
    String handicapKey;
    if (absDifference == 1) {
      handicapKey = '1_sub';
    } else if (absDifference == 2) {
      handicapKey = '1_main';
    } else if (absDifference == 3) {
      handicapKey = '1.5_main';
    } else if (absDifference == 4) {
      handicapKey = '2_main';
    } else {
      return ChallengeHandicapResult(
        isValid: false,
        errorMessage: 'Unsupported rank difference',
      );
    }

    final handicapValue = handicapMatrix[handicapKey]?[spaBetAmount] ?? 0.0;
    final raceTo = getRaceToForBet(spaBetAmount);

    // Weaker player gets handicap
    double challengerHandicap = 0.0;
    double challengedHandicap = 0.0;
    String explanation;

    if (difference > 0) {
      // Challenger is weaker
      challengerHandicap = handicapValue;
      explanation =
          '$challengerRank gets +$handicapValue handicap vs $challengedRank';
    } else {
      // Challenged is weaker
      challengedHandicap = handicapValue;
      explanation =
          '$challengedRank gets +$handicapValue handicap vs $challengerRank';
    }

    return ChallengeHandicapResult(
      isValid: true,
      challengerHandicap: challengerHandicap,
      challengedHandicap: challengedHandicap,
      raceTo: raceTo,
      rankDifference: absDifference,
      explanation: explanation,
    );
  }

  /// 📋 Validate complete challenge request
  Future<ChallengeValidationResult> validateChallenge({
    required String challengerId,
    required String challengedId,
    required int spaBetAmount,
  }) async {
    try {
      // Get both players' ranks
      final challengerData = await _supabase
          .from('users')
          .select('ranking, spa_balance')
          .eq('id', challengerId)
          .single();

      final challengedData = await _supabase
          .from('users')
          .select('ranking, spa_balance, is_available_for_challenges')
          .eq('id', challengedId)
          .single();

      final challengerRank = challengerData['ranking'] as String?;
      final challengedRank = challengedData['ranking'] as String?;
      final challengerBalance = challengerData['spa_balance'] as int? ?? 0;
      final challengedBalance = challengedData['spa_balance'] as int? ?? 0;
      final isAvailable =
          challengedData['is_available_for_challenges'] as bool? ?? true;

      if (challengerRank == null || challengedRank == null) {
        return ChallengeValidationResult(
          isValid: false,
          errorMessage: 'Both players must have valid ranks',
        );
      }

      // Check availability
      if (!isAvailable) {
        return ChallengeValidationResult(
          isValid: false,
          errorMessage: 'Player is not available for challenges',
        );
      }

      // Check rank eligibility
      if (!canChallenge(challengerRank, challengedRank)) {
        return ChallengeValidationResult(
          isValid: false,
          errorMessage:
              'Hạng quá chênh lệch (tối đa ±1 hạng chính). Ví dụ: K chỉ chơi với I tối đa, I chơi với K và H, H chơi với I và G',
        );
      }

      // Check SPA balance
      if (challengerBalance < spaBetAmount) {
        return ChallengeValidationResult(
          isValid: false,
          errorMessage: 'Insufficient SPA balance for challenger',
        );
      }

      if (challengedBalance < spaBetAmount) {
        return ChallengeValidationResult(
          isValid: false,
          errorMessage: 'Insufficient SPA balance for challenged player',
        );
      }

      // Calculate handicap
      final handicapResult = calculateHandicap(
        challengerRank: challengerRank,
        challengedRank: challengedRank,
        spaBetAmount: spaBetAmount,
      );

      if (!handicapResult.isValid) {
        return ChallengeValidationResult(
          isValid: false,
          errorMessage: handicapResult.errorMessage,
        );
      }

      return ChallengeValidationResult(
        isValid: true,
        challengerRank: challengerRank,
        challengedRank: challengedRank,
        handicapResult: handicapResult,
      );
    } catch (error) {
      return ChallengeValidationResult(
        isValid: false,
        errorMessage: 'Database error: $error',
      );
    }
  }

  /// 🏆 Get all SPA betting options
  List<Map<String, dynamic>> getSpaBettingOptions() {
    return spaBettingConfig.entries.map((entry) {
      return {
        'amount': entry.key,
        'raceTo': entry.value['raceTo'],
        'description': entry.value['description'],
      };
    }).toList();
  }

  /// 📈 Get rank display info (Updated for 10-rank system)
  Map<String, dynamic> getRankDisplayInfo(String rank) {
    final value = rankValues[rank];
    if (value == null) return {};

    // Determine color based on rank level (updated after removing K+ and I+)
    String color;
    if (value == 1) {
      color = '#4CAF50'; // Green for K
    } else if (value == 2)
      color = '#2196F3'; // Blue for I
    else if (value <= 4)
      color = '#FF9800'; // Orange for H, H+
    else if (value <= 6)
      color = '#9C27B0'; // Purple for G, G+
    else if (value <= 8)
      color = '#F44336'; // Red for F, F+
    else
      color = '#607D8B'; // Blue Grey for E, D, C

    return {
      'rank': rank,
      'value': value,
      'color': color,
      'displayName': RankMigrationHelper.getNewDisplayName(rank),
    };
  }
}

/// 📊 Result of handicap calculation
class ChallengeHandicapResult {
  final bool isValid;
  final String? errorMessage;
  final double challengerHandicap;
  final double challengedHandicap;
  final int raceTo;
  final int rankDifference;
  final String explanation;

  ChallengeHandicapResult({
    required this.isValid,
    this.errorMessage,
    this.challengerHandicap = 0.0,
    this.challengedHandicap = 0.0,
    this.raceTo = 8,
    this.rankDifference = 0,
    this.explanation = '',
  });
}

/// 📋 Result of complete challenge validation
class ChallengeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? challengerRank;
  final String? challengedRank;
  final ChallengeHandicapResult? handicapResult;

  ChallengeValidationResult({
    required this.isValid,
    this.errorMessage,
    this.challengerRank,
    this.challengedRank,
    this.handicapResult,
  });
}
