import 'package:flutter/material.dart';
import '../../../../models/club.dart';

class ClubInfoTab extends StatelessWidget {
  final Club club;

  const ClubInfoTab({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            club.description ?? 'Không có mô tả',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.6, // Better line height for readability
            ),
          ),

          const SizedBox(height: 24),

          // Facilities (using real data from club.amenities)
          if (club.amenities != null && club.amenities!.isNotEmpty) ...[
            Text(
              'Tiện ích',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: club.amenities!.map((facility) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    facility,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Club Details (Tables & Price)
          Text(
            'Thông tin bàn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.table_bar, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Số bàn: ${club.totalTables} bàn',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          if (club.pricePerHour != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Giá: ${club.pricePerHour} VNĐ/giờ',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Contact Info
          Text(
            'Liên hệ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (club.phone != null) ...[
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  club.phone!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (club.email != null) ...[
            Row(
              children: [
                Icon(Icons.email, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  club.email!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (club.websiteUrl != null) ...[
            Row(
              children: [
                Icon(Icons.language, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  club.websiteUrl!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Opening Hours
          Text(
            'Giờ mở cửa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                club.openingHours != null ? _formatOpeningHours(club.openingHours!) : 'Chưa cập nhật giờ mở cửa',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          
          // Bottom padding
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper method to format opening hours
  String _formatOpeningHours(Map<String, dynamic> openingHours) {
    // Try to format opening hours from JSON
    // Example format: {"monday": "08:00-22:00", "tuesday": "08:00-22:00", ...}
    // or {"default": "08:00-22:00"}

    if (openingHours.containsKey('default')) {
      return openingHours['default'] + ' (Hàng ngày)';
    }

    // If more complex format, return first day's hours as example
    if (openingHours.isNotEmpty) {
      final firstDay = openingHours.entries.first;
      return '${firstDay.value} (${firstDay.key})';
    }

    return 'Chưa cập nhật giờ mở cửa';
  }
}
