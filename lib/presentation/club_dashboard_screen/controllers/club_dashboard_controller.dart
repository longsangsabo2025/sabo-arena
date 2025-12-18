import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/club.dart';
import '../../../models/club_dashboard_stats.dart';
import '../../../models/club_activity.dart';
import '../../../services/admin_rank_approval_service.dart';
import '../../../services/club_service.dart';

class ClubDashboardController extends ChangeNotifier {
  final String clubId;
  final AdminRankApprovalService _rankApprovalService = AdminRankApprovalService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Club? _club;
  Club? get club => _club;

  ClubDashboardStats _stats = ClubDashboardStats.empty();
  ClubDashboardStats get stats => _stats;

  List<ClubActivity> _activities = [];
  List<ClubActivity> get activities => _activities;

  int _pendingRankRequests = 0;
  int get pendingRankRequests => _pendingRankRequests;

  ClubDashboardController({required this.clubId});

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _loadClubDetails(),
        _loadRealClubStats(),
        _loadRecentActivities(),
        _loadPendingRankRequestsCount(),
      ]);

      _club = results[0] as Club?;
      _stats = results[1] as ClubDashboardStats;
      _activities = results[2] as List<ClubActivity>;
      _pendingRankRequests = results[3] as int;
    } catch (e) {
      _error = e.toString();
      // REMOVED: debugPrint('ClubDashboardController Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Club?> _loadClubDetails() async {
    try {
      return await ClubService.instance.getClubById(clubId);
    } catch (e) {
      // REMOVED: debugPrint('Error loading club details: $e');
      rethrow; // Critical error, let main handler catch it
    }
  }

  Future<ClubDashboardStats> _loadRealClubStats() async {
    try {
      // Get real member count
      final memberCount = await Supabase.instance.client
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('status', 'active')
          .count();

      // Get tournament count
      int tournamentCount = 0;
      try {
        final tournamentResult = await Supabase.instance.client
            .from('tournaments')
            .select('id')
            .eq('club_id', clubId)
            .count();
        tournamentCount = tournamentResult.count;
      } catch (e) {
        // Tournaments table might not exist or error
        tournamentCount = 0;
      }

      return ClubDashboardStats(
        totalMembers: memberCount.count,
        activeMembers: memberCount.count,
        monthlyRevenue: 0.0, // Placeholder
        totalTournaments: tournamentCount,
        tournaments: tournamentCount,
        ranking: 0, // Placeholder
      );
    } catch (e) {
      // REMOVED: debugPrint('Error loading stats: $e');
      return ClubDashboardStats.empty();
    }
  }

  Future<List<ClubActivity>> _loadRecentActivities() async {
    try {
      final activities = <ClubActivity>[];

      // Get recent member joins
      final recentJoins = await Supabase.instance.client
          .from('club_members')
          .select('joined_at, users!inner(display_name)')
          .eq('club_id', clubId)
          .order('joined_at', ascending: false)
          .limit(5);

      for (final join in recentJoins) {
        final userName = join['users']['display_name'] ?? 'Unknown';
        activities.add(
          ClubActivity(
            type: 'member_join',
            timestamp: DateTime.parse(join['joined_at']),
            data: {'userName': userName},
          ),
        );
      }

      return activities;
    } catch (e) {
      // REMOVED: debugPrint('Error loading activities: $e');
      return [];
    }
  }

  Future<int> _loadPendingRankRequestsCount() async {
    try {
      final requests = await _rankApprovalService.getPendingRankRequests();
      return requests.length;
    } catch (e) {
      // REMOVED: debugPrint('Error loading rank requests: $e');
      return 0;
    }
  }
}
