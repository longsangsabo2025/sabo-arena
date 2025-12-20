import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/tournament/tournament_completion_orchestrator.dart';
import '../../../services/tournament_service.dart';
import '../../../widgets/common/app_button.dart';

class TournamentStatusPanel extends StatefulWidget {
  final String tournamentId;
  final String currentStatus;
  final bool canManage;
  final VoidCallback? onStatusChanged;

  const TournamentStatusPanel({
    super.key,
    required this.tournamentId,
    required this.currentStatus,
    this.canManage = false,
    this.onStatusChanged,
  });

  @override
  State<TournamentStatusPanel> createState() => _TournamentStatusPanelState();
}

class _TournamentStatusPanelState extends State<TournamentStatusPanel> {
  final TournamentCompletionOrchestrator _completionService =
      TournamentCompletionOrchestrator.instance;
  final TournamentService _tournamentService = TournamentService.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStatusGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            children: [
              Icon(_getStatusIcon(), color: Colors.white, size: 20.sp),
              SizedBox(width: 8.sp),
              Text(
                'Trạng thái giải đấu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),

          // Current Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Text(
              _getStatusDisplayText(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 16.sp),

          // Progress Indicator
          _buildProgressIndicator(),
          SizedBox(height: 16.sp),

          // Action Buttons
          if (widget.canManage) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Đang tuyển', 'Đang diễn ra', 'Hoàn thành'];
    final currentStep = _getCurrentStepIndex();

    return Column(
      children: [
        Row(
          children: steps.asMap().entries.map<Widget>((entry) {
            final index = entry.key;
            final isActive = index <= currentStep;
            final isCurrent = index == currentStep;

            return Expanded(
              child: Row(
                children: [
                  // Step Circle
                  Container(
                    width: 24.sp,
                    height: 24.sp,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isActive
                          ? Icon(
                              index < currentStep ? Icons.check : Icons.circle,
                              color: _getStatusGradient().first,
                              size: 12.sp,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  // Connector Line
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 8.sp),
        Row(
          children: steps.asMap().entries.map<Widget>((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= currentStep;

            return Expanded(
              child: Text(
                step,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 10.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Start Tournament Button
        if (widget.currentStatus == 'recruiting' ||
            widget.currentStatus == 'ready')
          AppButton(
            label: _isLoading ? 'Đang bắt đầu...' : 'Bắt đầu giải đấu',
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            icon: Icons.play_arrow,
            iconTrailing: false,
            isLoading: _isLoading,
            customColor: Colors.green,
            customTextColor: Colors.white,
            fullWidth: true,
            onPressed: _isLoading ? null : _startTournament,
          ),

        // Complete Tournament Button
        if (widget.currentStatus == 'active')
          AppButton(
            label: _isLoading ? 'Đang hoàn thành...' : 'Hoàn thành giải đấu',
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            icon: Icons.emoji_events,
            iconTrailing: false,
            isLoading: _isLoading,
            customColor: Colors.orange,
            customTextColor: Colors.white,
            fullWidth: true,
            onPressed: _isLoading ? null : _completeTournament,
          ),

        // Archive Tournament Button
        if (widget.currentStatus == 'completed')
          AppButton(
            label: _isLoading ? 'Đang lưu trữ...' : 'Lưu trữ giải đấu',
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            icon: Icons.archive,
            iconTrailing: false,
            isLoading: _isLoading,
            customColor: Colors.grey[600],
            customTextColor: Colors.white,
            fullWidth: true,
            onPressed: _isLoading ? null : _archiveTournament,
          ),
      ],
    );
  }

  List<Color> _getStatusGradient() {
    switch (widget.currentStatus) {
      case 'recruiting':
      case 'ready':
        return [Colors.blue[400]!, Colors.blue[600]!];
      case 'active':
        return [Colors.orange[400]!, Colors.orange[600]!];
      case 'completed':
        return [Colors.green[400]!, Colors.green[600]!];
      case 'cancelled':
        return [Colors.red[400]!, Colors.red[600]!];
      case 'archived':
        return [Colors.grey[400]!, Colors.grey[600]!];
      default:
        return [Colors.grey[400]!, Colors.grey[600]!];
    }
  }

  IconData _getStatusIcon() {
    switch (widget.currentStatus) {
      case 'recruiting':
      case 'ready':
        return Icons.group_add;
      case 'active':
        return Icons.sports_baseball;
      case 'completed':
        return Icons.emoji_events;
      case 'cancelled':
        return Icons.cancel;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayText() {
    switch (widget.currentStatus) {
      case 'recruiting':
        return 'Đang tuyển thành viên';
      case 'ready':
        return 'Sẵn sàng bắt đầu';
      case 'active':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'archived':
        return 'Đã lưu trữ';
      default:
        return 'Không xác định';
    }
  }

  int _getCurrentStepIndex() {
    switch (widget.currentStatus) {
      case 'recruiting':
      case 'ready':
        return 0;
      case 'active':
        return 1;
      case 'completed':
      case 'cancelled':
      case 'archived':
        return 2;
      default:
        return 0;
    }
  }

  Future<void> _startTournament() async {
    try {
      setState(() => _isLoading = true);

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận'),
          content: Text(
            'Bạn có chắc chắn muốn bắt đầu giải đấu? Sau khi bắt đầu, sẽ không thể thêm người chơi mới.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            AppButton(
              label: 'Bắt đầu',
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _tournamentService.startTournament(widget.tournamentId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Giải đấu đã bắt đầu thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onStatusChanged?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi bắt đầu giải đấu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeTournament() async {
    try {
      setState(() => _isLoading = true);

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Hoàn thành giải đấu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bạn có chắc chắn muốn hoàn thành giải đấu?'),
              SizedBox(height: 8.sp),
              Text(
                'Hệ thống sẽ thực hiện:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Cập nhật ELO cho tất cả người chơi'),
              Text('• Phân phối giải thưởng'),
              Text('• Đăng thông báo lên cộng đồng'),
              Text('• Gửi thông báo cho người tham gia'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            AppButton(
              label: 'Hoàn thành',
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _completionService.completeTournament(
          tournamentId: widget.tournamentId,
          // 🚀 ELON MODE: Auto-execute rewards (default: true)
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Tournament completed! Rewards distributed to all players.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          widget.onStatusChanged?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi hoàn thành giải đấu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _archiveTournament() async {
    try {
      setState(() => _isLoading = true);

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Lưu trữ giải đấu'),
          content: Text(
            'Bạn có chắc chắn muốn lưu trữ giải đấu? Giải đấu sẽ được chuyển vào kho lưu trữ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            AppButton(
              label: 'Lưu trữ',
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _tournamentService.updateTournamentStatus(
          widget.tournamentId,
          'archived',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📁 Giải đấu đã được lưu trữ'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onStatusChanged?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi lưu trữ giải đấu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
