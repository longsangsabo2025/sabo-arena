import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/user/user_avatar_widget.dart';

import '../../../core/app_export.dart';
import '../../../models/user_profile.dart';

class ParticipantsListWidget extends StatelessWidget {
  final List<UserProfile> participants;
  final VoidCallback? onViewAllTap;

  const ParticipantsListWidget({
    super.key,
    required this.participants,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E6EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // iOS Facebook style header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    size: 20,
                    color: Color(0xFF050505),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thành viên tham gia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF050505),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${participants.length} người',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF65676B),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E6EB)),
          // Participants list
          if (participants.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.person_off_rounded,
                        size: 32,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có người tham gia',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: participants.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 72,
                color: Color(0xFFE4E6EB),
              ),
              itemBuilder: (context, index) {
                return _buildParticipantItem(participants[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(UserProfile participant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Avatar with rank border
          UserAvatarWidget(
            avatarUrl: participant.avatarUrl,
            userName: participant.displayName,
            rankCode: participant.rank,
            size: 48,
            showRankBorder: true,
            borderWidth: 2,
          ),
          const SizedBox(width: 12),
          // Name and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF050505),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRankColor(participant.rank ?? 'UnRank'),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Rank ${participant.rank ?? 'UnRank'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${participant.eloRating ?? 0} ELO',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF65676B),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chevron icon
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFF8E8E93),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank.toUpperCase()) {
      case 'A':
        return const Color(0xFFFF6B6B);
      case 'B':
        return const Color(0xFFFF9F43);
      case 'C':
        return const Color(0xFFFFD93D);
      case 'D':
        return const Color(0xFF6BCF7F);
      case 'E':
        return const Color(0xFF4ECDC4);
      case 'F':
        return const Color(0xFF45B7D1);
      case 'G':
        return const Color(0xFF96CEB4);
      case 'H':
        return const Color(0xFFA8E6CF);
      case 'I':
        return const Color(0xFFDDA0DD);
      case 'J':
        return const Color(0xFFB19CD9);
      case 'K':
        return const Color(0xFF95A5A6);
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }
}
