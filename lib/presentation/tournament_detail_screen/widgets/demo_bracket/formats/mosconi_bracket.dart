// 🎯 SABO ARENA - Mosconi Cup Format
// Đấu đồng đội theo format Mosconi Cup

import 'package:flutter/material.dart';

class MosconiBracket extends StatelessWidget {
  const MosconiBracket({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildTeams(),
          const SizedBox(height: 24),
          _buildMatchTypes(),
          const SizedBox(height: 24),
          _buildScoreboard(),
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
            const Color(0xFFDC2626).withValues(alpha: 0.1),
            const Color(0xFF1E40AF).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Mosconi Cup',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đấu đồng đội\nĐội nào đạt 11 điểm trước thắng',
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

  Widget _buildTeams() {
    return Row(
      children: [
        Expanded(
          child: _buildTeam('Team Europe', '🇪🇺', const Color(0xFF1E40AF)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTeam('Team USA', '🇺🇸', const Color(0xFFDC2626)),
        ),
      ],
    );
  }

  Widget _buildTeam(String name, String flag, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(flag, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Player ${i + 1}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTypes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0866FF).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Các loại trận đấu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildMatchType('👤', 'Singles', '1 vs 1', const Color(0xFF0866FF)),
          const SizedBox(height: 12),
          _buildMatchType('👥', 'Doubles', '2 vs 2', const Color(0xFF42B72A)),
        ],
      ),
    );
  }

  Widget _buildMatchType(String emoji, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
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
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Bảng điểm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScore('🇪🇺', '8', const Color(0xFF1E40AF)),
              const Text(
                ':',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              _buildScore('🇺🇸', '7', const Color(0xFFDC2626)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'First to 11 wins',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildScore(String flag, String score, Color color) {
    return Column(
      children: [
        Text(flag, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          score,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
