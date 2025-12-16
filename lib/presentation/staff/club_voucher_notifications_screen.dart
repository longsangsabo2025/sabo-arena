import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../services/voucher_notification_service.dart';

/// Màn hình thông báo voucher cho Club Owner
class ClubVoucherNotificationsScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubVoucherNotificationsScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubVoucherNotificationsScreen> createState() => _ClubVoucherNotificationsScreenState();
}

class _ClubVoucherNotificationsScreenState extends State<ClubVoucherNotificationsScreen> {
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final requests = await VoucherNotificationService.getPendingVoucherRequests(widget.clubId);
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi', 'Không thể tải danh sách yêu cầu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yêu cầu Voucher'),
        backgroundColor: AppTheme.primaryLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.sp),
            Text(
              'Không có yêu cầu voucher nào',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Các yêu cầu sử dụng voucher sẽ xuất hiện ở đây',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16.sp),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(_pendingRequests[index]);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final data = request['data'] as Map<String, dynamic>? ?? {};
    final voucherCode = data['voucher_code'] as String? ?? '';
    final userEmail = data['user_email'] as String? ?? '';
    final userName = data['user_name'] as String? ?? '';
    final voucherValue = data['voucher_value'] as int? ?? 0;
    final voucherType = data['voucher_type'] as String? ?? '';
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.sp),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.orange.shade700,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu sử dụng voucher',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        _formatDateTime(request['created_at'] as String?),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.sp),

            // Voucher Info
            Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Mã voucher:',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      Text(
                        voucherCode,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.sp),
                  Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber, size: 16.sp),
                      SizedBox(width: 4.sp),
                      Text(
                        '$voucherValue SPA',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    _getVoucherTypeLabel(voucherType),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.sp),

            // User Info
            Row(
              children: [
                Icon(Icons.person, color: Colors.grey.shade600, size: 16.sp),
                SizedBox(width: 8.sp),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.sp),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectVoucher(voucherCode),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12.sp),
                    ),
                    child: Text('Từ chối'),
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveVoucher(voucherCode, voucherValue),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.sp),
                    ),
                    child: Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getVoucherTypeLabel(String type) {
    switch (type) {
      case 'tournament_prize':
        return 'Giải thưởng giải đấu';
      case 'spa_reward':
        return 'Phần thưởng SPA';
      case 'promotion':
        return 'Khuyến mãi';
      default:
        return 'Voucher';
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  Future<void> _approveVoucher(String voucherCode, int voucherValue) async {
    final confirmed = await _showConfirmDialog(
      'Xác nhận voucher',
      'Bạn có chắc muốn xác nhận voucher $voucherCode?\n\nSẽ cộng $voucherValue SPA vào tài khoản người dùng.',
    );
    
    if (!confirmed) return;

    try {
      _showLoadingDialog('Đang xử lý...');
      
      final result = await VoucherNotificationService.approveVoucherUsage(
        voucherCode: voucherCode,
        clubId: widget.clubId,
      );
      
      Navigator.pop(context); // Close loading
      
      if (result['success']) {
        _showSuccessDialog('Thành công', result['message']);
        await _loadPendingRequests(); // Refresh list
      } else {
        _showErrorDialog('Lỗi', result['message']);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showErrorDialog('Lỗi', 'Không thể xác nhận voucher: $e');
    }
  }

  Future<void> _rejectVoucher(String voucherCode) async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.trim().isEmpty) return;

    try {
      _showLoadingDialog('Đang xử lý...');
      
      final result = await VoucherNotificationService.rejectVoucherUsage(
        voucherCode: voucherCode,
        clubId: widget.clubId,
        reason: reason,
      );
      
      Navigator.pop(context); // Close loading
      
      if (result['success']) {
        _showSuccessDialog('Đã từ chối', result['message']);
        await _loadPendingRequests(); // Refresh list
      } else {
        _showErrorDialog('Lỗi', result['message']);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showErrorDialog('Lỗi', 'Không thể từ chối voucher: $e');
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Từ chối voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vui lòng nhập lý do từ chối:'),
            SizedBox(height: 12.sp),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Lý do từ chối...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16.sp),
            Text(message),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8.sp),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8.sp),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}