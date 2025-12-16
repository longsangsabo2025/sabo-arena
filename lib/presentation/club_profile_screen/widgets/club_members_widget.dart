import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/user_display_name.dart';
import '../../../widgets/avatar_with_quick_follow.dart';
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
              return Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar with Quick Follow
                    AvatarWithQuickFollow(
                      userId: member["id"] ?? '',
                      avatarUrl: member["avatar"],
                      size: 12.w,
                      showQuickFollow: true,
                    ),

                    SizedBox(width: 3.w),

                    // Member Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  UserDisplayName.fromMap(member),
                                  style: AppTheme
                                      .lightTheme
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (member["isOnline"] == true)
                                Container(
                                  width: 2.w,
                                  height: 2.w,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Text(
                                member["rank"] ?? "Unranked",
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                      color:
                                          AppTheme.lightTheme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              SizedBox(width: 2.w),
                              _buildRoleBadge(member["id"]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
