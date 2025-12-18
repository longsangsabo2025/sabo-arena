import 'package:flutter/material.dart';
import '../../../../models/club_permission.dart';
import '../../../../widgets/loading_state_widget.dart';
import '../../../../widgets/error_state_widget.dart';
import '../../../../widgets/empty_state_widget.dart';
import '../../../../widgets/avatar_with_quick_follow.dart';

class ClubMembersTab extends StatelessWidget {
  final String clubId;
  final List<ClubMemberWithPermissions> members;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final Function(BuildContext, String) onShowMemberProfile;

  const ClubMembersTab({
    super.key,
    required this.clubId,
    required this.members,
    required this.isLoading,
    this.error,
    required this.onRefresh,
    required this.onShowMemberProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading state
    if (isLoading) {
      return const Center(
        child: LoadingStateWidget(message: 'Đang tải danh sách thành viên...'),
      );
    }

    // Show error state
    if (error != null) {
      return RefreshableErrorStateWidget(
        errorMessage: error!,
        onRefresh: onRefresh,
        title: 'Không thể tải danh sách thành viên',
        showErrorDetails: true,
      );
    }

    // Show empty state
    if (members.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.people_outline,
          message: 'Chưa có thành viên',
          subtitle: 'Câu lạc bộ chưa có thành viên nào',
        ),
      );
    }

    return Column(
      children: [
        // Members list (stats header hidden per user request)
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: members.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                onTap: () => onShowMemberProfile(context, member.userId),
                leading: AvatarWithQuickFollow(
                  userId: member.userId,
                  avatarUrl: member.userAvatar,
                  size: 48,
                  showQuickFollow: true,
                  // onTap: () => onShowMemberProfile(context, member.userId), // AvatarWithQuickFollow handles tap internally to show profile if we don't override it, or we might need to check if it exposes onTap.
                ),
                title: Text(
                  member.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: member.userRank != null
                                ? colorScheme.primary
                                : colorScheme.outline,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member.userRank != null
                                ? 'Rank ${member.userRank}'
                                : 'Chưa xếp hạng',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.userRank != null
                              ? '${member.eloRating ?? 0} ELO'
                              : (member.skillLevel ?? 'N/A'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(member),
                      ],
                    ),
                  ],
                ),
                trailing: null, // Removed online status indicator
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(ClubMemberWithPermissions member) {
    final role = member.role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Color(int.parse(role.badgeColor.replaceFirst('#', '0xFF'))),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            role.icon,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            role.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
