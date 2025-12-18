// 🎯 SABO ARENA - Round Robin Bracket
// Complete Round Robin tournament format implementation

import 'package:flutter/material.dart';
import '../components/bracket_components.dart';
import '../shared/tournament_data_generator.dart';

class RoundRobinBracket extends StatelessWidget {
  final int playerCount;
  final VoidCallback? onFullscreenTap;

  const RoundRobinBracket({
    super.key,
    required this.playerCount,
    this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    return BracketContainer(
      title: 'Round Robin',
      subtitle: '$playerCount players',
      onFullscreenTap: onFullscreenTap,
      onInfoTap: () => _showRoundRobinInfo(context),
      child: _buildBracketContent(context),
    );
  }

  Widget _buildBracketContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTournamentStats(context),
          const SizedBox(height: 20),
          _buildStandingsTable(),
          const SizedBox(height: 30),
          _buildMatchSchedule(context),
          const SizedBox(height: 30),
          _buildHeadToHeadRecords(context),
          const SizedBox(height: 30),
          _buildRecentMatches(),
        ],
      ),
    );
  }

  Widget _buildTournamentStats(BuildContext context) {
    final schedule = TournamentDataGenerator.generateRoundRobinSchedule(
      playerCount,
    );
    final totalMatches = schedule.length;
    final playedMatches = schedule.where((m) => m['isPlayed'] == true).length;
    final totalGoals = schedule.where((m) => m['isPlayed'] == true).fold<int>(
      0,
      (sum, m) {
        final s1 = int.tryParse(m['score1'] ?? '') ?? 0;
        final s2 = int.tryParse(m['score2'] ?? '') ?? 0;
        return sum + s1 + s2;
      },
    );
    final avgGoals = playedMatches > 0
        ? (totalGoals / playedMatches).toStringAsFixed(1)
        : '0.0';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statCard('Trận đấu', '$totalMatches', Colors.indigo),
        _statCard('Đã đấu', '$playedMatches', Colors.teal),
        _statCard('TB bàn/trận', avgGoals, Colors.orange),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSchedule(BuildContext context) {
    final schedule = TournamentDataGenerator.generateRoundRobinSchedule(
      playerCount,
    );
    if (schedule.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCount = schedule.length > 12 ? 12 : schedule.length;
    final visibleMatches = schedule.take(displayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '📅 Lịch thi đấu (Schedule)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: visibleMatches.map((m) {
            return Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m['matchId']} · Vòng ${m['round']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${m['player1']} vs ${m['player2']}',
                    style: const TextStyle(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m['isPlayed']
                        ? '${m['score1']} - ${m['score2']}'
                        : m['result'],
                    style: TextStyle(
                      color: m['isPlayed'] ? Colors.black : Colors.orange,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (schedule.length > displayCount) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Full Schedule'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: schedule.length,
                        itemBuilder: (context, index) {
                          final m = schedule[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              '${m['matchId']} · ${m['player1']} vs ${m['player2']}',
                            ),
                            subtitle: Text(
                              m['isPlayed']
                                  ? '${m['score1']} - ${m['score2']}'
                                  : m['result'] ?? 'Pending',
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('View full schedule'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeadToHeadRecords(BuildContext context) {
    final schedule = TournamentDataGenerator.generateRoundRobinSchedule(
      playerCount,
    );
    if (playerCount < 2) return const SizedBox.shrink();

    final standings = TournamentDataGenerator.calculateRoundRobinStandings(
      playerCount,
      schedule,
    );
    // pick top 4 players for quick head-to-head overview
    final topPlayers = standings.take(4).map((s) {
      final parts = (s['name'] as String).split(' ');
      final id = int.tryParse(parts.isNotEmpty ? parts.last : '') ?? 0;
      return {'id': id, 'name': s['name']};
    }).toList();

    final pairs = <Map<String, dynamic>>[];
    for (int i = 0; i < topPlayers.length; i++) {
      for (int j = i + 1; j < topPlayers.length; j++) {
        final a = topPlayers[i];
        final b = topPlayers[j];
        final rec = TournamentDataGenerator.generateHeadToHeadRecord(
          a['id'],
          b['id'],
          schedule,
        );
        pairs.add({'a': a, 'b': b, 'rec': rec});
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🤼 Đối đầu trực tiếp',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...pairs.map((p) {
          final rec = p['rec'] as Map<String, dynamic>;
          return ListTile(
            title: Text('${p['a']['name']} vs ${p['b']['name']}'),
            subtitle: Text(
              'Đã đấu: ${rec['totalMatches']}, ${p['a']['name']}: ${rec['player1Wins']}, ${p['b']['name']}: ${rec['player2Wins']}, Hòa: ${rec['draws']}',
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStandingsTable() {
    final standings = TournamentDataGenerator.generateRoundRobinStandings(
      playerCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '📊 Bảng xếp hạng',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '#',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Tên',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Thắng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Thua',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Điểm',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              // Standings rows
              ...standings.map(
                (standing) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRankColor(standing['rank']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${standing['rank']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          standing['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${standing['wins']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${standing['losses']}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${standing['points']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMatches() {
    final matches = TournamentDataGenerator.generateRoundRobinMatches(
      playerCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.teal.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '⚔️ Kết quả gần đây',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: matches.map<Widget>((match) => MatchCard(match: match)).toList(),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600; // Gold
      case 2:
        return Colors.grey.shade500; // Silver
      case 3:
        return Colors.orange.shade700; // Bronze
      default:
        return Colors.blue.shade400; // Regular
    }
  }

  void _showRoundRobinInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Round Robin'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hình thức thi đấu vòng tròn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '🔄 Nguyên tắc cơ bản:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text('• Mọi player đấu với mọi player khác'),
              Text('• Mỗi cặp đấu đúng 1 lần'),
              Text('• Không có loại trừ, ai cũng đấu hết'),
              Text('• Xếp hạng theo điểm tích lũy'),
              SizedBox(height: 12),
              Text(
                '📊 Tính điểm:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 4),
              Text('• Thắng = 3 điểm'),
              Text('• Hòa = 1 điểm (nếu có)'),
              Text('• Thua = 0 điểm'),
              Text('• Xếp hạng theo tổng điểm'),
              SizedBox(height: 12),
              Text(
                '⚡ Đặc điểm:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 4),
              Text('• Công bằng nhất (ai cũng đấu với ai)'),
              Text('• Nhiều trận nhất'),
              Text('• Mất thời gian nhất'),
              Text('• Phù hợp với giải nhỏ'),
              SizedBox(height: 12),
              Text(
                '🏆 Ứng dụng:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text('• Vòng bảng World Cup'),
              Text('• Giải đấu câu lạc bộ'),
              Text('• Khi cần đánh giá toàn diện'),
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

// Full screen dialog for Round Robin
class RoundRobinFullscreenDialog extends StatelessWidget {
  final int playerCount;

  const RoundRobinFullscreenDialog({super.key, required this.playerCount});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Round Robin - $playerCount Players'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showRoundRobinInfo(context),
            ),
          ],
        ),
        body: RoundRobinBracket(playerCount: playerCount),
      ),
    );
  }

  void _showRoundRobinInfo(BuildContext context) {
    // Same info dialog as above
  }
}
