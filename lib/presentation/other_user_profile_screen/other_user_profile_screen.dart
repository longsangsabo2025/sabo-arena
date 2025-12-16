import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/app_export.dart';
import '../../core/utils/user_friendly_messages.dart';
import '../../models/user_profile.dart';
import '../../models/tournament.dart';
import '../direct_messages_screen/direct_messages_screen.dart';
import '../../services/user_service.dart';
import '../../services/direct_messaging_service.dart';
import '../../services/tournament_service.dart';
import '../../services/share_service.dart';
import '../user_profile_screen/widgets/modern_profile_header_widget.dart';
import '../user_profile_screen/widgets/profile_tab_navigation_widget.dart';
import '../shared/widgets/tournament_card_widget.dart';
import '../user_profile_screen/widgets/matches_section_widget.dart';
import '../user_profile_screen/widgets/user_posts_grid_widget.dart';
import '../../widgets/avatar_with_quick_follow.dart'; // Import FollowEventBroadcaster

import '../../widgets/loading_state_widget.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Màn hình profile của user khác - đồng bộ layout với UserProfileScreen
class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool _isLoading = true;

  // Services
  final UserService _userService = UserService.instance;
  final DirectMessagingService _messagingService =
      DirectMessagingService.instance;
  final TournamentService _tournamentService = TournamentService.instance;

  // User data
  UserProfile? _userProfile;
  Map<String, dynamic> _socialData = {};
  List<Tournament> _tournaments = [];

  // Follow status
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;

  bool _isProcessing = false;

  // StreamSubscription for follow events
  StreamSubscription<Map<String, dynamic>>? _followEventSubscription;

  // Tab navigation state
  String _currentTab = 'live'; // 'ready', 'live', 'done'
  int _mainTabIndex = 0; // 0: Bài đăng, 1: Giải Đấu, 2: Trận Đấu, 3: Kết quả

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTournaments();

    // Listen to follow events from other screens
    _followEventSubscription = FollowEventBroadcaster.stream.listen((event) {
      if (event['userId'] == widget.userId && mounted) {
        setState(() {
          _isFollowing = event['isFollowing'];
          if (event['isFollowing']) {
            _followersCount++;
          } else {
            _followersCount = (_followersCount - 1).clamp(0, 999999);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _followEventSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Load user profile
      final profile = await _userService.getUserProfileById(widget.userId);

      // Check follow status
      final isFollowing = await _userService.isFollowingUser(widget.userId);

      // Get follow counts
      final counts = await _userService.getUserFollowCounts(widget.userId);

      // Get user stats (if needed)
      final userStats = await _userService.getUserStats(widget.userId);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isFollowing = isFollowing;
          _followersCount = counts['followers'] ?? 0;
          _followingCount = counts['following'] ?? 0;
          _socialData = userStats;
          _isLoading = false;
        });
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyMessages.getErrorMessage(e, context: 'Tải profile'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadTournaments() async {
    try {
      String status;
      switch (_currentTab) {
        case 'ready':
          status = 'draft,open';
          break;
        case 'live':
          status = 'in_progress';
          break;
        case 'done':
          status = 'completed,cancelled';
          break;
        default:
          status = 'in_progress';
      }

      // Load all tournaments with status - will need to filter by user participation manually
      final tournaments = await _tournamentService.getTournaments(
        status: status,
        page: 1,
        pageSize: 50,
      );

      // TODO: Filter tournaments where this user is a participant
      // For now, show all tournaments (will be fixed later)

      if (mounted) {
        setState(() {
          _tournaments = tournaments;
        });
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        setState(() {
          _tournaments = [];
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isProcessing) return;

    try {
      setState(() => _isProcessing = true);

      if (_isFollowing) {
        await _userService.unfollowUser(widget.userId);
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followersCount = (_followersCount - 1).clamp(0, 999999);
          });
        }
        // Broadcast unfollow event to sync other screens
        FollowEventBroadcaster.notifyFollowChanged(widget.userId, false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bỏ theo dõi ${_userProfile?.displayName}'),
          ),
        );
      } else {
        await _userService.followUser(widget.userId);
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followersCount++;
          });
        }
        // Broadcast follow event to sync other screens
        FollowEventBroadcaster.notifyFollowChanged(widget.userId, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã theo dõi ${_userProfile?.displayName}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(UserFriendlyMessages.followError)));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    try {
      // Get or create direct room
      final roomId = await _messagingService.getOrCreateDirectRoom(
        widget.userId,
      );

      if (mounted) {
        // Navigate to chat screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DirectChatScreen(
              roomId: roomId,
              otherUserId: widget.userId,
              otherUserName:
                  _userProfile?.displayName ?? widget.userName ?? 'User',
              otherUserAvatar: _userProfile?.avatarUrl,
            ),
          ),
        );
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UserFriendlyMessages.messageError)),
        );
      }
    }
  }

  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.lightImpact();

    await _loadUserProfile();
    await _loadTournaments();

    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã cập nhật thông tin profile'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: _userProfile?.displayName ?? widget.userName ?? 'Profile',
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          // Follow/Unfollow button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _toggleFollow,
              icon: Icon(
                _isFollowing ? Icons.person_remove : Icons.person_add,
                size: 18,
              ),
              label: Text(
                _isFollowing ? 'Đang theo dõi' : 'Theo dõi', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing
                    ? Colors.grey[300]
                    : AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          SizedBox(width: 2.w),

          // Message button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _sendMessage,
              icon: Icon(Icons.message_outlined, size: 18),
              label: Text(
                'Nhắn tin', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.lightTheme.colorScheme.primary,
                side: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 1.5,
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentListSliver() {
    if (_tournaments.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có giải đấu', overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final tournament = _tournaments[index];
        final cardData = _tournamentToCardData(tournament);

        return TournamentCardWidget(
          tournament: cardData,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.tournamentDetailScreen,
              arguments: {'tournamentId': tournament.id},
            );
          },
          onShareTap: () => _shareTournament(tournament),
        );
      }, childCount: _tournaments.length),
    );
  }

  Widget _buildMatchesSectionSliver() {
    return SliverToBoxAdapter(
      child: MatchesSectionWidget(userId: widget.userId),
    );
  }

  Map<String, dynamic> _tournamentToCardData(Tournament tournament) {
    // ✅ Get prize breakdown from prize_distribution
    Map<String, String>? prizeBreakdown;
    final prizeDistribution = tournament.prizeDistribution;
    if (prizeDistribution != null) {
      // Check for text-based format (first, second, third keys)
      if (prizeDistribution.containsKey('first') && prizeDistribution['first'] is String) {
        prizeBreakdown = {
          'first': prizeDistribution['first'] as String,
          if (prizeDistribution['second'] != null)
            'second': prizeDistribution['second'] as String,
          if (prizeDistribution['third'] != null)
            'third': prizeDistribution['third'] as String,
        };
      }
    }

    return {
      'id': tournament.id,
      'name': tournament.title,
      'date': _formatTournamentDate(tournament.startDate),
      'playersCount':
          '${tournament.currentParticipants}/${tournament.maxParticipants}',
      'prizePool': _formatPrizePool(tournament.prizePool),
      'prizeBreakdown': prizeBreakdown,
      'rating': _formatRankRange(tournament.minRank, tournament.maxRank),
      'gameFormat': tournament.format,
      'venue': tournament.venueAddress ?? tournament.clubName ?? '',
      'clubLogo': tournament.clubLogo,
      'entryFee': _formatEntryFee(tournament.entryFee),
      'iconNumber': _generateIconNumber(tournament.id),
      'mangCount': 2,
      'isLive': tournament.status == 'in_progress',
      'status': _currentTab,
    };
  }

  String _formatTournamentDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final weekdays = [
      'CN',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
    ];
    final weekday = weekdays[date.weekday % 7];
    return '$day/$month - $weekday';
  }

  String _formatPrizePool(double amount) {
    if (amount == 0) return 'Free';
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)} Million';
    }
    return '${(amount / 1000).toStringAsFixed(0)}K';
  }

  String _formatEntryFee(double amount) {
    if (amount == 0) return 'Miễn phí';
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '${amount.toStringAsFixed(0)}đ';
  }

  String _generateIconNumber(String tournamentId) {
    final hash = tournamentId.hashCode;
    return (hash % 2 == 0) ? '8' : '9';
  }

  String _formatRankRange(String? minRank, String? maxRank) {
    if (minRank != null && maxRank != null) {
      return '$minRank → $maxRank';
    } else if (minRank != null) {
      return '$minRank+';
    } else if (maxRank != null) {
      return '≤ $maxRank';
    }
    return 'All Ranks';
  }

  Future<void> _shareTournament(Tournament tournament) async {
    try {
      await ShareService.shareTournament(
        tournamentId: tournament.id,
        tournamentName: tournament.title,
        startDate: _formatTournamentDate(tournament.startDate),
        participants: tournament.currentParticipants,
        prizePool: _formatPrizePool(tournament.prizePool),
      );
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chia sẻ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: const LoadingStateWidget(message: 'Đang tải hồ sơ...'),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 2.h),
              Text(
                'Không thể tải hồ sơ', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
              SizedBox(height: 1.h),
              Text(
                'Người dùng không tồn tại.', overflow: TextOverflow.ellipsis, style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    final userDataMap = _userProfile!.toJson();
    final displayUserData = Map<String, dynamic>.from(userDataMap);

    // Map fields for ModernProfileHeaderWidget
    displayUserData['avatar'] = _userProfile!.avatarUrl;
    displayUserData['coverPhoto'] = _userProfile!.coverPhotoUrl;
    displayUserData['displayName'] = _userProfile!.displayName.isNotEmpty
        ? _userProfile!.displayName
        : _userProfile!.fullName;
    displayUserData['currentRankCode'] = _userProfile!.rank;

    // Stats
    displayUserData['eloRating'] = _userProfile!.eloRating;
    displayUserData['spaPoints'] = _userProfile!.spaPoints;
    displayUserData['totalMatches'] =
        _userProfile!.totalWins + _userProfile!.totalLosses;
    displayUserData['totalTournaments'] = _userProfile!.totalTournaments;
    displayUserData['ranking'] = _socialData['ranking'] ?? 0;

    // Social stats
    displayUserData['followersCount'] = _followersCount;
    displayUserData['followingCount'] = _followingCount;
    displayUserData['likesCount'] = 0;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Modern Profile Header (NO edit/settings)
            SliverToBoxAdapter(
              child: ModernProfileHeaderWidget(
                userData: displayUserData,
                onEditProfile: null, // Không cho phép edit
                onCoverPhotoTap: null, // Không cho phép đổi cover
                onTabChanged: (tabIndex) {
                  if (tabIndex == 3) {
                    Navigator.pushNamed(context, AppRoutes.leaderboardScreen);
                    return;
                  }
                  setState(() {
                    _mainTabIndex = tabIndex;
                  });
                },
              ),
            ),

            // Action Buttons (Follow + Message)
            SliverToBoxAdapter(child: _buildActionButtons()),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Content based on main tab
            if (_mainTabIndex == 0) ...[
              // Bài đăng tab
              UserPostsGridWidget(userId: widget.userId),
            ] else if (_mainTabIndex == 1) ...[
              // Giải Đấu tab
              SliverToBoxAdapter(
                child: ProfileTabNavigationWidget(
                  currentTab: _currentTab,
                  onTabChanged: (tab) {
                    setState(() {
                      _currentTab = tab;
                    });
                    _loadTournaments();
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildTournamentListSliver(),
            ] else if (_mainTabIndex == 2) ...[
              // Trận Đấu tab
              _buildMatchesSectionSliver(),
            ],

            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          ],
        ),
      ),
    );
  }
}

