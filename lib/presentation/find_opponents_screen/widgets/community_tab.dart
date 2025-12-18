import 'package:flutter/material.dart';
import '../../../services/challenge_list_service.dart';
import '../../../widgets/loading_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import 'package:flutter/foundation.dart';
import '../../user_profile_screen/widgets/match_card_widget.dart';
import '../../user_profile_screen/widgets/match_card_widget_realtime.dart';
import '../../live_stream/live_stream_player_screen.dart';
import '../../../utils/challenge_to_match_converter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import 'package:sabo_arena/models/match.dart';
import './challenge_card_widget_redesign.dart';
import './challenge_detail_modal.dart';
import './schedule_match_modal.dart';
import './create_spa_challenge_modal.dart';
import './create_social_challenge_modal.dart';
import '../../../models/user_profile.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/constants/ranking_constants.dart';
import '../../../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

/// Tab to display accepted matches (Community - Cộng đồng)
/// Has 2 main tabs (Thách đấu/Giao lưu), each with 2 sub-tabs (Ready/Complete)
class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ChallengeListService _challengeService = ChallengeListService.instance;
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0; // 0: Thách đấu, 1: Giao lưu
  
  // Sub-tab controllers for each main tab
  late TabController _thachDauSubController;
  late TabController _giaoLuuSubController;

  // Filter state
  String? _selectedRankFilter; // null = All
  bool _onlyLiveFilter = false;
  bool _sameRankFilter = false;
  bool _nearMeFilter = false;
  Map<String, dynamic>? _selectedClubFilter;
  Position? _currentPosition;
  UserProfile? _currentUserProfile;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _thachDauSubController = TabController(length: 2, vsync: this);
    _giaoLuuSubController = TabController(length: 2, vsync: this);
    _loadData();
    // Removed auto-refresh to improve UX - user can pull-to-refresh manually
  }
  
  @override
  void dispose() {
    _thachDauSubController.dispose();
    _giaoLuuSubController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });


      // Load both open challenges and accepted matches for community visibility
      final matches = await _challengeService.getCommunityMatches();

      // Load current user profile for "Same Rank" filter
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        try {
          final userData = await supabase
              .from('users')
              .select()
              .eq('id', currentUserId)
              .single();
          _currentUserProfile = UserProfile.fromJson(userData);
        } catch (e) {
          // Ignore error
        }
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_selectedTabIndex == 0) {
      // Thách đấu FAB
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        child: FloatingActionButton.extended(
          heroTag: 'community_challenge_create',
          onPressed: _showCreateChallengeModal,
          backgroundColor: AppColors.info, // Xanh đậm chủ đạo
          foregroundColor: AppColors.textOnPrimary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.emoji_events, size: 20),
          label: const Text(
            'Tạo thách đấu',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else {
      // Giao lưu FAB
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        child: FloatingActionButton.extended(
          heroTag: 'community_social_create',
          onPressed: _showCreateSocialModal,
          backgroundColor: AppColors.premium, // Tím chủ đạo cho giao lưu
          foregroundColor: AppColors.textOnPrimary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.groups, size: 20),
          label: const Text(
            'Tạo giao lưu',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _showCreateChallengeModal() async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tạo thách đấu')),
      );
      return;
    }

    // Get current user profile
    final currentUserData = await supabase
        .from('users')
        .select()
        .eq('id', currentUserId)
        .single();

    // Convert to UserProfile
    final currentUser = UserProfile.fromJson(currentUserData);

    // Get challenge-eligible opponents
    final opponentsData = await _challengeService
        .getChallengeEligibleOpponents();
    final opponents = opponentsData
        .map((data) => UserProfile.fromJson(data))
        .toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSpaChallengeModal(
        currentUser: currentUser,
        opponents: opponents,
      ),
    );
  }

  Future<void> _showCreateSocialModal() async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tạo giao lưu')),
      );
      return;
    }

    // Get current user profile
    UserProfile? currentUserProfile;
    try {
      final currentUserData = await supabase
          .from('users')
          .select()
          .eq('id', currentUserId)
          .single();
      currentUserProfile = UserProfile.fromJson(currentUserData);
    } catch (e) {
      // Ignore error
    }

    // Get opponents (using same eligible list for now, or could be different)
    final opponentsData = await _challengeService.getChallengeEligibleOpponents();
    final opponentProfiles = opponentsData
        .map((data) => UserProfile.fromJson(data))
        .toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSocialChallengeModal(
        currentUser: currentUserProfile,
        opponents: opponentProfiles,
      ),
    );
  }


  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingStateWidget(
        message: 'Đang tải cộng đồng billiards...',
      );
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(errorMessage: _errorMessage, onRetry: _loadData);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section - Hidden for cleaner UI
            const SizedBox.shrink(),

            // Tabs: Thách đấu & Giao lưu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMatchTypeTab(
                      label: 'Thách đấu',
                      icon: Icons.emoji_events,
                      count: _getFilteredMatchesByType('thach_dau').length,
                      index: 0,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                  Expanded(
                    child: _buildMatchTypeTab(
                      label: 'Giao lưu',
                      icon: Icons.groups,
                      count: _getFilteredMatchesByType('giao_luu').length,
                      index: 1,
                      color: const Color(0xFF7B1FA2),
                    ),
                  ),
                ],
              ),
            ),

            // Smart Filters
            _buildFilterBar(),

            // Sub-tabs: Ready & Complete based on selected main tab
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _selectedTabIndex == 0 
                    ? _thachDauSubController 
                    : _giaoLuuSubController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Sắp diễn ra'),
                  Tab(text: 'Hoàn thành'),
                ],
              ),
            ),

            // Matches list based on selected tab and status
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: TabBarView(
                controller: _selectedTabIndex == 0 
                    ? _thachDauSubController 
                    : _giaoLuuSubController,
                children: [
                  // Ready tab
                  _buildMatchesList(
                    _selectedTabIndex == 0 ? 'thach_dau' : 'giao_luu',
                    isReady: true,
                  ),
                  // Complete tab
                  _buildMatchesList(
                    _selectedTabIndex == 0 ? 'thach_dau' : 'giao_luu',
                    isReady: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build matches list for sub-tab (Ready or Complete)
  Widget _buildMatchesList(String challengeType, {required bool isReady}) {
    final allMatches = _getFilteredMatchesByType(challengeType);
    
    // Filter by status: Ready = pending/accepted/in_progress, Complete = completed
    final filteredMatches = allMatches.where((match) {
      final status = match['status'] as String? ?? 'pending';
      if (isReady) {
        return ['pending', 'accepted', 'in_progress'].contains(status);
      } else {
        return status == 'completed';
      }
    }).toList();

    if (filteredMatches.isEmpty) {
      // Empty state
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isReady ? Icons.inbox_outlined : Icons.check_circle_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isReady 
                    ? 'Chưa có trận nào đang chờ'
                    : 'Chưa có trận nào hoàn thành',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isReady
                    ? 'Các trận đang chờ và đang diễn ra sẽ hiển thị ở đây'
                    : 'Các trận đã hoàn thành sẽ hiển thị ở đây',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // List of matches
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredMatches.length,
        itemBuilder: (context, index) {
          final challenge = filteredMatches[index];
          
          // Transform challenge data to match card format (same as My Challenges tab)
          final matchData = ChallengeToMatchConverter.convert(
            challenge,
            currentUserId: Supabase.instance.client.auth.currentUser?.id,
          );
          
          // Extract match information for live streaming detection
          final match = challenge['match'] as Map<String, dynamic>?;
          final isLive = match?['is_live'] as bool? ?? false;
          final matchStatus = match?['status'] as String? ?? 'pending';
          final videoUrls = match?['video_urls'] as List?;
          final hasVideoUrls = videoUrls != null && videoUrls.isNotEmpty;
          
          // Conditional rendering: Use realtime card for live matches, static card otherwise
          if ((matchStatus == 'in_progress' || isLive) && hasVideoUrls) {
            // Live match with video - use realtime card with "Watch Live" button
            return MatchCardWidgetRealtime(
              match: Match.fromJson(matchData),
              onWatchLive: () {
                // Navigate to live stream player
                final videoUrl = videoUrls[0] as String;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveStreamPlayerScreen(
                      videoUrl: videoUrl,
                    ),
                  ),
                );
              },
            );
          } else if (matchStatus == 'pending') {
            // ✅ FIX: Use MatchCardWidget with actions for pending challenges
            return MatchCardWidget(
              matchMap: matchData,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ChallengeDetailModal(
                    challenge: challenge,
                    isCompetitive: challengeType == 'thach_dau',
                    onAccepted: _loadData,
                    onDeclined: _loadData,
                  ),
                );
              },
              bottomAction: _buildActionButtons(challenge),
            );
          } else {
            // Non-live match or no video - use static card
            return MatchCardWidget(
              matchMap: matchData,
              onTap: () {
                // Show challenge detail in bottom sheet
                if (kDebugMode) {
                  ProductionLogger.info('🎯 Challenge tapped: ${challenge['id']}', tag: 'community_tab');
                }
                // You can add detail view here if needed
              },
            );
          }
        },
      ),
    );
  }

  Widget? _buildActionButtons(Map<String, dynamic> challenge) {
    final status = challenge['status'] as String? ?? 'pending';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final challengedId = challenge['challenged_id'] as String?;
    final challengerId = challenge['challenger_id'] as String?;
    
    // Don't show buttons if I am the challenger
    if (currentUserId == challengerId) return null;

    // Show buttons if:
    // 1. It's a public challenge (challengedId is null)
    // 2. OR it's a direct challenge to me
    if (status == 'pending' && (challengedId == null || challengedId == currentUserId)) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _acceptChallenge(challenge),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Nhận thách đấu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final challenger = challenge['challenger'] as Map<String, dynamic>?;
                if (challenger != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ScheduleMatchModal(
                      targetUserId: challenger['id'],
                      targetUserName: challenger['display_name'] ?? 'Đối thủ',
                    ),
                  );
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Không tìm thấy thông tin đối thủ')),
                   );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00695C),
                side: const BorderSide(color: Color(0xFF00695C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Hẹn lịch',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }
    return null;
  }

  Future<void> _acceptChallenge(Map<String, dynamic> challenge) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _challengeService.acceptChallenge(challenge['id']);
      
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chấp nhận thách đấu!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  /// Get filtered matches by type (thach_dau or giao_luu)
  List<Map<String, dynamic>> _getFilteredMatchesByType(String challengeType) {
    final filtered = _matches.where((match) {
      final type = match['challenge_type'] as String?;
      
      // 1. Filter by Type
      bool typeMatch = false;
      if (challengeType == 'giao_luu') {
        typeMatch = type == 'giao_luu' || type == 'schedule_request';
      } else {
        typeMatch = type == challengeType;
      }
      if (!typeMatch) return false;

      // 2. Filter by "Only Live"
      if (_onlyLiveFilter) {
        final status = match['status'] as String?;
        final isLive = match['is_live'] as bool? ?? false;
        if (status != 'in_progress' && !isLive) return false;
      }

      // 3. Filter by Rank (Selected Rank or Same Rank)
      if (_selectedRankFilter != null || _sameRankFilter) {
        final challenger = match['challenger'] as Map<String, dynamic>?;
        final challenged = match['challenged'] as Map<String, dynamic>?;
        
        final challengerRank = challenger?['rank'] as String?;
        final challengedRank = challenged?['rank'] as String?;

        String? targetRank;
        if (_sameRankFilter && _currentUserProfile != null) {
          targetRank = _currentUserProfile!.rank;
        } else {
          targetRank = _selectedRankFilter;
        }

        if (targetRank != null) {
          // Check if ANY player in the match has the target rank
          // This is a loose filter to show relevant matches
          final hasRank = (challengerRank == targetRank) || (challengedRank == targetRank);
          if (!hasRank) return false;
        }
      }

      // 4. Filter by Club
      if (_selectedClubFilter != null) {
        final club = match['club'] as Map<String, dynamic>?;
        if (club == null || club['id'] != _selectedClubFilter!['id']) {
          return false;
        }
      }

      // 5. Filter by "Near Me" (Distance)
      if (_nearMeFilter && _currentPosition != null) {
        final club = match['club'] as Map<String, dynamic>?;
        // Only keep matches with location data
        if (club == null || club['latitude'] == null || club['longitude'] == null) {
          return false;
        }
        // Don't filter by radius here, we will sort and take top 10 later
      }

      return true;
    }).toList();

    // Sort logic
    filtered.sort((a, b) {
      // Priority 1: Distance (if Near Me is active)
      if (_nearMeFilter && _currentPosition != null) {
        final clubA = a['club'] as Map<String, dynamic>?;
        final clubB = b['club'] as Map<String, dynamic>?;
        
        double distA = 999999;
        double distB = 999999;
        
        if (clubA != null && clubA['latitude'] != null && clubA['longitude'] != null) {
          distA = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            (clubA['latitude'] as num).toDouble(),
            (clubA['longitude'] as num).toDouble(),
          );
        }
        
        if (clubB != null && clubB['latitude'] != null && clubB['longitude'] != null) {
          distB = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            (clubB['latitude'] as num).toDouble(),
            (clubB['longitude'] as num).toDouble(),
          );
        }
        
        if ((distA - distB).abs() > 0.1) { // 100m difference
          return distA.compareTo(distB);
        }
      }

      // Priority 2: Created At (Newest first)
      final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    // If "Near Me" is active, take only top 10 closest matches
    if (_nearMeFilter && _currentPosition != null) {
      return filtered.take(10).toList();
    }

    return filtered;
  }


  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter Button
          ActionChip(
            avatar: Icon(
              Icons.filter_list,
              size: 16,
              color: _selectedRankFilter != null ? Colors.white : Colors.grey[700],
            ),
            label: Text(
              _selectedRankFilter != null 
                  ? (RankingConstants.RANK_DETAILS[_selectedRankFilter]?['name'] ?? _selectedRankFilter!)
                  : 'Bộ lọc',
              style: TextStyle(
                color: _selectedRankFilter != null ? Colors.white : Colors.grey[700],
                fontWeight: _selectedRankFilter != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            backgroundColor: _selectedRankFilter != null ? Theme.of(context).primaryColor : Colors.grey[200],
            onPressed: _showFilterModal,
          ),
          const SizedBox(width: 8),

          // "Live" Quick Filter
          FilterChip(
            label: const Text('Đang diễn ra'),
            selected: _onlyLiveFilter,
            onSelected: (bool selected) {
              setState(() {
                _onlyLiveFilter = selected;
              });
            },
            selectedColor: Colors.red.withValues(alpha: 0.2),
            checkmarkColor: Colors.red,
            labelStyle: TextStyle(
              color: _onlyLiveFilter ? Colors.red : Colors.grey[700],
              fontWeight: _onlyLiveFilter ? FontWeight.bold : FontWeight.normal,
            ),
            avatar: _onlyLiveFilter 
                ? const Icon(Icons.circle, size: 12, color: Colors.red) 
                : null,
          ),
          const SizedBox(width: 8),

          // "Near Me" Quick Filter
          FilterChip(
            label: const Text('Gần tôi'),
            selected: _nearMeFilter,
            onSelected: (bool selected) async {
              if (selected && _currentPosition == null) {
                // Request location
                try {
                  final position = await LocationService.instance.getCurrentPosition();
                  setState(() {
                    _currentPosition = position;
                    _nearMeFilter = true;
                    _selectedClubFilter = null; // Clear club filter if near me is chosen
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không thể lấy vị trí: $e')),
                    );
                  }
                }
              } else {
                setState(() {
                  _nearMeFilter = selected;
                  if (selected) _selectedClubFilter = null;
                });
              }
            },
            selectedColor: Colors.green.withValues(alpha: 0.2),
            checkmarkColor: Colors.green,
            labelStyle: TextStyle(
              color: _nearMeFilter ? Colors.green : Colors.grey[700],
              fontWeight: _nearMeFilter ? FontWeight.bold : FontWeight.normal,
            ),
            avatar: _nearMeFilter 
                ? const Icon(Icons.location_on, size: 12, color: Colors.green) 
                : null,
          ),
          const SizedBox(width: 8),

          // "Club" Filter
          ActionChip(
            avatar: Icon(
              Icons.store,
              size: 16,
              color: _selectedClubFilter != null ? Colors.white : Colors.grey[700],
            ),
            label: Text(
              _selectedClubFilter != null 
                  ? (_selectedClubFilter!['name'] ?? 'CLB')
                  : 'CLB',
              style: TextStyle(
                color: _selectedClubFilter != null ? Colors.white : Colors.grey[700],
                fontWeight: _selectedClubFilter != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            backgroundColor: _selectedClubFilter != null ? Colors.orange : Colors.grey[200],
            onPressed: _showClubFilterModal,
          ),
          const SizedBox(width: 8),

          // "Same Rank" Quick Filter
          if (_currentUserProfile?.rank != null)
            FilterChip(
              label: const Text('Ngang trình'),
              selected: _sameRankFilter,
              onSelected: (bool selected) {
                setState(() {
                  _sameRankFilter = selected;
                  if (selected) {
                    _selectedRankFilter = null; // Clear specific rank if "Same Rank" is chosen
                  }
                });
              },
              selectedColor: Colors.blue.withValues(alpha: 0.2),
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: _sameRankFilter ? Colors.blue : Colors.grey[700],
                fontWeight: _sameRankFilter ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  void _showClubFilterModal() {
    // Extract unique clubs from matches
    final clubsMap = <String, Map<String, dynamic>>{};
    for (final match in _matches) {
      final club = match['club'] as Map<String, dynamic>?;
      if (club != null && club['id'] != null) {
        clubsMap[club['id']] = club;
      }
    }
    final clubs = clubsMap.values.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lọc theo CLB',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (clubs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('Không có CLB nào trong danh sách trận đấu hiện tại')),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: clubs.length,
                        itemBuilder: (context, index) {
                          final club = clubs[index];
                          final isSelected = _selectedClubFilter?['id'] == club['id'];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: club['logo_url'] != null 
                                  ? NetworkImage(club['logo_url']) 
                                  : null,
                              child: club['logo_url'] == null ? const Icon(Icons.store) : null,
                            ),
                            title: Text(club['name'] ?? 'Unknown Club'),
                            subtitle: Text(club['address'] ?? ''),
                            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                            onTap: () {
                              setState(() {
                                _selectedClubFilter = isSelected ? null : club;
                                if (_selectedClubFilter != null) {
                                  _nearMeFilter = false; // Disable "Near Me" if specific club is chosen
                                }
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedClubFilter = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Xóa bộ lọc CLB'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lọc theo hạng (Rank)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // Introduction: Kiểm tra những thứ sẵn có trước khi tự chế thông tin
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 12),
                    child: Text(
                      'Chọn hạng để lọc các trận đấu phù hợp',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RankingConstants.RANK_ORDER.map((rankCode) {
                      final isSelected = _selectedRankFilter == rankCode;
                      final rankName = RankingConstants.RANK_DETAILS[rankCode]?['name'] ?? rankCode;
                      return ChoiceChip(
                        label: Text(rankName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedRankFilter = selected ? rankCode : null;
                            if (selected) {
                              _sameRankFilter = false; // Disable "Same Rank" if specific rank is chosen
                            }
                          });
                          setState(() {}); // Update parent UI
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedRankFilter = null;
                              _sameRankFilter = false;
                              _onlyLiveFilter = false;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build match type tab button
  Widget _buildMatchTypeTab({
    required String label,
    required IconData icon,
    required int count,
    required int index,
    required Color color,
  }) {
    final isActive = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

