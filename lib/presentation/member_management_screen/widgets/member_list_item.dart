import 'package:flutter/material.dart';
import '../../../models/member_data.dart';
import '../../../core/design_system/design_system.dart';
import '../../../widgets/avatar_with_quick_follow.dart';

class MemberListItem extends StatefulWidget {
  final MemberData member;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final Function(String) onAction;
  final bool showSelection;

  const MemberListItem({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onAction,
    this.showSelection = false,
  });

  @override
  _MemberListItemState createState() => _MemberListItemState();
}

class _MemberListItemState extends State<MemberListItem> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: widget.showSelection
                ? () => widget.onSelectionChanged(!widget.isSelected)
                : () => widget.onAction('view-profile'),
            onLongPress: () => widget.onSelectionChanged(!widget.isSelected),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Animated checkbox appearance
                  AnimatedSize(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: widget.showSelection
                        ? Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Checkbox(
                              value: widget.isSelected,
                              onChanged: (value) =>
                                  widget.onSelectionChanged(value ?? false),
                              activeColor: AppColors.primary,
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                  _buildAvatar(),
                  SizedBox(width: 12),
                  Expanded(child: _buildMemberInfo()),
                  // Hide action button in selection mode
                  if (!widget.showSelection) ...[
                    SizedBox(width: 8),
                    _buildActionButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: AppColors.divider,
          indent: 16,
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    // TODO: Get actual follow status from widget.member.user.isFollowing when available
    const isFollowing = false;

    // Use standard AvatarWithQuickFollow widget (same as Feed Post)
    return AvatarWithQuickFollow(
      userId: widget.member.user.id,
      avatarUrl: widget.member.user.avatar.isNotEmpty
          ? widget.member.user.avatar
          : null,
      size: 48.0, // DSAvatarSize.large = 48px
      isFollowing: isFollowing,
      showQuickFollow: true,
      onFollowChanged: () {
        // Callback when follow status changes
        widget.onAction('follow-changed');
      },
    );
  }

  Widget _buildMemberInfo() {
    final joinDuration = _getJoinDuration();
    final roleLabel = _getRoleLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.member.user.name,
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3),
        Text(
          '$roleLabel · $joinDuration',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 13,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: 3),
            Text(
              'ELO ${widget.member.user.elo}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
            Text(
              ' · ',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              '${(widget.member.activityStats.winRate * 100).toInt()}% thắng',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
      ),
      child: IconButton(
        icon: Icon(Icons.chat_bubble_outline, size: 20),
        color: AppColors.primary,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
        onPressed: () => widget.onAction('message'),
        tooltip: 'Nhắn tin',
      ),
    );
  }

  String _getJoinDuration() {
    final joinDate = widget.member.membershipInfo.joinDate;
    final duration = DateTime.now().difference(joinDate);

    if (duration.inDays < 30) {
      return '${duration.inDays} ngày';
    } else if (duration.inDays < 365) {
      final months = (duration.inDays / 30).floor();
      return '$months tháng';
    } else {
      final years = (duration.inDays / 365).floor();
      return '$years năm';
    }
  }

  String _getRoleLabel() {
    final status = widget.member.membershipInfo.status;
    final type = widget.member.membershipInfo.type;

    if (type.toLowerCase().contains('admin') ||
        type.toLowerCase().contains('owner')) {
      return 'Quản trị viên';
    } else if (type.toLowerCase().contains('vip') ||
        type.toLowerCase().contains('premium')) {
      return 'Thành viên VIP';
    } else if (status == MemberStatus.pending) {
      return 'Chờ duyệt';
    } else {
      return 'Thành viên';
    }
  }
}
