import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';

import '../../../core/app_export.dart' hide AppColors, AppTheme;
import '../../../core/design_system/design_system.dart';
import '../../../core/utils/sabo_rank_system.dart';
import '../../../core/constants/ranking_constants.dart';

import './rank_registration_info_modal.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onEditProfile;
  final VoidCallback? onCoverPhotoTap;
  final VoidCallback? onAvatarTap;

  const ProfileHeaderWidget({
    super.key,
    required this.userData,
    this.onEditProfile,
    this.onCoverPhotoTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(
              alpha: 0.1,
            ),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Photo Section
          _buildCoverPhotoSection(context),

          // Profile Info Section
          _buildProfileInfoSection(context),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildCoverPhotoSection(BuildContext context) {
    return SizedBox(
      height: 25.h,
      width: double.infinity,
      child: Stack(
        children: [
          // Cover Photo
          GestureDetector(
            onTap: onCoverPhotoTap,
            child: Container(
              height: 20.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: _buildImageWidget(
                  imageUrl:
                      userData["coverPhoto"] as String? ??
                      "https://images.pexels.com/photos/1040473/pexels-photo-1040473.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                  width: double.infinity,
                  height: 20.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Cover Photo Edit Button Only
          Positioned(
            top: 2.h,
            right: 4.w,
            child: GestureDetector(
              onTap: onCoverPhotoTap,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(
                    alpha: 0.9,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),

          // Avatar in center of cover photo (Rounded Square)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), // Rounded square
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Match inner radius
                        child: _buildImageWidget(
                          imageUrl:
                              userData["avatar"] as String? ??
                              "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // Rounded square for button too
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: CustomIconWidget(
                            iconName: 'camera_alt',
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Edit Profile Button (moved from bottom right)
          Positioned(bottom: 2.h, right: 4.w, child: _buildEditButton(context)),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return _buildActionButton(
      context: context,
      icon: 'edit',
      label: 'Sửa',
      onTap: onEditProfile,
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback? onTap,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 16,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two Column Layout: Avatar | Name + Rank Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Large Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: ClipOval(
                  child: _buildImageWidget(
                    imageUrl:
                        userData["avatar"] as String? ??
                        "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Right Column: Name + Rank Badge + Bio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name - 20px bold
                    Text(
                      userData["displayName"] as String? ?? "Trịnh Văn",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Rank Badge
                    _buildRankBadgeFacebook(context),

                    const SizedBox(height: 8),

                    // Bio - 13px regular gray
                    Text(
                      userData["bio"] as String? ??
                          "Tôi là Trịnh Văn, chơi bida với ELO 1799",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ELO Rating - Facebook Style
          _buildEloSectionFacebook(context),

          const SizedBox(height: 12),

          // SPA Points and Prize Pool - Facebook Style
          _buildSpaAndPrizeSectionFacebook(context),
        ],
      ),
    );
  }

  // ============= FACEBOOK 2025 STYLE METHODS =============

  Widget _buildRankBadgeFacebook(BuildContext context) {
    final currentElo = userData["elo_rating"] as int? ?? 1735;
    final rank = RankingConstants.getRankFromElo(currentElo);
    final rankColor = SaboRankSystem.getRankColor(rank);
    final hasRank = rank.isNotEmpty && rank != 'unranked';

    if (!hasRank) {
      // No rank version
      return GestureDetector(
        onTap: () => _showRankInfoModal(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.warning, // Orange
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'RANK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showRankExplanationDialog(context),
                    child: const Icon(
                      Icons.info_outline,
                      size: 12,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Has rank version - like screenshot "G+"
    return GestureDetector(
      onTap: () => _showRankDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: rankColor, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RANK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rankColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showRankExplanationDialog(context),
                  child: Icon(
                    Icons.info_outline,
                    size: 12,
                    color: rankColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              rank,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: rankColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              SaboRankSystem.getRankDisplayName(rank),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: rankColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEloSectionFacebook(BuildContext context) {
    final currentElo = userData["elo_rating"] as int? ?? 1735;
    final nextRankInfo = SaboRankSystem.getNextRankInfo(currentElo);
    final progress = SaboRankSystem.getRankProgress(currentElo);
    final currentRank = RankingConstants.getRankFromElo(currentElo);
    final skillDescription = SaboRankSystem.getRankSkillDescription(
      currentRank,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'ELO Rating',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showEloExplanationDialog(context),
                    child: const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                SaboRankSystem.formatElo(currentElo),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Skill description
          Text(
            skillDescription,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.info600, // Blue
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Next rank info
          Text(
            nextRankInfo['pointsNeeded'] > 0
                ? 'Hạng tiếp: ${nextRankInfo['nextRank']} • Còn ${nextRankInfo['pointsNeeded']} điểm'
                : 'Đã đạt rank cao nhất!',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaAndPrizeSectionFacebook(BuildContext context) {
    final spaPoints = userData["spa_points"] as int? ?? 850;
    final totalPrizePool = userData["total_prize_pool"] as double? ?? 0.0;

    return Row(
      children: [
        // SPA Points
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning50, // Light yellow
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CustomIconWidget(
                      iconName: 'star',
                      color: AppColors.warning,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SPA Points',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          _showStatExplanationDialog(context, 'SPA Points'),
                      child: const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatNumber(spaPoints),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Prize Pool
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success50, // Light green
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CustomIconWidget(
                      iconName: 'monetization_on',
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Prize Pool',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          _showStatExplanationDialog(context, 'Prize Pool'),
                      child: const Icon(
                        Icons.info_outline,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${_formatCurrency(totalPrizePool)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============= OLD METHODS (Keep for reference or remove later) =============

  // Tách riêng nội dung của rank badge để dễ quản lý
  Widget _buildRankContent(
    BuildContext context,
    bool hasRank,
    String? userRank,
  ) {
    if (!hasRank) {
      // Giao diện khi người dùng CHƯA CÓ RANK
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(
              alpha: 0.7,
            ),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(
                alpha: 0.1,
              ),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RANK',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 1.w),
                GestureDetector(
                  onTap: () => _showRankExplanationDialog(context),
                  child: Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              '?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Giao diện khi người dùng ĐÃ CÓ RANK
    final currentElo = userData["elo_rating"] as int? ?? 1200;
    final rank = RankingConstants.getRankFromElo(currentElo);
    final rankColor = SaboRankSystem.getRankColor(rank);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: rankColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'RANK',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 1.w),
              GestureDetector(
                onTap: () => _showRankExplanationDialog(context),
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: rankColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            rank, // Hiển thị rank code (K, I+, etc.)
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: rankColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            SaboRankSystem.getRankDisplayName(
              rank,
            ), // Mô tả rank (Người mới, Thợ 3, etc.)
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: rankColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRankInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RankRegistrationInfoModal(
        onStartRegistration: () {
          Navigator.pop(context); // Đóng modal trước khi điều hướng
          Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
        },
      ),
    );
  }

  void _showRankDetails(BuildContext context) {
    // TODO: Implement rank details dialog/screen
    // Show detailed rank information, progression, requirements, etc.
  }

  Widget _buildSpaAndPrizeSection(BuildContext context) {
    final spaPoints = userData["spa_points"] as int? ?? 0;
    final totalPrizePool = userData["total_prize_pool"] as double? ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // SPA Points
          Expanded(
            child: _buildStatItem(
              context,
              icon: 'star',
              label: 'SPA Points',
              value: _formatNumber(spaPoints),
              iconColor: AppColors.warning600,
            ),
          ),

          SizedBox(width: 4.w),

          // Prize Pool
          Expanded(
            child: _buildStatItem(
              context,
              icon: 'monetization_on',
              label: 'Prize Pool',
              value: '\$${_formatCurrency(totalPrizePool)}',
              iconColor: AppColors.success600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        CustomIconWidget(iconName: icon, color: iconColor, size: 24),
        SizedBox(height: 0.5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.7,
                ),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(width: 1.w),
            GestureDetector(
              onTap: () => _showStatExplanationDialog(context, label),
              child: Icon(
                Icons.info_outline,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 0.2.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else if (amount == amount.toInt()) {
      return amount.toInt().toString();
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  Widget _buildImageWidget({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Check if it's a local file path
    if (imageUrl.startsWith('/') || imageUrl.contains('\\')) {
      // Local file path
      return Image.file(
        File(imageUrl),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to network image if file doesn't exist
          return CustomImageWidget(
            imageUrl:
                "https://images.pexels.com/photos/1040473/pexels-photo-1040473.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    } else {
      // Network URL
      return CustomImageWidget(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }
  }

  // Hiển thị dialog giải thích ELO Rating
  void _showEloExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 2.w),
            Text('ELO Rating System'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ELO Rating đánh giá trình độ chơi bida dựa trên kết quả tournament.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Text(
                '🏆 Thưởng ELO Tournament (Fixed Rewards):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              _buildEloReward(
                '🥇 1st Place',
                '+75 ELO',
                'Vô địch',
                AppColors.warning,
              ),
              _buildEloReward(
                '🥈 2nd Place',
                '+60 ELO',
                'Á quân',
                AppColors.gray400,
              ),
              _buildEloReward(
                '🥉 3rd Place',
                '+45 ELO',
                'Đồng hạng 3 (3rd & 4th)',
                AppColors.warning,
              ),
              _buildEloReward('Top 25%', '+25 ELO', 'Tier trên', AppColors.success),
              _buildEloReward('Top 50%', '+15 ELO', 'Tier giữa', AppColors.info),
              _buildEloReward('Top 75%', '+10 ELO', 'Tier dưới', AppColors.premium),
              _buildEloReward(
                'Bottom 25%',
                '-5 ELO',
                'Penalty nhẹ',
                AppColors.error,
              ),
              SizedBox(height: 1.h),
              Text(
                '💡 Range: 1000-3000 điểm. Hệ thống Fixed Rewards đảm bảo công bằng!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.info600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildEloReward(
    String position,
    String reward,
    String description,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              position,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 15.w,
            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              reward,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(child: Text(description, style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // Hiển thị dialog giải thích cho SPA Points và Prize Pool
  void _showStatExplanationDialog(BuildContext context, String statType) {
    String title;
    String description;
    List<String> details;
    IconData icon;

    if (statType == 'SPA Points') {
      title = 'SPA Points System';
      icon = Icons.star;
      description =
          'SPA Points là điểm thưởng tích lũy được từ các hoạt động trên nền tảng SABO Arena.';
      details = [
        '🎯 Cách kiếm SPA Points:',
        '• Referral Code: +100 SPA (người giới thiệu), +50 SPA (người được giới thiệu)',
        '• Tournament tham gia: 50-150 SPA base (x multiplier theo vị trí)',
        '  - 1st place: x3.0, 2nd: x2.5, 3rd: x2.0',
        '  - Top 25%: x1.5, Top 50%: x1.2, Others: x1.0',
        '• Daily challenges và achievements',
        '',
        '💰 Sử dụng SPA Points:',
        '• SPA Shop: Đổi quà tặng và items',
        '• Premium features và benefits',
        '• Tournament entry fees (tùy chọn)',
      ];
    } else {
      title = 'Prize Pool System';
      icon = Icons.monetization_on;
      description =
          'Tổng giá trị tiền thưởng (VNĐ) bạn đã giành được từ tournaments.';
      details = [
        '🏆 Tournament Prize Distribution Templates:',
        '• Standard: 40% / 25% / 15% / 10% / 5% / 5%',
        '• Winner Takes All: 100% cho vô địch',
        '• Top Heavy: 60% / 25% / 15%',
        '• Flat Distribution: 25% / 25% / 25% / 25%',
        '',
        '💰 Prize Pool Sources:',
        '• Entry fees từ participants',
        '• Sponsorship và tài trợ',
        '• Platform contribution',
        '',
        '💳 Prize Withdrawal:',
        '• Rút về tài khoản ngân hàng',
        '• Phí giao dịch: 2% (minimum 10K VNĐ)',
        '• Xử lý trong 1-3 ngày làm việc',
      ];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              icon,
              color: statType == 'SPA Points' ? AppColors.warning : AppColors.success,
            ),
            SizedBox(width: 2.w),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            SizedBox(height: 2.h),
            ...details.map(
              (detail) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Text(detail),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Hiển thị dialog giải thích Rank System
  void _showRankExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.military_tech, color: AppColors.premium),
            SizedBox(width: 2.w),
            Text('Vietnamese Billiards Ranking'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hệ thống rank bida Việt Nam dựa trên điểm ELO và trình độ thực tế.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Text('🎱 Hệ thống rank K → C:'),
              SizedBox(height: 1.h),
              _buildRankInfo(
                'K',
                '1000-1099',
                'Người mới (2-4 bi khi hình dễ)',
                Color(0xFF8B4513),
              ),
              _buildRankInfo(
                'K+',
                '1100-1199',
                'Học việc (sắt ngưỡng lên I)',
                Color(0xFFA0522D),
              ),
              _buildRankInfo(
                'I',
                '1200-1299',
                'Thợ 3 (5-7 bi khi có hình)',
                Color(0xFF795548),
              ),
              _buildRankInfo(
                'I+',
                '1300-1399',
                'Thợ 2 (sắt ngưỡng lên H)',
                Color(0xFF6D4C41),
              ),
              _buildRankInfo(
                'H',
                '1400-1499',
                'Thợ 1 (8-10 bi khi có hình)',
                Color(0xFF5D4037),
              ),
              _buildRankInfo(
                'H+',
                '1500-1599',
                'Thợ chính (sắt ngưỡng lên G)',
                Color(0xFF4E342E),
              ),
              _buildRankInfo(
                'G',
                '1600-1699',
                'Thợ giỏi (11-13 bi đẹp)',
                Color(0xFF3E2723),
              ),
              _buildRankInfo(
                'G+',
                '1700-1799',
                'Cao thủ (sắt ngưỡng lên F)',
                Color(0xFF2E1916),
              ),
              _buildRankInfo(
                'F',
                '1800-1899',
                'Chuyên gia (14-15 bi clear)',
                Color(0xFF1B0E0A),
              ),
              _buildRankInfo(
                'F+',
                '1900-1999',
                'Đại cao thủ (sắt ngưỡng lên E)',
                Color(0xFF000000),
              ),
              _buildRankInfo(
                'E',
                '1900-1999',
                'Xuất sắc (an toàn chủ động)',
                Color(0xFFB22222),
              ),
              _buildRankInfo(
                'D',
                '2000-2099',
                'Huyền thoại (master cơ hội)',
                Color(0xFFDC143C),
              ),
              _buildRankInfo(
                'C',
                '2100-2199',
                'Vô địch (điều bi phức tạp)',
                Color(0xFFFFD700),
              ),
              SizedBox(height: 1.h),
              Text(
                '💡 Rank up cần verification, rank down tự động. Hệ thống dựa trên kỹ thuật bida Việt Nam thực tế!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.info600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildRankInfo(
    String rank,
    String range,
    String description,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              rank,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text('$range: $description', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
