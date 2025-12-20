import 'package:flutter/material.dart';

/// Official SABO Arena Rank System
/// Based on ELO rating with skill descriptions
class SaboRankSystem {
  /// SABO rank mapping - MIGRATED 2025: Removed K+ and I+, shifted ELO ranges
  static const Map<String, Map<String, dynamic>> rankEloMapping = {
    'K': {
      'elo': 1000,
      'name': 'K',
      'skill': '1-2 Bi',
      'stability': 'Không ổn định, chỉ biết các kỹ thuật như cule, trỏ',
      'color': Color(0xFF8BC34A),
    },
    'I': {
      'elo': 1100,
      'name': 'I',
      'skill': '1-3 Bi',
      'stability':
          'Không ổn định, chỉ biết đơn và biết các kỹ thuật như cule, trỏ',
      'color': Color(0xFF2196F3),
    },
    'H': {
      'elo': 1200,
      'name': 'H',
      'skill': '3-5 Bi',
      'stability': 'Chưa ổn định, không có khả năng đi chấm, biết 1 ít ắp phẻ',
      'color': Color(0xFF9C27B0),
    },
    'H+': {
      'elo': 1300,
      'name': 'H+',
      'skill': '3-5 Bi',
      'stability':
          'Ổn định, không có khả năng đi chấm, Don 1-2 hình trên 1 race 7',
      'color': Color(0xFF673AB7),
    },
    'G': {
      'elo': 1400,
      'name': 'G',
      'skill': '5-6 Bi',
      'stability':
          'Chưa ổn định, đi được 1 chấm / race chấm 7, Don 3 hình trên 1 race 7',
      'color': Color(0xFFFF9800),
    },
    'G+': {
      'elo': 1500,
      'name': 'G+',
      'skill': '5-6 Bi',
      'stability':
          'Ổn định, đi được 1 chấm / race chấm 7, Don 4 hình trên 1 race 7',
      'color': Color(0xFFFF5722),
    },
    'F': {
      'elo': 1600,
      'name': 'F',
      'skill': '6-8 Bi',
      'stability':
          'Rất ổn định, đi được 2 chấm / race chấm 7, Đi hình, đơn bàn khá tốt',
      'color': Color(0xFFF44336),
    },
    'F+': {
      'elo': 1700,
      'name': 'F+',
      'skill': '2 Chấm',
      'stability': 'Cực kỳ ổn định, khả năng đi 2 chấm thông',
      'color': Color(0xFFE91E63),
    },
    'E': {
      'elo': 1800,
      'name': 'E',
      'skill': '3 Chấm',
      'stability': 'Chuyên gia, khả năng đi 3 chấm thông',
      'color': Color(0xFFD32F2F),
    },
    'D': {
      'elo': 1900,
      'name': 'D',
      'skill': '4 Chấm',
      'stability': 'Huyền thoại, khả năng đi 4 chấm thông',
      'color': Color(0xFF795548),
    },
    'C': {
      'elo': 2000,
      'name': 'C',
      'skill': '5 Chấm',
      'stability': 'Vô địch, khả năng đi 5 chấm thông',
      'color': Color(0xFFFFD700),
    },
  };

  /// Lấy rank từ ELO rating
  static String getRankFromElo(int elo) {
    if (elo < 1000) return 'K';

    final sortedRanks = rankEloMapping.entries.toList()
      ..sort(
        (a, b) => (a.value['elo'] as int).compareTo(b.value['elo'] as int),
      );

    String currentRank = 'K';
    for (final entry in sortedRanks) {
      final entryElo = entry.value['elo'] as int;
      if (elo >= entryElo) {
        currentRank = entry.key;
      } else {
        break;
      }
    }

    return currentRank;
  }

  /// Lấy màu sắc của rank
  static Color getRankColor(String rank) {
    return rankEloMapping[rank]?['color'] as Color? ?? const Color(0xFF8BC34A);
  }

  /// Lấy tên hiển thị của rank (hệ thống mới)
  static String getRankDisplayName(String rank) {
    return rankEloMapping[rank]?['name'] as String? ?? 'Chưa xếp hạng';
  }

  /// Lấy mô tả skill level
  static String getRankSkillDescription(String rank) {
    return rankEloMapping[rank]?['skill'] as String? ?? 'Mới bắt đầu';
  }

  /// Lấy mô tả độ ổn định
  static String getRankStabilityDescription(String rank) {
    return rankEloMapping[rank]?['stability'] as String? ?? '';
  }

  /// Lấy ELO minimum cho rank
  static int getRankMinElo(String rank) {
    return rankEloMapping[rank]?['elo'] as int? ?? 1000;
  }

  /// Lấy next rank và ELO cần thiết
  static Map<String, dynamic> getNextRankInfo(int currentElo) {
    final currentRank = getRankFromElo(currentElo);
    final sortedRanks = rankEloMapping.entries.toList()
      ..sort(
        (a, b) => (a.value['elo'] as int).compareTo(b.value['elo'] as int),
      );

    // Tìm rank hiện tại trong danh sách
    int currentIndex = sortedRanks.indexWhere(
      (entry) => entry.key == currentRank,
    );

    // Nếu đã là rank cao nhất
    if (currentIndex == -1 || currentIndex >= sortedRanks.length - 1) {
      return {
        'nextRank': currentRank,
        'nextRankElo': currentElo,
        'pointsNeeded': 0,
      };
    }

    final nextRankEntry = sortedRanks[currentIndex + 1];
    final nextRankElo = nextRankEntry.value['elo'] as int;

    return {
      'nextRank': nextRankEntry.key,
      'nextRankElo': nextRankElo,
      'pointsNeeded': nextRankElo - currentElo,
    };
  }

  /// Tính progress percentage tới next rank
  static double getRankProgress(int currentElo) {
    final currentRank = getRankFromElo(currentElo);
    final currentRankElo = getRankMinElo(currentRank);
    final nextRankInfo = getNextRankInfo(currentElo);
    final nextRankElo = nextRankInfo['nextRankElo'] as int;

    if (nextRankElo == currentElo) return 1.0; // Đã max rank

    final progress =
        (currentElo - currentRankElo) / (nextRankElo - currentRankElo);
    return progress.clamp(0.0, 1.0);
  }

  /// Lấy tất cả ranks theo thứ tự
  static List<String> getAllRanksOrdered() {
    final sortedRanks = rankEloMapping.entries.toList()
      ..sort(
        (a, b) => (a.value['elo'] as int).compareTo(b.value['elo'] as int),
      );
    return sortedRanks.map((e) => e.key).toList();
  }

  /// Format ELO display với thousand separator
  static String formatElo(int elo) {
    return elo.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
