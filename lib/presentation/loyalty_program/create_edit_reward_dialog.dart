import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Dialog để create/edit Loyalty Reward
class CreateEditRewardDialog extends StatefulWidget {
  final Map<String, dynamic>? reward; // null = create mode

  const CreateEditRewardDialog({
    Key? key,
    this.reward,
  }) : super(key: key);

  @override
  State<CreateEditRewardDialog> createState() => _CreateEditRewardDialogState();
}

class _CreateEditRewardDialogState extends State<CreateEditRewardDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _pointsCostController;
  late TextEditingController _quantityController;
  late TextEditingController _validDaysController;
  late String _rewardType;
  late String _requiredTier;
  late bool _isActive;
  late bool _autoApprove;

  bool get isEditMode => widget.reward != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController = TextEditingController(text: widget.reward!['reward_name']);
      _descController = TextEditingController(text: widget.reward!['description'] ?? '');
      _pointsCostController = TextEditingController(
        text: widget.reward!['points_cost'].toString(),
      );
      _quantityController = TextEditingController(
        text: (widget.reward!['quantity_available'] ?? 0).toString(),
      );
      _validDaysController = TextEditingController(
        text: (widget.reward!['valid_days'] ?? 30).toString(),
      );
      _rewardType = widget.reward!['reward_type'] ?? 'discount_voucher';
      _requiredTier = widget.reward!['required_tier'] ?? 'bronze';
      _isActive = widget.reward!['is_active'] ?? true;
      _autoApprove = widget.reward!['auto_approve'] ?? false;
    } else {
      _nameController = TextEditingController();
      _descController = TextEditingController();
      _pointsCostController = TextEditingController(text: '100');
      _quantityController = TextEditingController(text: '10');
      _validDaysController = TextEditingController(text: '30');
      _rewardType = 'discount_voucher';
      _requiredTier = 'bronze';
      _isActive = true;
      _autoApprove = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _pointsCostController.dispose();
    _quantityController.dispose();
    _validDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 90.w,
        height: 85.h,
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  isEditMode ? 'Chỉnh sửa Phần thưởng' : 'Tạo Phần thưởng mới',
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên phần thưởng *',
                        hintText: 'VD: Giảm 50,000đ cho game tiếp theo',
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        hintText: 'Mô tả chi tiết về phần thưởng',
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 2.h),

                    // Reward Type
                    DropdownButtonFormField<String>(
                      initialValue: _rewardType,
                      decoration: const InputDecoration(labelText: 'Loại phần thưởng'),
                      items: const [
                        DropdownMenuItem(
                          value: 'discount_voucher',
                          child: Text('🎟️ Voucher giảm giá'),
                        ),
                        DropdownMenuItem(
                          value: 'free_game',
                          child: Text('🎮 Free game'),
                        ),
                        DropdownMenuItem(
                          value: 'free_hour',
                          child: Text('⏰ Free giờ chơi'),
                        ),
                        DropdownMenuItem(
                          value: 'merchandise',
                          child: Text('🛍️ Merchandise'),
                        ),
                        DropdownMenuItem(
                          value: 'food_drink',
                          child: Text('🍕 Food & Drink'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _rewardType = v!),
                    ),
                    SizedBox(height: 2.h),

                    // Points Cost
                    TextFormField(
                      controller: _pointsCostController,
                      decoration: const InputDecoration(
                        labelText: 'Chi phí điểm *',
                        hintText: 'VD: 100',
                        suffixIcon: Icon(Icons.stars, color: Colors.amber),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),

                    // Required Tier
                    DropdownButtonFormField<String>(
                      initialValue: _requiredTier,
                      decoration: const InputDecoration(
                        labelText: 'Hạng tối thiểu',
                        helperText: 'User phải có hạng này mới đổi được',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'bronze',
                          child: Row(
                            children: [
                              Icon(Icons.stars, color: Colors.brown),
                              SizedBox(width: 8),
                              Text('Đồng'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'silver',
                          child: Row(
                            children: [
                              Icon(Icons.stars, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Bạc'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'gold',
                          child: Row(
                            children: [
                              Icon(Icons.stars, color: Colors.amber),
                              SizedBox(width: 8),
                              Text('Vàng'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'platinum',
                          child: Row(
                            children: [
                              Icon(Icons.stars, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Bạch Kim'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _requiredTier = v!),
                    ),
                    SizedBox(height: 2.h),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng (0 = không giới hạn)',
                        hintText: 'VD: 10',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),

                    // Valid Days
                    TextFormField(
                      controller: _validDaysController,
                      decoration: const InputDecoration(
                        labelText: 'Số ngày có hiệu lực sau khi đổi',
                        hintText: 'VD: 30',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
                    ),
                    SizedBox(height: 2.h),

                    Divider(height: 3.h),

                    // Switches
                    SwitchListTile(
                      title: const Text('Đang hoạt động'),
                      subtitle: const Text('User có thể đổi thưởng này'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    SwitchListTile(
                      title: const Text('Tự động duyệt'),
                      subtitle: const Text('Không cần club owner xác nhận'),
                      value: _autoApprove,
                      onChanged: (v) => setState(() => _autoApprove = v),
                    ),

                    SizedBox(height: 2.h),

                    // Hint
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info, color: Colors.blue, size: 20),
                              SizedBox(width: 2.w),
                              Text(
                                'Lưu ý',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            '• User phải đủ điểm và hạng mới đổi được\n'
                            '• Nếu bật "Tự động duyệt", user nhận mã ngay\n'
                            '• Nếu tắt, bạn cần duyệt thủ công tại tab Redemptions',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
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
                    child: Text(isEditMode ? 'Cập nhật' : 'Tạo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final result = {
      'reward_name': _nameController.text,
      'description': _descController.text.isEmpty ? null : _descController.text,
      'reward_type': _rewardType,
      'points_cost': int.parse(_pointsCostController.text),
      'required_tier': _requiredTier,
      'quantity_available': int.parse(_quantityController.text),
      'valid_days': int.parse(_validDaysController.text),
      'is_active': _isActive,
      'auto_approve': _autoApprove,
    };

    Navigator.pop(context, result);
  }
}
