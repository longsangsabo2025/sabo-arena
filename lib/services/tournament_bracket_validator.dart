import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Tournament Bracket Validator Service
/// 
/// Validates that tournament brackets have proper advancement fields populated.
/// This prevents silent failures where matches complete but winners don't advance.
class TournamentBracketValidator {
  final SupabaseClient _supabase;

  TournamentBracketValidator(this._supabase);

  /// Validate advancement fields for a tournament
  /// 
  /// Returns validation result with:
  /// - `isValid`: true if all checks pass
  /// - `message`: description of validation result
  /// - `missingCount`: number of matches missing advancement fields
  Future<Map<String, dynamic>> validateAdvancementFields(
    String tournamentId,
  ) async {
    try {
      // Get all matches for tournament
      final matchesResponse = await _supabase
          .from('matches')
          .select('id, display_order, bracket_type, bracket_group, winner_advances_to, loser_advances_to')
          .eq('tournament_id', tournamentId)
          .order('display_order');

      final matches = matchesResponse as List<dynamic>;

      if (matches.isEmpty) {
        return {
          'isValid': false,
          'message': 'No matches found for tournament',
          'missingCount': 0,
        };
      }

      // Count matches missing advancement fields
      int missingWinner = 0;
      int totalMatches = matches.length;
      int finalMatches = 0; // Matches that shouldn't have advancement (finals)

      for (var match in matches) {
        final displayOrder = match['display_order'] as int;
        final bracketType = match['bracket_type'] as String?;
        final winnerAdvancesTo = match['winner_advances_to'];

        // Check if this is a final match (no winner advancement expected)
        bool isFinal = false;
        
        // SABO DE64: Grand Final
        if (displayOrder == 53101) isFinal = true;
        
        // SABO DE32/DE16: Similar patterns
        if (bracketType == 'GF' || bracketType == 'FINAL') isFinal = true;

        if (isFinal) {
          finalMatches++;
          continue; // Finals don't need advancement
        }

        // Non-final matches should have winner_advances_to
        if (winnerAdvancesTo == null) {
          missingWinner++;
          ProductionLogger.info('⚠️ Match $displayOrder missing winner_advances_to', tag: 'tournament_bracket_validator');
        }

        // Loser advancement is optional (only in double elimination)
        // We don't count this as critical error
      }

      final nonFinalMatches = totalMatches - finalMatches;
      final isValid = missingWinner == 0;
      
      String message;
      if (isValid) {
        message = '✅ All $nonFinalMatches non-final matches have advancement fields';
      } else {
        message = '❌ $missingWinner/$nonFinalMatches matches missing winner_advances_to field';
      }

      return {
        'isValid': isValid,
        'message': message,
        'missingCount': missingWinner,
        'totalMatches': totalMatches,
        'nonFinalMatches': nonFinalMatches,
        'finalMatches': finalMatches,
      };
    } catch (e) {
      return {
        'isValid': false,
        'message': 'Validation error: $e',
        'missingCount': -1,
      };
    }
  }

  /// Repair missing advancement fields for SABO DE64 tournament
  /// 
  /// This will repopulate advancement fields using the hardcoded map
  /// WARNING: Only use this if you're sure the tournament is SABO DE64 format
  Future<Map<String, dynamic>> repairSaboDE64AdvancementFields(
    String tournamentId,
  ) async {
    try {
      // Get advancement map from HardcodedSaboDE64Service
      final advancementMap = _getSaboDE64AdvancementMap();

      // Get all matches
      final matchesResponse = await _supabase
          .from('matches')
          .select('id, display_order')
          .eq('tournament_id', tournamentId);

      final matches = matchesResponse as List<dynamic>;
      int updated = 0;

      for (var match in matches) {
        final matchId = match['id'] as String;
        final displayOrder = match['display_order'] as int;

        // Get advancement info from map
        final advancement = advancementMap[displayOrder];
        if (advancement != null) {
          await _supabase.from('matches').update({
            'winner_advances_to': advancement['winner'],
            'loser_advances_to': advancement['loser'],
          }).eq('id', matchId);

          updated++;
        }
      }

      return {
        'success': true,
        'message': 'Updated $updated matches with advancement fields',
        'updatedCount': updated,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get SABO DE64 advancement map (NEW STRUCTURE - 21 matches/group, NO WB-R4)
  /// Synced with HardcodedSaboDE64Service - Updated with correct Cross R16 seeding
  Map<int, Map<String, dynamic>> _getSaboDE64AdvancementMap() {
    final map = <int, Map<String, dynamic>>{};

    // ========================================
    // GROUP A ADVANCEMENT (21 matches)
    // ========================================
    
    // Group A - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[11101] = {'winner': 11201, 'loser': 12101};
    map[11102] = {'winner': 11201, 'loser': 12101};
    map[11103] = {'winner': 11202, 'loser': 12102};
    map[11104] = {'winner': 11202, 'loser': 12102};
    map[11105] = {'winner': 11203, 'loser': 12103};
    map[11106] = {'winner': 11203, 'loser': 12103};
    map[11107] = {'winner': 11204, 'loser': 12104};
    map[11108] = {'winner': 11204, 'loser': 12104};

    // Group A - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[11201] = {'winner': 11301, 'loser': 13101};
    map[11202] = {'winner': 11301, 'loser': 13101};
    map[11203] = {'winner': 11302, 'loser': 13102};
    map[11204] = {'winner': 11302, 'loser': 13102};

    // Group A - WB R3 (2 matches - Group Finals): winners qualify for Cross R16
    map[11301] = {'winner': 51101, 'loser': null}; // A1 (WB #1) vs B4 at R16-1
    map[11302] = {'winner': 51102, 'loser': null}; // A2 (WB #2) vs C3 at R16-2

    // Group A - LB-A R1 (4 matches): winner to LB-A R2
    map[12101] = {'winner': 12201, 'loser': null};
    map[12102] = {'winner': 12201, 'loser': null};
    map[12103] = {'winner': 12202, 'loser': null};
    map[12104] = {'winner': 12202, 'loser': null};

    // Group A - LB-A R2 (2 matches): winner to LB-A R3
    map[12201] = {'winner': 12301, 'loser': null};
    map[12202] = {'winner': 12301, 'loser': null};

    // Group A - LB-A R3 (1 match): winner qualifies for Cross R16
    map[12301] = {'winner': 51106, 'loser': null}; // A3 (LB-A) vs C2 at R16-6

    // Group A - LB-B R1 (2 matches): winner to LB-B R2
    map[13101] = {'winner': 13201, 'loser': null};
    map[13102] = {'winner': 13201, 'loser': null};

    // Group A - LB-B R2 (1 match - LB-B Final): winner qualifies for Cross R16
    map[13201] = {'winner': 51103, 'loser': null}; // A4 (LB-B) vs B1 at R16-3

    // ========================================
    // GROUP B ADVANCEMENT (21 matches)
    // ========================================
    
    // Group B - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[21101] = {'winner': 21201, 'loser': 22101};
    map[21102] = {'winner': 21201, 'loser': 22101};
    map[21103] = {'winner': 21202, 'loser': 22102};
    map[21104] = {'winner': 21202, 'loser': 22102};
    map[21105] = {'winner': 21203, 'loser': 22103};
    map[21106] = {'winner': 21203, 'loser': 22103};
    map[21107] = {'winner': 21204, 'loser': 22104};
    map[21108] = {'winner': 21204, 'loser': 22104};

    // Group B - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[21201] = {'winner': 21301, 'loser': 23101};
    map[21202] = {'winner': 21301, 'loser': 23101};
    map[21203] = {'winner': 21302, 'loser': 23102};
    map[21204] = {'winner': 21302, 'loser': 23102};

    // Group B - WB R3 (2 matches - Group Finals): winners qualify for Cross R16
    map[21301] = {'winner': 51103, 'loser': null}; // B1 (WB #1) vs A4 at R16-3
    map[21302] = {'winner': 51104, 'loser': null}; // B2 (WB #2) vs D3 at R16-4

    // Group B - LB-A R1 (4 matches): winner to LB-A R2
    map[22101] = {'winner': 22201, 'loser': null};
    map[22102] = {'winner': 22201, 'loser': null};
    map[22103] = {'winner': 22202, 'loser': null};
    map[22104] = {'winner': 22202, 'loser': null};

    // Group B - LB-A R2 (2 matches): winner to LB-A R3
    map[22201] = {'winner': 22301, 'loser': null};
    map[22202] = {'winner': 22301, 'loser': null};

    // Group B - LB-A R3 (1 match): winner qualifies for Cross R16
    map[22301] = {'winner': 51108, 'loser': null}; // B3 (LB-A) vs D2 at R16-8

    // Group B - LB-B R1 (2 matches): winner to LB-B R2
    map[23101] = {'winner': 23201, 'loser': null};
    map[23102] = {'winner': 23201, 'loser': null};

    // Group B - LB-B R2 (1 match - LB-B Final): winner qualifies for Cross R16
    map[23201] = {'winner': 51101, 'loser': null}; // B4 (LB-B) vs A1 at R16-1

    // ========================================
    // GROUP C ADVANCEMENT (21 matches)
    // ========================================
    
    // Group C - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[31101] = {'winner': 31201, 'loser': 32101};
    map[31102] = {'winner': 31201, 'loser': 32101};
    map[31103] = {'winner': 31202, 'loser': 32102};
    map[31104] = {'winner': 31202, 'loser': 32102};
    map[31105] = {'winner': 31203, 'loser': 32103};
    map[31106] = {'winner': 31203, 'loser': 32103};
    map[31107] = {'winner': 31204, 'loser': 32104};
    map[31108] = {'winner': 31204, 'loser': 32104};

    // Group C - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[31201] = {'winner': 31301, 'loser': 33101};
    map[31202] = {'winner': 31301, 'loser': 33101};
    map[31203] = {'winner': 31302, 'loser': 33102};
    map[31204] = {'winner': 31302, 'loser': 33102};

    // Group C - WB R3 (2 matches - Group Finals): winners qualify for Cross R16
    map[31301] = {'winner': 51105, 'loser': null}; // C1 (WB #1) vs D4 at R16-5
    map[31302] = {'winner': 51106, 'loser': null}; // C2 (WB #2) vs A3 at R16-6

    // Group C - LB-A R1 (4 matches): winner to LB-A R2
    map[32101] = {'winner': 32201, 'loser': null};
    map[32102] = {'winner': 32201, 'loser': null};
    map[32103] = {'winner': 32202, 'loser': null};
    map[32104] = {'winner': 32202, 'loser': null};

    // Group C - LB-A R2 (2 matches): winner to LB-A R3
    map[32201] = {'winner': 32301, 'loser': null};
    map[32202] = {'winner': 32301, 'loser': null};

    // Group C - LB-A R3 (1 match): winner qualifies for Cross R16
    map[32301] = {'winner': 51102, 'loser': null}; // C3 (LB-A) vs A2 at R16-2

    // Group C - LB-B R1 (2 matches): winner to LB-B R2
    map[33101] = {'winner': 33201, 'loser': null};
    map[33102] = {'winner': 33201, 'loser': null};

    // Group C - LB-B R2 (1 match - LB-B Final): winner qualifies for Cross R16
    map[33201] = {'winner': 51107, 'loser': null}; // C4 (LB-B) vs D1 at R16-7

    // ========================================
    // GROUP D ADVANCEMENT (21 matches)
    // ========================================
    
    // Group D - WB R1 (8 matches): winner to WB R2, loser to LB-A R1
    map[41101] = {'winner': 41201, 'loser': 42101};
    map[41102] = {'winner': 41201, 'loser': 42101};
    map[41103] = {'winner': 41202, 'loser': 42102};
    map[41104] = {'winner': 41202, 'loser': 42102};
    map[41105] = {'winner': 41203, 'loser': 42103};
    map[41106] = {'winner': 41203, 'loser': 42103};
    map[41107] = {'winner': 41204, 'loser': 42104};
    map[41108] = {'winner': 41204, 'loser': 42104};

    // Group D - WB R2 (4 matches): winner to WB R3, loser to LB-B R1
    map[41201] = {'winner': 41301, 'loser': 43101};
    map[41202] = {'winner': 41301, 'loser': 43101};
    map[41203] = {'winner': 41302, 'loser': 43102};
    map[41204] = {'winner': 41302, 'loser': 43102};

    // Group D - WB R3 (2 matches - Group Finals): winners qualify for Cross R16
    map[41301] = {'winner': 51107, 'loser': null}; // D1 (WB #1) vs C4 at R16-7
    map[41302] = {'winner': 51108, 'loser': null}; // D2 (WB #2) vs B3 at R16-8

    // Group D - LB-A R1 (4 matches): winner to LB-A R2
    map[42101] = {'winner': 42201, 'loser': null};
    map[42102] = {'winner': 42201, 'loser': null};
    map[42103] = {'winner': 42202, 'loser': null};
    map[42104] = {'winner': 42202, 'loser': null};

    // Group D - LB-A R2 (2 matches): winner to LB-A R3
    map[42201] = {'winner': 42301, 'loser': null};
    map[42202] = {'winner': 42301, 'loser': null};

    // Group D - LB-A R3 (1 match): winner qualifies for Cross R16
    map[42301] = {'winner': 51104, 'loser': null}; // D3 (LB-A) vs B2 at R16-4

    // Group D - LB-B R1 (2 matches): winner to LB-B R2
    map[43101] = {'winner': 43201, 'loser': null};
    map[43102] = {'winner': 43201, 'loser': null};

    // Group D - LB-B R2 (1 match - LB-B Final): winner qualifies for Cross R16
    map[43201] = {'winner': 51105, 'loser': null}; // D4 (LB-B) vs C1 at R16-5

    // ========================================
    // CROSS-BRACKET FINALS ADVANCEMENT (15 matches: R16→QF→SF→GF)
    // ========================================

    // Cross Round of 16 (8 matches): winner to Quarter-Finals
    map[51101] = {'winner': 52101, 'loser': null}; // R16-1 → QF1
    map[51102] = {'winner': 52101, 'loser': null}; // R16-2 → QF1
    map[51103] = {'winner': 52102, 'loser': null}; // R16-3 → QF2
    map[51104] = {'winner': 52102, 'loser': null}; // R16-4 → QF2
    map[51105] = {'winner': 52103, 'loser': null}; // R16-5 → QF3
    map[51106] = {'winner': 52103, 'loser': null}; // R16-6 → QF3
    map[51107] = {'winner': 52104, 'loser': null}; // R16-7 → QF4
    map[51108] = {'winner': 52104, 'loser': null}; // R16-8 → QF4

    // Cross Quarter-Finals (4 matches): winner to Semi-Finals
    map[52101] = {'winner': 53101, 'loser': null}; // QF1 → SF1
    map[52102] = {'winner': 53101, 'loser': null}; // QF2 → SF1
    map[52103] = {'winner': 53102, 'loser': null}; // QF3 → SF2
    map[52104] = {'winner': 53102, 'loser': null}; // QF4 → SF2

    // Cross Semi-Finals (2 matches): winner to Grand Final
    map[53101] = {'winner': 54101, 'loser': null}; // SF1 → GF
    map[53102] = {'winner': 54101, 'loser': null}; // SF2 → GF

    // Grand Final (1 match): winner is champion, no advancement
    map[54101] = {'winner': null, 'loser': null}; // Champion!

    return map;
  }
}
