import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design_system/typography.dart';
import '../../core/design_system/app_colors.dart';
import '../../services/basic_referral_service.dart';
import '../referral_history/referral_history_screen.dart';
// ELON_MODE_AUTO_FIX

/// Basic Referral Card Widget
/// Displays user's referral code with sharing functionality
class BasicReferralCard extends StatefulWidget {
  final String userId;
  final VoidCallback? onStatsUpdate;

  const BasicReferralCard({
    super.key,
    required this.userId,
    this.onStatsUpdate,
  });

  @override
  State<BasicReferralCard> createState() => _BasicReferralCardState();
}

class _BasicReferralCardState extends State<BasicReferralCard> {
  String? _referralCode;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateReferralCode();
  }

  Future<void> _loadOrGenerateReferralCode() async {
    setState(() => _isLoading = true);

    try {
      // Try to get existing code first
      final stats = await BasicReferralService.getUserReferralStats(
        widget.userId,
      );

      if (stats['user_code'] != null) {
        setState(() {
          _referralCode = stats['user_code'];
          _isLoading = false;
        });
      } else {
        // Generate new code if doesn't exist
        await _generateNewCode();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateNewCode() async {
    setState(() => _isGenerating = true);

    try {
      final newCode = await BasicReferralService.generateReferralCode(
        widget.userId,
      );

      if (newCode != null) {
        if (!mounted) return;
        setState(() {
          _referralCode = newCode;
          _isGenerating = false;
          _isLoading = false;
        });

        widget.onStatsUpdate?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Mã giới thiệu đã được tạo: $newCode'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to generate code');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi tạo mã giới thiệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_referralCode != null) {
      await Clipboard.setData(ClipboardData(text: _referralCode!));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 Đã sao chép mã: $_referralCode'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareReferralCode() async {
    if (_referralCode != null) {
      final shareText =
          '''
🏆 Tham gia SABO Arena cùng tôi!

🎯 Sử dụng mã giới thiệu: $_referralCode
💰 Nhận ngay 50 điểm SPA miễn phí!

📱 Tải app SABO Arena và bắt đầu chinh phục bàn bida ngay hôm nay!

#SABOArena #BidaOnline #GioiThieu
''';

      await Share.share(
        shareText,
        subject: 'Tham gia SABO Arena với mã $_referralCode',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.card_giftcard, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mã Giới Thiệu Của Bạn',
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Referral Code Display
          if (_isLoading)
            _buildLoadingState()
          else if (_referralCode != null)
            _buildCodeDisplay()
          else
            _buildGenerateButton(),

          const SizedBox(height: 16),

          // Benefits Info
          _buildBenefitsInfo(),

          if (_referralCode != null) ...[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Đang tải mã giới thiệu...', style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildCodeDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.code, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _referralCode!,
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: _copyToClipboard,
            icon: Icon(Icons.copy, color: AppColors.primary),
            tooltip: 'Sao chép mã',
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateNewCode,
        icon: _isGenerating
            ? SizedBox(
                width: 16,
                height: 16,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_circle_outline),
        label: Text(_isGenerating ? 'Đang tạo mã...' : 'Tạo Mã Giới Thiệu'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildBenefitsInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎁 Phần thưởng giới thiệu:',
            style: AppTypography.bodyMediumMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text(
                'Bạn nhận +100 SPA khi bạn bè sử dụng mã',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Bạn bè nhận +50 SPA khi đăng ký',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Sao chép'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareReferralCode,
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Chia sẻ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReferralHistoryScreen(
                    userId: widget.userId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Xem Lịch Sử Giới Thiệu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

