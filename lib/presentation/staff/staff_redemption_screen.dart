import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../services/club_spa_service.dart';
import '../../widgets/custom_app_bar.dart';

/// Screen cho nhân viên quán để xác thực và sử dụng redemption code
/// Staff Redemption Code Verification Screen
class StaffRedemptionScreen extends StatefulWidget {
  final String clubId;

  const StaffRedemptionScreen({super.key, required this.clubId});

  @override
  State<StaffRedemptionScreen> createState() => _StaffRedemptionScreenState();
}

class _StaffRedemptionScreenState extends State<StaffRedemptionScreen> {
  final _codeController = TextEditingController();
  final _spaService = ClubSpaService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _redemptionData;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã đổi thưởng';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _redemptionData = null;
    });

    try {
      final result = await _spaService.verifyRedemptionCode(
        _codeController.text.trim(),
        widget.clubId,
      );

      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _redemptionData = result['redemption'];
        } else {
          _errorMessage = result['error'] ?? 'Mã không hợp lệ';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi hệ thống: $e';
      });
    }
  }

  Future<void> _markAsDelivered() async {
    if (_redemptionData == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎁 Xác nhận giao thưởng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc đã giao thưởng cho khách hàng?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎁 ${_redemptionData!['spa_rewards']['reward_name']}'),
                  Text('💰 Giá trị: ${_redemptionData!['spa_spent']} SPA'),
                  Text('👤 Khách hàng: ${_redemptionData!['users']['username'] ?? 'N/A'}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đã giao thưởng'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _spaService.markRedemptionAsDelivered(
        _redemptionData!['id'],
        widget.clubId,
      );

      if (result['success'] == true) {
        // Show success and clear form
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Thành công!'),
            content: const Text('Đã xác nhận giao thưởng cho khách hàng.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearForm();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Có lỗi xảy ra';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi hệ thống: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _codeController.clear();
      _redemptionData = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Xác thực mã đổi thưởng',
        backgroundColor: AppTheme.primaryLight,
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hướng dẫn sử dụng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        SizedBox(height: 4.sp),
                        Text(
                          '1. Nhập mã đổi thưởng khách hàng cung cấp\n2. Kiểm tra thông tin thưởng\n3. Giao thưởng và xác nhận',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Code Input Section
            Text(
              'Mã đổi thưởng',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.sp),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã (VD: SPA123456789)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data != null && data.text != null) {
                            _codeController.text = data.text!;
                          }
                        },
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    onSubmitted: (_) => _verifyCode(),
                  ),
                ),
                SizedBox(width: 12.sp),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.sp,
                      vertical: 16.sp,
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20.sp,
                          height: 20.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kiểm tra'),
                ),
              ],
            ),

            SizedBox(height: 24.sp),

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.sp),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.sp),
            ],

            // Redemption Details
            if (_redemptionData != null) ...[
              Container(
                padding: EdgeInsets.all(20.sp),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12.sp),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.sp),
                        Text(
                          'Mã hợp lệ! ✅',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.sp),
                    
                    _buildInfoRow('🎁 Phần thưởng:', _redemptionData!['spa_rewards']['reward_name'] ?? 'N/A'),
                    _buildInfoRow('💰 Giá trị SPA:', '${_redemptionData!['spa_spent']} SPA'),
                    _buildInfoRow('👤 Khách hàng:', _redemptionData!['users']['username'] ?? 'N/A'),
                    _buildInfoRow('📅 Ngày đổi:', _formatDate(_redemptionData!['redeemed_at'])),
                    _buildInfoRow('📋 Trạng thái:', _getStatusText(_redemptionData!['status'])),
                    
                    if (_redemptionData!['spa_rewards']['description'] != null) ...[
                      SizedBox(height: 12.sp),
                      Text(
                        'Mô tả:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        _redemptionData!['spa_rewards']['description'],
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],

                    SizedBox(height: 20.sp),
                    
                    // Action Button
                    if (_redemptionData!['status'] == 'pending')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _markAsDelivered,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Đã giao thưởng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.sp),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.sp),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(12.sp),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade600),
                            SizedBox(width: 8.sp),
                            Expanded(
                              child: Text(
                                _redemptionData!['status'] == 'delivered'
                                    ? 'Thưởng đã được giao'
                                    : 'Mã đã được sử dụng',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Clear Button
            if (_redemptionData != null || _errorMessage != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra mã khác'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.sp),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '⏳ Chờ giao hàng';
      case 'delivered':
        return '✅ Đã giao';
      case 'cancelled':
        return '❌ Đã hủy';
      default:
        return status;
    }
  }
}