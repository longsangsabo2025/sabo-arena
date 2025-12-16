import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/challenge_list_service.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/loading_state_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../core/design_system/design_system.dart';
import './challenge_card_widget_redesign.dart';
import './challenge_detail_modal.dart';
import './create_spa_challenge_modal.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

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
  bool _showTooltip = false;
  Timer? _tooltipTimer;
  
  // Sub-tab controller
  late TabController _subTabController;
  int _currentSubTab = 0; // 0: Ready, 1: Complete

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
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
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
              address
            )
          ''')
          .eq('challenge_type', 'thach_dau')
          .eq('challenged_id', currentUserId) // ✅ CHỈ lấy challenges MÀ USER LÀ NGƯỜI NHẬN (không phải người gửi)
          .order('created_at', ascending: false)
          .then((response) => response as List<dynamic>)
          .then((list) => list.cast<Map<String, dynamic>>());

      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      for (var i = 0; i < challenges.length && i < 3; i++) {
        final ch = challenges[i];
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }

      ProductionLogger.debug('Debug log', tag: 'AutoFix');

      if (mounted) {
        setState(() {
          _challenges = challenges;
          _isLoading = false;
        });
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
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
      return status == 'pending' || status == 'in_progress';
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

  Widget _buildChallengesList(List<Map<String, dynamic>> challenges, String tabName) {
    ProductionLogger.debug('Debug log', tag: 'AutoFix');

    if (_isLoading) {
      return const LoadingStateWidget(message: 'Đang tải thách đấu...');
    }

    if (_errorMessage != null) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      return ErrorStateWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadChallenges,
      );
    }

    if (challenges.isEmpty) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
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

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
    
    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return ChallengeCardWidgetRedesign(
            challenge: challenge,
            isCompetitive: true,
            onTap: () => _showChallengeDetail(challenge),
          );
        },
      ),
    );
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
}

