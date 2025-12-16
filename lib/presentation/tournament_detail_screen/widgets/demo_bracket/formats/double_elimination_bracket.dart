// 🎯 SABO ARENA - Double Elimination Bracket
// Complete Double Elimination tournament format implementation

import 'package:flutter/material.dart';
import '../components/bracket_components.dart';
import '../shared/tournament_data_generator.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class DoubleEliminationBracket extends StatelessWidget {
  final int playerCount;
  final VoidCallback? onFullscreenTap;

  const DoubleEliminationBracket({
    super.key,
    required this.playerCount,
    this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    return BracketContainer(
      title: 'Double Elimination',
      subtitle: '$playerCount players',
      height: 650, // Increased height for losers bracket info
      onFullscreenTap: onFullscreenTap,
      onInfoTap: () => _showDoubleEliminationInfo(context),
      child: _buildBracketContent(context),
    );
  }

  Widget _buildBracketContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWinnersBracket(),
          const SizedBox(height: 20),
          _buildLosersBracket(),
          const SizedBox(height: 20),
          _buildGrandFinal(),
        ],
      ),
    );
  }

  Widget _buildWinnersBracket() {
    final winnersRounds =
        TournamentDataGenerator.calculateDoubleEliminationWinners(playerCount);
    ProductionLogger.debug('Debug log', tag: 'AutoFix'); // Debug

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏆 Bảng Thắng',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Detailed info about Winners Bracket logic
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cơ Chế Bảng Thắng',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• Loại trực tiếp đơn giản\n• Thua → rơi xuống Bảng Thua (cơ hội thứ 2)\n• Người thắng vào Chung kết tổng',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRoundsWithConnectors(winnersRounds),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLosersBracket() {
    final losersRounds =
        TournamentDataGenerator.calculateDoubleEliminationLosers(playerCount);
    ProductionLogger.debug('Debug log', tag: 'AutoFix'); // Debug

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🔥 Bảng Thua',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Detailed info about Losers Bracket logic
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cơ Chế Bảng Thua Phức Tạp',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• V1 BT: Người thua V1 BT thi đấu (${playerCount == 8 ? "4→2" : "8→4"} sống sót)\n• V2 BT: Thắng V1 BT vs Thua V2 BT (vòng hỗn hợp)\n• V3+ BT: Tiến lên cho đến 1 người sống sót\n• Người thắng gặp Vô địch BT ở Chung kết tổng',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // Increased height for better visibility
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRoundsWithConnectors(losersRounds),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrandFinal() {
    final grandFinalRounds =
        TournamentDataGenerator.calculateDoubleEliminationGrandFinal(
          playerCount,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏅 Grand Final',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Detailed Grand Final info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.purple.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Luật Chung Kết Tổng',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• Vô địch Bảng Thắng vs Vô địch Bảng Thua\n• Nếu VĐ BT thắng: Reset bảng (cả 2 đều 1 thua)\n• Nếu VĐ BT thắng: Giải kết thúc (BT đã 2 thua)',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRoundsWithConnectors(grandFinalRounds),
            ),
          ),
        ),
      ],
    );
  }

  /// Helper method to build rounds with connectors
  List<Widget> _buildRoundsWithConnectors(List<Map<String, dynamic>> rounds) {
    List<Widget> widgets = [];

    for (int i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      final isLastRound = i == rounds.length - 1;

      // Add round column
      widgets.add(
        Container(
          width: 120,
          margin: const EdgeInsets.only(right: 4),
          child: RoundColumn(
            title: round['title'] ?? 'Round',
            matches: List<Map<String, String>>.from(round['matches'] ?? []),
            isFullscreen: false,
          ),
        ),
      );

      // Add connector if not the last round
      if (!isLastRound && i < rounds.length - 1) {
        final nextRound = rounds[i + 1];
        widgets.add(
          BracketConnector(
            fromMatchCount: (round['matches'] as List).length,
            toMatchCount: (nextRound['matches'] as List).length,
            isLastRound: isLastRound,
          ),
        );
      }
    }

    return widgets;
  }

  void _showDoubleEliminationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_tree, color: Colors.purple),
            SizedBox(width: 8),
            Text('Double Elimination'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hệ thống thi đấu loại kép',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('🏆 Bảng Thắng:'),
              Text('• Tất cả players bắt đầu ở đây'),
              Text('• Thua 1 trận → rơi xuống Bảng Thua'),
              Text('• Thắng Chung kết BT → Chung kết tổng'),
              SizedBox(height: 8),
              Text('🔥 Bảng Thua:'),
              Text('• Nhận players bị loại từ Bảng Thắng'),
              Text('• Cơ chế loại trực tiếp (thua là bye)'),
              Text('• Thắng Chung kết BT → Chung kết tổng'),
              SizedBox(height: 8),
              Text('🏅 Chung Kết Tổng:'),
              Text('• Vô địch BT vs Vô địch BT'),
              Text('• Nếu VĐ BT thắng → reset bảng'),
              Text('• VĐ BT cần thua 2 trận mới bị loại'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

