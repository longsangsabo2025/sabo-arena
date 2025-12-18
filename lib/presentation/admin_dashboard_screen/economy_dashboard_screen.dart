import 'package:flutter/material.dart';
import '../../services/economy_monitoring_service.dart';
// ELON_MODE_AUTO_FIX

/// Admin dashboard for monitoring SPA economy health
class EconomyDashboardScreen extends StatefulWidget {
  const EconomyDashboardScreen({super.key});

  @override
  State<EconomyDashboardScreen> createState() => _EconomyDashboardScreenState();
}

class _EconomyDashboardScreenState extends State<EconomyDashboardScreen> {
  final _economyService = EconomyMonitoringService.instance;

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _flowAnalysis;
  List<Map<String, String>>? _alerts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _economyService.getEconomyStats();
      final flow = await _economyService.getSPAFlowAnalysis();
      final alerts = await _economyService.getEconomyAlerts();

      setState(() {
        _stats = stats;
        _flowAnalysis = flow;
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Economy Monitor'),
        backgroundColor: const Color(0xFF0866FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alerts Section
                    if (_alerts != null && _alerts!.isNotEmpty)
                      _buildAlertsSection(),

                    const SizedBox(height: 16),

                    // Health Metrics
                    _buildHealthMetricsCard(),

                    const SizedBox(height: 16),

                    // Circulation Stats
                    _buildCirculationCard(),

                    const SizedBox(height: 16),

                    // Transaction Stats
                    _buildTransactionCard(),

                    const SizedBox(height: 16),

                    // Wealth Distribution
                    _buildWealthDistributionCard(),

                    const SizedBox(height: 16),

                    // SPA Flow Analysis
                    _buildFlowAnalysisCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚨 Alerts', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._alerts!.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, String> alert) {
    Color color;
    IconData icon;

    switch (alert['level']) {
      case 'critical':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert['message'] ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(color: color.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricsCard() {
    if (_stats == null) return const SizedBox();

    final health = _stats!['health_metrics'] as Map<String, dynamic>;
    final status = health['status'] as String;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'healthy':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'moderate':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📊 Economy Health', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(statusIcon, color: statusColor, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Status', status.toUpperCase(), statusColor),
            _buildMetricRow('Velocity', health['velocity'] ?? 'N/A'),
            _buildMetricRow('Concentration', health['concentration'] ?? 'N/A'),
            _buildMetricRow(
              'Inflation Risk',
              health['inflation_risk'] ?? 'N/A',
            ),
            const Divider(height: 24),
            Text(
              health['recommendation'] ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCirculationCard() {
    if (_stats == null) return const SizedBox();

    final circulation =
        _stats!['total_spa_circulation'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💰 SPA Circulation', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Total SPA',
              _formatNumber(circulation['total_spa'] ?? 0),
            ),
            _buildMetricRow(
              'User SPA',
              _formatNumber(circulation['user_spa'] ?? 0),
            ),
            _buildMetricRow(
              'Pending Transactions',
              _formatNumber(circulation['pending_spa'] ?? 0),
            ),
            _buildMetricRow(
              'In Challenges',
              _formatNumber(circulation['challenge_spa'] ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard() {
    if (_stats == null) return const SizedBox();

    final txnStats = _stats!['transaction_stats'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Transaction Activity', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Last 24h Transactions',
              '${txnStats['transactions_24h'] ?? 0}',
            ),
            _buildMetricRow(
              'Last 24h Volume',
              _formatNumber(txnStats['volume_24h'] ?? 0),
            ),
            _buildMetricRow(
              'Last 7 Days',
              '${txnStats['transactions_7days'] ?? 0}',
            ),
            _buildMetricRow(
              'Avg Transaction',
              _formatNumber((txnStats['avg_transaction_24h'] ?? 0).round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWealthDistributionCard() {
    if (_stats == null) return const SizedBox();

    final wealth = _stats!['wealth_distribution'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👥 Wealth Distribution', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Total Users', '${wealth['total_users'] ?? 0}'),
            _buildMetricRow('Top 1% Owns', '${wealth['top_1_percent'] ?? 0}%'),
            _buildMetricRow(
              'Top 10% Owns',
              '${wealth['top_10_percent'] ?? 0}%',
            ),
            _buildMetricRow('Median SPA', _formatNumber(wealth['median'] ?? 0)),
            _buildMetricRow(
              'Average SPA',
              _formatNumber(wealth['average'] ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowAnalysisCard() {
    if (_flowAnalysis == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔄 SPA Flow (Last 30 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Total Earned',
              _formatNumber(_flowAnalysis!['total_earned'] ?? 0),
              Colors.green,
            ),
            _buildMetricRow(
              'Total Spent',
              _formatNumber(_flowAnalysis!['total_spent'] ?? 0),
              Colors.red,
            ),
            _buildMetricRow(
              'Net Flow',
              _formatNumber(_flowAnalysis!['net_flow'] ?? 0),
              (_flowAnalysis!['net_flow'] ?? 0) >= 0
                  ? Colors.green
                  : Colors.red,
            ),
            _buildMetricRow(
              'Balance Ratio',
              '${_flowAnalysis!['balance_ratio'] ?? 'N/A'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value, style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

