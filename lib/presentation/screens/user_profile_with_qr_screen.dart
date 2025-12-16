import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import 'package:sabo_arena/presentation/widgets/user_qr_code_widget.dart';
import 'package:sabo_arena/models/user_profile.dart';

/// Ví dụ tích hợp UserQRCodeWidget vào UserProfileScreen
class UserProfileScreen extends StatelessWidget {
  final UserProfile user;
  final bool isCurrentUser;

  const UserProfileScreen({
    super.key,
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.fullName),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => _showQRCodeDialog(context),
              tooltip: 'Hiển thị mã QR của tôi',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin user
            _buildUserInfo(),

            const SizedBox(height: 24),

            // QR Code section (chỉ hiển thị cho user hiện tại)
            if (isCurrentUser) ...[
              const Text(
                'Mã QR của bạn', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chia sẻ mã QR này để bạn bè có thể kết nối với bạn dễ dàng hơn', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // QR Code Widget
              UserQRCodeWidget(user: user, size: 180, showShareButton: true),

              const SizedBox(height: 24),
            ],

            // Các thông tin khác của user...
            _buildUserStats(),
          ],
        ),
      ),
      floatingActionButton: isCurrentUser
          ? FloatingActionButton.extended(
              onPressed: () => _shareProfile(context),
              icon: const Icon(Icons.share),
              label: const Text('Chia sẻ hồ sơ'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildUserInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            UserAvatarWidget(
              avatarUrl: user.avatarUrl,
              size: 80,
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (user.username != null) ...[
              const SizedBox(height: 4),
              Text(
                '@${user.username}', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSkillLevelColor(user.skillLevel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getSkillLevelText(user.skillLevel),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Thắng', user.totalWins.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Thua', user.totalLosses.toString()),
                ),
                Expanded(
                  child: _buildStatItem(
                    'ELO',
                    user.eloRating?.toString() ?? 'Chưa xếp hạng',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Color _getSkillLevelColor(String skillLevel) {
    switch (skillLevel.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      case 'professional':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getSkillLevelText(String skillLevel) {
    switch (skillLevel.toLowerCase()) {
      case 'beginner':
        return 'Người mới';
      case 'intermediate':
        return 'Trung bình';
      case 'advanced':
        return 'Nâng cao';
      case 'professional':
        return 'Chuyên nghiệp';
      default:
        return skillLevel;
    }
  }

  Future<void> _showQRCodeDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: UserQRCodeWidget(
              user: user,
              size: 250,
              showShareButton: true,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareProfile(BuildContext context) async {
    final shareText =
        '''
🏆 ${user.fullName} - Cầu thủ billiards trên SABO ARENA

📊 Thống kê:
• ELO: ${user.eloRating ?? 'Chưa xếp hạng'}
• Thắng: ${user.totalWins} trận
• Thua: ${user.totalLosses} trận
• Giải đấu: ${user.totalTournaments} giải

🎯 Trình độ: ${_getSkillLevelText(user.skillLevel)}

Kết nối với tôi để thách đấu!
📱 Tải app: https://saboarena.com/download
''';

    await Share.share(shareText, subject: 'Hồ sơ cầu thủ: ${user.fullName}');
  }
}
