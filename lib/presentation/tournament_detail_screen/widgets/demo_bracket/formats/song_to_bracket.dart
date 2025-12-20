// 🎯 SABO ARENA - Song Tô (14-1 Straight Pool) Format
// Tích điểm đến 100, kinh điển billiards

import 'package:flutter/material.dart';

class SongToBracket extends StatelessWidget {
  const SongToBracket({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Rules
          _buildRules(),
          const SizedBox(height: 24),

          // Sample Match
          _buildSampleMatch(),
          const SizedBox(height: 24),

          // Leaderboard
          _buildLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.1),
            const Color(0xFF7C3AED).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text('🎱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            '14-1 Straight Pool\n(Song Tô)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF050505),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tích điểm đến 100\nFormat kinh điển của billiards',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRules() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Luật chơi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF050505),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildRuleItem(
            '1️⃣',
            'Mục tiêu',
            'Tích lũy 100 điểm trước đối thủ',
            const Color(0xFF1E3A8A),
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            '2️⃣',
            'Cách chơi',
            'Mỗi bi vào lỗ = 1 điểm\nGọi bi và lỗ trước khi đánh',
            const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            '3️⃣',
            'Rack mới',
            'Khi còn 1 bi, rack lại 14 bi\nBi cuối dùng để break rack mới',
            const Color(0xFF059669),
          ),
          const SizedBox(height: 12),
          _buildRuleItem(
            '4️⃣',
            'Lỗi',
            'Không vào bi hoặc foul = mất lượt\nCó thể bị trừ điểm',
            const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(
    String emoji,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleMatch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Trận đấu mẫu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF050505),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),

          // Player 1
          _buildPlayerScore('Nguyễn Văn A', 87, const Color(0xFF1E3A8A), true),
          const SizedBox(height: 16),

          // VS
          const Text(
            'vs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF65676B),
            ),
          ),
          const SizedBox(height: 16),

          // Player 2
          _buildPlayerScore('Trần Thị B', 73, const Color(0xFF7C3AED), false),
          const SizedBox(height: 20),

          // Progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mục tiêu: 100 điểm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Hiệp: 23',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.87,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(
    String name,
    int score,
    Color color,
    bool isLeading,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLeading ? color : color.withValues(alpha: 0.3),
          width: isLeading ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (isLeading)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.star, color: Colors.white, size: 16),
            ),
          if (isLeading) const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Bảng xếp hạng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF050505),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLeaderboardItem(1, 'Nguyễn Văn A', 100, true),
          _buildLeaderboardItem(2, 'Trần Thị B', 87, false),
          _buildLeaderboardItem(3, 'Lê Văn C', 73, false),
          _buildLeaderboardItem(4, 'Phạm Thị D', 65, false),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
    int rank,
    String name,
    int score,
    bool isWinner,
  ) {
    final color = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : const Color(0xFF65676B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isWinner ? color.withValues(alpha: 0.1) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border:
            isWinner ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF050505),
              ),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (isWinner) ...[
            const SizedBox(width: 8),
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20),
          ],
        ],
      ),
    );
  }
}
