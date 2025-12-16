import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/loading_state_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../user_profile_screen/widgets/match_card_widget.dart';
import '../../user_profile_screen/widgets/match_card_widget_realtime.dart';
import '../../user_profile_screen/widgets/score_input_dialog.dart';
import '../../../utils/challenge_to_match_converter.dart';
import '../../../presentation/live_stream/live_stream_player_screen.dart';
import '../../../services/share_service.dart';
import '../../../services/challenge_management_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Tab "Của tôi" - Hiển thị TẤT CẢ challenges mà user tạo hoặc tham gia
/// CHỈ DÙNG BẢNG CHALLENGES, KHÔNG CẦN BẢNG MATCHES!
/// Sub-tabs: Ready (pending/accepted) và Complete (completed)
class MyChallengesTab extends StatefulWidget {
  const MyChallengesTab({super.key});

  @override
  State<MyChallengesTab> createState() => _MyChallengesTabState();
}

class _MyChallengesTabState extends State<MyChallengesTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _challengeManagementService = ChallengeManagementService();
  int _currentSubTab = 0;

  List<Map<String, dynamic>> _allChallenges = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Sub-tab controller
  late TabController _subTabController;

  @override
  bool get wantKeepAlive => true;
  
  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _subTabController.addListener(() {
      if (_subTabController.indexIsChanging) {
        setState(() {
          _currentSubTab = _subTabController.index;
        });
      }
    });
    _loadMyChallenges();
    // Removed auto-refresh to improve UX - user can pull-to-refresh manually
  }

  Future<void> _loadMyChallenges() async {
    try {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('Vui lòng đăng nhập để xem dữ liệu của bạn');
      }

      // Get ALL challenges của user (mọi status: pending, accepted, completed...)
      // TEMPORARY: Removed match join due to PostgREST schema cache not yet recognizing challenge_id FK
      // Will be re-added once cache refreshes (5-10 minutes)
      final challengesResponse = await _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!fk_challenges_challenger_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating
            ),
            challenged:users!fk_challenges_challenged_id(
              id,
              display_name,
              avatar_url,
              rank,
              elo_rating
            ),
            club:clubs(
              id,
              name,
              address,
              logo_url
            )
          ''')
          .or(
            'challenger_id.eq.${currentUser.id},challenged_id.eq.${currentUser.id}',
          )
          .order('created_at', ascending: false);

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      // WORKAROUND: Fetch matches separately since schema cache hasn't recognized FK yet
      // Get all challenge IDs that are accepted
      final challengeIds = challengesResponse
          .where((c) => c['status'] == 'accepted')
          .map((c) => c['id'] as String)
          .toList();

      Map<String, dynamic> matchesMap = {};
      
      if (challengeIds.isNotEmpty) {
        try {
          ProductionLogger.debug('Debug log', tag: 'AutoFix');
          final matchesResponse = await _supabase
              .from('matches')
              .select('id, challenge_id, status, is_live, video_urls, player1_score, player2_score')
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
      final challenges = List<Map<String, dynamic>>.from(challengesResponse);
      for (var challenge in challenges) {
        final challengeId = challenge['id'];
        if (matchesMap.containsKey(challengeId)) {
          challenge['match'] = matchesMap[challengeId];
        }
      }

      // Debug: Show challenge statuses
      if (challenges.isNotEmpty) {
        final statusCounts = <String, int>{};
        for (var challenge in challenges) {
          final status = challenge['status'] as String? ?? 'unknown';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      if (mounted) {
        setState(() {
          _allChallenges = challenges;
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

    if (_isLoading) {
      return const LoadingStateWidget(message: 'Đang tải...');
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadMyChallenges,
      );
    }

    if (_allChallenges.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.sports_esports_outlined,
          message: 'Chưa có trận đấu nào',
          subtitle: 'Tạo thách đấu hoặc tham gia giao lưu để bắt đầu!',
          actionLabel: 'Làm mới',
          onAction: _loadMyChallenges,
        ),
      );
    }

    // Filter challenges by status
    final readyChallenges = _allChallenges.where((challenge) {
      final status = challenge['status'] as String?;
      return status == 'pending' || status == 'accepted';
    }).toList();

    final completedChallenges = _allChallenges.where((challenge) {
      final status = challenge['status'] as String?;
      return status == 'completed';
    }).toList();

    return Column(
      children: [
        // Sub-tabs header
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _subTabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    const SizedBox(width: 8),
                    Text('Ready (${readyChallenges.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 18),
                    const SizedBox(width: 8),
                    Text('Complete (${completedChallenges.length})'),
                  ],
                ),
              ),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
        ),
        
        // Sub-tabs content
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // Ready tab
              _buildChallengesList(readyChallenges, 'Ready'),
              
              // Complete tab
              _buildChallengesList(completedChallenges, 'Complete'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallengesList(List<Map<String, dynamic>> challenges, String tabName) {
    if (challenges.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: tabName == 'Ready' ? Icons.schedule : Icons.check_circle,
          message: tabName == 'Ready' 
              ? 'Không có trận đấu đang chờ'
              : 'Chưa có trận đấu hoàn thành',
          subtitle: tabName == 'Ready'
              ? 'Các trận đang chờ hoặc đang diễn ra sẽ hiển thị ở đây'
              : 'Các trận đã nhập tỷ số xong sẽ hiển thị ở đây',
          actionLabel: 'Làm mới',
          onAction: _loadMyChallenges,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          // Challenge card - Convert using unified converter
          final challenge = challenges[index];
          final matchData = ChallengeToMatchConverter.convert(
            challenge,
            currentUserId: _supabase.auth.currentUser?.id,
          );

          // Extract match info to check if live
          final matchRaw = challenge['match'];
          Map<String, dynamic>? match;

          if (matchRaw is List && matchRaw.isNotEmpty) {
            match = matchRaw[0] as Map<String, dynamic>?;
          } else if (matchRaw is Map<String, dynamic>) {
            match = matchRaw;
          }

          final isLive = match?['is_live'] as bool? ?? false;
          final matchStatus = match?['status'] as String? ?? 'pending';
          final hasVideoUrls = match?['video_urls'] != null &&
              (match!['video_urls'] as List).isNotEmpty;

          // Conditional rendering based on match status and live flag
          if ((matchStatus == 'in_progress' || isLive) && hasVideoUrls) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: MatchCardWidgetRealtime(
                match: matchData,
                onWatchLive: () {
                  ProductionLogger.debug('Debug log', tag: 'AutoFix');

                  // Extract video URL from match data
                  final videoUrls = match?['video_urls'] as List?;
                  if (videoUrls != null && videoUrls.isNotEmpty) {
                    final videoUrl = videoUrls[0] as String;

                    // Navigate to LiveStreamPlayerScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveStreamPlayerScreen(
                          videoUrl: videoUrl,
                        ),
                      ),
                    );
                  } else {
                    ProductionLogger.debug('Debug log', tag: 'AutoFix');
                  }
                },
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: MatchCardWidget(
                match: matchData,
                onTap: () {
                  ProductionLogger.debug('Debug log', tag: 'AutoFix');
                  // TODO: Navigate to challenge detail
                },
                onShareTap: () => _shareMatch(matchData),
                onInputScore: matchStatus != 'completed' 
                    ? () => _showScoreInputDialog(matchData)
                    : null,
              ),
            );
          }
        },
      ),
    );
  }

  /// Show score input dialog for club owner
  Future<void> _showScoreInputDialog(Map<String, dynamic> match) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScoreInputDialog(match: match),
    );

    if (result != null && mounted) {
      final player1Score = result['player1Score'] as int;
      final player2Score = result['player2Score'] as int;
      final winnerId = result['winnerId'] as String?;

      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Complete challenge with scores (not match - challenges are independent)
        await _challengeManagementService.completeChallenge(
          challengeId: match['id'] ?? match['challengeId'],
          winnerId: winnerId ?? match['player1_id'] ?? match['player1Id'],
          player1Score: player1Score,
          player2Score: player2Score,
        );

        // Close loading
        if (mounted) Navigator.pop(context);

        // Reload challenges
        await _loadMyChallenges();

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã cập nhật tỷ số: $player1Score-$player2Score'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Close loading
        if (mounted) Navigator.pop(context);

        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi cập nhật: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _shareMatch(Map<String, dynamic> match) async {
    try {
      final player1Name = match['player1Name'] as String? ?? 'Player 1';
      final player2Name = match['player2Name'] as String? ?? 'Player 2';
      final score1 = match['score1'] as String? ?? '?';
      final score2 = match['score2'] as String? ?? '?';
      final score = '$score1 - $score2';
      final winner = score1 != '?' && score2 != '?' 
        ? (int.tryParse(score1) ?? 0) > (int.tryParse(score2) ?? 0) 
          ? player1Name 
          : player2Name
        : 'TBD';
      final date = match['date'] as String? ?? '';
      final matchId = match['id'] as String?;
      
      await ShareService.shareMatchResult(
        player1Name: player1Name,
        player2Name: player2Name,
        score: score,
        winner: winner,
        matchDate: date,
        matchId: matchId,
      );
    } catch (e) {
      if (kDebugMode) ProductionLogger.info('❌ Error sharing match: $e', tag: 'my_challenges_tab');
    }
  }
}

