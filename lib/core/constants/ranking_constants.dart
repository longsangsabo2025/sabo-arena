import 'package:flutter/material.dart';

/// 🎱 SABO ARENA - Ranking System Constants
/// Vietnamese billiards ranking system with verification requirements

class RankingConstants {
  // Rank codes in progression order - MIGRATED 2025: Removed K+ and I+
  static const String unranked = 'UNRANKED';
  static const String RANK_K = 'K';
  static const String RANK_I = 'I';
  static const String RANK_H = 'H';
  static const String RANK_H_PLUS = 'H+';
  static const String RANK_G = 'G';
  static const String RANK_G_PLUS = 'G+';
  static const String RANK_F = 'F';
  static const String RANK_F_PLUS = 'F+';
  static const String RANK_E = 'E';
  static const String RANK_D = 'D';
  static const String RANK_C = 'C';

  // Rank progression order (from lowest to highest) - MIGRATED 2025
  static const List<String> RANK_ORDER = [
    RANK_K, // 1000-1099: 1-2 Bi
    RANK_I, // 1100-1199: 1-3 Bi
    RANK_H, // 1200-1299: 3-5 Bi
    RANK_H_PLUS, // 1300-1399: 3-5 Bi (ổn định)
    RANK_G, // 1400-1499: 5-6 Bi
    RANK_G_PLUS, // 1500-1599: 5-6 Bi (ổn định)
    RANK_F, // 1600-1699: 6-8 Bi
    RANK_F_PLUS, // 1700-1799: 2 Chấm
    RANK_E, // 1800-1899: 3 Chấm
    RANK_D, // 1900-1999: 4 Chấm
    RANK_C, // 2000-2099: 5 Chấm
  ];

  // ELO ranges for each rank - MIGRATED 2025: Removed K+/I+, shifted ranges
  static const Map<String, Map<String, int>> RANK_ELO_RANGES = {
    RANK_K: {'min': 1000, 'max': 1099}, // 1-2 Bi
    RANK_I: {'min': 1100, 'max': 1199}, // 1-3 Bi
    RANK_H: {'min': 1200, 'max': 1299}, // 3-5 Bi
    RANK_H_PLUS: {'min': 1300, 'max': 1399}, // 3-5 Bi (ổn định)
    RANK_G: {'min': 1400, 'max': 1499}, // 5-6 Bi
    RANK_G_PLUS: {'min': 1500, 'max': 1599}, // 5-6 Bi (ổn định)
    RANK_F: {'min': 1600, 'max': 1699}, // 6-8 Bi
    RANK_F_PLUS: {'min': 1700, 'max': 1799}, // 2 Chấm
    RANK_E: {'min': 1800, 'max': 1899}, // 3 Chấm
    RANK_D: {'min': 1900, 'max': 1999}, // 4 Chấm
    RANK_C: {'min': 2000, 'max': 2099}, // 5 Chấm
  };

  // Icons for each rank
  static const Map<String, IconData> RANK_ICONS = {
    RANK_K: Icons.star_border,
    RANK_I: Icons.star,
    RANK_H: Icons.military_tech_outlined,
    RANK_H_PLUS: Icons.military_tech,
    RANK_G: Icons.shield_outlined,
    RANK_G_PLUS: Icons.shield,
    RANK_F: Icons.local_fire_department_outlined,
    RANK_F_PLUS: Icons.local_fire_department,
    RANK_E: Icons.verified_user_outlined,
    RANK_D: Icons.verified_user,
    RANK_C: Icons.diamond,
    unranked: Icons.help_outline,
  };

  // Vietnamese rank names and descriptions - MIGRATED 2025
  static const Map<String, Map<String, String>> RANK_DETAILS = {
    RANK_K: {
      'name': 'K',
      'name_en': 'Beginner',
      'description': '1-2 Bi',
      'description_en': '1-2 balls',
      'stability': 'Không ổn định, chỉ biết các kỹ thuật như cule, trỏ',
      'color': '#8B4513',
    },
    RANK_I: {
      'name': 'I',
      'name_en': 'Novice',
      'description': '1-3 Bi',
      'description_en': '1-3 balls',
      'stability':
          'Không ổn định, chỉ biết đơn và biết các kỹ thuật như cule, trỏ',
      'color': '#CD853F',
    },
    RANK_H: {
      'name': 'H',
      'name_en': 'Amateur',
      'description': '3-5 Bi',
      'description_en': '3-5 balls',
      'stability': 'Chưa ổn định, không có khả năng đi chấm, biết 1 ít ắp phẻ',
      'color': '#C0C0C0',
    },
    RANK_H_PLUS: {
      'name': 'H+',
      'name_en': 'Amateur+',
      'description': '3-5 Bi',
      'description_en': '3-5 balls',
      'stability':
          'Ổn định, không có khả năng đi chấm, Don 1-2 hình trên 1 race 7',
      'color': '#B0B0B0',
    },
    RANK_G: {
      'name': 'G',
      'name_en': 'Intermediate',
      'description': '5-6 Bi',
      'description_en': '5-6 balls',
      'stability':
          'Chưa ổn định, đi được 1 chấm / race chấm 7, Don 3 hình trên 1 race 7',
      'color': '#FFD700',
    },
    RANK_G_PLUS: {
      'name': 'G+',
      'name_en': 'Intermediate+',
      'description': '5-6 Bi',
      'description_en': '5-6 balls',
      'stability':
          'Ổn định, đi được 1 chấm / race chấm 7, Don 4 hình trên 1 race 7',
      'color': '#FFA500',
    },
    RANK_F: {
      'name': 'F',
      'name_en': 'Advanced',
      'description': '6-8 Bi',
      'description_en': '6-8 balls',
      'stability':
          'Rất ổn định, đi được 2 chấm / race chấm 7, Đi hình, don bàn khá tốt',
      'color': '#FF6347',
    },
    RANK_F_PLUS: {
      'name': 'F+',
      'name_en': 'Expert',
      'description': '2 Chấm',
      'description_en': '2 dots',
      'stability': 'Cực kỳ ổn định, khả năng đi 2 chấm thông',
      'color': '#FF4500',
    },
    RANK_E: {
      'name': 'E',
      'name_en': 'Master',
      'description': '3 Chấm',
      'description_en': '3 dots',
      'stability': 'Chuyên gia, khả năng đi 3 chấm thông',
      'color': '#D32F2F',
    },
    RANK_D: {
      'name': 'D',
      'name_en': 'Grand Master',
      'description': '4 Chấm',
      'description_en': '4 dots',
      'stability': 'Huyền thoại, khả năng đi 4 chấm thông',
      'color': '#795548',
    },
    RANK_C: {
      'name': 'C',
      'name_en': 'Champion',
      'description': '5 Chấm',
      'description_en': '5 dots',
      'stability': 'Vô địch, khả năng đi 5 chấm thông',
      'color': '#FFD700',
    },
  };

  // Verification requirements
  static const int MIN_VERIFICATION_MATCHES = 3;
  static const double MIN_VERIFICATION_WIN_RATE = 0.40;
  static const int AUTO_VERIFY_MATCH_THRESHOLD = 10;
  static const int RANK_PROTECTION_DAYS = 7;
  static const int MIN_GAMES_BEFORE_DEMOTION = 10;

  // Rank progression helpers
  static String? getNextRank(String currentRank) {
    final currentIndex = RANK_ORDER.indexOf(currentRank);
    if (currentIndex == -1 || currentIndex == RANK_ORDER.length - 1) {
      return null;
    }
    return RANK_ORDER[currentIndex + 1];
  }

  static String? getPreviousRank(String currentRank) {
    final currentIndex = RANK_ORDER.indexOf(currentRank);
    if (currentIndex <= 0) {
      return null;
    }
    return RANK_ORDER[currentIndex - 1];
  }

  static bool isRankUp(String fromRank, String toRank) {
    final fromIndex = RANK_ORDER.indexOf(fromRank);
    final toIndex = RANK_ORDER.indexOf(toRank);
    return toIndex > fromIndex;
  }

  static bool isRankDown(String fromRank, String toRank) {
    final fromIndex = RANK_ORDER.indexOf(fromRank);
    final toIndex = RANK_ORDER.indexOf(toRank);
    return toIndex < fromIndex;
  }

  static String getRankFromElo(int elo) {
    if (elo <= 0) {
      return unranked;
    }
    if (elo > 0 && elo < 1000) {
      return RANK_K;
    }
    for (final entry in RANK_ELO_RANGES.entries) {
      final min = entry.value['min']!;
      final max = entry.value['max']!;
      if (elo >= min && elo <= max) {
        return entry.key;
      }
    }
    // If ELO is above all defined ranges, return highest rank
    return RANK_C;
  }

  static int getRankIndex(String rank) {
    return RANK_ORDER.indexOf(rank);
  }

  static int getRankDifference(String rank1, String rank2) {
    final index1 = getRankIndex(rank1);
    final index2 = getRankIndex(rank2);
    return (index2 - index1).abs();
  }

  // Check if rank requires verification
  static bool requiresVerification(String rank) {
    return rank != unranked;
  }

  // Get rank display info
  static Map<String, String> getRankDisplayInfo(String rank) {
    return RANK_DETAILS[rank] ??
        {
          'name': 'Unknown',
          'name_en': 'Unknown',
          'description': 'Unknown rank',
          'description_en': 'Unknown rank',
          'color': '#999999',
        };
  }
}
