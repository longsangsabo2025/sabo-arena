import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/club.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// 🎨 iOS/Facebook 2025 Club Card
/// Clean white card with shadow, thumbnail, and info
class ClubCardIOS extends StatelessWidget {
  final Club club;
  final VoidCallback onTap;

  const ClubCardIOS({super.key, required this.club, required this.onTap});

  // Facebook 2025 Colors
  static const Color fbWhite = Color(0xFFFFFFFF);
  static const Color fbTextPrimary = Color(0xFF050505);
  static const Color fbTextSecondary = Color(0xFF65676B);
  static const Color fbBlue = Color(0xFF0866FF);
  static const Color fbGreen = Color(0xFF45BD62);
  static const Color fbBackground = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 280, // Increased height for background image
        decoration: BoxDecoration(
          color: fbWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Background Image Section
            _buildBackgroundImage(),

            // Gradient overlay for better text readability
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                ),
              ),
            ),

            // Club Info Section (overlay on background)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      fbWhite.withValues(alpha: 0.95),
                      fbWhite,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Club Name
                    Text(
                      club.name,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fbTextPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location (clickable for map)
                    if (club.address != null && club.address!.isNotEmpty)
                      InkWell(
                        onTap: () => _openMap(
                          club.address!,
                          club.latitude,
                          club.longitude,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: fbBlue,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                club.address!,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: fbBlue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.map_outlined,
                              size: 12,
                              color: fbBlue,
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tables
                        _buildStatChip(
                          icon: Icons.table_chart_outlined,
                          label: '${club.totalTables} bàn',
                          color: fbBlue,
                        ),

                        // Rating (interactive)
                        InkWell(
                          onTap: () => _showRatingDialog(context),
                          child: _buildRatingChip(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: fbBackground,
      ),
      child: Stack(
        children: [
          // Background image or placeholder
          club.coverImageUrl != null && club.coverImageUrl!.isNotEmpty
              ? Image.network(
                  club.coverImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildBackgroundPlaceholder(),
                )
              : _buildBackgroundPlaceholder(),

          // Logo overlay in top-right corner
          if (club.logoUrl != null && club.logoUrl!.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fbWhite.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    club.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.business, size: 20, color: fbTextSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPlaceholder() {
    return Container(
      color: fbBackground,
      child: const Center(
        child: Icon(Icons.business, size: 48, color: fbTextSecondary),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip() {
    final rating = club.rating;
    final reviews = club.totalReviews;

    if (rating == 0 && reviews == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: fbTextSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Chưa có đánh giá',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fbTextSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fbGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star rating display
          ...List.generate(5, (index) {
            final starValue = index + 1;
            final isFilled = starValue <= rating.round();

            return Icon(
              isFilled ? Icons.star : Icons.star_border,
              size: 12,
              color: fbGreen,
            );
          }),
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($reviews)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fbGreen,
            ),
          ),
        ],
      ),
    );
  }

  void _openMap(String address, double? latitude, double? longitude) async {
    final Uri uri;

    if (latitude != null && longitude != null) {
      // Use coordinates if available
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else {
      // Use address as fallback
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: fbGreen),
            const SizedBox(width: 8),
            Text('Đánh giá ${club.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đánh giá hiện tại: ${club.rating.toStringAsFixed(1)} ⭐ (${club.totalReviews} đánh giá)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= club.rating.round();

                return IconButton(
                  onPressed: () {
                    // Handle rating selection
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bạn đánh giá $starValue sao cho ${club.name}',
                        ),
                        backgroundColor: fbGreen,
                      ),
                    );
                  },
                  icon: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: fbGreen,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn vào ngôi sao để đánh giá',
              style: TextStyle(fontSize: 12, color: fbTextSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

