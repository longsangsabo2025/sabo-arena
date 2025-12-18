import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/notification_analytics_service.dart';
import '../models/notification_models.dart';

class NotificationAnalyticsDashboard extends StatefulWidget {
  const NotificationAnalyticsDashboard({super.key});

  @override
  State<NotificationAnalyticsDashboard> createState() =>
      _NotificationAnalyticsDashboardState();
}

class _NotificationAnalyticsDashboardState
    extends State<NotificationAnalyticsDashboard> {
  final NotificationAnalyticsService _analyticsService =
      NotificationAnalyticsService.instance;

  NotificationAnalytics? _analytics;
  Map<String, dynamic>? _realTimeMetrics;
  bool _isLoading = true;
  String _selectedPeriod = '30d';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _loadRealTimeMetrics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    DateTime startDate;
    switch (_selectedPeriod) {
      case '7d':
        startDate = DateTime.now().subtract(const Duration(days: 7));
        break;
      case '30d':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case '90d':
        startDate = DateTime.now().subtract(const Duration(days: 90));
        break;
      default:
        startDate = DateTime.now().subtract(const Duration(days: 30));
    }

    final analytics = await _analyticsService.getNotificationAnalytics(
      startDate: startDate,
      endDate: DateTime.now(),
    );

    setState(() {
      _analytics = analytics;
      _isLoading = false;
    });
  }

  Future<void> _loadRealTimeMetrics() async {
    final metrics = await _analyticsService.getRealTimeMetrics();
    setState(() => _realTimeMetrics = metrics);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Phân tích thông báo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('7 ngày qua')),
              const PopupMenuItem(value: '30d', child: Text('30 ngày qua')),
              const PopupMenuItem(value: '90d', child: Text('90 ngày qua')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPeriodLabel(_selectedPeriod),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadAnalytics();
                await _loadRealTimeMetrics();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Real-time metrics cards
                    if (_realTimeMetrics != null) _buildRealTimeMetricsCards(),
                    const SizedBox(height: 20),

                    // Main statistics cards
                    if (_analytics != null) _buildMainStatsCards(),
                    const SizedBox(height: 20),

                    // Charts section
                    if (_analytics != null) _buildChartsSection(),
                    const SizedBox(height: 20),

                    // Type breakdown
                    if (_analytics != null) _buildTypeBreakdown(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRealTimeMetricsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chỉ số thời gian thực (24h qua)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Đã gửi',
                '${_realTimeMetrics!['notifications_sent_24h']}',
                Icons.send,
                const Color(0xFF1877F2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Đã đọc',
                '${_realTimeMetrics!['notifications_read_24h']}',
                Icons.mark_email_read,
                const Color(0xFF42B883),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Người dùng hoạt động',
                '${_realTimeMetrics!['active_users_24h']}',
                Icons.people,
                const Color(0xFFE1306C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Thời gian đọc TB',
                '${_realTimeMetrics!['avg_read_time_minutes']}m',
                Icons.schedule,
                const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan (${_getPeriodLabel(_selectedPeriod)})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tổng đã gửi',
                '${_analytics!.totalSent}',
                '${_analytics!.deliveryRate.toStringAsFixed(1)}% đã gửi',
                Icons.outbox,
                const Color(0xFF1877F2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Tổng đã đọc',
                '${_analytics!.totalRead}',
                '${_analytics!.readRate.toStringAsFixed(1)}% tỷ lệ đọc',
                Icons.visibility,
                const Color(0xFF42B883),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Đã nhấn',
                '${_analytics!.totalClicked}',
                '${_analytics!.clickRate.toStringAsFixed(1)}% tỷ lệ nhấn',
                Icons.touch_app,
                const Color(0xFFE1306C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Tương tác',
                _analytics!.engagementMetrics.averageEngagementScore.toStringAsFixed(1),
                '${_analytics!.engagementMetrics.totalActiveUsers} người dùng hoạt động',
                Icons.trending_up,
                const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xu hướng & Mẫu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Hourly distribution chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân phối hoạt động theo giờ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}h');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _analytics!.hourlyDistribution.map((activity) {
                          return FlSpot(
                            activity.hour.toDouble(),
                            activity.notificationsSent.toDouble(),
                          );
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF1877F2),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Daily trends chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xu hướng hàng ngày',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 &&
                                index < _analytics!.dailyTrends.length) {
                              final date = _analytics!.dailyTrends[index].date;
                              return Text('${date.day}/${date.month}');
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _analytics!.dailyTrends.asMap().entries.map((
                          entry,
                        ) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.notificationsSent.toDouble(),
                          );
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF42B883),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
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

  Widget _buildTypeBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hiệu suất theo loại thông báo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ..._analytics!.deliveryRatesByType.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForType(entry.key),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case '7d':
        return 'Last 7 days';
      case '30d':
        return 'Last 30 days';
      case '90d':
        return 'Last 90 days';
      default:
        return 'Last 30 days';
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.tournamentInvitation:
        return const Color(0xFF1877F2);
      case NotificationType.matchResult:
        return const Color(0xFF42B883);
      case NotificationType.challengeRequest:
        return const Color(0xFFE1306C);
      case NotificationType.clubAnnouncement:
        return const Color(0xFFFF6B35);
      case NotificationType.friendRequest:
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }
}
