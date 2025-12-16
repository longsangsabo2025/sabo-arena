import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/user_service.dart';
import '../../core/utils/sabo_rank_system.dart';
import '../../models/user_profile.dart';

class RankStatisticsScreen extends StatefulWidget {
  const RankStatisticsScreen({super.key});

  @override
  State<RankStatisticsScreen> createState() => _RankStatisticsScreenState();
}

class _RankStatisticsScreenState extends State<RankStatisticsScreen> {
  bool _isLoading = true;
  UserProfile? _userProfile;
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>> _recentMatches = [];
  List<Map<String, dynamic>> _rankHistory = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load user profile
      final userProfile = await UserService.instance.getCurrentUserProfile();
      if (userProfile == null) {
        throw Exception('Không thể tải thông tin người dùng');
      }

      final userStats = await UserService.instance.getUserStats(userProfile.id);

      // Simulate rank history (trong thực tế sẽ lấy từ database)
      final rankHistory = _generateRankHistory(userProfile);

      // Simulate recent matches (trong thực tế sẽ lấy từ matches table)
      final recentMatches = _generateRecentMatches();

      setState(() {
        _userProfile = userProfile;
        _userStats = userStats;
        _rankHistory = rankHistory;
        _recentMatches = recentMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateRankHistory(UserProfile profile) {
    // Simulate rank progression over time
    final currentElo = profile.eloRating;
    final history = <Map<String, dynamic>>[];

    // Generate 10 data points showing ELO progression
    for (int i = 9; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 7));
      final baseElo =
          ((currentElo ?? 0) - 100) + (i * 12); // Simulate progression
      final elo = baseElo + (i % 3 == 0 ? -15 : 10); // Add variation

      history.add({
        'date': date,
        'elo': elo.clamp(1000, 2500),
        'rank': SaboRankSystem.getRankFromElo(elo.clamp(1000, 2500)),
      });
    }

    return history;
  }

  List<Map<String, dynamic>> _generateRecentMatches() {
    // Simulate recent match results
    return [
      {
        'opponent': 'Player A',
        'result': 'win',
        'elo_change': '+25',
        'date': '2 ngày trước',
      },
      {
        'opponent': 'Player B',
        'result': 'loss',
        'elo_change': '-18',
        'date': '5 ngày trước',
      },
      {
        'opponent': 'Player C',
        'result': 'win',
        'elo_change': '+22',
        'date': '1 tuần trước',
      },
      {
        'opponent': 'Player D',
        'result': 'win',
        'elo_change': '+28',
        'date': '1 tuần trước',
      },
      {
        'opponent': 'Player E',
        'result': 'loss',
        'elo_change': '-15',
        'date': '2 tuần trước',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thống kê hạng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 8.h, color: Colors.red),
          SizedBox(height: 2.h),
          Text(
            'Có lỗi xảy ra', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            _error!, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _loadUserData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Rank Overview
          _buildCurrentRankCard(),
          SizedBox(height: 3.h),

          // ELO Progress Chart
          _buildEloProgressChart(),
          SizedBox(height: 3.h),

          // Performance Statistics
          _buildPerformanceStats(),
          SizedBox(height: 3.h),

          // Recent Matches
          _buildRecentMatches(),
          SizedBox(height: 3.h),

          // Rank Progression Info
          _buildRankProgressionInfo(),

          SizedBox(height: 3.h),

          // SABO Arena Ranking Rules
          _buildRankingRulesInfo(),
        ],
      ),
    );
  }

  Widget _buildCurrentRankCard() {
    if (_userProfile == null) return const SizedBox();

    final currentRank = _userProfile!.rank ?? 'K';
    final currentElo = _userProfile!.eloRating ?? 0;
    final progress = SaboRankSystem.getRankProgress(currentElo);
    final nextRankInfo = SaboRankSystem.getNextRankInfo(currentElo);
    final currentRankElo = SaboRankSystem.getRankMinElo(currentRank);
    final nextRankElo = nextRankInfo['nextRankElo'] as int;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_events, size: 8.w, color: Colors.white),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạng hiện tại', overflow: TextOverflow.ellipsis, style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      'Hạng ${_userProfile!.rank ?? 'K'}', overflow: TextOverflow.ellipsis, style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      SaboRankSystem.getRankSkillDescription(currentRank),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${SaboRankSystem.formatElo(currentElo ?? 0)} ELO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (nextRankElo > (currentElo ?? 0))
                    Text(
                      'Cần ${nextRankElo - (currentElo ?? 0)} ELO',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.sp,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ lên hạng', overflow: TextOverflow.ellipsis, style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
              SizedBox(height: 1.h),
              if (nextRankElo > (currentElo ?? 0))
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      SaboRankSystem.formatElo(currentRankElo),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      SaboRankSystem.formatElo(nextRankElo),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEloProgressChart() {
    if (_rankHistory.isEmpty) return const SizedBox();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biến động ELO (10 tuần gần đây)',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _rankHistory.length) {
                          final date =
                              _rankHistory[value.toInt()]['date'] as DateTime;
                          return Text(
                            '${date.day}/${date.month}', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.sp),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 10.sp),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _rankHistory.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['elo'].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    if (_userStats == null) return const SizedBox();

    final winRate = _userStats!['total_wins'] + _userStats!['total_losses'] > 0
        ? (_userStats!['total_wins'] /
              (_userStats!['total_wins'] + _userStats!['total_losses']) *
              100)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê hiệu suất', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 4.w,
            mainAxisSpacing: 2.h,
            children: [
              _buildStatCard(
                'Tổng trận',
                '${_userStats!['total_matches']}',
                Icons.sports_esports,
                Colors.blue,
              ),
              _buildStatCard(
                'Tỷ lệ thắng',
                '${winRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
              _buildStatCard(
                'Chuỗi thắng',
                '${_userStats!['win_streak']}',
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildStatCard(
                'Giải đấu',
                '${_userStats!['total_tournaments']}',
                Icons.emoji_events,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value, style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMatches() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trận đấu gần đây', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full match history
                },
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentMatches.length,
            separatorBuilder: (context, index) => Divider(height: 2.h),
            itemBuilder: (context, index) {
              final match = _recentMatches[index];
              final isWin = match['result'] == 'win';

              return Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: isWin ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWin ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 4.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'vs ${match['opponent']}', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          match['date'], overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isWin
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match['elo_change'], overflow: TextOverflow.ellipsis, style: TextStyle(
                        color: isWin ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankProgressionInfo() {
    final allRanks = SaboRankSystem.getAllRanksOrdered();
    final currentRank = _userProfile?.rank ?? 'K';
    final currentIndex = allRanks.indexOf(currentRank);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hệ thống hạng SABO Arena', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allRanks.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final rank = allRanks[index];
              final rankElo = SaboRankSystem.getRankMinElo(rank);
              final rankSkill = SaboRankSystem.getRankSkillDescription(rank);
              final isCurrentRank = rank == currentRank;
              final isPassed = index < currentIndex;
              final isNext = index == currentIndex + 1;

              return Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isCurrentRank
                      ? Colors.blue.withValues(alpha: 0.1)
                      : isPassed
                      ? Colors.green.withValues(alpha: 0.05)
                      : isNext
                      ? Colors.orange.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentRank
                        ? Colors.blue
                        : isPassed
                        ? Colors.green
                        : isNext
                        ? Colors.orange
                        : Colors.grey.withValues(alpha: 0.3),
                    width: isCurrentRank ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCurrentRank
                          ? Icons.star
                          : isPassed
                          ? Icons.check_circle
                          : isNext
                          ? Icons.radio_button_unchecked
                          : Icons.lock_outline,
                      color: isCurrentRank
                          ? Colors.blue
                          : isPassed
                          ? Colors.green
                          : isNext
                          ? Colors.orange
                          : Colors.grey,
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hạng $rank', overflow: TextOverflow.ellipsis, style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentRank
                                      ? Colors.blue
                                      : Colors.black87,
                                ),
                              ),
                              if (isCurrentRank)
                                Container(
                                  margin: EdgeInsets.only(left: 2.w),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 0.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Hiện tại', overflow: TextOverflow.ellipsis, style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            rankSkill, style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$rankElo ELO', overflow: TextOverflow.ellipsis, style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isCurrentRank ? Colors.blue : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingRulesInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 6.w),
              SizedBox(width: 3.w),
              Text(
                'Quy định hạng SABO Arena', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Ranking System Overview
          _buildRuleSection(
            'Hệ thống xếp hạng',
            [
              '• SABO Arena sử dụng hệ thống ELO Rating',
              '• 12 cấp hạng từ K (thấp nhất) đến C (cao nhất), sẽ phát triển tới các hạng cao hơn trong tương lai',
              '• Mỗi hạng có ngưỡng ELO riêng biệt',
              '• Hạng được cập nhật tự động theo ELO',
            ],
            Icons.emoji_events,
            Colors.blue,
          ),

          SizedBox(height: 2.h),

          // ELO System
          _buildRuleSection(
            'Cơ chế ELO Rating',
            [
              '• Người mới bắt đầu: 1000 ELO (Hạng K)',
              '• Thành viên club được xác minh hạng sẽ được cập nhật điểm elo tương ứng, ví dụ: 1200 ELO (Hạng I)',
              '• ELO tích lũy dần khi người chơi tham gia các giải đấu',
              '• Bonus ELO từ giải đấu và thành tích',
            ],
            Icons.trending_up,
            Colors.green,
          ),

          SizedBox(height: 2.h),

          // Rank Requirements
          _buildRuleSection(
            'Yêu cầu lên hạng',
            [
              '• Đạt đủ ELO minimum của hạng mục tiêu',
              '• Duy trì performance ổn định',
              '• Tham gia các giải đấu để kiếm ELO',
              '• Hạng không bao giờ bị giảm (chỉ ELO giảm)',
            ],
            Icons.arrow_upward,
            Colors.orange,
          ),

          SizedBox(height: 2.h),

          // Skill Level Descriptions
          _buildRuleSection(
            'Mô tả trình độ theo hạng',
            [
              '• Hạng K: Người mới tập, 2-4 bi khi hình dễ',
              '• Hạng I: Thợ 3, biết 3-5 bi cơ bản',
              '• Hạng H: Thợ 1, làm được 5-8 bi và "rùa" 1 chấm',
              '• Hạng G: Thợ giỏi, clear 1 chấm + điều bi 3 băng',
              '• Hạng F: Chuyên gia, 60-80% clear 1 chấm',
              '• Hạng E: Xuất sắc, 60-80% clear 1 chấm + safety',
              '• Hạng D: Huyền thoại, master cơ hội và kỹ thuật',
              '• Hạng C: Vô địch, điều bi phức tạp + safety chủ động',
            ],
            Icons.psychology,
            Colors.purple,
          ),

          SizedBox(height: 2.h),

          // Tournament Benefits
          _buildRuleSection(
            'Lợi ích từ hạng cao',
            [
              '• Ưu tiên tham gia giải đấu cao cấp',
              '• Nhận thưởng SPA Points nhiều hơn',
              '• Được tôn vinh trong bảng xếp hạng',
              '• Cơ hội trở thành coach/mentor',
            ],
            Icons.star,
            Colors.amber,
          ),

          SizedBox(height: 2.h),

          // Footer note
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue, size: 5.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Hạng của bạn được tính dựa trên ELO hiện tại. Hãy tham gia nhiều trận đấu và giải đấu để nâng cao ELO và lên hạng!', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue[700],
                      fontStyle: FontStyle.italic,
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

  Widget _buildRuleSection(
    String title,
    List<String> rules,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                title, style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...rules
              .map(
                (rule) => Padding(
                  padding: EdgeInsets.only(bottom: 0.5.h),
                  child: Text(
                    rule, style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ),
              )
              ,
        ],
      ),
    );
  }
}
