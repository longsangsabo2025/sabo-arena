import 'package:intl/intl.dart';
import 'number_formatter.dart';

/// Unified helper to convert challenge data to MatchCardWidget format
/// Used by both MyChallengesTab and CommunityTab to ensure consistency
class ChallengeToMatchConverter {
  /// Convert challenge data from Supabase to MatchCardWidget format
  static Map<String, dynamic> convert(
    Map<String, dynamic> challenge, {
    String? currentUserId,
  }) {
    // Extract player info
    final challenger = challenge['challenger'] as Map<String, dynamic>?;
    final challenged = challenge['challenged'] as Map<String, dynamic>?;
    final club = challenge['club'] as Map<String, dynamic>?;
    final matchConditions =
        challenge['match_conditions'] as Map<String, dynamic>?;

    // Determine player order for "My Challenges" tab
    // For community tab, always show challenger as player1
    final bool isCurrentUserChallenger =
        currentUserId != null && currentUserId == challenge['challenger_id'];

    // ✅ FIX: For open challenges (challenged = null), always show challenger as player1
    // regardless of currentUserId to avoid showing "Player 1" instead of real name
    final bool isOpenChallenge = challenged == null;
    
    final player1 = (currentUserId != null && !isCurrentUserChallenger && !isOpenChallenge)
        ? challenged
        : challenger;
    final player2 = (currentUserId != null && !isCurrentUserChallenger && !isOpenChallenge)
        ? challenger
        : challenged;

    // Get match parameters with fallback priority:
    // 1. Direct column on challenge table (race_to, stakes_amount)
    // 2. match_conditions JSONB
    // 3. Default value

    final raceToValue =
        challenge['race_to'] ?? matchConditions?['race_to'] ?? 7;

    final stakesAmount =
        challenge['stakes_amount'] ?? matchConditions?['wager'] ?? 0;

    final handicap =
        matchConditions?['handicap'] ?? challenge['handicap_challenger'] ?? 0;

    // Get rank requirements for OPEN challenges
    final rankMin = matchConditions?['rank_min'] as String?;
    final rankMax = matchConditions?['rank_max'] as String?;

    // Player 2 display: If OPEN challenge (challenged_id = null), show rank requirement
    String player2Name;
    String player2RankDisplay;
    String? player2Avatar;

    if (player2 == null || challenge['challenged_id'] == null) {
      // OPEN challenge - show rank requirement
      player2Name = 'Đang chờ...';
      if (rankMin != null && rankMax != null) {
        player2RankDisplay = '$rankMin → $rankMax';
      } else if (rankMin != null) {
        player2RankDisplay = 'Từ $rankMin';
      } else if (rankMax != null) {
        player2RankDisplay = 'Đến $rankMax';
      } else {
        player2RankDisplay = 'Mọi hạng';
      }
      player2Avatar = null;
    } else {
      // Has specific opponent
      player2Name = player2['display_name'] ?? 'Player 2';
      player2RankDisplay = player2['rank'] ?? 'Chưa xếp hạng';
      player2Avatar = player2['avatar_url'];
    }

    // Get status
    final status = challenge['status'] as String? ?? 'pending';
    String cardStatus = 'ready'; // default
    if (status == 'pending') {
      cardStatus = 'ready';
    } else if (status == 'accepted') {
      cardStatus = 'scheduled'; // Changed from 'live' to 'scheduled'
    } else if (status == 'in_progress') {
      cardStatus = 'live';
    } else if (status == 'completed') {
      cardStatus = 'done';
    }

    // Format date/time from scheduled_time or created_at
    final scheduledTime =
        challenge['scheduled_time'] as String? ??
        matchConditions?['scheduled_time'] as String?;
    final createdAt = challenge['created_at'] as String?;

    DateTime? matchDateTime;
    if (scheduledTime != null) {
      matchDateTime = DateTime.tryParse(scheduledTime);
    } else if (createdAt != null) {
      matchDateTime = DateTime.tryParse(createdAt);
    }

    String dateStr = 'TBD';
    String timeStr = '--:--';
    if (matchDateTime != null) {
      try {
        dateStr = DateFormat('EEE, dd/MM', 'vi').format(matchDateTime);
        timeStr = DateFormat('HH:mm').format(matchDateTime);
      } catch (e) {
        // Fallback to English if Vietnamese fails
        final weekday = [
          'CN',
          'T2',
          'T3',
          'T4',
          'T5',
          'T6',
          'T7',
        ][matchDateTime.weekday % 7];
        dateStr = '$weekday - ${DateFormat('dd/MM').format(matchDateTime)}';
        timeStr = DateFormat('HH:mm').format(matchDateTime);
      }
    }

    // Get club/location info
    final clubName = club?['name'] as String?;
    final location = challenge['location'] as String?;
    final currentTable = clubName ?? location ?? 'Chưa xác định';

    // Get match type
    final challengeType = challenge['challenge_type'] as String? ?? 'giao_luu';
    final matchTypeLabel = challengeType == 'thach_dau'
        ? 'Thách đấu'
        : 'Giao lưu';

    return {
      'id': challenge['id'],
      // Player 1
      'player1Id': player1?['id'], // ✅ NEW: For winner comparison
      'player1Name': player1?['display_name'] ?? 'Player 1',
      'player1Rank': player1?['rank'] ?? 'Chưa xếp hạng',
      'player1Avatar': player1?['avatar_url'],
      'player1Online': false,

      // Player 2
      'player2Id': player2?['id'], // ✅ NEW: For winner comparison
      'player2Name': player2Name,
      'player2Rank': player2RankDisplay,
      'player2Avatar': player2Avatar,
      'player2Online': false,

      // Club info
      'clubName': club?['name'],
      'clubLogo': club?['logo_url'],
      'clubAddress': club?['address'],

      // Match info
      'status': cardStatus,
      'matchType': matchTypeLabel,
      'date': dateStr,
      'time': timeStr,
      'score1': challenge['player1_score']?.toString() ?? '?',
      'score2': challenge['player2_score']?.toString() ?? '?',
      'handicap': handicap > 0 ? 'Handicap $handicap ván' : 'No handicap',
      'prize': NumberFormatter.formatWithUnit(stakesAmount, 'SPA'),
      'raceInfo': 'Race to $raceToValue',
      'currentTable': currentTable,
      
      // Winner info (for completed matches)
      'winnerId': challenge['winner_id'], // ✅ NEW: Highlight winner
      
      // Live streaming info (from joined matches table)
      'is_live': _getIsLive(challenge['match']),
      'video_url': _getFirstVideoUrl(challenge['match']),
    };
  }

  /// Check if match is live - handle both List and Map cases
  static bool _getIsLive(dynamic matchData) {
    if (matchData == null) return false;
    
    // Handle List (when using !column_name join)
    if (matchData is List) {
      if (matchData.isEmpty) return false;
      final match = matchData[0] as Map<String, dynamic>?;
      return match?['is_live'] as bool? ?? false;
    }
    
    // Handle Map (when using !fk_name join)
    if (matchData is Map<String, dynamic>) {
      return matchData['is_live'] as bool? ?? false;
    }
    
    return false;
  }

  /// Extract first video URL from video_urls array
  static String? _getFirstVideoUrl(dynamic matchData) {
    if (matchData == null) return null;
    
    Map<String, dynamic>? match;
    
    // Handle List (when using !column_name join)
    if (matchData is List) {
      if (matchData.isEmpty) return null;
      match = matchData[0] as Map<String, dynamic>?;
    }
    // Handle Map (when using !fk_name join)
    else if (matchData is Map<String, dynamic>) {
      match = matchData;
    }
    
    if (match == null) return null;
    
    final videoUrls = match['video_urls'] as List?;
    if (videoUrls == null || videoUrls.isEmpty) return null;
    
    return videoUrls[0] as String?;
  }
}
