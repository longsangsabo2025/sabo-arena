import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
import '../../services/club_analytics_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import 'dart:math' as math;

/// Club owner analytics dashboard
class ClubAnalyticsScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubAnalyticsScreen({
    Key? key,
    required this.clubId,
    required this.clubName,
  }) : super(key: key);

  @override
  State<ClubAnalyticsScreen> createState() => _ClubAnalyticsScreenState();
}

class _ClubAnalyticsScreenState extends State<ClubAnalyticsScreen> {
  final _analyticsService = ClubAnalyticsService.instance;

  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>>? _topMembers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final analytics = await _analyticsService.getClubAnalytics(widget.clubId);
      final topMembers = await _analyticsService.getTopMembers(widget.clubId);

      setState(() {
        _analytics = analytics;
        _topMembers = topMembers;
        _isLoading = false;
      });
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics - ${widget.clubName}'),
        backgroundColor: const Color(0xFF0866FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildOverviewSection(),

                    const SizedBox(height: 24),

                    // Member Stats
                    _buildMemberStatsCard(),

                    const SizedBox(height: 16),

                    // Tournament Stats
                    _buildTournamentStatsCard(),

                    const SizedBox(height: 16),

                    // Revenue Stats
                    _buildRevenueStatsCard(),

                    const SizedBox(height: 16),

                    // Engagement Stats
                    _buildEngagementStatsCard(),

                    const SizedBox(height: 16),

                    // Top Members
                    _buildTopMembersSection(),

                    const SizedBox(height: 16),

                    // Growth Trends
                    _buildGrowthTrendsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    if (_analytics == null) return const SizedBox();

    final memberStats = _analytics!['member_stats'] as Map<String, dynamic>;
    final tournamentStats =
        _analytics!['tournament_stats'] as Map<String, dynamic>;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Thành viên',
            '${memberStats['total_members']}',
            Icons.people,
            Colors.blue,
            '+${memberStats['new_members_30d']} (30d)',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Giải đấu',
            '${tournamentStats['total_tournaments']}',
            Icons.emoji_events,
            Colors.amber,
            '${tournamentStats['ongoing']} đang diễn ra',
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title, style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberStatsCard() {
    if (_analytics == null) return const SizedBox();

    final stats = _analytics!['member_stats'] as Map<String, dynamic>;
    final rankDist = stats['rank_distribution'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👥 Thống kê thành viên', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Tổng thành viên', '${stats['total_members']}'),
            _buildStatRow('Hoạt động (30d)', '${stats['active_members_30d']}'),
            _buildStatRow('Tỷ lệ hoạt động', '${stats['activity_rate']}%'),
            _buildStatRow(
              'Thành viên mới (30d)',
              '${stats['new_members_30d']}',
            ),

            if (rankDist != null && rankDist.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Phân bố hạng:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...rankDist.entries.map(
                (e) => _buildStatRow(e.key, '${e.value}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentStatsCard() {
    if (_analytics == null) return const SizedBox();

    final stats = _analytics!['tournament_stats'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Thống kê giải đấu', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Tổng giải đấu', '${stats['total_tournaments']}'),
            _buildStatRow('Hoàn thành', '${stats['completed']}'),
            _buildStatRow('Đang diễn ra', '${stats['ongoing']}'),
            _buildStatRow('Sắp diễn ra', '${stats['upcoming']}'),
            _buildStatRow('Giải đấu (30d)', '${stats['tournaments_30d']}'),
            _buildStatRow('TB người tham gia', stats['avg_participants']),
            _buildStatRow(
              'Tổng giải thưởng',
              '${stats['total_prize_pool']} VNĐ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueStatsCard() {
    if (_analytics == null) return const SizedBox();

    final stats = _analytics!['revenue_stats'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💰 Doanh thu', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Tổng doanh thu',
              '${stats['total_revenue']} VNĐ',
              valueColor: Colors.green,
            ),
            _buildStatRow('Từ giải đấu', '${stats['tournament_revenue']} VNĐ'),
            _buildStatRow('Từ đặt bàn', '${stats['reservation_revenue']} VNĐ'),
            _buildStatRow(
              'Doanh thu (30d)',
              '${stats['revenue_30d']} VNĐ',
              valueColor: Colors.blue,
            ),
            _buildStatRow(
              'TB/giải đấu',
              '${stats['avg_revenue_per_tournament']} VNĐ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementStatsCard() {
    if (_analytics == null) return const SizedBox();

    final stats = _analytics!['engagement_stats'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Tương tác', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Tổng bài viết', '${stats['total_posts']}'),
            _buildStatRow('Bài viết (30d)', '${stats['posts_30d']}'),
            _buildStatRow('Tổng lượt thích', '${stats['total_likes']}'),
            _buildStatRow('Tổng bình luận', '${stats['total_comments']}'),
            _buildStatRow('TB tương tác/bài', stats['avg_engagement']),
            _buildStatRow('Tỷ lệ tương tác', '${stats['engagement_rate']}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMembersSection() {
    if (_topMembers == null || _topMembers!.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⭐ Top thành viên', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(10, _topMembers!.length),
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final member = _topMembers![index];
                return ListTile(
                  leading: UserAvatarWidget(
                    avatarUrl: member['avatar_url'],
                    size: 40,
                  ),
                  title: UserDisplayNameText(
                    userData: member,
                  ),
                  subtitle: Text(
                    'Rank: ${member['rank'] ?? 'N/A'} | ELO: ${member['elo_rating'] ?? 0}',
                  ),
                  trailing: Text(
                    '${member['total_wins'] ?? 0} thắng', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthTrendsCard() {
    if (_analytics == null) return const SizedBox();

    final trends = _analytics!['growth_trends'] as Map<String, dynamic>;
    final memberGrowth = trends['member_growth'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Xu hướng tăng trưởng (6 tháng)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thành viên mới:', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...memberGrowth.entries.map(
              (e) => _buildStatRow(e.key, '${e.value} người'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value, style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

