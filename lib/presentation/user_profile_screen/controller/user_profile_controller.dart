import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_profile.dart';
import '../../../models/user_stats.dart';
import '../../../models/user_social_stats.dart';
import '../../../models/tournament.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/club_permission_service.dart';
import '../../../services/messaging_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/tournament_service.dart';
import '../../../models/tournament_tab_status.dart';
import '../../../widgets/avatar_with_quick_follow.dart';
import 'package:sabo_arena/utils/production_logger.dart';

class UserProfileController extends ChangeNotifier {
  // Services
  final UserService _userService = UserService.instance;
  final AuthService _authService = AuthService.instance;
  final ClubPermissionService _clubPermissionService = ClubPermissionService();
  final MessagingService _messagingService = MessagingService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final TournamentService _tournamentService = TournamentService.instance;

  // State
  bool isLoading = true;
  UserProfile? userProfile;
  UserStats? userStats;
  UserSocialStats socialData = const UserSocialStats();
  List<Tournament> tournaments = [];
  bool hasClubManagementAccess = false;
  int unreadMessageCount = 0;
  int unreadNotificationCount = 0;
  String currentTab = 'live'; // 'ready', 'live', 'done' for tournaments

  // Subscriptions
  StreamSubscription<Map<String, dynamic>>? _followEventSubscription;
  RealtimeChannel? _userProfileChannel;

  // Initialize
  void init({String? userId}) {
    loadUserProfile(userId: userId);
    
    // Only load private data if it's the current user
    final isCurrentUser = userId == null || userId == _authService.currentUser?.id;
    
    if (isCurrentUser) {
      loadClubManagementAccess();
      loadUnreadMessageCount();
      loadUnreadNotificationCount();
    }
    
    loadTournaments(); // This might need adjustment to load target user's tournaments

    // Listen to follow events
    _followEventSubscription = FollowEventBroadcaster.stream.listen((event) {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null) {
        _reloadFollowCounts(currentUserId);
      }
    });

    if (isCurrentUser) {
      _setupRealtimeListener();
    }
  }

  @override
  void dispose() {
    _followEventSubscription?.cancel();
    _userProfileChannel?.unsubscribe();
    super.dispose();
  }

  // Logic Methods
  void updateUserProfile(UserProfile profile) {
    userProfile = profile;
    notifyListeners();
  }

  Future<void> loadUserProfile({String? userId, bool forceRefresh = false}) async {
    try {
      isLoading = true;
      notifyListeners();

      final targetUserId = userId ?? _authService.currentUser?.id;
      
      if (targetUserId != null) {
        try {
          userProfile = await _userService.getUserProfileById(targetUserId, forceRefresh: forceRefresh);
          await _loadProfileData(userProfile!.id);
        } catch (e) {
          // Auto-create profile logic only for current user
          if (userId == null || userId == _authService.currentUser?.id) {
            ProductionLogger.info('⚠️ Profile not found, creating new profile...');
            final currentUser = _authService.currentUser;
            if (currentUser != null) {
              await _authService.upsertUserRecord(
                fullName: currentUser.userMetadata?['full_name'] ??
                    currentUser.email?.split('@')[0] ??
                    'User',
                email: currentUser.email,
                phone: currentUser.phone,
                role: 'player',
              );
              userProfile = await _userService.getUserProfileById(currentUser.id, forceRefresh: true);
              await _loadProfileData(userProfile!.id);
            }
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      ProductionLogger.error('❌ Profile error: $e', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfileData(String userId) async {
    try {
      final followCounts = await _userService.getUserFollowCounts(userId);
      userStats = await _userService.getUserStats(userId);
      
      socialData = UserSocialStats(
        followersCount: followCounts['followers'] ?? 0,
        followingCount: followCounts['following'] ?? 0,
        challengesCount: 0,
        tournamentsCount: userStats?.totalTournaments ?? 0,
        ranking: userStats?.ranking ?? 0,
      );
      notifyListeners();
    } catch (e) {
      ProductionLogger.error('❌ Profile data error: $e', error: e);
    }
  }

  Future<void> _reloadFollowCounts(String userId) async {
    try {
      final followCounts = await _userService.getUserFollowCounts(userId);
      socialData = socialData.copyWith(
        followersCount: followCounts['followers'] ?? 0,
        followingCount: followCounts['following'] ?? 0,
      );
      notifyListeners();
    } catch (e) {
      ProductionLogger.error('❌ Error reloading follow counts: $e', error: e);
    }
  }

  void _setupRealtimeListener() {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return;

    _userProfileChannel = Supabase.instance.client
        .channel('user-profile-$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: currentUserId,
          ),
          callback: (payload) {
            loadUserProfile(forceRefresh: true);
          },
        )
        .subscribe();
  }

  Future<void> loadClubManagementAccess() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;
      hasClubManagementAccess =
          await _clubPermissionService.hasClubManagementAccess(currentUser.id);
      notifyListeners();
    } catch (e) {
      ProductionLogger.error('❌ Error checking club management access: $e', error: e);
    }
  }

  Future<void> loadUnreadMessageCount() async {
    try {
      unreadMessageCount = await _messagingService.getUnreadMessageCount();
      notifyListeners();
    } catch (e) {
      ProductionLogger.error('❌ Error loading unread message count: $e', error: e);
    }
  }

  Future<void> loadUnreadNotificationCount() async {
    try {
      unreadNotificationCount =
          await _notificationService.getUnreadNotificationCount();
      notifyListeners();
    } catch (e) {
      ProductionLogger.error('❌ Error loading unread notification count: $e', error: e);
    }
  }

  Future<void> loadTournaments() async {
    try {
      final status = currentTab == 'live'
          ? TournamentTabStatus.live
          : currentTab == 'done'
              ? TournamentTabStatus.completed
              : TournamentTabStatus.upcoming;

      tournaments = await _tournamentService.getTournaments(
        status: status,
        page: 1,
        pageSize: 20,
      );
      notifyListeners();
    } catch (e) {
      ProductionLogger.error('❌ Error loading tournaments: $e', error: e);
      tournaments = [];
      notifyListeners();
    }
  }

  void setTournamentTab(String tab) {
    currentTab = tab;
    loadTournaments();
  }

  Future<void> refreshProfile() async {
    await loadUserProfile(forceRefresh: true);
    await loadUnreadMessageCount();
    await loadUnreadNotificationCount();
  }
}
