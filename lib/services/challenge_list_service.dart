import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to fetch and manage challenge lists
class ChallengeListService {
  static ChallengeListService? _instance;
  static ChallengeListService get instance =>
      _instance ??= ChallengeListService._();
  ChallengeListService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all OPEN competitive challenges (Thách đấu công khai)
  Future<List<Map<String, dynamic>>> getOpenCompetitiveChallenges() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final currentUser = _supabase.auth.currentUser;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get challenges where:
      // - OPEN challenges (challenged_id = null) - Ai cũng thấy
      // - OR challenges created by current user (challenger_id = user.id) - Bạn tạo
      // - OR challenges sent to current user (challenged_id = user.id) - Gửi cho bạn
      // - challenge_type = 'thach_dau'
      // - status = 'pending'

      List<Map<String, dynamic>> allChallenges = [];

      // 1. Get OPEN challenges (challenged_id = null)
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      final openChallengesRaw = await _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!fk_challenges_challenger_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating,
              total_wins,
              total_losses
            ),
            club:clubs(
              id,
              name,
              address,
              logo_url
            )
          ''')
          .filter('challenged_id', 'is', null)
          .eq('challenge_type', 'thach_dau')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Filter: KHÔNG hiển thị challenge của chính mình
      final openChallenges = currentUser != null
          ? openChallengesRaw
                .where(
                  (challenge) => challenge['challenger_id'] != currentUser.id,
                )
                .toList()
          : List<Map<String, dynamic>>.from(openChallengesRaw);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (openChallenges.isNotEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      allChallenges.addAll(List<Map<String, dynamic>>.from(openChallenges));

      // 2. Get challenges SENT TO current user
      // ✅ NEW: Check match_conditions.target_user_id since challenged_id is null until accepted
      if (currentUser != null) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        
        // Get all pending challenges and filter by target_user_id in match_conditions
        final allPendingChallenges = await _supabase
            .from('challenges')
            .select('''
              *,
              challenger:users!fk_challenges_challenger_id(
                id,
                display_name,
                avatar_url,
                rank,
                elo_rating,
                total_wins,
                total_losses
              ),
              club:clubs(
                id,
                name,
                address,
                logo_url
              )
            ''')
            .eq('challenge_type', 'thach_dau')
            .eq('status', 'pending')
            .order('created_at', ascending: false);

        // Filter: Challenges where match_conditions.target_user_id = current user
        final sentToMe = allPendingChallenges.where((challenge) {
          final matchConditions = challenge['match_conditions'];
          if (matchConditions is Map) {
            final targetUserId = matchConditions['target_user_id'];
            return targetUserId == currentUser.id;
          }
          return false;
        }).toList();

        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        // Add challenges not already in list (avoid duplicates)
        for (var challenge in sentToMe) {
          if (!allChallenges.any((c) => c['id'] == challenge['id'])) {
            allChallenges.add(Map<String, dynamic>.from(challenge));
          }
        }
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      // Sort by created_at descending
      allChallenges.sort((a, b) {
        final aDate = DateTime.parse(a['created_at'] ?? '2000-01-01');
        final bDate = DateTime.parse(b['created_at'] ?? '2000-01-01');
        return bDate.compareTo(aDate);
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (allChallenges.isEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        for (
          int i = 0;
          i < (allChallenges.length > 3 ? 3 : allChallenges.length);
          i++
        ) {
          // Variable c removed - was only used in debug log
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }

      return allChallenges;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Get all OPEN social invites (Giao lưu công khai)
  Future<List<Map<String, dynamic>>> getOpenSocialInvites() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final currentUser = _supabase.auth.currentUser;

      // Get challenges where:
      // - OPEN invites (challenged_id = null) - Ai cũng thấy
      // - OR invites created by current user (challenger_id = user.id) - Bạn tạo
      // - OR invites sent to current user (challenged_id = user.id) - Gửi cho bạn
      // - challenge_type = 'giao_luu'
      // - status = 'pending' OR 'accepted' (show both waiting and matched)

      List<Map<String, dynamic>> allInvites = [];

      // 1. Get OPEN invites (challenged_id = null) - pending only
      final openInvitesRaw = await _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!fk_challenges_challenger_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating,
              total_wins,
              total_losses
            ),
            club:clubs(
              id,
              name,
              address,
              logo_url
            )
          ''')
          .filter('challenged_id', 'is', null)
          .eq('challenge_type', 'giao_luu')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Filter: KHÔNG hiển thị invite của chính mình
      final openInvites = currentUser != null
          ? openInvitesRaw
                .where((invite) => invite['challenger_id'] != currentUser.id)
                .toList()
          : List<Map<String, dynamic>>.from(openInvitesRaw);

      allInvites.addAll(List<Map<String, dynamic>>.from(openInvites));

      // 2. Get invites SENT TO current user
      // ✅ NEW: Check match_conditions.target_user_id since challenged_id is null until accepted
      if (currentUser != null) {
        // Get all pending invites and filter by target_user_id in match_conditions
        final allPendingInvites = await _supabase
            .from('challenges')
            .select('''
              *,
              challenger:users!fk_challenges_challenger_id(
                id,
                display_name,
                avatar_url,
                rank,
                elo_rating,
                total_wins,
                total_losses
              ),
              club:clubs(
                id,
                name,
                address,
                logo_url
              )
            ''')
            .eq('challenge_type', 'giao_luu')
            .eq('status', 'pending')
            .order('created_at', ascending: false);

        // Filter: Invites where match_conditions.target_user_id = current user
        final sentToMe = allPendingInvites.where((invite) {
          final matchConditions = invite['match_conditions'];
          if (matchConditions is Map) {
            final targetUserId = matchConditions['target_user_id'];
            return targetUserId == currentUser.id;
          }
          return false;
        }).toList();

        // Add invites not already in list (avoid duplicates)
        for (var invite in sentToMe) {
          if (!allInvites.any((c) => c['id'] == invite['id'])) {
            allInvites.add(Map<String, dynamic>.from(invite));
          }
        }
      }

      // NOTE: KHÔNG lấy accepted matches ở đây nữa
      // Accepted matches nên có method riêng: getAcceptedSocialMatches()
      // để UI có thể hiển thị ở section riêng (community activity)

      // Sort by created_at descending
      allInvites.sort((a, b) {
        final aDate = DateTime.parse(a['created_at'] ?? '2000-01-01');
        final bDate = DateTime.parse(b['created_at'] ?? '2000-01-01');
        return bDate.compareTo(aDate);
      });

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return allInvites;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Get all ACCEPTED matches for Community tab (Cộng đồng)
  /// Hiển thị TẤT CẢ các trận đã có đủ 2 người để cộng đồng theo dõi
  Future<List<Map<String, dynamic>>> getAcceptedMatches() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Get ALL challenges where:
      // - status IN ('accepted', 'in_progress', 'completed') - Lấy tất cả trận đã bắt đầu
      // - challenged_id IS NOT NULL (đảm bảo có người chấp nhận)
      // - Hiển thị cho cả cộng đồng theo dõi
      // TEMPORARY: Removed match join due to PostgREST schema cache not yet recognizing challenge_id FK
      // Will be re-added once cache refreshes (5-10 minutes)
      final response = await _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!fk_challenges_challenger_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating,
              total_wins,
              total_losses
            ),
            club:clubs(
              id,
              name,
              address,
              logo_url
            ),
            challenged:users!fk_challenges_challenged_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating,
              total_wins,
              total_losses
            )
          ''')
          .inFilter('status', ['accepted', 'in_progress', 'completed']) // Include all matched statuses
          .not('challenged_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(50); // Giới hạn 50 trận gần nhất để tránh quá tải

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // WORKAROUND: Fetch matches separately since schema cache hasn't recognized FK yet
      final challengeIds = response.map((c) => c['id'] as String).toList();
      
      Map<String, dynamic> matchesMap = {};
      
      if (challengeIds.isNotEmpty) {
        try {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          final matchesResponse = await _supabase
              .from('matches')
              .select('id, challenge_id, status, is_live, video_urls, player1_score, player2_score, winner_id, scheduled_time')
              .inFilter('challenge_id', challengeIds);
          
          // Build map of challenge_id -> match
          for (var match in matchesResponse) {
            final challengeId = match['challenge_id'];
            if (challengeId != null) {
              matchesMap[challengeId] = match;
            }
          }
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }

      // Merge match data into challenges
      final challenges = List<Map<String, dynamic>>.from(response);
      for (var challenge in challenges) {
        final challengeId = challenge['id'];
        if (matchesMap.containsKey(challengeId)) {
          challenge['match'] = matchesMap[challengeId];
        }
      }

      return challenges;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Accept a challenge
  Future<void> acceptChallenge(String challengeId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // First check if challenge exists and get its current state
      final existingChallenges = await _supabase
          .from('challenges')
          .select()
          .eq('id', challengeId);

      if (existingChallenges.isEmpty) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        throw Exception('Thách đấu không tồn tại hoặc đã bị xóa');
      }

      final existingChallenge = existingChallenges.first;
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Check if already accepted
      if (existingChallenge['status'] == 'accepted') {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        throw Exception('Thách đấu này đã được chấp nhận rồi');
      }

      // Update BOTH challenged_id AND status in one atomic operation
      // This ensures:
      // 1. Match has 2 users (challenger + challenged)
      // 2. Status is 'accepted' -> immediately visible in Community tab
      // DO NOT use .select() after update - it causes 406 error when RLS prevents reading
      await _supabase
          .from('challenges')
          .update({
            'challenged_id': currentUser.id, // Set the second player
            'status': 'accepted', // Mark as accepted
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', challengeId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Send notification to challenger that their challenge was accepted
      try {
        final challenge = await _supabase
            .from('challenges')
            .select('''
              id,
              challenger_id,
              challenge_type,
              challenger:users!fk_challenges_challenger_id(display_name),
              challenged:users!fk_challenges_challenged_id(display_name)
            ''')
            .eq('id', challengeId)
            .single();

        final challengedName = challenge['challenged']?['display_name'] ?? 'Người chơi';
        
        await NotificationService.instance.sendNotification(
          userId: challenge['challenger_id'],
          title: 'Thách đấu được chấp nhận! ⚔️',
          message: '$challengedName đã chấp nhận thách đấu của bạn. Hãy chuẩn bị cho trận đấu!',
          type: 'challenge_accepted',
          data: {'challenge_id': challengeId},
        );

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } catch (notifError) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        // Don't throw - acceptance was successful even if notification fails
      }

      // Try to verify by reading the challenge again (optional - may fail due to RLS)
      try {
        final updatedChallenges = await _supabase
            .from('challenges')
            .select()
            .eq('id', challengeId);

        if (updatedChallenges.isNotEmpty) {
          final updated = updatedChallenges.first;
          ProductionLogger.debug('Debug log', tag: 'AutoFix');

          if (updated['status'] != 'accepted' ||
              updated['challenged_id'] != currentUser.id) {
            ProductionLogger.debug('Debug log', tag: 'AutoFix');
          }
        } else {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      } catch (verifyError) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        // Don't throw - update was successful, just can't verify
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Không thể chấp nhận thách đấu: $e');
    }
  }

  /// Decline a challenge
  Future<void> declineChallenge(String challengeId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      await _supabase
          .from('challenges')
          .update({
            'status': 'declined',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', challengeId);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Send notification to challenger that their challenge was declined
      try {
        final challenge = await _supabase
            .from('challenges')
            .select('''
              id,
              challenger_id,
              challenger:users!fk_challenges_challenger_id(display_name),
              challenged:users!fk_challenges_challenged_id(display_name)
            ''')
            .eq('id', challengeId)
            .single();

        final challengedName = challenge['challenged']?['display_name'] ?? 'Người chơi';
        
        await NotificationService.instance.sendNotification(
          userId: challenge['challenger_id'],
          title: 'Thách đấu bị từ chối 😔',
          message: '$challengedName đã từ chối thách đấu của bạn.',
          type: 'challenge_declined',
          data: {'challenge_id': challengeId},
        );

        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      } catch (notifError) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
        // Don't throw - decline was successful even if notification fails
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      throw Exception('Không thể từ chối thách đấu: $e');
    }
  }

  /// Get challenge details by ID
  Future<Map<String, dynamic>?> getChallengeDetails(String challengeId) async {
    try {
      final response = await _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!fk_challenges_challenger_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating,
              total_wins,
              total_losses
            ),
            club:clubs(
              id,
              name,
              address,
              logo_url
            ),
            challenged:users!fk_challenges_challenged_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating
            )
          ''')
          .eq('id', challengeId)
          .single();

      return response;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Parse match conditions from JSON
  Map<String, dynamic> parseMatchConditions(dynamic matchConditions) {
    if (matchConditions == null) return {};
    if (matchConditions is Map)
      return Map<String, dynamic>.from(matchConditions);
    return {};
  }

  /// Format challenge date/time
  String formatChallengeDateTime(String? isoString) {
    if (isoString == null) return 'Chưa xác định';

    try {
      final dateTime = DateTime.parse(isoString);
      final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      final weekday = weekdays[dateTime.weekday % 7];
      return '$weekday, ${dateTime.day}/${dateTime.month} lúc ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Chưa xác định';
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final userProfile = await _supabase
          .from('users')
          .select('''
            id,
            display_name,
            avatar_url,
            rank,
            elo_rating,
            total_wins,
            total_losses,
            spa_points,
            is_verified
          ''')
          .eq('id', user.id)
          .single();

      return userProfile;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return null;
    }
  }

  /// Get challenge-eligible opponents (verified, within rank range)
  Future<List<Map<String, dynamic>>> getChallengeEligibleOpponents() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      // Get current user's rank
      final currentUserData = await _supabase
          .from('users')
          .select('rank, elo_rating')
          .eq('id', currentUser.id)
          .single();

      final currentRank = currentUserData['rank'] as String?;
      final currentElo = currentUserData['elo_rating'] as int? ?? 1000;

      // Get all verified, active users except current user
      final opponents = await _supabase
          .from('users')
          .select('''
            id,
            display_name,
            avatar_url,
            rank,
            elo_rating,
            total_wins,
            total_losses,
            spa_points,
            is_verified,
            location_name
          ''')
          .neq('id', currentUser.id)
          .eq('is_verified', true)
          .eq('is_active', true)
          .order('elo_rating', ascending: false);

      // Filter by rank range (±2 sub-ranks according to SABO rules v1.2)
      final List<Map<String, dynamic>> eligible = [];

      for (final opponent in opponents) {
        final opponentRank = opponent['rank'] as String?;
        final opponentElo = opponent['elo_rating'] as int? ?? 1000;

        // Skip if no rank
        if (opponentRank == null || currentRank == null) continue;

        // Calculate rank similarity (using same logic as OpponentMatchingService)
        final eloDiff = (currentElo - opponentElo).abs();

        // Allow matches within ±200 ELO (roughly ±2 sub-ranks = 1 main rank)
        if (eloDiff <= 200) {
          eligible.add(opponent);
        }
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return eligible;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }

  /// Get all community visible matches (Open challenges + Accepted matches) for Community tab
  Future<List<Map<String, dynamic>>> getCommunityMatches() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final response = await _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!fk_challenges_challenger_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating,
              total_wins,
              total_losses
            ),
            club:clubs(
              id,
              name,
              address,
              logo_url
            ),
            challenged:users!fk_challenges_challenged_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating,
              total_wins,
              total_losses
            )
          ''')
          .or('challenged_id.is.null,status.in.(accepted,in_progress,completed)')
          .inFilter('challenge_type', ['giao_luu', 'thach_dau'])
          .order('created_at', ascending: false)
          .limit(100); // Show more matches for community visibility

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Fetch matches data separately (workaround for schema cache)
      final challengeIds = response.map((c) => c['id'] as String).toList();
      Map<String, dynamic> matchesMap = {};
      
      if (challengeIds.isNotEmpty) {
        try {
          final matchesResponse = await _supabase
              .from('matches')
              .select('id, challenge_id, status, is_live, video_urls, player1_score, player2_score, winner_id, scheduled_time')
              .inFilter('challenge_id', challengeIds);
          
          for (var match in matchesResponse) {
            final challengeId = match['challenge_id'];
            if (challengeId != null) {
              matchesMap[challengeId] = match;
            }
          }
        } catch (e) {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
        }
      }

      // Merge match data into challenges
      final challenges = List<Map<String, dynamic>>.from(response);
      for (var challenge in challenges) {
        final challengeId = challenge['id'];
        if (matchesMap.containsKey(challengeId)) {
          challenge['match'] = matchesMap[challengeId];
        }
      }

      return challenges;
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return [];
    }
  }
}

