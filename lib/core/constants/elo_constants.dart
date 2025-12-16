/// ELO System Constants - Simple Fixed Position-Based Rewards
/// Simplified ELO system for SABO Arena tournaments
class EloConstants {
  // Starting ELO for new players
  static const int startingElo = 1000;

  // Fixed ELO rewards - SABO Arena Tournament System
  static const int elo1stPlace = 75; // 1st place (Vô địch)
  static const int elo2ndPlace = 50; // 2nd place (Á quân) - CORRECTED
  static const int elo3rdPlace = 35; // 3rd place (Đồng hạng 3) - CORRECTED
  static const int elo4thPlace = 35; // 4th place (Đồng hạng 3) - Same as 3rd
  static const int eloTop25Percent = 25; // Top 25%
  static const int eloTop50Percent = 15; // Top 50%
  static const int eloTop75Percent = 10; // Top 75%
  static const int eloBottom25Percent = -5; // Bottom 25% (Small penalty)

  // ELO limits
  static const int MIN_ELO = 500; // Absolute minimum ELO
  static const int MAX_ELO = 3000; // Theoretical maximum ELO

  /// Calculate ELO change based on tournament position
  static int calculateEloChange(int position, int totalParticipants) {
    // Fixed positions (Top 4)
    if (position == 1) return elo1stPlace; // 1st: +75 ELO
    if (position == 2) return elo2ndPlace; // 2nd: +60 ELO
    if (position == 3) return elo3rdPlace; // 3rd: +45 ELO
    if (position == 4) return elo4thPlace; // 4th: +35 ELO

    // Percentage-based positions
    if (position <= totalParticipants * 0.25) {
      return eloTop25Percent; // Top 25%: +25 ELO
    }
    if (position <= totalParticipants * 0.50) {
      return eloTop50Percent; // Top 50%: +15 ELO
    }
    if (position <= totalParticipants * 0.75) {
      return eloTop75Percent; // Top 75%: +10 ELO
    }

    return eloBottom25Percent; // Bottom 25%: -5 ELO
  }

  /// Get position category description in Vietnamese
  static String getPositionCategoryVi(int position) {
    if (position == 1) return 'Vô địch';
    if (position == 2) return 'Á quân';
    if (position == 3) return 'Hạng 3';
    if (position == 4) return 'Hạng 4';
    return 'Top $position';
  }

  /// Get position category description in English
  static String getPositionCategory(int position) {
    if (position == 1) return '1st Place';
    if (position == 2) return '2nd Place';
    if (position == 3) return '3rd Place';
    if (position == 4) return '4th Place';
    return 'Top $position';
  }

  /// Get ELO examples for common tournament sizes
  static Map<String, Map<int, int>> getEloExamples() {
    return {
      '8_players': {
        1: elo1stPlace, // 1st: +75
        2: elo2ndPlace, // 2nd: +60
        3: elo3rdPlace, // 3rd: +45
        4: elo4thPlace, // 4th: +35
        5: eloTop50Percent, // 5th (Top 62.5%): +15
        6: eloTop50Percent, // 6th (Top 75%): +15
        7: eloTop75Percent, // 7th (Top 87.5%): +10
        8: eloBottom25Percent, // 8th (Bottom 100%): -5
      },
      '16_players': {
        1: elo1stPlace, // 1st: +75
        2: elo2ndPlace, // 2nd: +60
        3: elo3rdPlace, // 3rd: +45
        4: elo4thPlace, // 4th: +35
        8: eloTop50Percent, // 5th-8th (Top 50%): +15
        12: eloTop75Percent, // 9th-12th (Top 75%): +10
        16: eloBottom25Percent, // 13th-16th (Bottom 25%): -5
      },
      '32_players': {
        1: elo1stPlace, // 1st: +75
        2: elo2ndPlace, // 2nd: +60
        3: elo3rdPlace, // 3rd: +45
        4: elo4thPlace, // 4th: +35
        8: eloTop25Percent, // 5th-8th (Top 25%): +25
        16: eloTop50Percent, // 9th-16th (Top 50%): +15
        24: eloTop75Percent, // 17th-24th (Top 75%): +10
        32: eloBottom25Percent, // 25th-32nd (Bottom 25%): -5
      },
    };
  }
}
