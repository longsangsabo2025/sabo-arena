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

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // Load both open challenges and accepted matches for community visibility
      final matches = await _challengeService.getCommunityMatches();

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
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
    return Scaffold(body: _buildBody());
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
                  Tab(text: 'Ready'),
                  Tab(text: 'Complete'),
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
              match: matchData,
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
          } else {
            // Non-live match or no video - use static card
            return MatchCardWidget(
              match: matchData,
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

  /// Get filtered matches by type (thach_dau or giao_luu)
  List<Map<String, dynamic>> _getFilteredMatchesByType(String challengeType) {
    return _matches.where((match) {
      final type = match['challenge_type'] as String?;

      // Map schedule_request to giao_luu (scheduled friendly matches)
      if (challengeType == 'giao_luu') {
        return type == 'giao_luu' || type == 'schedule_request';
      }

      return type == challengeType;
    }).toList();
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

