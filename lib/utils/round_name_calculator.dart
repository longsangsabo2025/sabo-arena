/// 🎯 Round Name Calculator - Shared utility for all bracket services
/// 
/// Calculates round names based on bracket structure for consistent UI display
/// 
/// Usage:
/// ```dart
/// final roundName = RoundNameCalculator.calculate(
///   bracketType: 'WB',
///   stageRound: 1,
///   displayOrder: 1101,
/// );
/// // Returns: "WB R1"
/// ```
class RoundNameCalculator {
  /// Calculate round name for UI display
  /// 
  /// Supports:
  /// - DE16: WB R1-R3, LB R1-R5, Finals
  /// - DE32: WB R1-R5, LB R1-R9, Finals
  /// - SABO DE32: Group A/B with WB/LB, Cross Finals (8→4→2→1)
  /// - DE64: Group A/B/C/D with WB/LB, Cross Finals
  static String? calculate({
    required String bracketType,
    String? bracketGroup,
    required int stageRound,
    int? displayOrder,
  }) {
    // SABO DE32 Cross Finals (31xxx-33xxx)
    if (displayOrder != null && displayOrder >= 31000 && displayOrder < 34000) {
      return _calculateSaboDE32CrossFinalsName(displayOrder: displayOrder);
    }
    
    // DE64 with groups (display_order >= 10000)
    if (displayOrder != null && displayOrder >= 10000) {
      return _calculateDE64RoundName(
        bracketType: bracketType,
        bracketGroup: bracketGroup,
        stageRound: stageRound,
        displayOrder: displayOrder,
      );
    }
    
    // DE16/DE32 without groups (display_order < 10000)
    return _calculateStandardRoundName(
      bracketType: bracketType,
      stageRound: stageRound,
      displayOrder: displayOrder,
    );
  }

  /// Calculate round name for SABO DE32 Cross Finals (8→4→2→1)
  static String? _calculateSaboDE32CrossFinalsName({
    required int displayOrder,
  }) {
    // Cross Semi-Finals: 31xxx (8→4 people)
    if (displayOrder >= 31000 && displayOrder < 32000) {
      return 'Tứ Kết Liên Bảng'; // 8→4 (Quarter-Finals between groups)
    }
    // Cross Finals: 32xxx (4→2 people)
    else if (displayOrder >= 32000 && displayOrder < 33000) {
      return 'Bán Kết'; // 4→2 (Semi-Finals)
    }
    // Grand Final: 33xxx (2→1 Champion!)
    else if (displayOrder >= 33000 && displayOrder < 34000) {
      return '🏆 Chung Kết'; // 2→1 (Grand Final)
    }
    
    return null;
  }

  /// Calculate round name for DE64 with groups
  static String? _calculateDE64RoundName({
    required String bracketType,
    String? bracketGroup,
    required int stageRound,
    required int displayOrder,
  }) {
    // Group stage matches (11xxx - 43xxx)
    if (bracketGroup != null && bracketGroup.isNotEmpty) {
      if (bracketType == 'WB') {
        return 'Group $bracketGroup - WB R$stageRound';
      } else if (bracketType == 'LB-A') {
        return 'Group $bracketGroup - LB R$stageRound';
      } else if (bracketType == 'LB-B') {
        return 'Group $bracketGroup - LB R${stageRound + 3}';
      }
    }
    
    // Cross finals (51xxx - 54xxx)
    if (displayOrder >= 51000 && displayOrder < 52000) {
      return 'Round of 16';
    } else if (displayOrder >= 52000 && displayOrder < 53000) {
      return 'Quarter-Finals';
    } else if (displayOrder >= 53000 && displayOrder < 54000) {
      return 'Semi-Finals';
    } else if (displayOrder >= 54000) {
      return 'Grand Final';
    }
    
    return null;
  }

  /// Calculate round name for standard DE16/DE32
  static String? _calculateStandardRoundName({
    required String bracketType,
    required int stageRound,
    int? displayOrder,
  }) {
    // Winners Bracket
    if (bracketType == 'WB') {
      return 'WB R$stageRound';
    }
    
    // Losers Branch A
    if (bracketType == 'LB-A') {
      return 'LB R$stageRound';
    }
    
    // Losers Branch B (continues from LB-A)
    if (bracketType == 'LB-B') {
      return 'LB R${stageRound + 3}';
    }
    
    // Finals
    if (bracketType == 'SABO' || (displayOrder != null && displayOrder >= 4000)) {
      return 'Finals';
    }
    
    // Fallback: try to guess from display_order
    if (displayOrder != null) {
      if (displayOrder >= 1000 && displayOrder < 2000) {
        // WB: 1101-1302
        if (displayOrder < 1200) return 'WB R1';
        if (displayOrder < 1300) return 'WB R2';
        if (displayOrder < 1400) return 'WB R3';
        if (displayOrder < 1500) return 'WB R4';
        return 'WB R5';
      } else if (displayOrder >= 2000 && displayOrder < 3000) {
        // LB-A: 2101-2301
        if (displayOrder < 2200) return 'LB R1';
        if (displayOrder < 2300) return 'LB R2';
        if (displayOrder < 2400) return 'LB R3';
        if (displayOrder < 2500) return 'LB R4';
        return 'LB R5';
      } else if (displayOrder >= 3000 && displayOrder < 4000) {
        // LB-B: 3101-3201
        if (displayOrder < 3200) return 'LB R4';
        if (displayOrder < 3300) return 'LB R5';
        if (displayOrder < 3400) return 'LB R6';
        if (displayOrder < 3500) return 'LB R7';
        return 'LB R8';
      } else if (displayOrder >= 4000) {
        // Finals: 4101+
        return 'Finals';
      }
    }
    
    return null;
  }
  
  /// Get round category for filtering (WB, LB, Finals)
  static String? getRoundCategory(String? roundName) {
    if (roundName == null) return null;
    
    if (roundName.startsWith('WB') || roundName.contains('- WB')) {
      return 'WB';
    } else if (roundName.startsWith('LB') || roundName.contains('- LB')) {
      return 'LB';
    } else if (roundName.contains('Finals') || 
               roundName.contains('Round of') || 
               roundName.contains('Quarter') ||
               roundName.contains('Semi')) {
      return 'Finals';
    }
    
    return null;
  }
}
