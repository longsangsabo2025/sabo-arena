import 'package:flutter/material.dart';
import '../../../models/club.dart';
import '../../../routes/app_routes.dart';

/// 🎨 iOS/Facebook 2025 Club Detail Bottom Sheet
/// Shows detailed info about a club with smooth animations
class ClubDetailSheetIOS extends StatelessWidget {
  final Club club;

  const ClubDetailSheetIOS({super.key, required this.club});

  // Facebook 2025 Colors
  static const Color fbWhite = Color(0xFFFFFFFF);
  static const Color fbTextPrimary = Color(0xFF050505);
  static const Color fbTextSecondary = Color(0xFF65676B);
  static const Color fbBlue = Color(0xFF0866FF);
  static const Color fbGreen = Color(0xFF45BD62);
  static const Color fbBackground = Color(0xFFF0F2F5);
  static const Color fbDivider = Color(0xFFE4E6EB);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: fbWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: fbTextSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Cover Image
                    _buildCoverImage(),
                    const SizedBox(height: 16),

                    // Title & Rating
                    Text(
                      club.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: fbTextPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Rating Row
                    _buildRatingRow(),
                    const SizedBox(height: 16),

                    // Quick Stats
                    _buildQuickStats(),
                    const SizedBox(height: 20),

                    // Description
                    if (club.description != null &&
                        club.description!.isNotEmpty) ...[
                      _buildSectionTitle('Giới thiệu'),
                      const SizedBox(height: 8),
                      Text(
                        club.description!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: fbTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Contact Info
                    _buildSectionTitle('Thông tin liên hệ'),
                    const SizedBox(height: 12),
                    _buildContactInfo(),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: fbBackground,
            child:
                club.profileImageUrl != null && club.profileImageUrl!.isNotEmpty
                ? Image.network(
                    club.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),

          // Follow Button - Floating on top right of image
          Positioned(top: 12, right: 12, child: _buildFollowButton()),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    // TODO: Implement actual follow state management
    const bool isFollowing = false; // TODO: Get from controller

    return Material(
      color: fbWhite,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // TODO: Toggle follow state
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(
            Icons.add_circle_outline,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: fbBackground,
      child: const Center(
        child: Icon(Icons.business, size: 64, color: fbTextSecondary),
      ),
    );
  }

  Widget _buildRatingRow() {
    final rating = club.rating;
    final reviews = club.totalReviews;

    return Row(
      children: [
        if (rating > 0) ...[
          const Icon(Icons.star, size: 18, color: fbGreen),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: fbTextPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($reviews đánh giá)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: fbTextSecondary,
            ),
          ),
        ] else
          Text(
            'Chưa có đánh giá',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: fbTextSecondary,
            ),
          ),
        const Spacer(),

        // Verified Badge
        if (club.isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: fbBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified, size: 14, color: fbBlue),
                SizedBox(width: 4),
                Text(
                  'Đã xác minh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fbBlue,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.table_chart_outlined,
            value: '${club.totalTables} bàn',
            label: 'Số bàn',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            value: '${club.pricePerHour ?? 0}k/h',
            label: 'Giá thuê',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            value: club.isActive ? 'Đang mở' : 'Đã đóng',
            label: 'Trạng thái',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fbBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: fbBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: fbTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: fbTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: fbTextPrimary,
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        if (club.address != null && club.address!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ',
            value: club.address!,
          ),
        if (club.phone != null && club.phone!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Điện thoại',
            value: club.phone!,
          ),
        if (club.email != null && club.email!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: club.email!,
          ),
        if (club.websiteUrl != null && club.websiteUrl!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.language_outlined,
            label: 'Website',
            value: club.websiteUrl!,
          ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fbTextSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: fbTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: fbTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Register Member & Rank Buttons Row
        Row(
          children: [
            // Register Member Button
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to member registration
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đăng ký thành viên'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fbGreen,
                    foregroundColor: fbWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.card_membership, size: 18),
                  label: const Text(
                    'Member',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Register Rank Button
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to rank registration
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đăng ký hạng thi đấu'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00), // Orange color
                    foregroundColor: fbWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.emoji_events, size: 18),
                  label: const Text(
                    'Đăng ký hạng',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // View Profile Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.clubProfileScreen,
                arguments: club.id,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: fbBlue,
              foregroundColor: fbWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xem trang câu lạc bộ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Contact Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Open contact options (call, message, etc.)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng liên hệ đang được phát triển'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: fbBlue,
              side: const BorderSide(color: fbBlue, width: 1.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Liên hệ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
