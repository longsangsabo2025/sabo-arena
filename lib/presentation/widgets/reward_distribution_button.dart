import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/tournament/reward_execution_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

/// "Gửi Quà" Button Widget for Tournament Results Tab
/// Distributes rewards based on tournament_results data
class RewardDistributionButton extends StatefulWidget {
  final String tournamentId;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const RewardDistributionButton({
    Key? key,
    required this.tournamentId,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<RewardDistributionButton> createState() => _RewardDistributionButtonState();
}

class _RewardDistributionButtonState extends State<RewardDistributionButton> {
  bool _isDistributing = false;
  bool _hasRewardsBeenDistributed = false;
  int _totalParticipants = 0;
  int _distributedCount = 0;

  @override
  void initState() {
    super.initState();
    _checkRewardStatus();
  }

  /// Check if rewards have already been distributed
  Future<void> _checkRewardStatus() async {
    try {
      // Check tournament_results count
      final resultsResponse = await Supabase.instance.client
          .from('tournament_results')
          .select('participant_id')
          .eq('tournament_id', widget.tournamentId);

      _totalParticipants = resultsResponse.length;

      // Check spa_transactions count
      final spaResponse = await Supabase.instance.client
          .from('spa_transactions')
          .select('user_id')
          .eq('reference_id', widget.tournamentId)
          .eq('reference_type', 'reward');

      _distributedCount = spaResponse.length;
      _hasRewardsBeenDistributed = _distributedCount >= _totalParticipants;

      setState(() {});
    } catch (e) {
      ProductionLogger.info('❌ Error checking reward status: $e', tag: 'reward_distribution_button');
    }
  }

  /// Distribute rewards to all participants
  Future<void> _distributeRewards() async {
    if (_isDistributing) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isDistributing = true;
    });

    try {
      ProductionLogger.info('🎁 Starting reward distribution for ${widget.tournamentId}', tag: 'reward_distribution_button');

      final rewardService = RewardExecutionService();
      final success = await rewardService.executeRewardsFromResults(
        tournamentId: widget.tournamentId,
      );

      if (success) {
        setState(() {
          _hasRewardsBeenDistributed = true;
          _distributedCount = _totalParticipants;
        });

        _showSuccessDialog();
        widget.onSuccess?.call();
      } else {
        _showErrorDialog('Có lỗi xảy ra khi phân phối quà. Vui lòng thử lại.');
        widget.onError?.call();
      }
    } catch (e) {
      ProductionLogger.info('❌ Reward distribution error: $e', tag: 'reward_distribution_button');
      _showErrorDialog('Lỗi: $e');
      widget.onError?.call();
    } finally {
      setState(() {
        _isDistributing = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎁 Xác nhận phân phối quà'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn gửi quà cho $_totalParticipants người chơi?'),
            const SizedBox(height: 16),
            const Text('Quà bao gồm:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• SPA Points (100-1000 tùy hạng)'),
            const Text('• ELO Rating (+75 đến -5)'),
            const Text('• Prize Money (nếu có)'),
            const Text('• Vouchers (Top 4)'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Hành động này không thể hoàn tác!',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('🎁 Gửi Quà'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Đã gửi quà thành công cho $_totalParticipants người chơi!'),
            const SizedBox(height: 8),
            const Text('Tất cả SPA, ELO và vouchers đã được phân phối.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Lỗi'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_totalParticipants == 0) {
      return const SizedBox.shrink(); // No results yet
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Phân phối quà thưởng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _hasRewardsBeenDistributed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasRewardsBeenDistributed ? Icons.check_circle : Icons.pending,
                    color: _hasRewardsBeenDistributed ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasRewardsBeenDistributed 
                        ? 'Đã gửi quà cho $_distributedCount/$_totalParticipants người chơi'
                        : 'Chưa phân phối quà ($_distributedCount/$_totalParticipants)',
                    style: TextStyle(
                      color: _hasRewardsBeenDistributed ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isDistributing || _hasRewardsBeenDistributed) 
                    ? null 
                    : _distributeRewards,
                icon: _isDistributing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_hasRewardsBeenDistributed ? Icons.check_circle : Icons.card_giftcard),
                label: Text(
                  _isDistributing 
                      ? 'Đang phân phối...'
                      : _hasRewardsBeenDistributed 
                          ? 'Đã Gửi Quà' 
                          : 'Gửi Quà',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasRewardsBeenDistributed ? Colors.grey.shade600 : Colors.green,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            
            if (!_hasRewardsBeenDistributed) ...[
              const SizedBox(height: 8),
              const Text(
                '💡 Tip: Hãy kiểm tra kết quả trước khi gửi quà',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}