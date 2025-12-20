import 'package:supabase_flutter/supabase_flutter.dart';
// ELON_MODE_AUTO_FIX

/// Service for managing first match bonus system
/// Awards 100 SPA to users on their first completed challenge match in a club
class FirstMatchBonusService {
  final SupabaseClient _supabase;

  FirstMatchBonusService(this._supabase);

  /// Check if user is eligible for first match bonus
  /// Returns eligibility status and bonus details
  Future<Map<String, dynamic>> checkEligibility(
    String userId,
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('user_first_match_tracking')
          .select()
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .maybeSingle();

      if (response == null) {
        return {
          'is_eligible': true,
          'is_first_match': true,
          'bonus_amount': 100.0,
          'message': 'Eligible for first match bonus',
        };
      }

      final bonusAwarded = response['bonus_awarded'] as bool? ?? false;
      final bonusAmount = response['bonus_amount'] as num? ?? 100.0;

      return {
        'is_eligible': !bonusAwarded,
        'is_first_match': false,
        'bonus_amount': bonusAmount,
        'bonus_awarded': bonusAwarded,
        'awarded_at': response['awarded_at'],
        'first_match_id': response['first_match_id'],
        'message': bonusAwarded
            ? 'Bonus already awarded'
            : 'Eligible but bonus not yet awarded',
      };
    } catch (e) {
      return {
        'is_eligible': false,
        'error': e.toString(),
        'message': 'Error checking eligibility',
      };
    }
  }

  /// Award first match bonus to user
  /// Called after match completion
  Future<Map<String, dynamic>> awardFirstMatchBonus(
    String userId,
    String clubId,
    String matchId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'check_and_award_first_match_bonus',
        params: {
          'p_user_id': userId,
          'p_club_id': clubId,
          'p_match_id': matchId,
        },
      );

      if (response == null) {
        return {
          'success': false,
          'message': 'No response from server',
        };
      }

      final result = Map<String, dynamic>.from(response as Map);
      final success = result['success'] as bool? ?? false;

      if (success) {
        // Bonus awarded successfully
      } else {
        if (result['is_first_match'] == true) {
        } else {}
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error awarding bonus: $e',
      };
    }
  }

  /// Award bonus for both players in a match
  /// Returns results for both players
  Future<Map<String, Map<String, dynamic>>> awardBonusForBothPlayers(
    String player1Id,
    String player2Id,
    String clubId,
    String matchId,
  ) async {
    final player1Result = await awardFirstMatchBonus(
      player1Id,
      clubId,
      matchId,
    );

    final player2Result = await awardFirstMatchBonus(
      player2Id,
      clubId,
      matchId,
    );

    return {
      'player1': player1Result,
      'player2': player2Result,
    };
  }

  /// Get first match history for user in a club
  /// Returns tracking record with match and club details
  Future<Map<String, dynamic>?> getFirstMatchHistory(
    String userId,
    String clubId,
  ) async {
    try {
      final response = await _supabase
          .from('user_first_match_tracking')
          .select('*, matches(*), clubs(name)')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .maybeSingle();

      if (response != null) {
      } else {}

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get all first match bonuses awarded to user (across all clubs)
  Future<List<Map<String, dynamic>>> getUserFirstMatchBonuses(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('user_first_match_tracking')
          .select('*, clubs(name)')
          .eq('user_id', userId)
          .eq('bonus_awarded', true)
          .order('awarded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get first match bonus statistics for a club (Admin only)
  Future<Map<String, dynamic>?> getClubStats(String clubId) async {
    try {
      final response = await _supabase
          .from('first_match_bonus_stats')
          .select()
          .eq('club_id', clubId)
          .maybeSingle();

      if (response != null) {
      } else {}

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get all club statistics (Super Admin only)
  Future<List<Map<String, dynamic>>> getAllClubsStats() async {
    try {
      final response = await _supabase
          .from('first_match_bonus_stats')
          .select()
          .order('total_bonus_paid', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
