import 'package:flutter/material.dart';
import '../../../widgets/common/app_button.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/challenge_list_service.dart';
import '../../../services/opponent_tab_backend_service.dart';
import '../../../models/user_profile.dart';
import '../../../widgets/loading_state_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../core/design_system/design_system.dart';
// Use redesigned card
import './challenge_detail_modal.dart';
import './create_social_challenge_modal.dart';
import './schedule_match_modal.dart';
import '../../user_profile_screen/widgets/match_card_widget.dart';
import '../../../utils/challenge_to_match_converter.dart';
// ELON_MODE_AUTO_FIX

/// Tab to display social invites (giao lưu) - both open and user's challenges
/// Sub-tabs: Ready (pending/accepted) và Complete (completed)
class SocialInvitesTab extends StatefulWidget {
  const SocialInvitesTab({super.key});

  @override
  State<SocialInvitesTab> createState() => _SocialInvitesTabState();
}

class _SocialInvitesTabState extends State<SocialInvitesTab>
    with SingleTickerProviderStateMixin {
  final ChallengeListService _challengeService = ChallengeListService.instance;
  final OpponentTabBackendService _opponentService =
      OpponentTabBackendService();
  List<Map<String, dynamic>> _invites = [];
  // int _currentSubTab = 0;
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _opponents = [];
  bool _isLoading = true;
  String? _errorMessage;

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
    _loadInvites();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load ALL social challenges where user is involved (challenger or challenged)
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      // Load challenges, current user, and opponents in parallel
      final results = await Future.wait([
        supabase
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
            .eq('challenge_type', 'giao_luu')
            .eq('challenged_id',
                currentUserId) // ✅ CHỈ lấy invites MÀ USER LÀ NGƯỜI NHẬN (không phải người gửi)
            .order('created_at', ascending: false)
            .then((response) => response as List<dynamic>)
            .then((list) => list.cast<Map<String, dynamic>>()),
        _challengeService.getCurrentUser(),
        _loadOpponents(),
      ]);

      if (mounted) {
        setState(() {
          _invites = results[0] as List<Map<String, dynamic>>;
          _currentUser = results[1] as Map<String, dynamic>?;
          _opponents = results[2] as List<Map<String, dynamic>>;
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

  Future<List<Map<String, dynamic>>> _loadOpponents() async {
    try {
      // Get user's location (default to center if unavailable)
      const double defaultLat = 21.0285; // Hanoi coordinates
      const double defaultLng = 105.8542;

      final opponents = await _opponentService.testGetNearbyPlayers(
        latitude: defaultLat,
        longitude: defaultLng,
        radiusKm: 50, // 50km radius
      );

      return opponents;
    } catch (e) {
      return [];
    }
  }

  void _showInviteDetail(Map<String, dynamic> invite) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChallengeDetailModal(
        challenge: invite,
        isCompetitive: false,
        onAccepted: _loadInvites,
        onDeclined: _loadInvites,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter challenges by status
    // Ready: pending, accepted, in_progress (đang chờ hoặc đang thi đấu)
    // Complete: completed (đã hoàn thành)
    final readyInvites = _invites.where((invite) {
      final status = invite['status'] as String?;

      // Basic status check
      final isStatusReady = status == 'pending' ||
          status == 'accepted' ||
          status == 'in_progress';
      if (!isStatusReady) return false;

      // ✅ Filter out past matches (older than 24h)
      if (status != 'in_progress') {
        final scheduledTimeStr = invite['scheduled_time'] as String? ??
            (invite['match_conditions'] is Map
                ? invite['match_conditions']['scheduled_time']
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

        // Also check created_at for pending invites that are too old (e.g. > 30 days)
        // to prevent cluttering with stale invites
        if (status == 'pending') {
          final createdAtStr = invite['created_at'] as String?;
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

    final completedInvites = _invites.where((invite) {
      final status = invite['status'] as String?;
      return status == 'completed';
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
                      Text('Sắp diễn ra (${readyInvites.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 18),
                      const SizedBox(width: 8),
                      Text('Hoàn thành (${completedInvites.length})'),
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
                _buildInvitesList(readyInvites, 'Ready'),

                // Complete tab
                _buildInvitesList(completedInvites, 'Complete'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        child: FloatingActionButton.extended(
          heroTag: 'social_invites_create',
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
      ),
    );
  }

  Widget _buildInvitesList(List<Map<String, dynamic>> invites, String tabName) {
    if (_isLoading) {
      return const LoadingStateWidget(message: 'Đang tải lời mời giao lưu...');
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadInvites,
      );
    }

    if (invites.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: tabName == 'Ready' ? Icons.schedule : Icons.check_circle,
          message: tabName == 'Ready'
              ? 'Không có giao lưu đang chờ'
              : 'Chưa có giao lưu hoàn thành',
          subtitle: tabName == 'Ready'
              ? 'Các lời mời giao lưu sẽ hiển thị ở đây'
              : 'Các trận giao lưu đã xong sẽ hiển thị ở đây',
          actionLabel: 'Làm mới',
          onAction: _loadInvites,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvites,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: invites.length,
        itemBuilder: (context, index) {
          final invite = invites[index];

          // Convert to match data for MatchCardWidget
          final matchData = ChallengeToMatchConverter.convert(
            invite,
            currentUserId: Supabase.instance.client.auth.currentUser?.id,
          );

          return MatchCardWidget(
            matchMap: matchData,
            onTap: () => _showInviteDetail(invite),
            bottomAction: _buildActionButtons(invite),
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
              label: 'Nhận giao lưu',
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
              customColor: const Color(0xFF7B1FA2), // Purple for social
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
              customColor: const Color(0xFF7B1FA2), // Purple for social
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
          const SnackBar(content: Text('Đã chấp nhận giao lưu!')),
        );
        _loadInvites();
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

  void _showCreateSocialModal() {
    // Convert Map to UserProfile
    UserProfile? currentUserProfile;
    if (_currentUser != null) {
      try {
        currentUserProfile = UserProfile.fromJson(_currentUser!);
      } catch (e) {
        // Ignore error
      }
    }

    // Convert List<Map> to List<UserProfile>
    final List<UserProfile> opponentProfiles = _opponents
        .map((opponentMap) {
          try {
            return UserProfile.fromJson(opponentMap);
          } catch (e) {
            return null;
          }
        })
        .whereType<UserProfile>()
        .toList();

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
}
