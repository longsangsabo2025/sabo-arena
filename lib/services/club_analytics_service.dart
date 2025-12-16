import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Service to provide analytics for club owners
class ClubAnalyticsService {
  static ClubAnalyticsService? _instance;
  static ClubAnalyticsService get instance =>
      _instance ??= ClubAnalyticsService._();
  ClubAnalyticsService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive analytics for a club
  Future<Map<String, dynamic>> getClubAnalytics(String clubId) async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      final memberStats = await _getMemberStatistics(clubId);
      final tournamentStats = await _getTournamentStatistics(clubId);
      final revenueStats = await _getRevenueStatistics(clubId);
      final engagementStats = await _getEngagementStatistics(clubId);
      final growthTrends = await _getGrowthTrends(clubId);

      return {
        'member_stats': memberStats,
        'tournament_stats': tournamentStats,
        'revenue_stats': revenueStats,
        'engagement_stats': engagementStats,
        'growth_trends': growthTrends,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      rethrow;
    }
  }

  /// Get member statistics
  Future<Map<String, dynamic>> _getMemberStatistics(String clubId) async {
    // Total members
    final members = await _supabase
        .from('club_members')
        .select('id, joined_at, user_id')
        .eq('club_id', clubId);

    final totalMembers = members.length;

    // New members in last 30 days
    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final newMembers = members.where((m) {
      final joinedAt = DateTime.parse(m['joined_at'] as String);
      return joinedAt.isAfter(last30Days);
    }).length;

    // Active members (participated in tournament or posted in last 30 days)
    final activeMemberIds = await _getActiveMemberIds(clubId);
    final activeMembers = activeMemberIds.length;

    // Member rank distribution
    final memberIds = members.map((m) => m['user_id'] as String).toList();
    final rankDistribution = await _getRankDistribution(memberIds);

    return {
      'total_members': totalMembers,
      'new_members_30d': newMembers,
      'active_members_30d': activeMembers,
      'activity_rate': totalMembers > 0
          ? ((activeMembers / totalMembers) * 100).toStringAsFixed(1)
          : '0',
      'rank_distribution': rankDistribution,
    };
  }

  /// Get tournament statistics
  Future<Map<String, dynamic>> _getTournamentStatistics(String clubId) async {
    // All tournaments
    final tournaments = await _supabase
        .from('tournaments')
        .select(
          'id, title, status, created_at, current_participants, entry_fee, prize_pool',
        )
        .eq('club_id', clubId)
        .order('created_at', ascending: false);

    final totalTournaments = tournaments.length;
    final completed = tournaments
        .where((t) => t['status'] == 'completed')
        .length;
    final ongoing = tournaments.where((t) => t['status'] == 'ongoing').length;
    final upcoming = tournaments.where((t) => t['status'] == 'upcoming').length;

    // Tournaments in last 30 days
    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final recent = tournaments.where((t) {
      final createdAt = DateTime.parse(t['created_at'] as String);
      return createdAt.isAfter(last30Days);
    }).length;

    // Average participants
    final avgParticipants = totalTournaments > 0
        ? tournaments.fold<int>(
                0,
                (sum, t) => sum + ((t['current_participants'] as int?) ?? 0),
              ) /
              totalTournaments
        : 0;

    // Total prize pool distributed
    final totalPrizePool = tournaments.fold<double>(
      0,
      (sum, t) => sum + ((t['prize_pool'] as num?)?.toDouble() ?? 0),
    );

    // Recent tournaments (up to 5 most recent)
    final recentTournaments = tournaments.take(5).map((t) => {
      'id': t['id'],
      'name': t['title'],
      'status': t['status'],
      'participant_count': t['current_participants'] ?? 0,
      'created_at': t['created_at'],
    }).toList();

    return {
      'total_tournaments': totalTournaments,
      'completed': completed,
      'ongoing': ongoing,
      'upcoming': upcoming,
      'tournaments_30d': recent,
      'avg_participants': avgParticipants.toStringAsFixed(1),
      'total_prize_pool': totalPrizePool.toStringAsFixed(0),
      'recent_tournaments': recentTournaments,
    };
  }

  /// Get revenue statistics
  Future<Map<String, dynamic>> _getRevenueStatistics(String clubId) async {
    // Get all completed tournaments
    final tournaments = await _supabase
        .from('tournaments')
        .select('entry_fee, current_participants, created_at')
        .eq('club_id', clubId)
        .eq('status', 'completed');

    // Calculate total revenue from entry fees
    final totalRevenue = tournaments.fold<double>(0, (sum, t) {
      final entryFee = (t['entry_fee'] as num?)?.toDouble() ?? 0;
      final participants = (t['current_participants'] as int?) ?? 0;
      return sum + (entryFee * participants);
    });

    // Revenue in last 30 days
    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final revenue30d = tournaments
        .where((t) {
          final createdAt = DateTime.parse(t['created_at'] as String);
          return createdAt.isAfter(last30Days);
        })
        .fold<double>(0, (sum, t) {
          final entryFee = (t['entry_fee'] as num?)?.toDouble() ?? 0;
          final participants = (t['current_participants'] as int?) ?? 0;
          return sum + (entryFee * participants);
        });

    // Revenue today
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final revenueToday = tournaments
        .where((t) {
          final createdAt = DateTime.parse(t['created_at'] as String);
          return createdAt.isAfter(todayStart);
        })
        .fold<double>(0, (sum, t) {
          final entryFee = (t['entry_fee'] as num?)?.toDouble() ?? 0;
          final participants = (t['current_participants'] as int?) ?? 0;
          return sum + (entryFee * participants);
        });

    // Get table reservations revenue (if implemented)
    final reservations = await _supabase
        .from('table_reservations')
        .select('total_price, created_at')
        .eq('club_id', clubId)
        .eq('status', 'completed');

    final reservationRevenue = reservations.fold<double>(
      0,
      (sum, r) => sum + ((r['total_price'] as num?)?.toDouble() ?? 0),
    );

    final reservationRevenueToday = reservations
        .where((r) {
          final createdAt = DateTime.parse(r['created_at'] as String);
          return createdAt.isAfter(todayStart);
        })
        .fold<double>(
          0,
          (sum, r) => sum + ((r['total_price'] as num?)?.toDouble() ?? 0),
        );

    return {
      'total_revenue': (totalRevenue + reservationRevenue).toStringAsFixed(0),
      'tournament_revenue': totalRevenue.toStringAsFixed(0),
      'reservation_revenue': reservationRevenue.toStringAsFixed(0),
      'revenue_30d': revenue30d.toStringAsFixed(0),
      'revenue_today': (revenueToday + reservationRevenueToday).toStringAsFixed(0),
      'avg_revenue_per_tournament': tournaments.isNotEmpty
          ? (totalRevenue / tournaments.length).toStringAsFixed(0)
          : '0',
    };
  }

  /// Get engagement statistics
  Future<Map<String, dynamic>> _getEngagementStatistics(String clubId) async {
    // Get club posts
    final posts = await _supabase
        .from('posts')
        .select('id, like_count, comment_count, created_at')
        .eq('club_id', clubId);

    final totalPosts = posts.length;
    final totalLikes = posts.fold<int>(
      0,
      (sum, p) => sum + ((p['like_count'] as int?) ?? 0),
    );
    final totalComments = posts.fold<int>(
      0,
      (sum, p) => sum + ((p['comment_count'] as int?) ?? 0),
    );

    // Posts in last 30 days
    final last30Days = DateTime.now().subtract(const Duration(days: 30));
    final posts30d = posts.where((p) {
      final createdAt = DateTime.parse(p['created_at'] as String);
      return createdAt.isAfter(last30Days);
    }).length;

    // Get average engagement rate
    final avgEngagement = totalPosts > 0
        ? ((totalLikes + totalComments) / totalPosts).toStringAsFixed(1)
        : '0';

    return {
      'total_posts': totalPosts,
      'posts_30d': posts30d,
      'total_likes': totalLikes,
      'total_comments': totalComments,
      'avg_engagement': avgEngagement,
      'engagement_rate': totalPosts > 0
          ? (((totalLikes + totalComments) / totalPosts / 10) * 100)
                .toStringAsFixed(1)
          : '0', // Assuming 10 followers per post average
    };
  }

  /// Get growth trends
  Future<Map<String, dynamic>> _getGrowthTrends(String clubId) async {
    final now = DateTime.now();

    // Get member growth over last 6 months
    final monthlyGrowth = <String, int>{};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final members = await _supabase
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .gte('joined_at', month.toIso8601String())
          .lt('joined_at', nextMonth.toIso8601String());

      final monthKey = '${month.month}/${month.year}';
      monthlyGrowth[monthKey] = members.length;
    }

    // Get tournament growth
    final tournamentGrowth = <String, int>{};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final tournaments = await _supabase
          .from('tournaments')
          .select('id')
          .eq('club_id', clubId)
          .gte('created_at', month.toIso8601String())
          .lt('created_at', nextMonth.toIso8601String());

      final monthKey = '${month.month}/${month.year}';
      tournamentGrowth[monthKey] = tournaments.length;
    }

    return {
      'member_growth': monthlyGrowth,
      'tournament_growth': tournamentGrowth,
    };
  }

  /// Get active member IDs (participated in events in last 30 days)
  Future<List<String>> _getActiveMemberIds(String clubId) async {
    final last30Days = DateTime.now().subtract(const Duration(days: 30));

    // Get tournament participants
    final tournaments = await _supabase
        .from('tournaments')
        .select('id')
        .eq('club_id', clubId)
        .gte('created_at', last30Days.toIso8601String());

    final tournamentIds = tournaments.map((t) => t['id'] as String).toList();

    if (tournamentIds.isEmpty) return [];

    final participants = await _supabase
        .from('tournament_participants')
        .select('user_id')
        .inFilter('tournament_id', tournamentIds);

    return participants.map((p) => p['user_id'] as String).toSet().toList();
  }

  /// Get rank distribution of members
  Future<Map<String, int>> _getRankDistribution(List<String> memberIds) async {
    if (memberIds.isEmpty) return {};

    final users = await _supabase
        .from('users')
        .select('rank')
        .inFilter('id', memberIds);

    final Map<String, int> distribution = {};

    for (final user in users) {
      final rank = user['rank'] as String? ?? 'Unranked';
      distribution[rank] = (distribution[rank] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get top performing members
  Future<List<Map<String, dynamic>>> getTopMembers(
    String clubId, {
    int limit = 10,
  }) async {
    final members = await _supabase
        .from('club_members')
        .select('user_id')
        .eq('club_id', clubId);

    final memberIds = members.map((m) => m['user_id'] as String).toList();

    if (memberIds.isEmpty) return [];

    final users = await _supabase
        .from('users')
        .select(
          'id, display_name, avatar_url, rank, elo_rating, total_wins, total_tournaments',
        )
        .inFilter('id', memberIds)
        .order('elo_rating', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(users);
  }
}

