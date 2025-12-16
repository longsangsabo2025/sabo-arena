import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../widgets/error_state_widget.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_state_widget.dart';
import '../../../core/design_system/design_system.dart';
import './player_card_widget.dart';
import './create_social_challenge_modal.dart';

class SocialPlayTab extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<UserProfile> players;
  final bool isMapView;
  final VoidCallback onRefresh;

  const SocialPlayTab({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.players,
    required this.isMapView,
    required this.onRefresh,
  });

  @override
  State<SocialPlayTab> createState() => _SocialPlayTabState();
}

class _SocialPlayTabState extends State<SocialPlayTab> {
  void _showCreateSocialChallengeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CreateSocialChallengeModal(opponents: widget.players),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: _buildBody(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'social_play_create_challenge',
        onPressed: _showCreateSocialChallengeModal,
        backgroundColor: AppColors.success700, // Consistent dark green
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Tạo giao lưu'),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return const LoadingStateWidget(
        message: 'Đang tìm người chơi để giao lưu...',
      );
    }

    if (widget.errorMessage != null) {
      return RefreshableErrorStateWidget(
        errorMessage: widget.errorMessage,
        onRefresh: () async => widget.onRefresh(),
        title: 'Không thể tìm người chơi',
        description: 'Đã xảy ra lỗi khi tìm kiếm người chơi gần bạn',
        showErrorDetails: true,
      );
    }

    if (widget.players.isEmpty) {
      return RefreshableEmptyStateWidget(
        message: 'Chưa có người chơi nào',
        subtitle: 'Thử mở rộng phạm vi tìm kiếm hoặc thay đổi bộ lọc',
        icon: Icons.people_outline,
        onRefresh: () async => widget.onRefresh(),
      );
    }

    return Column(
      children: [
        // Info banner for social play
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info100),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giao lưu thân thiện',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.info700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tìm đối thủ để chơi casual, học hỏi kinh nghiệm',
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Players list (map view disabled for privacy)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            itemCount: widget.players.length,
            itemBuilder: (context, index) {
              return PlayerCardWidget(
                player: widget.players[index],
                mode: 'giao_luu',
              );
            },
          ),
        ),
      ],
    );
  }
}

// Enum to distinguish play types
enum PlayType {
  social, // Giao lưu thân thiện
  competitive, // Thách đấu ranked
}
