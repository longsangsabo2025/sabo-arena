import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Dialog để edit Loyalty Program configuration
class EditLoyaltyProgramDialog extends StatefulWidget {
  final Map<String, dynamic> program;

  const EditLoyaltyProgramDialog({
    Key? key,
    required this.program,
  }) : super(key: key);

  @override
  State<EditLoyaltyProgramDialog> createState() =>
      _EditLoyaltyProgramDialogState();
}

class _EditLoyaltyProgramDialogState extends State<EditLoyaltyProgramDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _expiryDaysController;
  late TextEditingController _pointsPerGameController;
  late TextEditingController _pointsPerVndController;
  late TextEditingController _pointsPerHourController;
  late TextEditingController _birthdayMultiplierController;
  late TextEditingController _weekendMultiplierController;
  late bool _isActive;

  // Tier system controllers
  late Map<String, Map<String, TextEditingController>> _tierControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.program['program_name'],
    );
    _expiryDaysController = TextEditingController(
      text: (widget.program['points_expiry_days'] ?? 365).toString(),
    );
    _pointsPerGameController = TextEditingController(
      text: (widget.program['points_per_game'] ?? 10).toString(),
    );
    _pointsPerVndController = TextEditingController(
      text: (widget.program['points_per_vnd'] ?? 0.01).toString(),
    );
    _pointsPerHourController = TextEditingController(
      text: (widget.program['points_per_hour'] ?? 20).toString(),
    );
    _birthdayMultiplierController = TextEditingController(
      text: (widget.program['birthday_multiplier'] ?? 2.0).toString(),
    );
    _weekendMultiplierController = TextEditingController(
      text: (widget.program['weekend_multiplier'] ?? 1.5).toString(),
    );
    _isActive = widget.program['is_active'] ?? true;

    // Initialize tier controllers
    final tierSystem = widget.program['tier_system'] as Map<String, dynamic>;
    _tierControllers = {};
    for (final tier in ['bronze', 'silver', 'gold', 'platinum']) {
      final tierData = tierSystem[tier] as Map<String, dynamic>?;
      _tierControllers[tier] = {
        'min_points': TextEditingController(
          text: (tierData?['min_points'] ?? 0).toString(),
        ),
        'discount_percent': TextEditingController(
          text: (tierData?['discount_percent'] ?? 0).toString(),
        ),
        'priority_booking': TextEditingController(
          text: (tierData?['priority_booking'] ?? 0).toString(),
        ),
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expiryDaysController.dispose();
    _pointsPerGameController.dispose();
    _pointsPerVndController.dispose();
    _pointsPerHourController.dispose();
    _birthdayMultiplierController.dispose();
    _weekendMultiplierController.dispose();
    for (final controllers in _tierControllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 90.w,
        height: 90.h,
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Chỉnh sửa Loyalty Program',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: 3.h),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Basic Info
                    _buildSectionTitle('Thông tin cơ bản'),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên chương trình'),
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _expiryDaysController,
                      decoration: const InputDecoration(labelText: 'Số ngày hết hạn điểm'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),
                    SwitchListTile(
                      title: const Text('Trạng thái hoạt động'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),

                    Divider(height: 4.h),
                    
                    // Points Rules
                    _buildSectionTitle('Quy tắc tích điểm'),
                    TextFormField(
                      controller: _pointsPerGameController,
                      decoration: const InputDecoration(
                        labelText: 'Điểm / Game',
                        helperText: 'VD: 10',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _pointsPerVndController,
                      decoration: const InputDecoration(
                        labelText: 'Điểm / VNĐ',
                        helperText: 'VD: 0.01 (= 1 điểm / 100 VNĐ)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _pointsPerHourController,
                      decoration: const InputDecoration(
                        labelText: 'Điểm / Giờ',
                        helperText: 'VD: 20',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),

                    Divider(height: 4.h),

                    // Multipliers
                    _buildSectionTitle('Hệ số nhân'),
                    TextFormField(
                      controller: _birthdayMultiplierController,
                      decoration: const InputDecoration(
                        labelText: 'Sinh nhật (x)',
                        helperText: 'VD: 2.0 (nhân đôi)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _weekendMultiplierController,
                      decoration: const InputDecoration(
                        labelText: 'Cuối tuần (x)',
                        helperText: 'VD: 1.5',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),

                    Divider(height: 4.h),

                    // Tier System
                    _buildSectionTitle('Hệ thống hạng'),
                    ..._buildTierFields('bronze', 'Đồng', Colors.brown),
                    Divider(height: 2.h),
                    ..._buildTierFields('silver', 'Bạc', Colors.grey),
                    Divider(height: 2.h),
                    ..._buildTierFields('gold', 'Vàng', Colors.amber),
                    Divider(height: 2.h),
                    ..._buildTierFields('platinum', 'Bạch Kim', Colors.purple),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h, bottom: 1.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  List<Widget> _buildTierFields(String tier, String label, Color color) {
    final controllers = _tierControllers[tier]!;
    return [
      Row(
        children: [
          Icon(Icons.stars, color: color),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      SizedBox(height: 1.h),
      TextFormField(
        controller: controllers['min_points'],
        decoration: const InputDecoration(
          labelText: 'Điểm tối thiểu',
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
      ),
      SizedBox(height: 1.h),
      TextFormField(
        controller: controllers['discount_percent'],
        decoration: const InputDecoration(
          labelText: 'Giảm giá (%)',
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
      ),
      SizedBox(height: 1.h),
      TextFormField(
        controller: controllers['priority_booking'],
        decoration: const InputDecoration(
          labelText: 'Ưu tiên đặt bàn (mức)',
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
      ),
    ];
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Build tier system
    final tierSystem = <String, Map<String, dynamic>>{};
    for (final tier in ['bronze', 'silver', 'gold', 'platinum']) {
      final controllers = _tierControllers[tier]!;
      tierSystem[tier] = {
        'min_points': int.parse(controllers['min_points']!.text),
        'discount_percent': int.parse(controllers['discount_percent']!.text),
        'priority_booking': int.parse(controllers['priority_booking']!.text),
      };
    }

    final result = {
      'program_name': _nameController.text,
      'points_expiry_days': int.parse(_expiryDaysController.text),
      'points_per_game': int.parse(_pointsPerGameController.text),
      'points_per_vnd': double.parse(_pointsPerVndController.text),
      'points_per_hour': int.parse(_pointsPerHourController.text),
      'birthday_multiplier': double.parse(_birthdayMultiplierController.text),
      'weekend_multiplier': double.parse(_weekendMultiplierController.text),
      'is_active': _isActive,
      'tier_system': tierSystem,
    };

    Navigator.pop(context, result);
  }
}
