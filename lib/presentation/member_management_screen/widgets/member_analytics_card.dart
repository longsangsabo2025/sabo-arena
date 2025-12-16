import 'package:flutter/material.dart';
import '../../../models/member_analytics.dart';

class MemberAnalyticsCard extends StatefulWidget {
  final MemberAnalytics analytics;

  const MemberAnalyticsCard({super.key, required this.analytics});

  @override
  _MemberAnalyticsCardState createState() => _MemberAnalyticsCardState();
}

class _MemberAnalyticsCardState extends State<MemberAnalyticsCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _animations = [
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.2, 0.7, curve: Curves.easeOut),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.4, 0.9, curve: Curves.easeOut),
        ),
      ),
    ];

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thống kê thành viên',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _showDetailedAnalytics,
                icon: Icon(Icons.bar_chart, size: 16),
                label: Text('Chi tiết'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsItem(
                  animation: _animations[0],
                  icon: Icons.trending_up,
                  title: 'Tăng trưởng tháng',
                  value: '+${widget.analytics.memberGrowth?['thisMonth'] ?? 0}',
                  subtitle:
                      'So với tháng trước: ${widget.analytics.memberGrowth?['lastMonth'] ?? 0}',
                  trend:
                      (widget.analytics.memberGrowth?['growthRate'] as num?)
                          ?.toDouble() ??
                      0.0,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsItem(
                  animation: _animations[1],
                  icon: Icons.people_alt,
                  title: 'Hoạt động',
                  value:
                      '${((widget.analytics.activityRate ?? 0) * 100).toInt()}%',
                  subtitle: '${widget.analytics.activeMembers} hoạt động',
                  trend: (widget.analytics.activityRate ?? 0) > 0.7
                      ? 5.0
                      : -2.0,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsItem(
                  animation: _animations[2],
                  icon: Icons.refresh,
                  title: 'Duy trì',
                  value:
                      '${((widget.analytics.retentionRate ?? 0) * 100).toInt()}%',
                  subtitle: 'Tỷ lệ gia hạn',
                  trend: (widget.analytics.retentionRate ?? 0) > 0.5
                      ? 3.2
                      : -1.5,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem({
    required Animation<double> animation,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required double trend,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Opacity(
            opacity: animation.value,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: trend > 0
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trend > 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: trend > 0 ? Colors.green : Colors.red,
                            ),
                            Text(
                              '${trend.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: trend > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailedAnalytics() {
    showDialog(
      context: context,
      builder: (context) =>
          _DetailedAnalyticsDialog(analytics: widget.analytics),
    );
  }
}

class _DetailedAnalyticsDialog extends StatelessWidget {
  final MemberAnalytics analytics;

  const _DetailedAnalyticsDialog({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: 600),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thống kê chi tiết',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      context,
                      'Tăng trưởng thành viên',
                      Icons.trending_up,
                      [
                        _DetailItem(
                          'Tháng này',
                          '${analytics.memberGrowth?['thisMonth'] ?? 0} thành viên',
                        ),
                        _DetailItem(
                          'Tháng trước',
                          '${analytics.memberGrowth?['lastMonth'] ?? 0} thành viên',
                        ),
                        _DetailItem(
                          'Tỷ lệ tăng trưởng',
                          '${((analytics.memberGrowth?['growthRate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                        ),
                        _DetailItem(
                          'Xu hướng',
                          ((analytics.memberGrowth?['growthRate'] as num?)
                                          ?.toDouble() ??
                                      0.0) >
                                  0
                              ? 'Tích cực'
                              : 'Tiêu cực',
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildDetailSection(
                      context,
                      'Tỷ lệ hoạt động',
                      Icons.people_alt,
                      [
                        _DetailItem(
                          'Thành viên hoạt động',
                          '${analytics.activeMembers} người',
                        ),
                        _DetailItem(
                          'Thành viên không hoạt động',
                          '${analytics.totalMembers - analytics.activeMembers} người',
                        ),
                        _DetailItem(
                          'Tỷ lệ hoạt động',
                          '${((analytics.activityRate ?? 0) * 100).toStringAsFixed(1)}%',
                        ),
                        _DetailItem(
                          'Đánh giá',
                          (analytics.activityRate ?? 0) > 0.7
                              ? 'Tốt'
                              : 'Cần cải thiện',
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildDetailSection(context, 'Tỷ lệ duy trì', Icons.refresh, [
                      _DetailItem(
                        'Tỷ lệ gia hạn',
                        '${((analytics.retentionRate ?? 0) * 100).toStringAsFixed(1)}%',
                      ),
                      _DetailItem(
                        'Xu hướng',
                        (analytics.retentionRate ?? 0) > 0.5 ? 'Tăng' : 'Giảm',
                      ),
                      _DetailItem(
                        'Đánh giá',
                        (analytics.retentionRate ?? 0) > 0.8
                            ? 'Xuất sắc'
                            : 'Cần cải thiện',
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Export analytics
                    },
                    icon: Icon(Icons.file_download),
                    label: Text('Xuất báo cáo'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.check),
                    label: Text('Đóng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    IconData icon,
    List<_DetailItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          item.value,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem(this.label, this.value);
}
