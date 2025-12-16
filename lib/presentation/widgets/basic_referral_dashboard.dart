import 'package:flutter/material.dart';
import 'basic_referral_card.dart';
import 'basic_referral_code_input.dart';
import 'basic_referral_stats_widget.dart';
import '../../core/design_system/typography.dart';
import '../../core/design_system/app_colors.dart';

/// Complete Basic Referral Dashboard
/// Combines all referral widgets into a comprehensive dashboard
class BasicReferralDashboard extends StatefulWidget {
  final String userId;
  final bool allowCodeInput;
  final bool showStats;

  const BasicReferralDashboard({
    super.key,
    required this.userId,
    this.allowCodeInput = true,
    this.showStats = true,
  });

  @override
  State<BasicReferralDashboard> createState() => _BasicReferralDashboardState();
}

class _BasicReferralDashboardState extends State<BasicReferralDashboard> {
  final GlobalKey<State<BasicReferralStatsWidget>> _statsKey = GlobalKey();

  void _onStatsUpdate() {
    // Refresh stats when user generates new code or applies code
    // Force widget rebuild to refresh stats
    setState(() {});
  }

  void _onCodeApplied(bool success, String message) {
    // Show result and refresh stats
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    if (success) {
      _onStatsUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎁 Hệ Thống Giới Thiệu',
                  style: AppTypography.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giới thiệu bạn bè và nhận thưởng SPA',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // My Referral Code Card
          BasicReferralCard(
            userId: widget.userId,
            onStatsUpdate: _onStatsUpdate,
          ),

          // Code Input Section (if allowed)
          if (widget.allowCodeInput) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(
                color: AppColors.primary.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            BasicReferralCodeInput(
              userId: widget.userId,
              onResult: _onCodeApplied,
            ),
          ],

          // Stats Section (if enabled)
          if (widget.showStats) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(
                color: AppColors.primary.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            BasicReferralStatsWidget(key: _statsKey, userId: widget.userId),
          ],

          // How It Works Section
          _buildHowItWorksSection(),

          // Footer spacing
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.05),
            Colors.indigo.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Cách Thức Hoạt Động',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStep(
            step: '1',
            title: 'Tạo mã giới thiệu',
            description: 'Nhấn "Tạo Mã Giới Thiệu" để có mã riêng của bạn',
            icon: Icons.add_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStep(
            step: '2',
            title: 'Chia sẻ với bạn bè',
            description: 'Gửi mã cho bạn bè qua tin nhắn hoặc mạng xã hội',
            icon: Icons.share,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStep(
            step: '3',
            title: 'Nhận thưởng SPA',
            description: 'Bạn nhận +100 SPA, bạn bè nhận +50 SPA khi đăng ký',
            icon: Icons.monetization_on,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mẹo: Chia sẻ mã trong các nhóm bida hoặc khi gặp bạn bè mới để tăng cơ hội nhận thưởng!',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.amber.shade800,
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

  Widget _buildStep({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              step,
              style: AppTypography.headingXSmall.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headingXSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mini referral widget for quick access
class MiniReferralWidget extends StatelessWidget {
  final String userId;
  final VoidCallback? onTapExpand;

  const MiniReferralWidget({super.key, required this.userId, this.onTapExpand});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTapExpand,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(Icons.card_giftcard, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giới thiệu bạn bè',
                    style: AppTypography.bodyMediumMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Nhận +100 SPA mỗi lần giới thiệu',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
