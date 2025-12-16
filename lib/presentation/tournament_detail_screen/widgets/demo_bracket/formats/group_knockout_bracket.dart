// 🎯 SABO ARENA - Group + Knockout Bracket
// Vòng bảng → Loại trực tiếp

import 'package:flutter/material.dart';

class GroupKnockoutBracket extends StatelessWidget {
  const GroupKnockoutBracket({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Group Stage
          _buildGroupStage(),
          const SizedBox(height: 24),

          // Arrow
          const Icon(Icons.arrow_downward, color: Color(0xFF0866FF), size: 40),
          const SizedBox(height: 24),

          // Knockout Stage
          _buildKnockoutStage(),
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
            const Color(0xFF0866FF).withValues(alpha: 0.1),
            const Color(0xFF42B72A).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0866FF).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFF0866FF), size: 32),
          const SizedBox(height: 12),
          const Text(
            'Group + Knockout',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF050505),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vòng bảng → Loại trực tiếp\nPhổ biến trong World Cup, Champions League',
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

  Widget _buildGroupStage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0866FF).withValues(alpha: 0.2),
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
          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0866FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'GIAI ĐOẠN 1: VÒNG BẢNG',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0866FF),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Groups
          Row(
            children: [
              Expanded(child: _buildGroup('A', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildGroup('B', Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGroup('C', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildGroup('D', Colors.purple)),
            ],
          ),
          const SizedBox(height: 20),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF0866FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mỗi bảng: 4 người đấu vòng tròn\nTop 2 mỗi bảng → Knockout',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
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

  Widget _buildGroup(String name, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Bảng $name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${i + 1}. Player $name${i + 1}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnockoutStage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF42B72A).withValues(alpha: 0.2),
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
          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF42B72A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'GIAI ĐOẠN 2: KNOCKOUT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF42B72A),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bracket structure
          _buildKnockoutRound('Tứ kết', 4, const Color(0xFF42B72A)),
          const SizedBox(height: 16),
          const Icon(Icons.arrow_downward, color: Color(0xFF42B72A), size: 24),
          const SizedBox(height: 16),
          _buildKnockoutRound('Bán kết', 2, const Color(0xFFFF9800)),
          const SizedBox(height: 16),
          const Icon(Icons.arrow_downward, color: Color(0xFFFF9800), size: 24),
          const SizedBox(height: 16),
          _buildKnockoutRound('Chung kết', 1, const Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _buildKnockoutRound(String title, int matches, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(
            matches,
            (i) => Container(
              width: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Match ${i + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
