import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/services/tournament_service.dart';
import '../../../widgets/common/app_button.dart';
import 'package:sabo_arena/widgets/user/user_widgets.dart';
// ELON_MODE_AUTO_FIX

class ParticipantManagementTab extends StatefulWidget {
  final String tournamentId;

  const ParticipantManagementTab({super.key, required this.tournamentId});

  @override
  _ParticipantManagementTabState createState() =>
      _ParticipantManagementTabState();
}

class _ParticipantManagementTabState extends State<ParticipantManagementTab> {
  final TournamentService _tournamentService = TournamentService.instance;
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final participants = await _tournamentService
          .getTournamentParticipantsWithPaymentStatus(widget.tournamentId);
      for (int i = 0; i < participants.length; i++) {
        // Note: Display name priority is now handled by UserDisplayNameText component
      }
      setState(() {
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.sp),
            Text('Đang tải danh sách người chơi...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64.sp, color: Colors.grey[300]),
              SizedBox(height: 16.sp),
              Text(
                "Không thể tải danh sách người chơi",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8.sp),
              Text(
                "Vui lòng kiểm tra kết nối mạng và thử lại",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 24.sp),
              AppButton(
                label: 'Thử lại',
                type: AppButtonType.primary,
                size: AppButtonSize.medium,
                icon: Icons.refresh,
                iconTrailing: false,
                onPressed: _loadParticipants,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Participants list with index numbers
        Expanded(
          child: _participants.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 12.sp,
                    right: 12.sp,
                    top: 8.sp,
                    bottom: kBottomNavigationBarHeight +
                        8.sp, // Add bottom padding for nav bar
                  ),
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    return _buildParticipantCard(
                      _participants[index],
                      index + 1,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80.sp, color: Colors.grey[300]),
            SizedBox(height: 16.sp),
            Text(
              "Chưa có ai đăng ký tham gia",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              "Hãy chia sẻ giải đấu để mời thêm người chơi tham gia",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant, int index) {
    final user = participant['user'];
    final paymentStatus = participant['payment_status'] ?? 'pending';
    final registeredAt = participant['registered_at'];

    return Container(
      margin: EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerLight.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Index number (STT) - Simple text, no background
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Avatar
          UserAvatarWidget(
            avatarUrl: user?['avatar_url'],
            size: 40,
          ),
          SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserDisplayNameText(
                  userData: user,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 4),
                // User rank/level
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                    SizedBox(width: 4),
                    Text(
                      _getUserRank(user),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Registration date - Compact format at the end
          if (_formatRegistrationDateCompact(registeredAt).isNotEmpty)
            Text(
              _formatRegistrationDateCompact(registeredAt),
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          SizedBox(width: 12),

          // Payment status badge - compact
          SizedBox(width: 8),
          _buildPaymentStatusBadge(paymentStatus),

          // Actions menu
          PopupMenuButton<String>(
            onSelected: (action) =>
                _handleParticipantAction(action, participant),
            itemBuilder: (context) => [
              if (paymentStatus != 'confirmed')
                PopupMenuItem(
                  value: 'confirm_payment',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: AppTheme.successLight, size: 16),
                      SizedBox(width: 8),
                      Text('Xác nhận thanh toán'),
                    ],
                  ),
                ),
              if (paymentStatus == 'confirmed')
                PopupMenuItem(
                  value: 'reset_payment',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: AppTheme.warningLight,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text('Đặt lại thanh toán'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'add_note',
                child: Row(
                  children: [
                    Icon(
                      Icons.note_add,
                      color: AppTheme.primaryLight,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text('Thêm ghi chú'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppTheme.errorLight, size: 16),
                    SizedBox(width: 8),
                    Text('Loại bỏ'),
                  ],
                ),
              ),
            ],
            child: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    // Simple icon-only badge - Facebook style
    IconData icon;
    Color iconColor;

    switch (status) {
      case 'completed':
      case 'confirmed':
        // Green checkmark for confirmed payment
        icon = Icons.check_circle;
        iconColor = Color(0xFF00C853); // Bright green like Facebook verified
        break;
      case 'pending':
      default:
        // Gray pending icon for unconfirmed
        icon = Icons.schedule;
        iconColor = Colors.grey[400]!;
        break;
    }

    return Icon(icon, color: iconColor, size: 20);
  }

  String _formatRegistrationDateCompact(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  String _getUserRank(Map<String, dynamic>? user) {
    if (user == null) return 'Chưa xếp hạng';

    // Try to get rank from user data
    final rank = user['rank'] ?? user['level'] ?? user['title'];
    if (rank != null && rank.toString().isNotEmpty) {
      return rank.toString();
    }

    // Default ranks based on some logic (you can customize)
    return 'Người chơi';
  }

  Future<void> _confirmPayment(Map<String, dynamic> participant) async {
    try {
      // Show confirmation dialog first
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xác nhận thanh toán cho:'),
              SizedBox(height: 8),
              UserDisplayNameText(
                userData: participant['user'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Xác nhận'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (!mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      await _tournamentService.updateParticipantPaymentStatus(
        tournamentId: widget.tournamentId,
        userId: participant['user_id'],
        paymentStatus: 'confirmed',
        notes:
            'Đã xác nhận thanh toán bởi quản lý CLB - ${DateTime.now().toString().substring(0, 19)}',
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('Đã xác nhận thanh toán cho: '),
              UserDisplayNameText(
                userData: participant['user'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: AppTheme.successLight,
          duration: Duration(seconds: 3),
        ),
      );

      _loadParticipants(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog if open

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xác nhận thanh toán: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleParticipantAction(
    String action,
    Map<String, dynamic> participant,
  ) {
    switch (action) {
      case 'confirm_payment':
        _confirmPayment(participant);
        break;
      case 'reset_payment':
        _resetPaymentStatus(participant);
        break;
      case 'add_note':
        _showAddNoteDialog(participant);
        break;
      case 'remove':
        _showRemoveParticipantDialog(participant);
        break;
    }
  }

  Future<void> _resetPaymentStatus(Map<String, dynamic> participant) async {
    try {
      await _tournamentService.updateParticipantPaymentStatus(
        tournamentId: widget.tournamentId,
        userId: participant['user_id'],
        paymentStatus: 'pending',
        notes: 'Đặt lại trạng thái thanh toán bởi quản lý CLB',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đặt lại trạng thái thanh toán'),
          backgroundColor: AppTheme.warningLight,
        ),
      );

      _loadParticipants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt lại trạng thái: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  void _showAddNoteDialog(Map<String, dynamic> participant) {
    final noteController = TextEditingController(
      text: participant['notes'] ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Text('Ghi chú cho: '),
            Expanded(
              child: UserDisplayNameText(
                userData: participant['user'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Hủy'),
          ),
          AppButton(
            label: 'Lưu',
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            onPressed: () async {
              try {
                await _tournamentService.updateParticipantPaymentStatus(
                  tournamentId: widget.tournamentId,
                  userId: participant['user_id'],
                  paymentStatus: participant['payment_status'],
                  notes: noteController.text,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                      SnackBar(content: Text('Đã cập nhật ghi chú')));
                  _loadParticipants();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi cập nhật ghi chú: ${e.toString()}'),
                      backgroundColor: AppTheme.errorLight,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRemoveParticipantDialog(Map<String, dynamic> participant) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorLight),
            SizedBox(width: 8),
            Text('Loại bỏ người chơi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn loại bỏ người chơi này khỏi giải đấu?',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  UserAvatarWidget(
                    avatarUrl: participant['user']['avatar_url'],
                    size: 40,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserDisplayNameText(
                          userData: participant['user'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          'Trạng thái: ${_getPaymentStatusText(participant['payment_status'])}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Lý do (tùy chọn):',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Vi phạm quy định, không đủ điều kiện...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.errorLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: AppTheme.errorLight),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hành động này không thể hoàn tác',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.errorLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.of(dialogContext).pop();
            },
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.of(dialogContext).pop();

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Đang xóa người chơi...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                // Remove participant
                final success = await _tournamentService.removeParticipant(
                  tournamentId: widget.tournamentId,
                  userId: participant['user_id'],
                  reason: reasonController.text.trim().isNotEmpty
                      ? reasonController.text.trim()
                      : null,
                );

                reasonController.dispose();

                if (success) {
                  // Reload participants list
                  await _loadParticipants();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Text('Đã loại bỏ '),
                                  Expanded(
                                    child: UserDisplayNameText(
                                      userData: participant['user'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(' khỏi giải đấu'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                reasonController.dispose();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Lỗi: ${e.toString()}'),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.errorLight,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
            ),
            child: Text(
              'Loại bỏ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentStatusText(String? status) {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Chờ xác nhận';
      case 'unpaid':
        return 'Chưa thanh toán';
      default:
        return 'Không rõ';
    }
  }
}
