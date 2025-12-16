import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service for handling rank registration
/// Users start with NULL rank/elo, then register for a rank
class RankRegistrationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if user has registered a rank
  Future<bool> hasRank(String userId) async {
    try {
      final response = await _supabase.rpc(
        'user_has_rank',
        params: {'user_id': userId},
      );
      return response as bool? ?? false;
    } catch (e) {
      ProductionLogger.info('Error checking rank: $e', tag: 'rank_registration_service');
      return false;
    }
  }

  /// Get user's current rank and ELO
  Future<Map<String, dynamic>?> getUserRankInfo(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('rank, elo_rating')
          .eq('id', userId)
          .single();

      return {
        'rank': response['rank'],
        'elo_rating': response['elo_rating'],
        'has_rank': response['rank'] != null && response['elo_rating'] != null,
      };
    } catch (e) {
      ProductionLogger.info('Error getting rank info: $e', tag: 'rank_registration_service');
      return null;
    }
  }

  /// Assign rank to user after successful registration
  ///
  /// Available ranks and their initial ELO:
  /// - Bronze: 1200
  /// - Silver: 1400
  /// - Gold: 1600
  /// - Platinum: 1800
  /// - Diamond: 2000
  /// - Master: 2200
  /// - Grandmaster: 2400
  Future<Map<String, dynamic>?> assignRank(String userId, String rank) async {
    try {
      final response = await _supabase.rpc(
        'assign_rank_to_user',
        params: {'user_id': userId, 'assigned_rank': rank},
      );

      return response as Map<String, dynamic>?;
    } catch (e) {
      ProductionLogger.info('Error assigning rank: $e', tag: 'rank_registration_service');
      return null;
    }
  }

  /// Get initial ELO for a rank
  int getInitialEloForRank(String rank) {
    switch (rank) {
      case 'Bronze':
        return 1200;
      case 'Silver':
        return 1400;
      case 'Gold':
        return 1600;
      case 'Platinum':
        return 1800;
      case 'Diamond':
        return 2000;
      case 'Master':
        return 2200;
      case 'Grandmaster':
        return 2400;
      default:
        return 1200; // Default to Bronze
    }
  }

  /// Get all available ranks
  List<Map<String, dynamic>> getAvailableRanks() {
    return [
      {'name': 'Bronze', 'initial_elo': 1200, 'description': 'Beginner'},
      {'name': 'Silver', 'initial_elo': 1400, 'description': 'Intermediate'},
      {'name': 'Gold', 'initial_elo': 1600, 'description': 'Advanced'},
      {'name': 'Platinum', 'initial_elo': 1800, 'description': 'Expert'},
      {'name': 'Diamond', 'initial_elo': 2000, 'description': 'Master'},
      {'name': 'Master', 'initial_elo': 2200, 'description': 'Grand Master'},
      {'name': 'Grandmaster', 'initial_elo': 2400, 'description': 'Legend'},
    ];
  }

  /// Check if user needs to register rank (for onboarding flow)
  Future<bool> needsRankRegistration(String userId) async {
    final hasRankResult = await hasRank(userId);
    return !hasRankResult;
  }
}
