/// Member Growth Chart Widget
///
/// Displays member growth trends over time using line charts
/// Powered by fl_chart library

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/design_system.dart' as ds;

class MemberGrowthData {
  final DateTime date;
  final int count;

  MemberGrowthData({required this.date, required this.count});
}

class MemberGrowthChart extends StatefulWidget {
  final List<MemberGrowthData> data;
  final String title;
  final Color? lineColor;
  final bool showGrid;

  const MemberGrowthChart({
    super.key,
    required this.data,
    this.title = 'Tăng trưởng thành viên',
    this.lineColor,
    this.showGrid = true,
  });

  @override
  State<MemberGrowthChart> createState() => _MemberGrowthChartState();
}

class _MemberGrowthChartState extends State<MemberGrowthChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate min/max for better visualization
    final values = widget.data.map((d) => d.count).toList();
    final minY = values.reduce((a, b) => a < b ? a : b).toDouble();
    final maxY = values.reduce((a, b) => a > b ? a : b).toDouble();
    final range = maxY - minY;
    final padding = range * 0.2; // 20% padding

    return Container(
      padding: const EdgeInsets.all(ds.AppSpacing.md),
      decoration: BoxDecoration(
        color: ds.AppColors.surface,
        borderRadius: BorderRadius.circular(ds.AppRadius.card),
        border: Border.all(color: ds.AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: ds.AppTypography.h5()),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: ds.AppSpacing.md),

          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY - padding < 0 ? 0 : minY - padding,
                maxY: maxY + padding,
                gridData: FlGridData(
                  show: widget.showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: ds.AppColors.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _calculateBottomInterval(),
                      getTitlesWidget: (value, meta) {
                        return _buildBottomTitle(value.toInt());
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY - minY) / 4,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: ds.AppTypography.caption(
                            color: ds.AppColors.grey600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: widget.lineColor ?? ds.AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: index == _selectedIndex ? 6 : 4,
                          color: widget.lineColor ?? ds.AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: ds.AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (widget.lineColor ?? ds.AppColors.primary)
                              .withValues(alpha: 0.3),
                          (widget.lineColor ?? ds.AppColors.primary)
                              .withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (response?.lineBarSpots != null &&
                        response!.lineBarSpots!.isNotEmpty) {
                      setState(() {
                        _selectedIndex = response.lineBarSpots!.first.spotIndex;
                      });
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => ds.AppColors.grey900,
                    tooltipRoundedRadius: ds.AppRadius.sm,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final data = widget.data[spot.spotIndex];
                        return LineTooltipItem(
                          '${data.count} thành viên\n${_formatDate(data.date)}',
                          ds.AppTypography.caption(
                            color: ds.AppColors.surface,
                          ).copyWith(fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: ds.AppDuration.normal,
              curve: Curves.easeInOut,
            ),
          ),

          // Stats Summary
          const SizedBox(height: ds.AppSpacing.md),
          _buildStatsSummary(),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return widget.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
    }).toList();
  }

  Widget _buildBottomTitle(int index) {
    if (index < 0 || index >= widget.data.length) {
      return const SizedBox.shrink();
    }

    final date = widget.data[index].date;
    String label;

    if (widget.data.length > 30) {
      // Show month for large datasets
      label = '${date.month}/${date.year.toString().substring(2)}';
    } else if (widget.data.length > 7) {
      // Show day/month for medium datasets
      label = '${date.day}/${date.month}';
    } else {
      // Show day for small datasets
      label = '${date.day}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: ds.AppTypography.labelSmall(color: ds.AppColors.grey600),
      ),
    );
  }

  double _calculateBottomInterval() {
    final count = widget.data.length;
    if (count <= 7) return 1;
    if (count <= 30) return (count / 5).floorToDouble();
    return (count / 6).floorToDouble();
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.lineColor ?? ds.AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Thành viên',
          style: ds.AppTypography.caption(color: ds.AppColors.grey600),
        ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    if (widget.data.length < 2) return const SizedBox.shrink();

    final firstCount = widget.data.first.count;
    final lastCount = widget.data.last.count;
    final growth = lastCount - firstCount;
    final growthPercent = firstCount > 0
        ? ((growth / firstCount) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(ds.AppSpacing.sm),
      decoration: BoxDecoration(
        color: growth >= 0
            ? ds.AppColors.success.withValues(alpha: 0.1)
            : ds.AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.AppRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Tổng', lastCount.toString()),
          _buildStat('Tăng trưởng', '${growth >= 0 ? '+' : ''}$growth'),
          _buildStat('Tỷ lệ', '${growth >= 0 ? '+' : ''}$growthPercent%'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: ds.AppTypography.h6().copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: ds.AppTypography.caption(color: ds.AppColors.grey600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(ds.AppSpacing.lg),
      decoration: BoxDecoration(
        color: ds.AppColors.surface,
        borderRadius: BorderRadius.circular(ds.AppRadius.card),
        border: Border.all(color: ds.AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 64,
            color: ds.AppColors.grey400,
          ),
          const SizedBox(height: ds.AppSpacing.md),
          Text(
            'Chưa có dữ liệu',
            style: ds.AppTypography.bodyLarge(color: ds.AppColors.grey600),
          ),
          const SizedBox(height: ds.AppSpacing.xs),
          Text(
            'Biểu đồ sẽ hiển thị khi có thành viên mới',
            style: ds.AppTypography.caption(color: ds.AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Revenue Sparkline Widget - Compact trend visualization
class RevenueSparkline extends StatelessWidget {
  final List<double> data;
  final Color? color;
  final double height;

  const RevenueSparkline({
    super.key,
    required this.data,
    this.color,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Chưa có dữ liệu',
            style: ds.AppTypography.caption(color: ds.AppColors.grey500),
          ),
        ),
      );
    }

    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY * 0.9,
          maxY: maxY * 1.1,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: color ?? ds.AppColors.primary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (color ?? ds.AppColors.primary).withValues(alpha: 0.3),
                    (color ?? ds.AppColors.primary).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: ds.AppDuration.fast,
        curve: Curves.easeInOut,
      ),
    );
  }
}
