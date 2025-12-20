import 'package:flutter/material.dart';
import '../../core/design_system/typography.dart';
import '../../core/design_system/app_colors.dart';
import '../../services/basic_referral_service.dart';
// ELON_MODE_AUTO_FIX

/// Basic Referral Stats Widget
/// Simple dashboard showing referral statistics and SPA earned
class BasicReferralStatsWidget extends StatefulWidget {
  final String userId;
  final bool showTitle;

  const BasicReferralStatsWidget({
    super.key,
    required this.userId,
    this.showTitle = true,
  });

  @override
  State<BasicReferralStatsWidget> createState() =>
      _BasicReferralStatsWidgetState();
}

class _BasicReferralStatsWidgetState extends State<BasicReferralStatsWidget> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await BasicReferralService.getUserReferralStats(
        widget.userId,
      );
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStats() async {
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thống Kê Giới Thiệu',
                    style: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _refreshStats,
                  icon: Icon(Icons.refresh, color: AppColors.primary, size: 20),
                  tooltip: 'Làm mới thống kê',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (_isLoading)
            _buildLoadingState()
          else if (_stats != null)
            _buildStatsContent()
          else
            _buildErrorState(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Đang tải thống kê...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
                size: 40),
            const SizedBox(height: 8),
            Text(
              'Không thể tải thống kê',
              style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _refreshStats,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    final referralCode = _stats?['user_code'] ?? 'Chưa có';
    final totalReferred = _stats?['total_referred'] ?? 0;
    final totalSpaEarned = _stats?['total_spa_earned'] ?? 0;
    final isActive = _stats?['is_active'] ?? false;

    return Column(
      children: [
        // Current Referral Code
        _buildStatCard(
          icon: Icons.code,
          title: 'Mã Giới Thiệu',
          value: referralCode,
          color: AppColors.primary,
          isCode: true,
        ),

        const SizedBox(height: 12),

        // Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.group_add,
                title: 'Số Lượng\nGiới Thiệu',
                value: totalReferred.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.monetization_on,
                title: 'Tổng SPA\nNhận Được',
                value: totalSpaEarned.toString(),
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Status Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.3)
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.pause_circle,
                color: isActive
                    ? Colors.green
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Mã đang hoạt động' : 'Mã chưa kích hoạt',
                style: AppTypography.bodyMedium.copyWith(
                  color: isActive
                      ? Colors.green.shade700
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        if (totalReferred > 0) ...[
          const SizedBox(height: 12),
          _buildSpaBreakdown(totalReferred, totalSpaEarned),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isCode = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: isCode ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaBreakdown(int totalReferred, int totalSpaEarned) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.amber.shade700, size: 16),
              const SizedBox(width: 8),
              Text(
                'Chi Tiết SPA',
                style: AppTypography.bodyMediumMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số người giới thiệu:', style: AppTypography.bodySmall),
              Text(
                '$totalReferred người',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SPA mỗi lần giới thiệu:', style: AppTypography.bodySmall),
              Text(
                '100 SPA',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Divider(color: Colors.amber.withValues(alpha: 0.3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng SPA đã nhận:',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalSpaEarned SPA',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact stats widget for inline display
class CompactReferralStats extends StatelessWidget {
  final String userId;

  const CompactReferralStats({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BasicReferralStatsWidget(userId: userId, showTitle: false);
  }
}
