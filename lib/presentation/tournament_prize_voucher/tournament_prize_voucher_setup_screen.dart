import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/tournament_prize_voucher_service.dart';
import '../../theme/app_colors_styles.dart';

/// Screen để club owner setup voucher giải thưởng cho giải đấu
class TournamentPrizeVoucherSetupScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentTitle;

  const TournamentPrizeVoucherSetupScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentTitle,
  });

  @override
  State<TournamentPrizeVoucherSetupScreen> createState() =>
      _TournamentPrizeVoucherSetupScreenState();
}

class _TournamentPrizeVoucherSetupScreenState
    extends State<TournamentPrizeVoucherSetupScreen> {
  final _service = TournamentPrizeVoucherService();
  
  // Prize configs
  final _firstPrizeController = TextEditingController(text: '700000');
  final _secondPrizeController = TextEditingController(text: '500000');
  final _thirdPrizeController = TextEditingController(text: '300000');
  
  int _validDays = 30;
  bool _isLoading = false;
  List<Map<String, dynamic>> _existingPrizes = [];

  @override
  void initState() {
    super.initState();
    _loadExistingPrizes();
  }

  Future<void> _loadExistingPrizes() async {
    setState(() => _isLoading = true);
    try {
      final prizes = await _service.getTournamentPrizeVouchers(widget.tournamentId);
      setState(() => _existingPrizes = prizes);
      
      // Populate fields nếu đã có config
      if (prizes.isNotEmpty) {
        for (var prize in prizes) {
          final position = prize['position'] as int;
          final value = prize['voucher_value'].toString();
          
          if (position == 1) {
            _firstPrizeController.text = value;
          } else if (position == 2) {
            _secondPrizeController.text = value;
          } else if (position == 3) {
            _thirdPrizeController.text = value;
          }
        }
        
        if (prizes.first['valid_days'] != null) {
          _validDays = prizes.first['valid_days'] as int;
        }
      }
    } catch (e) {
      _showError('Lỗi tải dữ liệu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrizeConfig() async {
    // Validate
    final first = double.tryParse(_firstPrizeController.text);
    final second = double.tryParse(_secondPrizeController.text);
    final third = double.tryParse(_thirdPrizeController.text);
    
    if (first == null || first <= 0) {
      _showError('Nhập giá trị giải Nhất hợp lệ');
      return;
    }
    
    if (second == null || second <= 0) {
      _showError('Nhập giá trị giải Nhì hợp lệ');
      return;
    }
    
    if (third == null || third <= 0) {
      _showError('Nhập giá trị giải Ba hợp lệ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prizes = [
        TournamentPrizeConfig(
          position: 1,
          positionLabel: 'NHẤT',
          voucherValue: first,
          validDays: _validDays,
          description: 'Giải Nhất - ${widget.tournamentTitle}',
        ),
        TournamentPrizeConfig(
          position: 2,
          positionLabel: 'NHÌ',
          voucherValue: second,
          validDays: _validDays,
          description: 'Giải Nhì - ${widget.tournamentTitle}',
        ),
        TournamentPrizeConfig(
          position: 3,
          positionLabel: 'BA',
          voucherValue: third,
          validDays: _validDays,
          description: 'Giải Ba - ${widget.tournamentTitle}',
        ),
      ];

      await _service.setupTournamentPrizeVouchers(
        tournamentId: widget.tournamentId,
        prizes: prizes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã cài đặt voucher giải thưởng')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Lỗi lưu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _useTemplateFromPoster() {
    _firstPrizeController.text = '700000';
    _secondPrizeController.text = '500000';
    _thirdPrizeController.text = '300000';
    _validDays = 30;
    setState(() {});
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt Voucher Giải Thưởng'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePrizeConfig,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament info
                  Text(
                    widget.tournamentTitle,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  
                  Text(
                    'Cài đặt mệnh giá voucher cho từng giải thưởng. User thắng giải sẽ tự động nhận voucher để thanh toán tiền bàn.',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                  
                  SizedBox(height: 3.h),
                  
                  // Quick template
                  OutlinedButton.icon(
                    onPressed: _useTemplateFromPoster,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Dùng mẫu từ Poster (700K-500K-300K)'),
                  ),
                  
                  SizedBox(height: 3.h),
                  
                  // Prize inputs
                  _buildPrizeInput(
                    label: '🥇 Giải Nhất',
                    controller: _firstPrizeController,
                    color: const Color(0xFFFFD700),
                  ),
                  
                  SizedBox(height: 2.h),
                  
                  _buildPrizeInput(
                    label: '🥈 Giải Nhì',
                    controller: _secondPrizeController,
                    color: const Color(0xFFC0C0C0),
                  ),
                  
                  SizedBox(height: 2.h),
                  
                  _buildPrizeInput(
                    label: '🥉 Giải Ba',
                    controller: _thirdPrizeController,
                    color: const Color(0xFFCD7F32),
                  ),
                  
                  SizedBox(height: 3.h),
                  
                  // Valid days
                  Text(
                    'Thời hạn voucher',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 1.h),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _validDays.toDouble(),
                          min: 7,
                          max: 90,
                          divisions: 11,
                          label: '$_validDays ngày',
                          onChanged: (value) {
                            setState(() => _validDays = value.toInt());
                          },
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_validDays ngày',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 3.h),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePrizeConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Lưu cài đặt',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  // Existing prizes preview
                  if (_existingPrizes.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Divider(),
                    SizedBox(height: 2.h),
                    Text(
                      'Cài đặt hiện tại',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 1.h),
                    
                    ..._existingPrizes.map((prize) {
                      return ListTile(
                        leading: Text(
                          prize['position_label'],
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        title: Text(
                          '${(prize['voucher_value'] as num).toStringAsFixed(0)} VND',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        subtitle: Text(
                          'Hạn ${prize['valid_days']} ngày',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        trailing: prize['is_issued'] == true
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.pending, color: Colors.orange),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPrizeInput({
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 0.5.h),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(10),
            color: color.withValues(alpha: 0.05),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              border: InputBorder.none,
              suffixText: 'VND',
              suffixStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstPrizeController.dispose();
    _secondPrizeController.dispose();
    _thirdPrizeController.dispose();
    super.dispose();
  }
}
