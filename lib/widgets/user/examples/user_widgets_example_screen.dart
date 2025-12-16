import 'package:flutter/material.dart';
import '../user_widgets.dart';
import 'package:sabo_arena/utils/production_logger.dart';

/// 🎨 User Widgets Demo Screen
///
/// Screen demo để showcase tất cả user widgets components
class UserWidgetsExampleScreen extends StatelessWidget {
  const UserWidgetsExampleScreen({super.key});

  // Sample user data
  static final Map<String, dynamic> sampleUser1 = {
    'id': '1',
    'display_name': 'Nguyễn Văn A',
    'full_name': 'Nguyễn Văn An',
    'username': 'nguyenvana',
    'avatar_url':
        'https://i.pravatar.cc/150?img=1',
    'rank': 'G',
    'elo_rating': 1650,
    'total_wins': 45,
    'total_losses': 23,
    'total_tournaments': 12,
    'is_verified': true,
  };

  static final Map<String, dynamic> sampleUser2 = {
    'id': '2',
    'display_name': 'Trần Thị B',
    'avatar_url':
        'https://i.pravatar.cc/150?img=5',
    'rank': 'E',
    'elo_rating': 1920,
    'total_wins': 89,
    'total_losses': 34,
    'total_tournaments': 28,
    'is_verified': true,
  };

  static final Map<String, dynamic> unrankedUser = {
    'id': '3',
    'display_name': 'Lê Văn C',
    'avatar_url':
        'https://i.pravatar.cc/150?img=8',
    'rank': null,
    'elo_rating': null,
    'is_verified': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Widgets Demo'),
        backgroundColor: const Color(0xFF00695C),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('1. UserAvatarWidget', _buildAvatarExamples()),
          const SizedBox(height: 24),
          _buildSection('2. UserDisplayNameText', _buildNameExamples()),
          const SizedBox(height: 24),
          _buildSection('3. UserRankBadgeWidget', _buildRankExamples()),
          const SizedBox(height: 24),
          _buildSection('4. UserProfileCard', _buildCardExamples(context)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00695C),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildAvatarExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Basic avatars
            const Text('Basic Avatars:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    UserAvatarWidget(
                      avatarUrl: sampleUser1['avatar_url'],
                      size: 60,
                    ),
                    const SizedBox(height: 4),
                    const Text('Size 60', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    UserAvatarWidget(
                      avatarUrl: sampleUser1['avatar_url'],
                      size: 80,
                    ),
                    const SizedBox(height: 4),
                    const Text('Size 80', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    const UserAvatarWidget(
                      avatarUrl: 'invalid-url',
                      size: 60,
                    ),
                    const SizedBox(height: 4),
                    const Text('Error', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            // Avatars with rank border
            const Text('With Rank Border:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    UserAvatarWidget(
                      avatarUrl: sampleUser1['avatar_url'],
                      rankCode: 'G',
                      size: 80,
                      showRankBorder: true,
                    ),
                    const SizedBox(height: 4),
                    const Text('Rank G', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    UserAvatarWidget(
                      avatarUrl: sampleUser2['avatar_url'],
                      rankCode: 'E',
                      size: 80,
                      showRankBorder: true,
                    ),
                    const SizedBox(height: 4),
                    const Text('Rank E', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            // Avatar with badge
            const Text('With Badges:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    UserAvatarWithBadge(
                      avatarUrl: sampleUser1['avatar_url'],
                      size: 70,
                      badge: const OnlineStatusBadge(isOnline: true),
                    ),
                    const SizedBox(height: 4),
                    const Text('Online', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    UserAvatarWithBadge(
                      avatarUrl: sampleUser1['avatar_url'],
                      size: 70,
                      badge: const VerifiedBadge(),
                    ),
                    const SizedBox(height: 4),
                    const Text('Verified', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Basic Display:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            UserDisplayNameText(userData: sampleUser1),
            const Divider(height: 24),

            const Text('With Verified Badge:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            UserDisplayNameText(
              userData: sampleUser1,
              showVerifiedBadge: true,
            ),
            const Divider(height: 24),

            const Text('Truncated:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            UserDisplayNameText(
              userData: sampleUser1,
              maxLength: 10,
            ),
            const Divider(height: 24),

            const Text('Name + Username:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            UserNameWithUsername(
              userData: sampleUser1,
              showVerifiedBadge: true,
            ),
            const Divider(height: 24),

            const Text('Helper Functions:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Full: ${UserDisplayNameHelper.getDisplayName(sampleUser1)}'),
            Text('Short: ${UserDisplayNameHelper.getShortDisplayName(sampleUser1, maxLength: 10)}'),
            Text('First: ${UserDisplayNameHelper.getFirstName(sampleUser1)}'),
            Text('Initials: ${UserDisplayNameHelper.getInitials(sampleUser1)}'),
            Text('Username: ${UserDisplayNameHelper.getUsername(sampleUser1)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRankExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compact Style:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                UserRankBadgeWidget(
                  rankCode: 'K',
                  style: RankBadgeStyle.compact,
                ),
                UserRankBadgeWidget(
                  rankCode: 'G',
                  style: RankBadgeStyle.compact,
                ),
                UserRankBadgeWidget(
                  rankCode: 'E',
                  style: RankBadgeStyle.compact,
                ),
                UserRankBadgeWidget(
                  rankCode: 'C',
                  style: RankBadgeStyle.compact,
                ),
              ],
            ),
            const Divider(height: 24),

            const Text('Standard Style:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            UserRankBadgeWidget(
              rankCode: 'G',
              showFullName: true,
              eloRating: 1650,
            ),
            const SizedBox(height: 8),
            UserRankBadgeWidget(
              rankCode: 'E',
              showFullName: true,
              eloRating: 1920,
            ),
            const Divider(height: 24),

            const Text('Unranked:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            UserRankBadgeWidget(
              rankCode: null,
              onTap: () => ProductionLogger.info('Show rank registration'),
            ),
            const Divider(height: 24),

            const Text('Rank Icon:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                UserRankIcon(rankCode: 'K', size: 30),
                const SizedBox(width: 12),
                UserRankIcon(rankCode: 'G', size: 30),
                const SizedBox(width: 12),
                UserRankIcon(rankCode: 'E', size: 30),
                const SizedBox(width: 12),
                UserRankIcon(rankCode: null, size: 30),
              ],
            ),
            const Divider(height: 24),

            const Text('Rank Comparison:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RankComparisonWidget(
              player1Rank: 'G',
              player2Rank: 'E',
              player1Name: 'Nguyễn Văn A',
              player2Name: 'Trần Thị B',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardExamples(BuildContext context) {
    return Column(
      children: [
        const Text('List Variant:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        UserProfileCard(
          userData: sampleUser1,
          variant: UserCardVariant.list,
          showRank: true,
          showStats: true,
          onTap: () => _showToast(context, 'Tapped user 1'),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showToast(context, 'More menu'),
          ),
        ),
        const SizedBox(height: 8),
        UserProfileCard(
          userData: sampleUser2,
          variant: UserCardVariant.list,
          showRank: true,
          showStats: true,
          onTap: () => _showToast(context, 'Tapped user 2'),
        ),
        const SizedBox(height: 16),

        const Text('Compact Variant:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        UserProfileCard(
          userData: sampleUser1,
          variant: UserCardVariant.compact,
          showRank: true,
          onTap: () => _showToast(context, 'Compact card'),
        ),
        const SizedBox(height: 16),

        const Text('Grid Variant:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: UserProfileCard(
                userData: sampleUser1,
                variant: UserCardVariant.grid,
                showRank: true,
                showStats: true,
                onTap: () => _showToast(context, 'Grid card 1'),
              ),
            ),
            Expanded(
              child: UserProfileCard(
                userData: sampleUser2,
                variant: UserCardVariant.grid,
                showRank: true,
                showStats: true,
                onTap: () => _showToast(context, 'Grid card 2'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text('Unranked User:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        UserProfileCard(
          userData: unrankedUser,
          variant: UserCardVariant.list,
          showRank: true,
          onTap: () => _showToast(context, 'Unranked user'),
        ),
        const SizedBox(height: 16),

        const Text('ListTile Wrapper:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          child: UserProfileListTile(
            userData: sampleUser1,
            showRank: true,
            onTap: () => _showToast(context, 'ListTile tapped'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Chip Style:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            UserProfileChip(
              userData: sampleUser1,
              showAvatar: true,
              onDeleted: () => _showToast(context, 'Deleted user 1'),
            ),
            UserProfileChip(
              userData: sampleUser2,
              showAvatar: true,
              onDeleted: () => _showToast(context, 'Deleted user 2'),
            ),
          ],
        ),
      ],
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
