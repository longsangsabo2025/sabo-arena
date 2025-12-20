import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../models/club_promotion.dart';
import '../../theme/app_theme.dart';

class CreatePromotionScreen extends StatefulWidget {
  final String clubId;
  final String clubName;
  final ClubPromotion? editingPromotion;

  const CreatePromotionScreen({
    super.key,
    required this.clubId,
    required this.clubName,
    this.editingPromotion,
  });

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _discountAmountController = TextEditingController();
  final _maxRedemptionsController = TextEditingController();

  PromotionType _selectedType = PromotionType.discount;
  PromotionStatus _selectedStatus = PromotionStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 30));
  List<String> _selectedServices = [];
  bool _isPercentageDiscount = true;
  bool _hasMaxRedemptions = false;

  final List<String> _availableServices = [
    'table_booking',
    'membership',
    'food_drink',
    'equipment_rental',
    'training',
    'tournament',
  ];

  final Map<String, String> _serviceNames = {
    'table_booking': 'Đặt bàn',
    'membership': 'Thành viên',
    'food_drink': 'Đồ ăn & uống',
    'equipment_rental': 'Thuê thiết bị',
    'training': 'Đào tạo',
    'tournament': 'Giải đấu',
  };

  @override
  void initState() {
    super.initState();
    if (widget.editingPromotion != null) {
      _populateFromExisting();
    }
  }

  void _populateFromExisting() {
    final promotion = widget.editingPromotion!;
    _titleController.text = promotion.title;
    _descriptionController.text = promotion.description;
    _promoCodeController.text = promotion.promoCode ?? '';
    _selectedType = promotion.type;
    _selectedStatus = promotion.status;
    _startDate = promotion.startDate;
    _endDate = promotion.endDate;
    _selectedServices = promotion.applicableServices ?? [];

    if (promotion.discountPercentage != null) {
      _isPercentageDiscount = true;
      _discountPercentageController.text =
          promotion.discountPercentage.toString();
    } else if (promotion.discountAmount != null) {
      _isPercentageDiscount = false;
      _discountAmountController.text = promotion.discountAmount.toString();
    }

    if (promotion.maxRedemptions != null) {
      _hasMaxRedemptions = true;
      _maxRedemptionsController.text = promotion.maxRedemptions.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _promoCodeController.dispose();
    _discountPercentageController.dispose();
    _discountAmountController.dispose();
    _maxRedemptionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: Text(
          widget.editingPromotion != null
              ? 'Chỉnh sửa khuyến mãi'
              : 'Tạo khuyến mãi mới',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: AppTheme.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _validateAndSave,
            child: Text(
              'Lưu',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: 24),
              _buildPromotionTypeSection(),
              SizedBox(height: 24),
              _buildDiscountSection(),
              SizedBox(height: 24),
              _buildDateSection(),
              SizedBox(height: 24),
              _buildApplicableServicesSection(),
              SizedBox(height: 24),
              _buildAdvancedOptionsSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Thông tin cơ bản',
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Tên chương trình khuyến mãi *',
              hintText: 'Ví dụ: Giảm giá 20% cho thành viên mới',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên chương trình';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Mô tả *',
              hintText: 'Mô tả chi tiết về chương trình khuyến mãi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mô tả';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _promoCodeController,
            decoration: InputDecoration(
              labelText: 'Mã khuyến mãi (tùy chọn)',
              hintText: 'Ví dụ: NEWMEMBER20',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.auto_awesome),
                onPressed: _generatePromoCode,
                tooltip: 'Tạo mã tự động',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionTypeSection() {
    return _buildSection(
      title: 'Loại khuyến mãi',
      child: Column(
        children: [
          DropdownButtonFormField<PromotionType>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: 'Chọn loại khuyến mãi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: PromotionType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<PromotionStatus>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [
              PromotionStatus.draft,
              PromotionStatus.active,
              PromotionStatus.paused,
            ].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    if (_selectedType == PromotionType.discount ||
        _selectedType == PromotionType.membershipDiscount) {
      return _buildSection(
        title: 'Mức giảm giá',
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioGroup<bool>(
                    groupValue: _isPercentageDiscount,
                    onChanged: (value) {
                      setState(() {
                        _isPercentageDiscount = value!;
                        _discountAmountController.clear();
                      });
                    },
                    child: RadioListTile<bool>(
                      title: const Text('Theo phần trăm (%)'),
                      value: true,
                    ),
                  ),
                ),
                Expanded(
                  child: RadioGroup<bool>(
                    groupValue: _isPercentageDiscount,
                    onChanged: (value) {
                      setState(() {
                        _isPercentageDiscount = value!;
                        _discountPercentageController.clear();
                      });
                    },
                    child: RadioListTile<bool>(
                      title: const Text('Theo số tiền (đ)'),
                      value: false,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_isPercentageDiscount) ...[
              TextFormField(
                controller: _discountPercentageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Phần trăm giảm giá *',
                  hintText: '20',
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập phần trăm giảm giá';
                  }
                  final percentage = double.tryParse(value);
                  if (percentage == null ||
                      percentage <= 0 ||
                      percentage > 100) {
                    return 'Phần trăm phải từ 1-100';
                  }
                  return null;
                },
              ),
            ] else ...[
              TextFormField(
                controller: _discountAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền giảm *',
                  hintText: '50000',
                  suffixText: 'đ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền giảm';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildDateSection() {
    return _buildSection(
      title: 'Thời gian áp dụng',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(isStartDate: true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Ngày bắt đầu *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(_startDate),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(isStartDate: false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Ngày kết thúc *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(_endDate),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_endDate.isBefore(_startDate)) ...[
            SizedBox(height: 8),
            Text(
              'Ngày kết thúc phải sau ngày bắt đầu',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicableServicesSection() {
    return _buildSection(
      title: 'Dịch vụ áp dụng',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn các dịch vụ mà khuyến mãi này áp dụng:',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableServices.map((service) {
              final isSelected = _selectedServices.contains(service);
              return FilterChip(
                label: Text(_serviceNames[service] ?? service),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                },
                selectedColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryLight,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return _buildSection(
      title: 'Tùy chọn nâng cao',
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Giới hạn số lượt sử dụng'),
            subtitle: Text('Đặt số lượt sử dụng tối đa cho khuyến mãi này'),
            value: _hasMaxRedemptions,
            onChanged: (value) {
              setState(() {
                _hasMaxRedemptions = value;
                if (!value) {
                  _maxRedemptionsController.clear();
                }
              });
            },
          ),
          if (_hasMaxRedemptions) ...[
            SizedBox(height: 16),
            TextFormField(
              controller: _maxRedemptionsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số lượt sử dụng tối đa',
                hintText: '100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (_hasMaxRedemptions &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Vui lòng nhập số lượt sử dụng tối đa';
                }
                if (value != null && value.isNotEmpty) {
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Số lượt phải lớn hơn 0';
                  }
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _generatePromoCode() {
    // Generate a random promo code
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(
          7,
        );
    _promoCodeController.text = 'PROMO$random';
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = isStartDate ? DateTime.now() : _startDate;
    final lastDate = DateTime.now().add(Duration(days: 365));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (!mounted) return;

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final newDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartDate) {
            _startDate = newDate;
            // Ensure end date is after start date
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(Duration(days: 1));
            }
          } else {
            _endDate = newDate;
          }
        });
      }
    }
  }

  void _validateAndSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ngày kết thúc phải sau ngày bắt đầu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn ít nhất một dịch vụ áp dụng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show success message and return
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.editingPromotion != null
              ? 'Đã cập nhật khuyến mãi thành công'
              : 'Đã tạo khuyến mãi thành công',
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }
}
