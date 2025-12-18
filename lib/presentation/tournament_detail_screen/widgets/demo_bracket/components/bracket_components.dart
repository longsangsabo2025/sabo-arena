// 🎯 SABO ARENA - Shared Bracket Components
// Reusable UI components for all tournament formats

import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
// ELON_MODE_AUTO_FIX

/// Shared header component for all bracket types
class BracketHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onFullscreenTap;
  final VoidCallback? onInfoTap;

  const BracketHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onFullscreenTap,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E86AB),
            const Color(0xFF2E86AB).withValues(alpha: 0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_tree,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(
                    'Dữ liệu demo để xem trước cấu trúc bảng đấu',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onInfoTap != null) ...[
            IconButton(
              onPressed: onInfoTap,
              icon: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Thông tin chi tiết',
            ),
            const SizedBox(width: 8),
          ],
          if (onFullscreenTap != null) ...[
            IconButton(
              onPressed: onFullscreenTap,
              icon: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
              tooltip: 'Xem toàn màn hình',
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'DEMO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual match card component
class MatchCard extends StatelessWidget {
  final Map<String, String> match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    // Extract match score for winner determination
    final scoreText = match['score'] ?? '0-0';

    final isCompleted = match['status'] == 'completed';
    final winnerId = match['winner_id'];
    final player1Id = match['player1_id'];
    final player2Id = match['player2_id'];

    final player1IsWinner = isCompleted && winnerId == player1Id;
    final player2IsWinner = isCompleted && winnerId == player2Id;

    // Debug print to see actual data
    if (isCompleted) {
    }

    return Container(
      width: 180, // TĂNG từ 160 lên 180 để có chỗ cho avatar lớn hơn
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10), // TĂNG từ 8 lên 10 cho padding tốt hơn
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // TĂNG từ 6 lên 8
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 4, // TĂNG từ 2 lên 4 cho depth tốt hơn
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Match status indicator
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Hoàn thành',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E86AB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Chờ đấu',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E86AB),
                ),
              ),
            ),
          const SizedBox(height: 4),
          PlayerRow(
            playerName: match['player1'] ?? 'TBD',
            score: null, // Don't show individual scores
            avatarUrl: match['player1_avatar'],
            isWinner: player1IsWinner,
          ),
          const Divider(height: 8),
          PlayerRow(
            playerName: match['player2'] ?? 'TBD',
            score: null, // Don't show individual scores
            avatarUrl: match['player2_avatar'],
            isWinner: player2IsWinner,
          ),
          // Show match score prominently
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted && scoreText != '0-0'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCompleted && scoreText != '0-0'
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted && scoreText != '0-0'
                      ? Icons.sports_score
                      : Icons.timer,
                  size: 12,
                  color: isCompleted && scoreText != '0-0'
                      ? Colors.green
                      : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isCompleted && scoreText != '0-0' ? scoreText : '0 - 0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted && scoreText != '0-0'
                        ? Colors.green[700]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Player row within a match card
class PlayerRow extends StatelessWidget {
  final String playerName;
  final String? score;
  final String? avatarUrl;
  final bool isWinner;

  const PlayerRow({
    super.key,
    required this.playerName,
    this.score,
    this.avatarUrl,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Log avatar URLs to verify they're being fetched
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
    } else {
    }
    
    return Row(
      children: [
        // Avatar with fallback to initials - LARGER & MORE VISIBLE
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isWinner
                  ? const Color(0xFF2E86AB)
                  : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isWinner
                    ? const Color(0xFF2E86AB).withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: UserAvatarWidget(
            avatarUrl: avatarUrl,
            size: 32,
          ),
        ),
        const SizedBox(width: 8), // TĂNG từ 6 lên 8 cho spacing tốt hơn
        Expanded(
          child: Text(
            playerName,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
              color: isWinner ? const Color(0xFF2E86AB) : Colors.black87,
              fontSize: 12, // TĂNG từ 11 lên 12 để dễ đọc hơn
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Show score only if provided
        if (score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isWinner ? Colors.green : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              score!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWinner ? Colors.white : Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }
}

/// Round column header
class RoundColumn extends StatelessWidget {
  final String title;
  final List<Map<String, String>> matches;
  final int? roundIndex;
  final int? totalRounds;
  final bool? isFullscreen;

  const RoundColumn({
    super.key,
    required this.title,
    required this.matches,
    this.roundIndex,
    this.totalRounds,
    this.isFullscreen,
  });

  // Helper method to calculate spacing between matches based on round
  double _calculateMatchSpacing() {
    // Nếu không có roundIndex, dùng spacing mặc định
    if (roundIndex == null) {
      return isFullscreen == true ? 8.0 : 4.0;
    }

    // Tính spacing động dựa trên round index
    // Vòng 1 (roundIndex=0): spacing nhỏ
    // Vòng 2 (roundIndex=1): spacing tăng gấp đôi
    // Vòng 3 (roundIndex=2): spacing tăng gấp 4
    // ...
    final double baseSpacing = isFullscreen == true ? 8.0 : 4.0;
    
    // Công thức: baseSpacing * 2^roundIndex
    // Nhưng giới hạn tối đa để tránh quá lớn
    final multiplier = 1 << roundIndex!; // 2^roundIndex
    final calculatedSpacing = baseSpacing * multiplier;
    
    // Giới hạn spacing tối đa để tránh layout vỡ
    const double maxSpacing = 128.0;
    return calculatedSpacing > maxSpacing ? maxSpacing : calculatedSpacing;
  }

  @override
  Widget build(BuildContext context) {
    final isLast =
        roundIndex != null &&
        totalRounds != null &&
        roundIndex == totalRounds! - 1;
    final spacing = _calculateMatchSpacing(); // Dùng spacing động

    return Container(
      width: 140, // Giảm width từ 180 xuống 140
      margin: EdgeInsets.only(right: isLast ? 0 : 12), // Giảm margin
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header của round
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: isFullscreen == true ? 4 : 3,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2E86AB),
              borderRadius: BorderRadius.circular(isFullscreen == true ? 12 : 10),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isFullscreen == true ? 10 : 9,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: spacing),
          // Matches - không dùng spread operator
          for (int i = 0; i < matches.length; i++) ...[
            MatchCard(match: matches[i]),
            if (i < matches.length - 1) SizedBox(height: spacing),
          ],
        ],
      ),
    );
  }
}

/// Container wrapper for bracket displays
class BracketContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final VoidCallback? onFullscreenTap;
  final VoidCallback? onInfoTap;
  final double? height; // Thêm optional height parameter

  const BracketContainer({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.onFullscreenTap,
    this.onInfoTap,
    this.height, // Thêm vào constructor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: height ?? 400, // Sử dụng height parameter hoặc default 400
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          if (title != null) ...[
            BracketHeader(
              title: title!,
              subtitle: subtitle,
              onFullscreenTap: onFullscreenTap,
              onInfoTap: onInfoTap,
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tournament bracket connector widget
/// Draws connecting lines between matches to show progression flow
class BracketConnector extends StatelessWidget {
  final int fromMatchCount;
  final int toMatchCount;
  final bool isLastRound;

  const BracketConnector({
    super.key,
    required this.fromMatchCount,
    required this.toMatchCount,
    this.isLastRound = false,
  });

  @override
  Widget build(BuildContext context) {
    // Temporarily disable connectors to fix layout issues
    return const SizedBox(width: 30, height: 100);
  }
}

/// Custom painter for drawing bracket connectors
class ConnectorPainter extends CustomPainter {
  final int fromMatchCount;
  final int toMatchCount;

  ConnectorPainter({required this.fromMatchCount, required this.toMatchCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E86AB).withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final matchHeight = 80.0; // Approximate height of MatchCard
    final spacing = 4.0; // Spacing between matches
    final headerHeight = 25.0; // Round header height

    // Calculate positions for "from" matches (left side)
    final fromStartY = headerHeight;
    final fromSpacing = (matchHeight + spacing);

    // Calculate positions for "to" matches (right side)
    final toStartY = headerHeight;
    final toSpacing = fromSpacing * 2; // Double spacing for next round

    // Draw horizontal lines from each "from" match
    for (int i = 0; i < fromMatchCount; i++) {
      final fromY = fromStartY + (i * fromSpacing) + (matchHeight / 2);

      // Horizontal line to the right
      canvas.drawLine(Offset(0, fromY), Offset(15, fromY), paint);
    }

    // Draw connecting vertical and horizontal lines to "to" matches
    for (int i = 0; i < toMatchCount; i++) {
      final toY = toStartY + (i * toSpacing) + (matchHeight / 2);

      // Calculate which "from" matches connect to this "to" match
      final fromMatch1Index = i * 2;
      final fromMatch2Index = i * 2 + 1;

      if (fromMatch1Index < fromMatchCount &&
          fromMatch2Index < fromMatchCount) {
        final fromY1 =
            fromStartY + (fromMatch1Index * fromSpacing) + (matchHeight / 2);
        final fromY2 =
            fromStartY + (fromMatch2Index * fromSpacing) + (matchHeight / 2);

        // Vertical connector line
        canvas.drawLine(Offset(15, fromY1), Offset(15, fromY2), paint);

        // Horizontal line to "to" match
        canvas.drawLine(Offset(15, toY), Offset(30, toY), paint);

        // Vertical line from mid-point to "to" match
        final midY = (fromY1 + fromY2) / 2;
        canvas.drawLine(Offset(15, midY), Offset(15, toY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

