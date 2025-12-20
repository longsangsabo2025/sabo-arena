import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/sabo_rank_system.dart';
import '../../widgets/common/app_button.dart';

/// Screen hiển thị lịch sử thay đổi Rank của user
class RankHistoryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const RankHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<RankHistoryScreen> createState() => _RankHistoryScreenState();
}

class _RankHistoryScreenState extends State<RankHistoryScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _rankHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRankHistory();
  }

  Future<void> _loadRankHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load ELO history với rank promotion/demotion
      final response = await _supabase
          .from('elo_history')
          .select('*')
          .eq('user_id', widget.userId)
          .or('change_reason.eq.rank_promotion,change_reason.eq.rank_demotion')
          .order('created_at', ascending: false);

      setState(() {
        _rankHistory = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải lịch sử rank: $e';
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
              'Lịch sử Rank',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.userName,
              style: const TextStyle(
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
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Thử lại',
                          type: AppButtonType.primary,
                          size: AppButtonSize.medium,
                          onPressed: _loadRankHistory,
                        ),
                      ],
                    ),
                  ),
                )
              : _rankHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_up,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có lịch sử thăng/giáng hạng',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tham gia giải đấu để thăng hạng!',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRankHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rankHistory.length,
                        itemBuilder: (context, index) {
                          final record = _rankHistory[index];
                          return _buildRankHistoryCard(record);
                        },
                      ),
                    ),
    );
  }

  Widget _buildRankHistoryCard(Map<String, dynamic> record) {
    final newElo = record['new_elo'] as int? ?? 0;
    final changeReason = record['change_reason'] as String? ?? '';
    final createdAt = DateTime.parse(record['created_at'] as String);

    final isPromotion = changeReason == 'rank_promotion';
    final changeColor = isPromotion ? Colors.green : Colors.orange;
    final changeIcon = isPromotion ? Icons.trending_up : Icons.trending_down;
    final changeText = isPromotion ? 'THĂNG HẠNG' : 'GIÁNG HẠNG';

    // Get rank info from ELO
    final rankCode = SaboRankSystem.getRankFromElo(newElo);
    final rankName = SaboRankSystem.getRankDisplayName(rankCode);
    final rankColor = SaboRankSystem.getRankColor(rankCode);
    final rankMinElo = SaboRankSystem.getRankMinElo(rankCode);
    final rankMaxElo = rankMinElo + 99; // Each rank is 100 ELO range

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: changeColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: changeColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header với gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  changeColor.withValues(alpha: 0.2),
                  changeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Icon + Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: changeColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        changeText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
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
                  DateFormat('dd/MM/yyyy').format(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Body - Rank Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Rank Badge lớn
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        rankColor.withValues(alpha: 0.2),
                        rankColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: rankColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Rank Icon/Letter
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: rankColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: rankColor.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            rankCode,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Rank Name
                      Text(
                        rankName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: rankColor,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ELO Range
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: rankColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'ELO: $rankMinElo-$rankMaxElo',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: rankColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Current ELO at that time
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events,
                          size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'ELO tại thời điểm: ',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        newElo.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
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
