import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class MuskDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const MuskDashboardWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final liveOps = metrics['live_ops'] ?? {};
    final financials = metrics['financials'] ?? {};
    final integrity = metrics['integrity'] ?? {};
    final growth = metrics['growth'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGodModeSection(liveOps),
        SizedBox(height: 2.h),
        _buildGridSection(financials, integrity, growth),
        SizedBox(height: 2.h),
        _buildSystemTelemetry(),
      ],
    );
  }

  Widget _buildGodModeSection(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'GOD MODE (LIVE OPS)',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  letterSpacing: 1.5,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 8.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLiveMetric(
                'Active Matches',
                '${data['active_matches'] ?? 0}',
                Icons.sports_tennis,
              ),
              Container(width: 1, height: 40, color: Colors.grey[700]),
              _buildLiveMetric(
                'Online Users',
                '${data['online_users'] ?? 0}',
                Icons.people,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: Colors.grey, size: 14),
            SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.grey,
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridSection(
    Map<String, dynamic> fin,
    Map<String, dynamic> integ,
    Map<String, dynamic> growth,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final revenue = fin['estimated_revenue'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCard(
                'MONEY MACHINE',
                currencyFormat.format(revenue),
                '${fin['transactions'] ?? 0} txns',
                Colors.amber[700]!,
                Icons.attach_money,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildCard(
                'GROWTH',
                '+${growth['new_users_24h'] ?? 0}',
                'K-Factor: ${growth['k_factor'] ?? 0}',
                Colors.blue[600]!,
                Icons.trending_up,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildCard(
          'INTEGRITY (BAN HAMMER)',
          '${integ['high_elo'] ?? 0} High ELO',
          '${integ['reports'] ?? 0} Reports Today',
          Colors.red[400]!,
          Icons.gavel,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildCard(
    String title,
    String mainValue,
    String subValue,
    Color color,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            mainValue,
            style: TextStyle(
              color: Colors.black87,
              fontSize: fullWidth ? 14.sp : 12.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            subValue,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTelemetry() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
          SizedBox(width: 8),
          Text(
            'SYSTEM TELEMETRY',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 9.sp,
              fontFamily: 'monospace',
            ),
          ),
          Spacer(),
          _buildTelemetryItem('API', '24ms'),
          SizedBox(width: 12),
          _buildTelemetryItem('ERR', '0.01%'),
          SizedBox(width: 12),
          _buildTelemetryItem('VER', 'v1.2.4'),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9.sp,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.sp,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
