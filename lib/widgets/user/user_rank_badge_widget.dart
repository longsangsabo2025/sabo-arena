import 'package:flutter/material.dart';
import '../../core/utils/sabo_rank_system.dart';

/// 🏆 UserRankBadgeWidget - Unified Rank Display Component
///
/// **Single source of truth** cho việc hiển thị rank badge trong toàn bộ app.
///
/// ## Features:
/// - ✅ 3 styles: compact, standard, detailed
/// - ✅ Show rank code (K, I, H, G, E, D, C) hoặc tên đầy đủ (Người mới, Thợ giỏi...)
/// - ✅ Auto color theo rank
/// - ✅ Unranked state handling
/// - ✅ Clickable để mở rank info
///
/// ## Usage:
/// ```dart
/// // Compact badge (chỉ code)
/// UserRankBadgeWidget(
///   rankCode: 'G',
///   style: RankBadgeStyle.compact,
/// )
///
/// // Standard badge (code + tên)
/// UserRankBadgeWidget(
///   rankCode: 'G',
///   showFullName: true,
/// )
///
/// // Unranked
/// UserRankBadgeWidget(
///   rankCode: null,
/// )
/// ```
class UserRankBadgeWidget extends StatelessWidget {
  /// Rank code (K, I, H, G, E, D, C) - null nếu chưa xác minh
  final String? rankCode;

  /// Hiển thị tên đầy đủ (true: "Thợ giỏi", false: "G")
  final bool showFullName;

  /// Style của badge
  final RankBadgeStyle style;

  /// Clickable để xem rank info
  final VoidCallback? onTap;

  /// Custom padding
  final EdgeInsetsGeometry? padding;

  /// Show ELO number
  final int? eloRating;

  const UserRankBadgeWidget({
    super.key,
    this.rankCode,
    this.showFullName = false,
    this.style = RankBadgeStyle.standard,
    this.onTap,
    this.padding,
    this.eloRating,
  });

  @override
  Widget build(BuildContext context) {
    // Handle unranked state
    if (rankCode == null || rankCode!.isEmpty) {
      return _buildUnrankedBadge();
    }

    switch (style) {
      case RankBadgeStyle.compact:
        return _buildCompactBadge();
      case RankBadgeStyle.standard:
        return _buildStandardBadge();
      case RankBadgeStyle.detailed:
        return _buildDetailedBadge();
    }
  }

  /// 🔹 Compact Badge - Chỉ rank code + icon nhỏ
  Widget _buildCompactBadge() {
    final color = SaboRankSystem.getRankColor(rankCode!);
    final displayText = showFullName
        ? SaboRankSystem.getRankDisplayName(rankCode!)
        : rankCode!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              displayText,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Standard Badge - Icon + Text + (Optional ELO)
  Widget _buildStandardBadge() {
    final color = SaboRankSystem.getRankColor(rankCode!);
    final displayName = showFullName
        ? SaboRankSystem.getRankDisplayName(rankCode!)
        : 'Rank $rankCode';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, size: 18, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                if (eloRating != null)
                  Text(
                    '$eloRating ELO',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Detailed Badge - Full info với skill description
  Widget _buildDetailedBadge() {
    final color = SaboRankSystem.getRankColor(rankCode!);
    final rankName = SaboRankSystem.getRankDisplayName(rankCode!);
    final skillDesc = SaboRankSystem.getRankSkillDescription(rankCode!);
    final minElo = SaboRankSystem.getRankMinElo(rankCode!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Icon + Rank Code + Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'RANK $rankCode',
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rankName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Min. $minElo ELO',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Skill Description
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                skillDesc,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⚪ Unranked Badge
  Widget _buildUnrankedBadge() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[400]!, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              'Chưa xác minh hạng',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[600]),
            ],
          ],
        ),
      ),
    );
  }
}

/// 🏆 Badge Style Enum
enum RankBadgeStyle {
  /// Compact - Chỉ code + icon nhỏ (cho lists)
  compact,

  /// Standard - Icon + text + optional ELO (default)
  standard,

  /// Detailed - Full info với skill description (cho profile)
  detailed,
}

/// 🏆 UserRankIcon - Simple rank icon only
///
/// Dùng khi chỉ cần icon rank (ví dụ: trong leaderboard compact view)
class UserRankIcon extends StatelessWidget {
  final String? rankCode;
  final double size;
  final bool filled;

  const UserRankIcon({
    super.key,
    this.rankCode,
    this.size = 24,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (rankCode == null || rankCode!.isEmpty) {
      return Icon(
        Icons.shield_outlined,
        size: size,
        color: Colors.grey[400],
      );
    }

    final color = SaboRankSystem.getRankColor(rankCode!);

    return Icon(
      filled ? Icons.shield : Icons.shield_outlined,
      size: size,
      color: color,
    );
  }
}

/// 🏆 RankComparisonWidget - So sánh 2 ranks
///
/// Dùng cho match-ups, challenge screens
class RankComparisonWidget extends StatelessWidget {
  final String? player1Rank;
  final String? player2Rank;
  final String? player1Name;
  final String? player2Name;

  const RankComparisonWidget({
    super.key,
    this.player1Rank,
    this.player2Rank,
    this.player1Name,
    this.player2Name,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Player 1
        Expanded(
          child: Column(
            children: [
              if (player1Name != null)
                Text(
                  player1Name!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 4),
              UserRankBadgeWidget(
                rankCode: player1Rank,
                style: RankBadgeStyle.compact,
              ),
            ],
          ),
        ),

        // VS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Player 2
        Expanded(
          child: Column(
            children: [
              if (player2Name != null)
                Text(
                  player2Name!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 4),
              UserRankBadgeWidget(
                rankCode: player2Rank,
                style: RankBadgeStyle.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
