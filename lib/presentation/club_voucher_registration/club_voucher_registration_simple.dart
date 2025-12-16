import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple voucher campaign registration form
class ClubVoucherRegistrationSimple extends StatefulWidget {
  final String clubId;

  const ClubVoucherRegistrationSimple({super.key, required this.clubId});

  @override
  State<ClubVoucherRegistrationSimple> createState() =>
      _ClubVoucherRegistrationSimpleState();
}

class _ClubVoucherRegistrationSimpleState
    extends State<ClubVoucherRegistrationSimple> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController(text: '100000');
  final _quantityController = TextEditingController(text: '50');

  String _campaignType = 'prize'; // welcome, loyalty, prize
  String _voucherType = 'spa_balance'; // spa_balance, percentage_discount, fixed_amount
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Vui lòng chọn ngày bắt đầu và kết thúc')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final campaignData = {
        'club_id': widget.clubId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'campaign_type': _campaignType,
        'voucher_type': _voucherType,
        'voucher_value': int.parse(_valueController.text),
        'total_quantity': int.parse(_quantityController.text),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
      };

      await Supabase.instance.client
          .from('voucher_campaigns')
          .insert(campaignData);

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close screen

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã gửi yêu cầu! Admin sẽ xét duyệt trong 24h.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Voucher'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            // Tên Voucher
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên Voucher *',
                hintText: 'VD: Voucher Giải Nhất',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
            ),
            SizedBox(height: 3.w),

            // Loại Campaign
            DropdownButtonFormField<String>(
              initialValue: _campaignType,
              decoration: const InputDecoration(
                labelText: 'Loại Campaign',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'welcome', child: Text('Chào Mừng')),
                DropdownMenuItem(value: 'loyalty', child: Text('Thành Viên')),
                DropdownMenuItem(value: 'prize', child: Text('Giải Thưởng')),
              ],
              onChanged: (v) => setState(() => _campaignType = v!),
            ),
            SizedBox(height: 3.w),

            // Loại Voucher
            DropdownButtonFormField<String>(
              initialValue: _voucherType,
              decoration: const InputDecoration(
                labelText: 'Loại Voucher',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_giftcard),
              ),
              items: const [
                DropdownMenuItem(value: 'spa_balance', child: Text('SPA Balance')),
                DropdownMenuItem(value: 'percentage_discount', child: Text('Giảm %')),
                DropdownMenuItem(value: 'fixed_amount', child: Text('Giảm VNĐ')),
              ],
              onChanged: (v) => setState(() => _voucherType = v!),
            ),
            SizedBox(height: 3.w),

            // Giá trị
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Giá Trị *',
                hintText: 'VNĐ hoặc %',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập giá trị' : null,
            ),
            SizedBox(height: 3.w),

            // Số lượng
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Số Lượng *',
                hintText: 'Số voucher phát hành',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập số lượng' : null,
            ),
            SizedBox(height: 3.w),

            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày Bắt Đầu *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Chọn',
                        style: TextStyle(
                          color: _startDate != null ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày Kết Thúc *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Chọn',
                        style: TextStyle(
                          color: _endDate != null ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),

            // Mô tả
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô Tả (tùy chọn)',
                hintText: 'Mô tả ngắn gọn về campaign...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            SizedBox(height: 6.w),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _submitCampaign,
                icon: const Icon(Icons.send, size: 24),
                label: const Text(
                  'ĐĂNG KÝ VOUCHER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
