import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'location_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to find and match opponents based on location and rank
class OpponentMatchingService {
  static OpponentMatchingService? _instance;
  static OpponentMatchingService get instance =>
      _instance ??= OpponentMatchingService._();
  OpponentMatchingService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocationService _locationService = LocationService.instance;

  /// Get all available opponents, prioritizing nearby and similar rank
  Future<List<UserProfile>> findMatchedOpponents({
    double radiusKm = 500.0, // Increased default radius for better results
    String? rankFilter,
    int limit = 20,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }


      // Get current user's location with permission check (fail safe)
      double? currentLat;
      double? currentLon;
      try {
        final position = await _locationService.getCurrentPosition();
        currentLat = position.latitude;
        currentLon = position.longitude;
      } catch (e) {
        ProductionLogger.warning('⚠️ Could not get location for matching: $e', tag: 'opponent_matching');
        // Continue without location
      }

      // Get current user's rank for matching
      final currentUserProfile = await _supabase
          .from('users')
          .select('rank, elo_rating')
          .eq('id', currentUser.id)
          .single();

      final currentRank = currentUserProfile['rank'] as String?;
      final currentElo = currentUserProfile['elo_rating'] as int? ?? 1000;


      // Fetch all users except current user
      final response = await _supabase
          .from('users')
          .select('''
            id,
            email,
            full_name,
            display_name,
            username,
            avatar_url,
            role,
            skill_level,
            rank,
            elo_rating,
            total_wins,
            total_losses,
            total_tournaments,
            spa_points,
            total_prize_pool,
            is_verified,
            is_active,
            created_at,
            updated_at,
            latitude,
            longitude,
            location_name
          ''')
          .neq('id', currentUser.id)
          // .eq('is_active', true) // Commented out for testing visibility
          .order('elo_rating', ascending: false)
          .limit(limit * 2); // Query more for filtering

      final users = List<Map<String, dynamic>>.from(response);

      // Calculate distance and rank similarity for each user
      final List<Map<String, dynamic>> scoredUsers = [];

      for (final user in users) {
        final userLat = user['latitude'] as double?;
        final userLon = user['longitude'] as double?;
        final userElo = user['elo_rating'] as int? ?? 1000;
        final userRank = user['rank'] as String?;

        // Calculate distance (if location available)
        double? distance;
        if (userLat != null && userLon != null && currentLat != null && currentLon != null) {
          distance = _calculateDistance(
            currentLat,
            currentLon,
            userLat,
            userLon,
          );
        }

        // Calculate ELO difference (smaller is better)
        final eloDiff = (currentElo - userElo).abs();

        // Calculate rank similarity score (0-100)
        final rankScore = _calculateRankSimilarity(currentRank, userRank);

        // Calculate distance score (0-100, closer is better)
        final distanceScore = distance != null && distance <= radiusKm
            ? (100 * (1 - (distance / radiusKm))).clamp(0, 100)
            : 0.0;

        // Calculate total match score
        // Weight: 50% rank similarity, 30% distance, 20% activity
        final matchScore =
            (rankScore * 0.5) +
            (distanceScore * 0.3) +
            (20.0); // Base activity score

        scoredUsers.add({
          ...user,
          'distance_km': distance,
          'elo_diff': eloDiff,
          'rank_score': rankScore,
          'distance_score': distanceScore,
          'match_score': matchScore,
        });
      }

      // Sort by match score (highest first)
      scoredUsers.sort(
        (a, b) =>
            (b['match_score'] as double).compareTo(a['match_score'] as double),
      );

      // Apply rank filter if specified
      List<Map<String, dynamic>> filteredUsers = scoredUsers;
      if (rankFilter != null && rankFilter != 'all') {
        filteredUsers = scoredUsers
            .where((user) => user['rank'] == rankFilter)
            .toList();
      }

      // Convert to UserProfile objects
      final opponents = filteredUsers.map((userData) {
        return UserProfile(
          id: userData['id'] as String,
          email: userData['email'] as String? ?? '',
          fullName:
              userData['display_name'] as String? ?? userData['full_name'] as String? ??
              'Unknown',
          displayName:
              userData['display_name'] as String? ?? userData['full_name'] as String? ??
              'Unknown',
          username:
              userData['username'] as String? ??
              'unknown',
          avatarUrl: userData['avatar_url'] as String?,
          role: userData['role'] as String? ?? 'player',
          skillLevel: userData['skill_level'] as String? ?? 'beginner',
          rank: userData['rank'] as String? ?? 'Unranked',
          eloRating: userData['elo_rating'] as int? ?? 1000,
          totalWins: userData['total_wins'] as int? ?? 0,
          totalLosses: userData['total_losses'] as int? ?? 0,
          totalTournaments: userData['total_tournaments'] as int? ?? 0,
          spaPoints: userData['spa_points'] as int? ?? 0,
          totalPrizePool:
              (userData['total_prize_pool'] as num?)?.toDouble() ?? 0.0,
          isVerified: userData['is_verified'] as bool? ?? false,
          isActive: userData['is_active'] as bool? ?? true,
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'] as String)
              : DateTime.now(),
          updatedAt: userData['updated_at'] != null
              ? DateTime.parse(userData['updated_at'] as String)
              : DateTime.now(),
        );
      }).toList();

      // Return limited results with distance info
      final limitedOpponents = opponents.take(limit).toList();
      
      ProductionLogger.info(
        '⚙️ Found ${opponents.length} potential opponents, returning ${limitedOpponents.length}',
        tag: 'opponent_matching'
      );
      
      return limitedOpponents;
    } catch (e) {
      ProductionLogger.error('❌ Opponent matching failed: $e', tag: 'opponent_matching');
      rethrow;
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Calculate rank similarity score (0-100)
  /// Uses Vietnamese billiards rank system: K, K+, I, I+, H, H+, G, G+, F, F+, E, D, C
  double _calculateRankSimilarity(String? rank1, String? rank2) {
    if (rank1 == null || rank2 == null) return 0.0;
    if (rank1 == rank2) return 100.0;

    // Define rank hierarchy - Vietnamese billiards system
    final ranks = [
      'K', // Tập Sự (1000-1099)
      'K+', // Tập Sự+ (1100-1199)
      'I', // Sơ Cấp (1200-1299)
      'I+', // Sơ Cấp+ (1300-1399)
      'H', // Trung Cấp (1400-1499)
      'H+', // Trung Cấp+ (1500-1599)
      'G', // Khá (1600-1699)
      'G+', // Khá+ (1700-1799)
      'F', // Giỏi (1800-1899)
      'F+', // Giỏi+ (1900-1999)
      'E', // Xuất Sắc (1900-1999)
      'D', // Huyền Thoại (2000-2099)
      'C', // Vô Địch (2100-2199)
    ];

    final index1 = ranks.indexOf(rank1);
    final index2 = ranks.indexOf(rank2);

    if (index1 == -1 || index2 == -1) return 30.0; // Unranked penalty

    final diff = (index1 - index2).abs();

    // Closer ranks = higher score
    // SABO rule: Maximum rank difference allowed is 2 sub-ranks (±1 main rank)
    if (diff == 0) return 100.0; // Same rank
    if (diff == 1) return 90.0; // Adjacent sub-rank (K vs K+)
    if (diff == 2) return 75.0; // 1 main rank (K vs I) - max allowed
    if (diff <= 4) return 40.0; // Beyond limit (was allowed before v1.2)
    if (diff <= 6) return 20.0; // Too far
    return 5.0; // Way too far apart
  }

  /// Get rank options for filter
  List<String> getRankOptions() {
    return [
      'all',
      'K', // Tập Sự
      'K+', // Tập Sự+
      'I', // Sơ Cấp
      'I+', // Sơ Cấp+
      'H', // Trung Cấp
      'H+', // Trung Cấp+
      'G', // Khá
      'G+', // Khá+
      'F', // Giỏi
      'F+', // Giỏi+
      'E', // Xuất Sắc
      'D', // Huyền Thoại
      'C', // Vô Địch
    ];
  }

  /// Get rank display name (Vietnamese)
  String getRankDisplayName(String rank) {
    final displayNames = {
      'K': 'Tập Sự',
      'K+': 'Tập Sự+',
      'I': 'Sơ Cấp',
      'I+': 'Sơ Cấp+',
      'H': 'Trung Cấp',
      'H+': 'Trung Cấp+',
      'G': 'Khá',
      'G+': 'Khá+',
      'F': 'Giỏi',
      'F+': 'Giỏi+',
      'E': 'Xuất Sắc',
      'D': 'Huyền Thoại',
      'C': 'Vô Địch',
    };
    return displayNames[rank] ?? rank;
  }

  /// Find nearby opponents within specific radius and rank range
  Future<List<UserProfile>> findNearbyOpponents({
    required double radiusKm,
    String? rankFilter,
    bool verifiedOnly = false,
    bool availableForChallenges = false,
  }) async {
    final allOpponents = await findMatchedOpponents(
      radiusKm: radiusKm,
      rankFilter: rankFilter,
    );

    // Apply additional filters
    var filtered = allOpponents;

    if (verifiedOnly) {
      filtered = filtered.where((user) => user.isVerified).toList();
    }

    // Filter by distance (only show users within radius)
    // Note: This requires location data to be available

    return filtered;
  }

  /// Get challenge-eligible opponents (verified, active, within rank range)
  Future<List<UserProfile>> getChallengeEligibleOpponents({
    double radiusKm = 50.0,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return [];

    // Get current user's rank
    final currentUserData = await _supabase
        .from('users')
        .select('rank, elo_rating')
        .eq('id', currentUser.id)
        .single();

    final currentRank = currentUserData['rank'] as String?;

    // Get all verified opponents
    final opponents = await findMatchedOpponents(
      radiusKm: radiusKm,
      rankFilter: null, // Get all ranks first
    );

    // Filter: verified only, within rank range (±4 sub-ranks)
    final eligible = opponents.where((opponent) {
      if (!opponent.isVerified) return false;
      if (opponent.rank == null || currentRank == null) return false;

      final rankScore = _calculateRankSimilarity(currentRank, opponent.rank);
      return rankScore >= 45.0; // At least within 2 main ranks
    }).toList();

    return eligible;
  }
}

