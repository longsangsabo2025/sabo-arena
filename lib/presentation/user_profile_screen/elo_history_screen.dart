import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// Screen hiển thị lịch sử thay đổi ELO của user
class EloHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const EloHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<EloHistoryScreen> createState() => _EloHistoryScreenState();
}

class _EloHistoryScreenState extends State<EloHistoryScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _eloHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEloHistory();
  }

  Future<void> _loadEloHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('elo_history')
          .select('*')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      setState(() {
        _eloHistory = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải lịch sử ELO: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử ELO', overflow: TextOverflow.ellipsis, style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.userName, style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center, style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadEloHistory,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _eloHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có lịch sử thay đổi ELO', overflow: TextOverflow.ellipsis, style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEloHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _eloHistory.length,
                        itemBuilder: (context, index) {
                          final record = _eloHistory[index];
                          return _buildEloHistoryCard(record);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEloHistoryCard(Map<String, dynamic> record) {
    final oldElo = record['old_elo'] as int? ?? 0;
    final newElo = record['new_elo'] as int? ?? 0;
    final change = record['elo_change'] as int? ?? 0; // FIX: Use 'elo_change' not 'change'
    final changeReason = record['change_reason'] as String? ?? '';
    final reason = record['reason'] as String? ?? ''; // Also get 'reason' field
    final createdAt = DateTime.parse(record['created_at'] as String);
    final tournamentId = record['tournament_id'] as String?;

    final isPositive = change > 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return FutureBuilder<String>(
      future: _getDetailedReason(reason, changeReason, tournamentId),
      builder: (context, snapshot) {
        final reasonText = snapshot.data ?? changeReason.replaceAll('_', ' ');
        final reasonInfo = _getReasonInfo(reason, reasonText);
        
        return _buildHistoryCard(
          changeColor: changeColor,
          changeIcon: changeIcon,
          change: change,
          isPositive: isPositive,
          createdAt: createdAt,
          reasonInfo: reasonInfo,
          oldElo: oldElo,
          newElo: newElo,
          tournamentId: tournamentId,
        );
      },
    );
  }

  Widget _buildHistoryCard({
    required Color changeColor,
    required IconData changeIcon,
    required int change,
    required bool isPositive,
    required DateTime createdAt,
    required Map<String, String> reasonInfo,
    required int oldElo,
    required int newElo,
    String? tournamentId,
  }) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: changeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: changeColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header với gradient background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  changeColor.withValues(alpha: 0.1),
                  changeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                // Icon + Change amount - PROMINENT
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: changeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${isPositive ? '+' : ''}$change điểm', overflow: TextOverflow.ellipsis, style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Time
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM HH:mm').format(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason with emoji
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: changeColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        reasonInfo['emoji'] as String, style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lý do', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reasonInfo['text'] as String, style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ELO Change visualization
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Old ELO
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'ELO cũ', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                oldElo.toString(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow with change
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              size: 24,
                              color: changeColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${isPositive ? '+' : ''}$change', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: changeColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // New ELO
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'ELO mới', overflow: TextOverflow.ellipsis, style: TextStyle(
                                fontSize: 12,
                                color: changeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: changeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: changeColor.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                newElo.toString(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: changeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tournament info (nếu có)
                if (tournamentId != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00695C).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Color(0xFF00695C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Từ giải đấu', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getReasonInfo(String reason, String detailedText) {
    String emoji;
    
    switch (reason) {
      case 'tournament_position_1':
        emoji = '🏆';
        break;
      case 'tournament_position_2':
        emoji = '🥈';
        break;
      case 'tournament_position_3':
      case 'tournament_position_4':
        emoji = '🥉';
        break;
      case 'tournament_participation':
        emoji = '�';
        break;
      case 'tournament_completion_backend_test':
      case 'tournament_completion':
        emoji = '✅';
        break;
      case 'match_win':
        emoji = '✅';
        break;
      case 'match_loss':
        emoji = '❌';
        break;
      case 'rank_promotion':
        emoji = '⬆️';
        break;
      case 'rank_demotion':
        emoji = '⬇️';
        break;
      case 'manual_adjustment':
        emoji = '🔧';
        break;
      default:
        emoji = '📊';
    }
    
    return {'emoji': emoji, 'text': detailedText};
  }

  /// Get detailed reason text with tournament info
  Future<String> _getDetailedReason(
    String reason,
    String changeReason,
    String? tournamentId,
  ) async {
    // If no tournament ID, return basic reason
    if (tournamentId == null || tournamentId.isEmpty) {
      return _getBasicReasonText(reason);
    }

    try {
      // Query tournament info with format
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('name, id, format')
          .eq('id', tournamentId)
          .single();

      final tournamentName = tournamentResponse['name'] as String? ?? 'Giải đấu';
      final tournamentFormat = tournamentResponse['format'] as String? ?? '';

      // Query participant info to get position and stats
      final participantResponse = await _supabase
          .from('tournament_participants')
          .select('final_position, wins, losses')
          .eq('tournament_id', tournamentId)
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (participantResponse != null) {
        final position = participantResponse['final_position'] as int?;
        final wins = participantResponse['wins'] as int? ?? 0;
        final losses = participantResponse['losses'] as int? ?? 0;

        // Build detailed text with position, stats, and format
        String positionText = '';
        if (position != null) {
          if (position == 1) {
            positionText = '🏆 Vô địch';
          } else if (position == 2) {
            positionText = '🥈 Á quân';
          } else if (position == 3 || position == 4) {
            positionText = '🥉 Hạng $position';
          } else if (position <= 8) {
            positionText = 'Top $position';
          } else {
            positionText = 'Hạng $position';
          }
        }

        // Format type display
        String formatText = '';
        if (tournamentFormat.isNotEmpty) {
          final formatMap = {
            'de8': 'Loại trực tiếp 8',
            'de16': 'Loại trực tiếp 16',
            'de32': 'Loại trực tiếp 32',
            'de64': 'Loại trực tiếp 64',
            'round_robin': 'Vòng tròn',
            'swiss': 'Swiss',
            'song_to': 'Song Tô',
          };
          formatText = formatMap[tournamentFormat] ?? tournamentFormat.toUpperCase();
        }

        // Build complete description
        List<String> parts = [];
        if (positionText.isNotEmpty) parts.add(positionText);
        if (formatText.isNotEmpty) parts.add(formatText);
        parts.add('$wins-$losses');
        
        return '$tournamentName\n${parts.join(' • ')}';
      }

      return tournamentName;
    } catch (e) {
      ProductionLogger.info('Error loading tournament details: $e', tag: 'elo_history_screen');
      return _getBasicReasonText(reason);
    }
  }

  String _getBasicReasonText(String reason) {
    switch (reason) {
      case 'tournament_position_1':
        return 'Vô địch giải đấu';
      case 'tournament_position_2':
        return 'Á quân giải đấu';
      case 'tournament_position_3':
      case 'tournament_position_4':
        return 'Hạng 3-4 giải đấu';
      case 'tournament_participation':
        return 'Tham gia giải đấu';
      case 'tournament_completion_backend_test':
      case 'tournament_completion':
        return 'Hoàn thành giải đấu';
      case 'match_win':
        return 'Thắng trận đấu';
      case 'match_loss':
        return 'Thua trận đấu';
      case 'rank_promotion':
        return 'Thăng hạng';
      case 'rank_demotion':
        return 'Giáng hạng';
      case 'manual_adjustment':
        return 'Điều chỉnh thủ công';
      default:
        return reason.replaceAll('_', ' ');
    }
  }
}
