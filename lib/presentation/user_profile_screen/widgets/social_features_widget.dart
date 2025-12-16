import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../models/user_profile.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class SocialFeaturesWidget extends StatelessWidget {
  final Map<String, dynamic> socialData;
  final VoidCallback? onFriendsListTap;
  final VoidCallback? onRecentChallengesTap;
  final VoidCallback? onTournamentHistoryTap;

  const SocialFeaturesWidget({
    super.key,
    required this.socialData,
    this.onFriendsListTap,
    this.onRecentChallengesTap,
    this.onTournamentHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động xã hội',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          // Social Stats Row
          Row(
            children: [
              Expanded(
                child: _buildSocialStatCard(
                  context,
                  title: 'Bạn bè',
                  count: '${socialData["friendsCount"] ?? 127}',
                  icon: 'people',
                  onTap: onFriendsListTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialStatCard(
                  context,
                  title: 'Thách đấu',
                  count: '${socialData["challengesCount"] ?? 45}',
                  icon: 'sports_martial_arts',
                  onTap: onRecentChallengesTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialStatCard(
                  context,
                  title: 'Giải đấu',
                  count: '${socialData["tournamentsCount"] ?? 23}',
                  icon: 'emoji_events',
                  onTap: onTournamentHistoryTap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recent Friends Section
          _buildRecentFriendsSection(context),

          const SizedBox(height: 16),

          // Recent Challenges Section
          _buildRecentChallengesSection(context),
        ],
      ),
    );
  }

  Widget _buildSocialStatCard(
    BuildContext context, {
    required String title,
    required String count,
    required String icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
            bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
            left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
            right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFriendsSection(BuildContext context) {
    final recentFriendsList = socialData["recentFriends"] as List?;
    if (recentFriendsList == null || recentFriendsList.isEmpty)
      return const SizedBox.shrink();

    final recentFriends = <UserProfile>[];
    for (final item in recentFriendsList) {
      try {
        if (item is UserProfile) {
          recentFriends.add(item);
        } else if (item is Map<String, dynamic>) {
          recentFriends.add(UserProfile.fromJson(item));
        }
      } catch (e) {
        ProductionLogger.info('Error parsing friend data: $e', tag: 'social_features_widget');
      }
    }

    if (recentFriends.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bạn bè gần đây',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: onFriendsListTap,
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: recentFriends.length > 5 ? 5 : recentFriends.length,
            itemBuilder: (context, index) {
              final friend = recentFriends[index];
              return _buildFriendCard(context, friend);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendCard(BuildContext context, UserProfile friend) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          // Avatar with Online Status
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl:
                        friend.avatarUrl ??
                        "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Online Status Indicator
              if (friend.isActive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Friend Name
          Text(
            friend.displayName.isNotEmpty
                ? friend.displayName
                : friend.fullName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChallengesSection(BuildContext context) {
    final recentChallenges =
        (socialData["recentChallenges"] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    if (recentChallenges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thách đấu gần đây',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: onRecentChallengesTap,
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: recentChallenges.length > 3 ? 3 : recentChallenges.length,
          itemBuilder: (context, index) {
            final challenge = recentChallenges[index];
            return _buildChallengeCard(context, challenge);
          },
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    Map<String, dynamic> challenge,
  ) {
    final status = challenge["status"] as String? ?? "completed";
    final statusColor = _getChallengeStatusColor(status);
    final statusText = _getChallengeStatusText(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
          right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Opponent Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl:
                    challenge["opponentAvatar"] as String? ??
                    "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Challenge Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${challenge["opponentName"] as String? ?? "Unknown"}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${challenge["gameType"] as String? ?? "8-Ball"} • ${challenge["date"] as String? ?? "Hôm nay"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getChallengeStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return Colors.green;
      case 'lost':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getChallengeStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return 'Thắng';
      case 'lost':
        return 'Thua';
      case 'pending':
        return 'Chờ';
      case 'ongoing':
        return 'Đang đấu';
      default:
        return 'Hoàn thành';
    }
  }
}
