import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/user/user_profile_card.dart';
import '../../../services/club_permission_service.dart';
import '../../../models/club_permission.dart';

class ClubMembersWidget extends StatelessWidget {
  final String clubId; // Add clubId for permission checks
  final List<Map<String, dynamic>> members;
  final bool isOwner;
  final VoidCallback onViewAll;
  final Function(Map<String, dynamic>) onMemberTap;

  const ClubMembersWidget({
    super.key,
    required this.clubId,
    required this.members,
    required this.isOwner,
    required this.onViewAll,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thành viên (${members.length})',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(onPressed: onViewAll, child: Text('Xem tất cả')),
            ],
          ),
          SizedBox(height: 2.h),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: members.length > 5 ? 5 : members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              // Map member data to UserProfileCard format
              final userData = Map<String, dynamic>.from(member);
              if (userData['avatar_url'] == null &&
                  userData['avatar'] != null) {
                userData['avatar_url'] = userData['avatar'];
              }

              return UserProfileCard(
                userData: userData,
                variant: UserCardVariant.list,
                showRank: true,
                showStats: true,
                margin: EdgeInsets.only(bottom: 2.h),
                onTap: () => onMemberTap(member),
                trailing: _buildRoleBadge(member["id"]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String? userId) {
    if (userId == null) return SizedBox.shrink();

    return FutureBuilder<ClubPermission?>(
      future: ClubPermissionService().getUserPermissions(userId, clubId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        final role = snapshot.data!.role;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: Color(int.parse(role.badgeColor.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                role.icon,
                style: TextStyle(fontSize: 10.sp),
              ),
              SizedBox(width: 1.w),
              Text(
                role.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
