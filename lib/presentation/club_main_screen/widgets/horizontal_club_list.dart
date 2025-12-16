import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../models/club.dart';

class HorizontalClubList extends StatelessWidget {
  final List<Club> clubs;
  final Club? selectedClub;
  final Function(Club) onClubSelected;

  const HorizontalClubList({
    super.key,
    required this.clubs,
    required this.selectedClub,
    required this.onClubSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (clubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có câu lạc bộ nào',
              style: AppTypography.bodyLarge(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ).copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tham gia hoặc tạo câu lạc bộ đầu tiên của bạn',
              style: AppTypography.bodyMedium(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal club list (no header to avoid duplication)
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final club = clubs[index];
              final isSelected = selectedClub?.id == club.id;

              return Semantics(
                label:
                    'Club ${club.name}, rating ${club.rating.toStringAsFixed(1)} stars, ${club.totalTables} tables',
                button: true,
                child: GestureDetector(
                  onTap: () => onClubSelected(club),
                  child: Container(
                    width: _getCardWidth(context),
                    height: 220, // Height for iOS Facebook style cards
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: _buildClubCard(club, isSelected, colorScheme),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClubCard(Club club, bool isSelected, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF1877F2) // Facebook blue
              : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          if (isSelected) // Extra glow when selected
            BoxShadow(
              color: const Color(0xFF1877F2).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 0),
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Cover Image (ảnh bìa)
            club.coverImageUrl != null && club.coverImageUrl!.isNotEmpty
                ? Image.network(
                    club.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1877F2), Color(0xFF42A5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1877F2), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

            // Dark overlay for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Bottom content with logo and club name
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  // Club Logo (nếu không có logo thì hiển thị ảnh đại diện)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _buildLogoOrProfileImage(club),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Club Name
                  Expanded(
                    child: Text(
                      club.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method: Hiển thị logo, nếu không có logo thì hiển thị ảnh đại diện
  Widget _buildLogoOrProfileImage(Club club) {
    // Ưu tiên logo trước
    final imageUrl = (club.logoUrl != null && club.logoUrl!.isNotEmpty)
        ? club.logoUrl
        : club.profileImageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1877F2),
          child: const Icon(Icons.business, color: Colors.white, size: 20),
        ),
      );
    }

    // Fallback: hiển thị icon mặc định
    return Container(
      color: const Color(0xFF1877F2),
      child: const Icon(Icons.business, color: Colors.white, size: 20),
    );
  }

  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // iOS Facebook card sizing
    if (screenWidth > 1200) {
      return 280; // Desktop - compact
    } else if (screenWidth > 600) {
      return 240; // Tablet - compact
    } else {
      return screenWidth * 0.65; // Mobile - optimal for horizontal scroll
    }
  }
}
