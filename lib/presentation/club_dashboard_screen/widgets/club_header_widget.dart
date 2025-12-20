import 'package:flutter/material.dart';
// Temporarily removed AppLocalizations import
import 'package:sabo_arena/core/design_system/design_system.dart';
import 'package:sabo_arena/core/performance/performance_widgets.dart';
import 'package:sabo_arena/models/club.dart';

class ClubHeaderWidget extends StatelessWidget {
  final Club? club;
  final VoidCallback onEditProfile;
  final VoidCallback onEditCover;

  const ClubHeaderWidget({
    super.key,
    required this.club,
    required this.onEditProfile,
    required this.onEditCover,
  });

  @override
  Widget build(BuildContext context) {
    // Temporarily disabled: final l10n = // AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover photo with edit button
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover photo section - 200px height
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(color: AppColors.border),
                child: club?.coverImageUrl != null
                    ? OptimizedImage(
                        imageUrl: club!.coverImageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
              ),
              // Edit cover button
              Positioned(
                bottom: DesignTokens.space12,
                right: DesignTokens.space16,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  elevation: 1,
                  child: InkWell(
                    onTap: onEditCover,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.space12,
                        vertical: DesignTokens.space8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.camera,
                            size: AppIcons.sizeSM,
                            // color: AppColors.textPrimary,
                          ),
                          SizedBox(width: DesignTokens.space8),
                          Text(
                            "Chỉnh sửa",
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Avatar overlapping cover
              Positioned(
                left: DesignTokens.space16,
                bottom: -50, // Overlap down 50px
                child: Stack(
                  clipBehavior: Clip.none, // Allow children to overflow
                  children: [
                    // Avatar with white border
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: club?.profileImageUrl != null
                            ? OptimizedImage(
                                imageUrl: club!.profileImageUrl!,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                alignment: Alignment.center,
                                child: Text(
                                  (club?.name != null && club!.name.isNotEmpty)
                                      ? club!.name.substring(0, 1).toUpperCase()
                                      : 'C',
                                  style: AppTypography.displayLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // Camera icon badge - positioned at bottom right
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onEditProfile,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Space for avatar overlap + info section
          SizedBox(
            height: 60,
          ), // Space for avatar overlap (50px + 10px padding)
          // Club info section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        club?.name ?? "Đang tải...",
                        style: AppTypography.headingLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (club?.isVerified == true) ...[
                      SizedBox(width: DesignTokens.space8),
                      Icon(Icons.verified, color: AppColors.info, size: 20),
                    ],
                  ],
                ),
                SizedBox(height: DesignTokens.space4),
                Text(
                  "Bảng điều khiển quản lý",
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: DesignTokens.space16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
