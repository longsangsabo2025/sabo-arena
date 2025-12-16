import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/tournament_prize_voucher_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

/// Screen cho user thanh toán tiền bàn bằng voucher
class VoucherTablePaymentScreen extends StatefulWidget {
  final String userId;
  final String? clubId; // Optional: filter vouchers by club

  const VoucherTablePaymentScreen({
    super.key,
    required this.userId,
    this.clubId,
  });

  @override
  State<VoucherTablePaymentScreen> createState() =>
      _VoucherTablePaymentScreenState();
}

class _VoucherTablePaymentScreenState extends State<VoucherTablePaymentScreen> {
  final _service = TournamentPrizeVoucherService();
  final _supabase = SupabaseService.instance.client;

  List<Map<String, dynamic>> _availableVouchers = [];
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;
  String? _selectedVoucherCode;
  Map<String, dynamic>? _selectedVoucher;

  // Payment form
  final _tableNumberController = TextEditingController();
  final _originalAmountController = TextEditingController();
  DateTime _sessionStart = DateTime.now().subtract(const Duration(hours: 2));
  DateTime _sessionEnd = DateTime.now();

  // Calculated values
  double _discount = 0;
  double _finalAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final vouchers =
          await _service.getUserTablePaymentVouchers(widget.userId);
      final history = await _service.getUserTablePaymentHistory(widget.userId);

      setState(() {
        _availableVouchers = vouchers;
        _paymentHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi tải dữ liệu: $e');
    }
  }

  void _calculatePayment() {
    final originalAmount = double.tryParse(_originalAmountController.text) ?? 0;
    final voucherValue = _selectedVoucher?['voucher_value'] as num? ?? 0;

    setState(() {
      _discount = originalAmount < voucherValue.toDouble()
          ? originalAmount
          : voucherValue.toDouble();
      _finalAmount = originalAmount - _discount;
    });
  }

  Future<void> _confirmPayment() async {
    // Validate
    if (_selectedVoucherCode == null) {
      _showError('Vui lòng chọn voucher');
      return;
    }

    final tableNumber = int.tryParse(_tableNumberController.text);
    if (tableNumber == null || tableNumber <= 0) {
      _showError('Nhập số bàn hợp lệ');
      return;
    }

    final originalAmount = double.tryParse(_originalAmountController.text);
    if (originalAmount == null || originalAmount <= 0) {
      _showError('Nhập số tiền hợp lệ');
      return;
    }

    // Get club ID from voucher's tournament
    String? clubId = widget.clubId;
    if (clubId == null) {
      final tournament = _selectedVoucher?['tournament'];
      clubId = tournament?['club_id'] as String?;
    }

    if (clubId == null) {
      _showError('Không xác định được club');
      return;
    }

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bàn số: $tableNumber'),
            Text('Tiền gốc: ${originalAmount.toStringAsFixed(0)} VND'),
            Text(
              'Giảm giá: ${_discount.toStringAsFixed(0)} VND',
              style: const TextStyle(color: Colors.green),
            ),
            const Divider(),
            Text(
              'Còn lại: ${_finalAmount.toStringAsFixed(0)} VND',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Voucher sẽ được đánh dấu đã sử dụng sau khi xác nhận.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Apply voucher
    try {
      setState(() => _isLoading = true);

      final result = await _service.applyVoucherToTablePayment(
        userId: widget.userId,
        clubId: clubId,
        voucherCode: _selectedVoucherCode!,
        originalAmount: originalAmount,
        tableNumber: tableNumber,
        sessionStart: _sessionStart,
        sessionEnd: _sessionEnd,
      );

      if (mounted) {
        _showSuccess('✅ Thanh toán thành công!\n'
            'Còn lại: ${result['final_amount']} VND');

        // Reset form
        _tableNumberController.clear();
        _originalAmountController.clear();
        _selectedVoucherCode = null;
        _selectedVoucher = null;
        _discount = 0;
        _finalAmount = 0;

        // Reload data
        await _loadData();
      }
    } catch (e) {
      _showError('Lỗi thanh toán: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán bằng Voucher'),
        backgroundColor: AppTheme.primaryLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppTheme.primaryLight,
                    tabs: const [
                      Tab(text: 'Thanh toán'),
                      Tab(text: 'Lịch sử'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPaymentTab(),
                        _buildHistoryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voucher selection
          Text(
            'Chọn voucher',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),

          if (_availableVouchers.isEmpty)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Bạn chưa có voucher thanh toán bàn',
                  style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
            )
          else
            ..._availableVouchers.map((voucher) {
              final isSelected =
                  _selectedVoucherCode == voucher['voucher_code'];
              final voucherValue = voucher['voucher_value'] as num? ?? 0;
              final tournament = voucher['tournament'] as Map?;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVoucherCode = voucher['voucher_code'] as String;
                    _selectedVoucher = voucher;
                    _calculatePayment();
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryLight
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? AppTheme.primaryLight.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppTheme.primaryLight
                            : Colors.grey,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${voucherValue.toStringAsFixed(0)} VND',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                            if (tournament != null)
                              Text(
                                'Giải: ${tournament['title']}',
                                style: TextStyle(fontSize: 11.sp),
                              ),
                            Text(
                              'Mã: ${voucher['voucher_code']}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          SizedBox(height: 3.h),

          // Payment form
          if (_selectedVoucherCode != null) ...[
            Text(
              'Thông tin thanh toán',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),

            TextField(
              controller: _tableNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số bàn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.table_restaurant),
              ),
            ),

            SizedBox(height: 2.h),

            TextField(
              controller: _originalAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tiền bàn (VND)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              onChanged: (_) => _calculatePayment(),
            ),

            SizedBox(height: 2.h),

            // Session time
            ListTile(
              title: const Text('Giờ bắt đầu'),
              subtitle: Text(
                '${_sessionStart.hour}:${_sessionStart.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_sessionStart),
                );
                if (time != null) {
                  setState(() {
                    _sessionStart = DateTime(
                      _sessionStart.year,
                      _sessionStart.month,
                      _sessionStart.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),

            ListTile(
              title: const Text('Giờ kết thúc'),
              subtitle: Text(
                '${_sessionEnd.hour}:${_sessionEnd.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_sessionEnd),
                );
                if (time != null) {
                  setState(() {
                    _sessionEnd = DateTime(
                      _sessionEnd.year,
                      _sessionEnd.month,
                      _sessionEnd.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),

            SizedBox(height: 3.h),

            // Payment preview
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiền gốc:'),
                      Text(
                        '${(double.tryParse(_originalAmountController.text) ?? 0).toStringAsFixed(0)} VND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giảm giá:'),
                      Text(
                        '- ${_discount.toStringAsFixed(0)} VND',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Còn lại:',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_finalAmount.toStringAsFixed(0)} VND',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Xác nhận thanh toán',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_paymentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'Chưa có lịch sử thanh toán',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = _paymentHistory[index];
        final club = payment['club'] as Map?;
        final voucher = payment['voucher'] as Map?;

        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
              child: Icon(
                Icons.table_restaurant,
                color: AppTheme.primaryLight,
              ),
            ),
            title: Text(
              'Bàn ${payment['table_number']} - ${club?['name'] ?? 'N/A'}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giảm ${(payment['voucher_discount'] as num).toStringAsFixed(0)} VND',
                  style: TextStyle(fontSize: 11.sp, color: Colors.green),
                ),
                Text(
                  'Thanh toán ${(payment['final_amount'] as num).toStringAsFixed(0)} VND',
                  style: TextStyle(fontSize: 11.sp),
                ),
                Text(
                  'Voucher: ${voucher?['voucher_code'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
            trailing: Icon(
              payment['payment_status'] == 'completed'
                  ? Icons.check_circle
                  : Icons.pending,
              color: payment['payment_status'] == 'completed'
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _originalAmountController.dispose();
    super.dispose();
  }
}
