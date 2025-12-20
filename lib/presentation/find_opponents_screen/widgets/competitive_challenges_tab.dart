import 'package:flutter/material.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/challenge_list_service.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/loading_state_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../core/design_system/design_system.dart';
import './challenge_detail_modal.dart';
import './create_spa_challenge_modal.dart';
import './schedule_match_modal.dart';
import '../../user_profile_screen/widgets/match_card_widget.dart';
import '../../../utils/challenge_to_match_converter.dart';
// ELON_MODE_AUTO_FIX

/// Tab to display competitive challenges (thách đấu) sent TO current user
/// Sub-tabs: Ready (pending/accepted) và Complete (completed)
class CompetitiveChallengesTab extends StatefulWidget {
  const CompetitiveChallengesTab({super.key});

  @override
  State<CompetitiveChallengesTab> createState() =>
      _CompetitiveChallengesTabState();
}

class _CompetitiveChallengesTabState extends State<CompetitiveChallengesTab>
    with SingleTickerProviderStateMixin {
  final ChallengeListService _challengeService = ChallengeListService.instance;
  List<Map<String, dynamic>> _challenges = [];
  bool _isLoading = true;
  String? _errorMessage;
  // int _currentSubTab = 0;
  bool _showTooltip = false;
  Timer? _tooltipTimer;

  // Sub-tab controller
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _subTabController.addListener(() {
      if (_subTabController.indexIsChanging) {
        setState(() {
          // _currentSubTab = _subTabController.index;
        });
      }
    });
    _loadChallenges();
    // Hiển thị tooltip tạm thởi khi vào tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _showTooltip = true);
      _tooltipTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _showTooltip = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load ALL competitive challenges where user is involved (challenger or challenged)
      // This includes: pending, accepted, in_progress, completed
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final challenges = await supabase
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
          .eq('challenge_type', 'thach_dau')
          .eq('challenged_id',
              currentUserId) // ✅ CHỈ lấy challenges MÀ USER LÀ NGƯỜI NHẬN (không phải người gửi)
          .order('created_at', ascending: false)
          .then((response) => response as List<dynamic>)
          .then((list) => list.cast<Map<String, dynamic>>());

      for (var i = 0; i < challenges.length && i < 3; i++) {}

      if (mounted) {
        setState(() {
          _challenges = challenges;
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

  void _showChallengeDetail(Map<String, dynamic> challenge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChallengeDetailModal(
        challenge: challenge,
        isCompetitive: true,
        onAccepted: _loadChallenges,
        onDeclined: _loadChallenges,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter challenges by status
    // Ready: ONLY pending & in_progress (chưa accept hoặc đang thi đấu)
    // Complete: accepted & completed (đã accept = đã hẹn, hoặc đã hoàn thành)
    final readyChallenges = _challenges.where((challenge) {
      final status = challenge['status'] as String?;
      // ✅ CHỈ hiển thị pending (chờ accept) và in_progress (đang thi đấu)
      // ❌ KHÔNG hiển thị accepted (đã hẹn rồi, không cần hiển thị nữa)
      final isStatusReady = status == 'pending' || status == 'in_progress';
      if (!isStatusReady) return false;

      // ✅ Filter out past matches (older than 24h)
      if (status != 'in_progress') {
        final scheduledTimeStr = challenge['scheduled_time'] as String? ??
            (challenge['match_conditions'] is Map
                ? challenge['match_conditions']['scheduled_time']
                : null) as String?;

        if (scheduledTimeStr != null) {
          final scheduledTime = DateTime.tryParse(scheduledTimeStr);
          if (scheduledTime != null) {
            // If scheduled time is older than 24 hours, hide it
            if (scheduledTime
                .isBefore(DateTime.now().subtract(const Duration(hours: 24)))) {
              return false;
            }
          }
        }

        // Also check created_at for pending challenges that are too old (e.g. > 30 days)
        if (status == 'pending') {
          final createdAtStr = challenge['created_at'] as String?;
          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null &&
                createdAt.isBefore(
                    DateTime.now().subtract(const Duration(days: 30)))) {
              return false;
            }
          }
        }
      }

      return true;
    }).toList();

    final completedChallenges = _challenges.where((challenge) {
      final status = challenge['status'] as String?;
      // ✅ Hiển thị cả accepted (đã hẹn) và completed (đã hoàn thành)
      return status == 'accepted' || status == 'completed';
    }).toList();

    return Scaffold(
      body: Column(
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
                      Text('Sắp diễn ra (${readyChallenges.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 18),
                      const SizedBox(width: 8),
                      Text('Hoàn thành (${completedChallenges.length})'),
                    ],
                  ),
                ),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: AppColors.textTertiary,
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
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        child: FloatingActionButton(
          heroTag: 'competitive_challenges_create',
          onPressed: _showCreateChallengeModal,
          backgroundColor: AppColors.info, // Xanh đậm chủ đạo
          foregroundColor: AppColors.textOnPrimary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Bo góc nhẹ
          ),
          tooltip: _showTooltip ? 'Tạo thách đấu' : null,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'assets/images/icon8ball.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengesList(
      List<Map<String, dynamic>> challenges, String tabName) {
    if (_isLoading) {
      return const LoadingStateWidget(message: 'Đang tải thách đấu...');
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadChallenges,
      );
    }

    if (challenges.isEmpty) {
      return EmptyStateWidget(
        icon: tabName == 'Ready' ? Icons.schedule : Icons.check_circle,
        message: tabName == 'Ready'
            ? 'Không có thách đấu đang chờ'
            : 'Chưa có thách đấu hoàn thành',
        subtitle: tabName == 'Ready'
            ? 'Các thách đấu từ người chơi khác sẽ hiển thị ở đây'
            : 'Các trận đã nhập tỷ số xong sẽ hiển thị ở đây',
        actionLabel: 'Làm mới',
        onAction: _loadChallenges,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];

          // Convert to match data for MatchCardWidget
          final matchData = ChallengeToMatchConverter.convert(
            challenge,
            currentUserId: Supabase.instance.client.auth.currentUser?.id,
          );

          return MatchCardWidget(
            matchMap: matchData,
            onTap: () => _showChallengeDetail(challenge),
            bottomAction: _buildActionButtons(challenge),
          );
        },
      ),
    );
  }

  Widget? _buildActionButtons(Map<String, dynamic> challenge) {
    final status = challenge['status'] as String? ?? 'pending';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final challengedId = challenge['challenged_id'] as String?;

    // Only show buttons for pending challenges where I am the challenged user
    if (status == 'pending' && currentUserId == challengedId) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Nhận thách đấu',
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
              customColor: const Color(0xFF00695C), // Brand teal green
              customTextColor: Colors.white,
              fullWidth: true,
              onPressed: () => _acceptChallenge(challenge),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'Hẹn lịch',
              type: AppButtonType.outline,
              size: AppButtonSize.medium,
              customColor: const Color(0xFF00695C), // Brand teal green
              fullWidth: true,
              onPressed: () {
                final challenger =
                    challenge['challenger'] as Map<String, dynamic>?;
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
                }
              },
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
        _loadChallenges();
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

  Future<void> _showCreateChallengeModal() async {
    // Get current user from Supabase
    final currentUserData = await _challengeService.getCurrentUser();
    if (currentUserData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải thông tin người dùng')),
        );
      }
      return;
    }

    // Convert to UserProfile
    final currentUser = UserProfile.fromJson(currentUserData);

    // Get challenge-eligible opponents
    final opponentsData =
        await _challengeService.getChallengeEligibleOpponents();
    final opponents =
        opponentsData.map((data) => UserProfile.fromJson(data)).toList();

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
}
