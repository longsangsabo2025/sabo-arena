import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../services/voucher_management_service.dart';
import '../../widgets/custom_app_bar.dart';

/// Màn hình nhân viên xác thực và sử dụng voucher
/// Staff screen for voucher verification and redemption
class StaffVoucherVerificationScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const StaffVoucherVerificationScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<StaffVoucherVerificationScreen> createState() => _StaffVoucherVerificationScreenState();
}

class _StaffVoucherVerificationScreenState extends State<StaffVoucherVerificationScreen> {
  final _codeController = TextEditingController();
  final _voucherService = VoucherManagementService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _voucherData;
  String? _errorMessage;
  bool _isUsed = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyVoucher() async {
    if (_codeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã voucher';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _voucherData = null;
      _isUsed = false;
    });

    try {
      final result = await _voucherService.verifyVoucherCode(
        _codeController.text.trim(),
        widget.clubId,
      );

      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _voucherData = result['voucher'];
        } else {
          _errorMessage = result['error'] ?? 'Mã voucher không hợp lệ';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi hệ thống: $e';
      });
    }
  }

  Future<void> _useVoucher() async {
    if (_voucherData == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎫 Xác nhận sử dụng voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn sử dụng voucher này?'),
            SizedBox(height: 16.sp),
            Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎁 ${_getVoucherTypeText(_voucherData!['voucher_type'])}'),
                  Text('💰 Giá trị: ${_formatVoucherValue(_voucherData!['voucher_value'])}'),
                  Text('👤 Khách hàng: ${_voucherData!['users']['username'] ?? 'N/A'}'),
                  Text('🏆 Tournament: ${_voucherData!['tournaments']?['name'] ?? 'N/A'}'),
                ],
              ),
            ),
            SizedBox(height: 16.sp),
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6.sp),
              ),
              child: const Text(
                '⚠️ Sau khi sử dụng, voucher sẽ bị xóa khỏi hệ thống và không thể hoàn tác!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Sử dụng voucher'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _voucherService.useVoucher(
        _voucherData!['voucher_code'],
        widget.clubId,
      );

      if (result['success'] == true) {
        setState(() {
          _isUsed = true;
          _isLoading = false;
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Voucher đã được sử dụng thành công!'),
                SizedBox(height: 16.sp),
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: const Text(
                    '💡 Voucher đã bị xóa khỏi hệ thống và cập nhật trên app của khách hàng.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
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
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi hệ thống: $e';
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _codeController.clear();
      _voucherData = null;
      _errorMessage = null;
      _isUsed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Xác thực Voucher',
        backgroundColor: AppTheme.primaryLight,
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club Info
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.store, color: Colors.blue.shade600),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clubName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        SizedBox(height: 4.sp),
                        const Text(
                          'Nhập mã voucher để xác thực và sử dụng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.sp),

            // Voucher Code Input
            Text(
              'Mã Voucher',
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
                      hintText: 'Nhập mã voucher (VD: VOUCHER123)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      prefixIcon: const Icon(Icons.confirmation_number),
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
                    onSubmitted: (_) => _verifyVoucher(),
                  ),
                ),
                SizedBox(width: 12.sp),
                ElevatedButton(
                  onPressed: _isLoading || _isUsed ? null : _verifyVoucher,
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

            // Voucher Details
            if (_voucherData != null) ...[
              Container(
                padding: EdgeInsets.all(20.sp),
                decoration: BoxDecoration(
                  color: _isUsed ? Colors.grey.shade100 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12.sp),
                  border: Border.all(
                    color: _isUsed ? Colors.grey.shade300 : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isUsed ? Icons.check_circle : Icons.confirmation_number,
                          color: _isUsed ? Colors.grey : Colors.green.shade600,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: Text(
                            _isUsed ? 'Voucher đã được sử dụng! ✅' : 'Voucher hợp lệ! 🎫',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: _isUsed ? Colors.grey.shade700 : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.sp),
                    
                    _buildVoucherInfoRow('🎁 Loại voucher:', _getVoucherTypeText(_voucherData!['voucher_type'])),
                    _buildVoucherInfoRow('💰 Giá trị:', _formatVoucherValue(_voucherData!['voucher_value'])),
                    _buildVoucherInfoRow('👤 Khách hàng:', _voucherData!['users']['username'] ?? 'N/A'),
                    _buildVoucherInfoRow('📧 Email:', _voucherData!['users']['email'] ?? 'N/A'),
                    _buildVoucherInfoRow('🏆 Tournament:', _voucherData!['tournaments']?['name'] ?? 'N/A'),
                    _buildVoucherInfoRow('📅 Ngày tạo:', _formatDate(_voucherData!['created_at'])),
                    
                    if (_voucherData!['expires_at'] != null)
                      _buildVoucherInfoRow('⏰ Hết hạn:', _formatDate(_voucherData!['expires_at'])),

                    if (!_isUsed) ...[
                      SizedBox(height: 20.sp),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _useVoucher,
                          icon: const Icon(Icons.redeem),
                          label: const Text('Sử dụng Voucher'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.sp),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.sp),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 16.sp),
                      Container(
                        padding: EdgeInsets.all(12.sp),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.green.shade600),
                            SizedBox(width: 8.sp),
                            const Expanded(
                              child: Text(
                                'Voucher đã được sử dụng và xóa khỏi hệ thống',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Clear Button
            if (_voucherData != null || _errorMessage != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra voucher khác'),
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

  Widget _buildVoucherInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
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

  String _getVoucherTypeText(String? type) {
    switch (type?.toLowerCase()) {
      case 'cash':
        return 'Tiền mặt';
      case 'discount':
        return 'Giảm giá';
      case 'free_drink':
        return 'Nước uống miễn phí';
      case 'free_game':
        return 'Game miễn phí';
      case 'tournament_prize':
        return 'Giải thưởng Tournament';
      default:
        return type ?? 'Voucher';
    }
  }

  String _formatVoucherValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      return '${value.toStringAsFixed(0)} VNĐ';
    }
    return value.toString();
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
}