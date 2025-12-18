import 'package:flutter/material.dart';
import '../../../models/club.dart';
import '../../../utils/map_launcher.dart';

class ClubDetailHeader extends StatelessWidget {
  final Club club;
  final bool isFollowing;
  final bool isFollowLoading;
  final bool isCurrentUserMember;
  final VoidCallback onFollow;
  final VoidCallback onJoin;
  final VoidCallback onRegisterRank;
  final VoidCallback onViewSpaRewards;
  final VoidCallback onTableReservation;
  final VoidCallback onRateClub;
  final VoidCallback onShowReviewHistory;

  const ClubDetailHeader({
    super.key,
    required this.club,
    required this.isFollowing,
    required this.isFollowLoading,
    required this.isCurrentUserMember,
    required this.onFollow,
    required this.onJoin,
    required this.onRegisterRank,
    required this.onViewSpaRewards,
    required this.onTableReservation,
    required this.onRateClub,
    required this.onShowReviewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hàng 1: Logo + Club Info + Nút Đặt Bàn
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  image: club.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(club.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: club.profileImageUrl == null
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : null,
                ),
                child: club.profileImageUrl == null
                    ? Icon(Icons.business, size: 24, color: colorScheme.primary)
                    : null,
              ),

              const SizedBox(width: 16),

              // Club Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tên CLB
                    Text(
                      club.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Địa chỉ + Icon bản đồ
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            club.address ?? 'Không có địa chỉ',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (club.latitude != null && club.longitude != null)
                          OutlinedButton.icon(
                            onPressed: () {
                              MapLauncher.showMapOptionsDialog(
                                context: context,
                                latitude: club.latitude!,
                                longitude: club.longitude!,
                                label: club.name,
                                address: club.address,
                              );
                            },
                            icon: const Icon(Icons.map_outlined, size: 16),
                            label: const Text('Xem bản đồ'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Số sao + Nút đánh giá
                    Row(
                      children: [
                        // Clickable rating stars to view review history
                        InkWell(
                          onTap: onShowReviewHistory,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < club.rating.floor()
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 16,
                                      color: colorScheme.primary,
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    club.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${club.totalReviews})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onRateClub,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Đánh giá',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Nút Đặt Bàn (góc phải trên)
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onTableReservation,
                  icon: const Icon(Icons.event_available, size: 16),
                  label: const Text(
                    'Đặt Bàn',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hàng 2: Action buttons nằm ngang
          Row(
            children: [
              Expanded(
                child: _buildHorizontalActionButton(
                  icon: isFollowing ? Icons.favorite : Icons.favorite_border,
                  label: isFollowing ? 'Bỏ theo dõi' : 'Theo dõi',
                  colorScheme: colorScheme,
                  onPressed: isFollowLoading ? null : onFollow,
                  isLoading: isFollowLoading,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildHorizontalActionButton(
                  icon: isCurrentUserMember
                      ? Icons.check_circle
                      : Icons.group_add,
                  label: isCurrentUserMember ? 'Đã tham gia' : 'ĐK Member',
                  colorScheme: colorScheme,
                  onPressed: isCurrentUserMember ? null : onJoin,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildHorizontalActionButton(
                  icon: Icons.emoji_events,
                  label: 'ĐK Hạng',
                  colorScheme: colorScheme,
                  onPressed: onRegisterRank,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hàng 3: Button Phần thưởng SPA
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onViewSpaRewards,
              icon: const Icon(Icons.card_giftcard, size: 20),
              label: const Text(
                'Phần thưởng SPA',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalActionButton({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: onPressed != null
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.5),
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: onPressed != null
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
