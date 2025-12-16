// 🎯 SABO ARENA - DE8 Demo Wrapper
// Wraps DE8 bracket with sample data for demo purposes

import 'package:flutter/material.dart';

class DE8DemoWrapper extends StatelessWidget {
  const DE8DemoWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Bracket Structure
          _buildBracketStructure(),
          const SizedBox(height: 24),

          // Qualifiers
          _buildQualifiers(),
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
            const Color(0xFF0866FF).withValues(alpha: 0.05),
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
          Icon(Icons.emoji_events, color: const Color(0xFF0866FF), size: 32),
          const SizedBox(height: 12),
          const Text(
            'DE8 SABO Format',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF050505),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '8 người • 13 trận đấu\nWB(6) + LB-A(3) + LB-B(1) + Finals(3)',
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

  Widget _buildBracketStructure() {
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
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0866FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SABO Format Structure',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0866FF),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Winner Bracket
          _buildBracketSection(
            'Winner Bracket',
            '6 trận (R1: 4, R2: 2)',
            Icons.trending_up,
            const Color(0xFF42B72A),
          ),
          const SizedBox(height: 12),

          // Loser Branch A
          _buildBracketSection(
            'Loser Branch A',
            '3 trận (R1: 2, R2: 1)',
            Icons.trending_down,
            const Color(0xFFFF9800),
          ),
          const SizedBox(height: 12),

          // Loser Branch B
          _buildBracketSection(
            'Loser Branch B',
            '1 trận (R1: 1)',
            Icons.trending_down,
            const Color(0xFFE91E63),
          ),
          const SizedBox(height: 16),

          // Arrow
          const Icon(Icons.arrow_downward, color: Color(0xFF0866FF), size: 32),
          const SizedBox(height: 16),

          // Finals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.military_tech, color: Colors.purple, size: 28),
                const SizedBox(height: 8),
                const Text(
                  'SABO Finals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3 trận (2 Semis + 1 Final)\n4 người: 2 WB + 2 LB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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

  Widget _buildBracketSection(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualifiers() {
    return Column(
      children: [
        // Title
        const Text(
          'Advancement Flow',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF050505),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 16),

        // Flow diagram
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // WB R1 losers → LB-A
              _buildFlowItem(
                'WB R1 Losers (4)',
                'Loser Branch A',
                const Color(0xFF42B72A),
                const Color(0xFFFF9800),
              ),
              const SizedBox(height: 12),

              // WB R2 losers → LB-B
              _buildFlowItem(
                'WB R2 Losers (2)',
                'Loser Branch B',
                const Color(0xFF42B72A),
                const Color(0xFFE91E63),
              ),
              const SizedBox(height: 12),

              // WB R2 winners → Finals
              _buildFlowItem(
                'WB R2 Winners (2)',
                'SABO Finals',
                const Color(0xFF42B72A),
                Colors.purple,
              ),
              const SizedBox(height: 12),

              // LB Champions → Finals
              _buildFlowItem(
                'LB Champions (2)',
                'SABO Finals',
                const Color(0xFFFF9800),
                Colors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Final note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.2),
                const Color(0xFFFFD700).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Feature',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF050505),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mọi người có 2 cơ hội (thua 2 mới loại)\n4-player finals tạo kịch tính cao',
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
        ),
      ],
    );
  }

  Widget _buildFlowItem(
    String from,
    String to,
    Color fromColor,
    Color toColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: fromColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: fromColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              from,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fromColor,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, color: Colors.grey[400], size: 20),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: toColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: toColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              to,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: toColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
