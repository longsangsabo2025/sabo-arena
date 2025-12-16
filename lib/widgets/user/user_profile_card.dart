import 'package:flutter/material.dart';
import 'user_avatar_widget.dart';
import 'user_display_name_text.dart';
import 'user_rank_badge_widget.dart';

/// 👤 UserProfileCard - Reusable User Card Component
///
/// **Single source of truth** cho việc hiển thị user card trong lists, leaderboards, chat.
///
/// ## Features:
/// - ✅ Unified avatar, name, rank display
/// - ✅ Multiple variants: list, grid, compact
/// - ✅ Optional stats (ELO, wins, tournaments)
/// - ✅ Clickable with navigation
/// - ✅ Custom trailing widget
///
/// ## Usage:
/// ```dart
/// // Basic card
/// UserProfileCard(
///   userData: userMap,
///   onTap: () => navigateToProfile(userId),
/// )
///
/// // Card với stats
/// UserProfileCard(
///   userData: userMap,
///   variant: UserCardVariant.list,
///   showRank: true,
///   showStats: true,
/// )
/// ```
class UserProfileCard extends StatelessWidget {
  /// User data map (từ Supabase hoặc UserProfile.toJson())
  final Map<String, dynamic> userData;

  /// Card variant style
  final UserCardVariant variant;

  /// Callback khi tap vào card
  final VoidCallback? onTap;

  /// Hiển thị rank badge
  final bool showRank;

  /// Hiển thị stats (ELO, wins, etc.)
  final bool showStats;

  /// Custom trailing widget (action button, menu, etc.)
  final Widget? trailing;

  /// Show verified badge on name
  final bool showVerifiedBadge;

  /// Avatar size
  final double? avatarSize;

  /// Card elevation
  final double elevation;

  /// Card margin
  final EdgeInsetsGeometry? margin;

  /// Background color
  final Color? backgroundColor;

  const UserProfileCard({
    super.key,
    required this.userData,
    this.variant = UserCardVariant.list,
    this.onTap,
    this.showRank = true,
    this.showStats = false,
    this.trailing,
    this.showVerifiedBadge = true,
    this.avatarSize,
    this.elevation = 0,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case UserCardVariant.list:
        return _buildListCard();
      case UserCardVariant.compact:
        return _buildCompactCard();
      case UserCardVariant.grid:
        return _buildGridCard();
    }
  }

  /// 📋 List Card Variant - Standard ListTile style
  Widget _buildListCard() {
    final eloRating = userData['elo_rating'] ?? userData['eloRating'];
    final rank = userData['rank'];

    return Card(
      elevation: elevation,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              UserAvatarWidget(
                avatarUrl: userData['avatar_url'] ?? userData['avatarUrl'],
                rankCode: showRank ? rank : null,
                size: avatarSize ?? 56,
                showRankBorder: showRank,
              ),

              const SizedBox(width: 12),

              // Name + Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    UserDisplayNameText(
                      userData: userData,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      showVerifiedBadge: showVerifiedBadge,
                      maxLength: 25,
                    ),

                    const SizedBox(height: 4),

                    // Rank + Stats Row
                    Row(
                      children: [
                        if (showRank && rank != null)
                          UserRankBadgeWidget(
                            rankCode: rank,
                            style: RankBadgeStyle.compact,
                          ),
                        if (showStats && showRank) const SizedBox(width: 8),
                        if (showStats && eloRating != null)
                          Text(
                            '$eloRating ELO',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),

                    // Additional stats
                    if (showStats) ...[
                      const SizedBox(height: 4),
                      _buildStatsRow(),
                    ],
                  ],
                ),
              ),

              // Trailing widget
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Compact Card Variant - Minimal info
  Widget _buildCompactCard() {
    final rank = userData['rank'];

    return Card(
      elevation: elevation,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Avatar (smaller)
              UserAvatarWidget(
                avatarUrl: userData['avatar_url'] ?? userData['avatarUrl'],
                rankCode: showRank ? rank : null,
                size: avatarSize ?? 40,
                showRankBorder: showRank,
              ),

              const SizedBox(width: 10),

              // Name only
              Expanded(
                child: UserDisplayNameText(
                  userData: userData,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  showVerifiedBadge: false,
                  maxLength: 20,
                ),
              ),

              // Rank icon
              if (showRank && rank != null) ...[
                const SizedBox(width: 8),
                UserRankIcon(rankCode: rank, size: 20),
              ],

              // Trailing
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Grid Card Variant - For grid views
  Widget _buildGridCard() {
    final rank = userData['rank'];
    final eloRating = userData['elo_rating'] ?? userData['eloRating'];

    return Card(
      elevation: elevation,
      margin: margin ?? const EdgeInsets.all(8),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar (centered)
              UserAvatarWidget(
                avatarUrl: userData['avatar_url'] ?? userData['avatarUrl'],
                rankCode: showRank ? rank : null,
                size: avatarSize ?? 70,
                showRankBorder: showRank,
              ),

              const SizedBox(height: 12),

              // Name (centered)
              UserDisplayNameText(
                userData: userData,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                showVerifiedBadge: showVerifiedBadge,
                maxLength: 15,
              ),

              const SizedBox(height: 8),

              // Rank badge
              if (showRank && rank != null)
                UserRankBadgeWidget(
                  rankCode: rank,
                  style: RankBadgeStyle.compact,
                ),

              // ELO
              if (showStats && eloRating != null) ...[
                const SizedBox(height: 6),
                Text(
                  '$eloRating ELO',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Trailing widget (bottom)
              if (trailing != null) ...[
                const SizedBox(height: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Stats row widget
  Widget _buildStatsRow() {
    final wins = userData['total_wins'] ?? userData['totalWins'] ?? 0;
    final losses = userData['total_losses'] ?? userData['totalLosses'] ?? 0;
    final tournaments =
        userData['total_tournaments'] ?? userData['totalTournaments'] ?? 0;

    return Row(
      children: [
        _buildStatItem(Icons.emoji_events, '$wins', Colors.green),
        const SizedBox(width: 12),
        _buildStatItem(Icons.close, '$losses', Colors.red),
        const SizedBox(width: 12),
        _buildStatItem(Icons.military_tech, '$tournaments', Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 👤 Card Variant Enum
enum UserCardVariant {
  /// Standard list item (default)
  list,

  /// Compact version cho small lists
  compact,

  /// Grid item cho grid views
  grid,
}

/// 👤 UserProfileListTile - Simple ListTile wrapper
///
/// Drop-in replacement cho ListTile với user data
class UserProfileListTile extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showRank;
  final bool dense;

  const UserProfileListTile({
    super.key,
    required this.userData,
    this.onTap,
    this.trailing,
    this.showRank = true,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final rank = userData['rank'];

    return ListTile(
      dense: dense,
      leading: UserAvatarWidget(
        avatarUrl: userData['avatar_url'] ?? userData['avatarUrl'],
        rankCode: showRank ? rank : null,
        size: dense ? 40 : 50,
        showRankBorder: showRank,
      ),
      title: UserDisplayNameText(
        userData: userData,
        showVerifiedBadge: true,
      ),
      subtitle: showRank && rank != null
          ? UserRankBadgeWidget(
              rankCode: rank,
              style: RankBadgeStyle.compact,
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// 👤 UserProfileChip - Chip style user display
///
/// Dùng cho tags, mentions, selected users
class UserProfileChip extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool showAvatar;

  const UserProfileChip({
    super.key,
    required this.userData,
    this.onTap,
    this.onDeleted,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = UserDisplayNameHelper.getDisplayName(userData);

    return Chip(
      avatar: showAvatar
          ? CircleAvatar(
              child: UserAvatarWidget(
                avatarUrl: userData['avatar_url'] ?? userData['avatarUrl'],
                size: 24,
              ),
            )
          : null,
      label: Text(displayName),
      onDeleted: onDeleted,
      deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 18) : null,
    );
  }
}
