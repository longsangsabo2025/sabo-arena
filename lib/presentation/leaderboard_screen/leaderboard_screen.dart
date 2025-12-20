import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_bar_theme.dart' as app_theme;
import '../../services/user_service.dart';
import '../../services/share_service.dart';
import '../../core/utils/sabo_rank_system.dart';
import '../../models/user_profile.dart';
import '../../widgets/user/user_widgets.dart';
import '../../core/design_system/design_system.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
// ELON_MODE_AUTO_FIX

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  String _currentFilter = 'all'; // all, K, I, H, G, F, E
  String _currentSort = 'elo'; // elo, wins, tournaments, spa_points

  List<Map<String, dynamic>> _leaderboardData = [];
  UserProfile? _currentUser;
  int _userRanking = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'key': 'elo', 'title': 'ELO Rating', 'icon': Icons.star},
    {'key': 'wins', 'title': 'Thắng lợi', 'icon': Icons.emoji_events},
    {'key': 'tournaments', 'title': 'Giải đấu', 'icon': Icons.military_tech},
    {'key': 'spa_points', 'title': 'SPA Points', 'icon': Icons.monetization_on},
  ];

  final List<Map<String, dynamic>> _rankFilters = [
    {'key': 'all', 'title': 'Tất cả', 'color': AppColors.gray500},
    {'key': 'K', 'title': 'Hạng K', 'color': AppColors.success},
    {'key': 'I', 'title': 'Hạng I', 'color': AppColors.info},
    {'key': 'H', 'title': 'Hạng H', 'color': AppColors.premium},
    {'key': 'G', 'title': 'Hạng G', 'color': AppColors.warning},
    {'key': 'F', 'title': 'Hạng F', 'color': AppColors.error},
    {'key': 'E', 'title': 'Hạng E', 'color': AppColors.gray700},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCurrentUser();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentSort = _tabs[_tabController.index]['key'];
      });
      _loadLeaderboard();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService.instance.getCurrentUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Call Supabase function for leaderboard
      final response = await Supabase.instance.client.rpc(
        'get_leaderboard',
        params: {
          'board_type': _currentSort,
          'rank_filter': _currentFilter == 'all' ? null : _currentFilter,
          'limit_count': 100,
        },
      );

      final List<dynamic> rawData = response as List<dynamic>;
      final leaderboardData = rawData.cast<Map<String, dynamic>>();

      // Find user ranking
      int userRanking = 0;
      if (_currentUser != null) {
        final userIndex = leaderboardData.indexWhere(
          (player) => player['player_id'] == _currentUser!.id,
        );
        userRanking = userIndex >= 0 ? userIndex + 1 : 0;
      }

      setState(() {
        _leaderboardData = leaderboardData;
        _userRanking = userRanking;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to mock data for development
      _loadMockData();
    }
  }

  void _loadMockData() {
    // Mock leaderboard data for development - MIGRATED 2025: Removed K+/I+
    final mockData = List.generate(50, (index) {
      final ranks = [
        'K',
        'I',
        'H',
        'H+',
        'G',
        'G+',
        'F',
        'F+',
        'E',
        'D',
        'C',
      ];
      final rank = ranks[index % ranks.length];

      return {
        'rank': index + 1,
        'player_id': 'user_$index',
        'username': 'Player${index + 1}',
        'display_name': 'Người chơi số ${index + 1}',
        'player_rank': rank,
        'elo_rating': 2000 - (index * 15) + (index % 3 == 0 ? 50 : 0),
        'total_wins': 100 - index + (index % 5 == 0 ? 20 : 0),
        'tournament_wins': 10 - (index ~/ 5),
        'spa_points': 5000 - (index * 100) + (index % 4 == 0 ? 500 : 0),
        'win_rate': (85.0 - (index * 0.5)).clamp(40.0, 95.0),
        'recent_activity': index < 10
            ? 'Very Active'
            : index < 25
                ? 'Active'
                : 'Somewhat Active',
      };
    });

    setState(() {
      _leaderboardData = mockData;
      _userRanking = 15; // Mock user position
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50, // Facebook gray background
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        shadowColor: AppColors.shadow,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: app_theme.AppBarTheme.primaryGreen,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: app_theme.AppBarTheme.buildGradientTitle('Bảng xếp hạng'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share,
                color: app_theme.AppBarTheme.primaryGreen),
            onPressed: _shareLeaderboard,
            tooltip: 'Chia sẻ bảng xếp hạng',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(105),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Rank Filter với style iOS mới
                _buildModernRankFilter(),
                const SizedBox(height: 8),

                // Tab Bar với style Facebook
                _buildModernTabBar(),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map((tab) => _buildModernLeaderboardView())
                      .toList(),
                ),
    );
  }

  Widget _buildModernRankFilter() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _rankFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _rankFilters[index];
          final isSelected = _currentFilter == filter['key'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentFilter = filter['key'];
              });
              _loadLeaderboard();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.gray50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  filter['title'],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: AppColors.surface),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: _tabs
            .map(
              (tab) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab['icon'], size: 18),
                    const SizedBox(width: 6),
                    Text(tab['title']),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return ErrorStateWidget(
      description: _error ?? 'Có lỗi xảy ra',
      onRetry: _loadLeaderboard,
    );
  }

  Widget _buildModernLeaderboardView() {
    return Column(
      children: [
        // User Position Card - Modern style
        if (_currentUser != null && _userRanking > 0)
          _buildModernUserPositionCard(),

        // Leaderboard List
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadLeaderboard,
            child: _leaderboardData.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.space16,
                      vertical: DesignTokens.space12,
                    ),
                    itemCount: _leaderboardData.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final player = _leaderboardData[index];
                      final isCurrentUser = _currentUser != null &&
                          player['player_id'] == _currentUser!.id;

                      return _buildModernPlayerCard(
                        player,
                        isCurrentUser,
                        player['rank'] ?? (index + 1),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.leaderboard_outlined,
      message: 'Chưa có dữ liệu',
      subtitle: 'Bảng xếp hạng sẽ xuất hiện khi có người chơi',
    );
  }

  Widget _buildModernUserPositionCard() {
    final currentUserData = _leaderboardData.firstWhere(
      (player) => player['player_id'] == _currentUser!.id,
      orElse: () => {
        'rank': _userRanking,
        'player_rank': _currentUser!.rank ?? 'K',
        'elo_rating': _currentUser!.eloRating,
        'total_wins': _currentUser!.totalWins,
        'tournament_wins': 0,
        'spa_points': _currentUser!.spaPoints,
      },
    );

    return Container(
      margin: EdgeInsets.fromLTRB(
        DesignTokens.space16,
        DesignTokens.space12,
        DesignTokens.space16,
        DesignTokens.space8,
      ),
      padding: EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.info700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#${currentUserData['rank']}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Của bạn',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.displayName,
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Hạng ${currentUserData['player_rank']}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Current Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textOnPrimary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _getCurrentValue(currentUserData),
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getCurrentLabel(),
                  style: TextStyle(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPlayerCard(
    Map<String, dynamic> player,
    bool isCurrentUser,
    int ranking,
  ) {
    final rankColor = SaboRankSystem.getRankColor(player['player_rank'] ?? 'K');

    // Use ranking directly for badge color, but treat 3rd and 4th as bronze (same rank)
    final badgeColor = _getModernRankingColor(ranking);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with Ranking Badge Overlay
          Stack(
            children: [
              // Avatar with unified component
              UserAvatarWidget(
                avatarUrl: player['avatar_url']?.toString(),
                size: 56,
                showRankBorder: true,
                rankCode: player['player_rank']?.toString(),
              ),
              // Ranking Badge
              if (ranking <= 3)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textOnPrimary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        ranking == 1
                            ? Icons.emoji_events
                            : Icons.workspace_premium,
                        color: AppColors.textOnPrimary,
                        size: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ranking number for positions 4+
                    if (ranking > 3) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '#$ranking',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: UserDisplayNameText(
                        userData: player,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Rank Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: rankColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Hạng ${player['player_rank']}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: rankColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Bạn',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Stats Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getCurrentValue(player),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isCurrentUser
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getCurrentLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getModernRankingColor(int ranking) {
    if (ranking == 1)
      return const Color(
          0xFFFFB800); // Gold - Champion (specific ranking color)
    if (ranking == 2) return AppColors.gray500; // Silver - Runner-up
    if (ranking == 3 || ranking == 4)
      return const Color(
          0xFFCD7F32); // Bronze - Both semi-final losers (specific ranking color)
    if (ranking <= 10) return AppColors.primary; // Blue
    if (ranking <= 25) return AppColors.success; // Green
    return AppColors.textSecondary; // Gray
  }

  String _getCurrentValue(Map<String, dynamic> player) {
    switch (_currentSort) {
      case 'elo':
        return '${player['elo_rating'] ?? 0}';
      case 'wins':
        return '${player['total_wins'] ?? 0}';
      case 'tournaments':
        return '${player['tournament_wins'] ?? 0}';
      case 'spa_points':
        return SaboRankSystem.formatElo(player['spa_points'] ?? 0);
      default:
        return '0';
    }
  }

  String _getCurrentLabel() {
    switch (_currentSort) {
      case 'elo':
        return 'ELO';
      case 'wins':
        return 'Thắng';
      case 'tournaments':
        return 'Giải';
      case 'spa_points':
        return 'SPA';
      default:
        return '';
    }
  }

  Future<void> _shareLeaderboard() async {
    try {
      await ShareService.shareLeaderboard(
        tournamentId: 'global',
        tournamentName: 'Bảng xếp hạng toàn quốc',
        clubName: 'SABO Arena',
        totalPlayers: _leaderboardData.length,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chia sẻ: $e')),
        );
      }
    }
  }
}
