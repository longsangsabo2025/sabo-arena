import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/payment_method.dart';
import '../../services/payment_method_service.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class PaymentMethodsTab extends StatefulWidget {
  final String clubId;

  const PaymentMethodsTab({super.key, required this.clubId});

  @override
  State<PaymentMethodsTab> createState() => _PaymentMethodsTabState();
}

class _PaymentMethodsTabState extends State<PaymentMethodsTab> {
  final _paymentService = PaymentMethodService.instance;
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    try {
      ProductionLogger.info('🔍 Loading payment methods for club: ${widget.clubId}', tag: 'payment_methods_tab');
      final methods = await _paymentService.getClubPaymentMethods(
        widget.clubId,
      );
      ProductionLogger.info('✅ Loaded ${methods.length} payment methods', tag: 'payment_methods_tab');
      for (var method in methods) {
        ProductionLogger.info('  - ${method.type.displayName} - ${method.accountName ?? "N/A"}', tag: 'payment_methods_tab');
      }
      setState(() {
        _paymentMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      ProductionLogger.info('❌ Error loading payment methods: $e', tag: 'payment_methods_tab');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentMethods,
              child: _paymentMethods.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: EdgeInsets.all(16.w),
                      children: [
                        _buildHeader(),
                        SizedBox(height: 20.h),
                        ..._paymentMethods
                            .map((method) => _buildPaymentMethodCard(method))
                            ,
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentMethodDialog(),
        backgroundColor: context.appTheme.primary,
        icon: Icon(Icons.add),
        label: Text('Thêm phương thức'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.appTheme.primary.withValues(alpha: 0.1),
            context.appTheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.appTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.payment,
              color: context.appTheme.primary,
              size: 28,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Thiết lập các phương thức thanh toán cho giải đấu',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(
            'Chưa có phương thức thanh toán',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Thêm phương thức để nhận thanh toán',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: method.isDefault
              ? context.appTheme.primary
              : Colors.grey.shade200,
          width: method.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: method.isDefault
                  ? context.appTheme.primary.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _buildMethodIcon(method.type),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              method.type.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (method.isDefault) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: context.appTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Mặc định',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (!method.type.isDeveloped) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Sắp ra mắt',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (method.bankName != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          method.bankName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ON/OFF Toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: method.isActive,
                      onChanged: method.type.isDeveloped
                          ? (value) => _togglePaymentMethod(method, value)
                          : null, // Disable toggle for undeveloped methods
                      activeThumbColor: context.appTheme.primary,
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  itemBuilder: (context) => [
                    if (!method.isDefault)
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8.w),
                            Text('Đặt làm mặc định'),
                          ],
                        ),
                        onTap: () => _setAsDefault(method),
                      ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8.w),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                      onTap: () => _editPaymentMethod(method),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8.w),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onTap: () => _deletePaymentMethod(method),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (method.accountName != null) ...[
                  _buildInfoRow('Tên tài khoản', method.accountName!),
                  SizedBox(height: 8.h),
                ],
                if (method.accountNumber != null) ...[
                  _buildInfoRow('Số tài khoản', method.accountNumber!),
                  SizedBox(height: 8.h),
                ],
                if (method.qrCodeUrl != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    'Mã QR thanh toán',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () => _showQRCodeFullScreen(method.qrCodeUrl!),
                    child: Container(
                      height: 200.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: method.qrCodeUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodIcon(PaymentMethodType type) {
    Color color;

    switch (type) {
      case PaymentMethodType.bankTransfer:
        color = Colors.blue;
        break;
      case PaymentMethodType.cash:
        color = Colors.green;
        break;
      case PaymentMethodType.momo:
        color = Color(0xFFD82D8B);
        break;
      case PaymentMethodType.zalopay:
        color = Color(0xFF0068FF);
        break;
      case PaymentMethodType.vnpay:
        color = Color(0xFFFF6C00);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(type.icon, color: color, size: 24),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.w,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaymentMethodSheet(
        clubId: widget.clubId,
        onAdded: () {
          _loadPaymentMethods();
        },
      ),
    );
  }

  void _editPaymentMethod(PaymentMethod method) {
    // TODO: Implement edit
  }

  Future<void> _togglePaymentMethod(PaymentMethod method, bool isActive) async {
    try {
      await _paymentService.updatePaymentMethod(
        paymentMethodId: method.id,
        isActive: isActive,
      );
      _loadPaymentMethods();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Đã bật phương thức thanh toán'
                  : 'Đã tắt phương thức thanh toán',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setAsDefault(PaymentMethod method) async {
    try {
      await _paymentService.updatePaymentMethod(
        paymentMethodId: method.id,
        isDefault: true,
      );
      _loadPaymentMethods();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đặt làm phương thức mặc định'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa phương thức thanh toán?'),
        content: Text('Bạn có chắc muốn xóa phương thức này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _paymentService.deletePaymentMethod(method.id);
        _loadPaymentMethods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa phương thức thanh toán'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showQRCodeFullScreen(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add Payment Method Sheet
class AddPaymentMethodSheet extends StatefulWidget {
  final String clubId;
  final VoidCallback onAdded;

  const AddPaymentMethodSheet({
    super.key,
    required this.clubId,
    required this.onAdded,
  });

  @override
  State<AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<AddPaymentMethodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _qrNameController = TextEditingController();
  final _paymentService = PaymentMethodService.instance;

  XFile? _qrCodeImage;
  bool _isCreating = false;
  String _selectedType = 'bank_transfer'; // 'bank_transfer' or 'qr_code'

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _qrNameController.dispose();
    super.dispose();
  }

  Future<void> _pickQRCode() async {
    final image = await _paymentService.pickQRCodeImage();
    if (image != null) {
      setState(() => _qrCodeImage = image);
    }
  }

  Future<void> _createPaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;
    if (_qrCodeImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn mã QR'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      if (_selectedType == 'qr_code') {
        // Create simple QR Code method
        await _paymentService.createQRCodeMethod(
          clubId: widget.clubId,
          qrCodeImage: _qrCodeImage!,
          methodName: _qrNameController.text.trim().isEmpty
              ? 'Quét mã QR'
              : _qrNameController.text.trim(),
          setAsDefault: false,
        );
      } else {
        // Create bank transfer method
        await _paymentService.createBankTransferMethod(
          clubId: widget.clubId,
          bankName: _bankNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          accountName: _accountNameController.text.trim(),
          qrCodeImage: _qrCodeImage!,
          setAsDefault: true,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm phương thức thanh toán'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm phương thức thanh toán',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),

              // Payment type selector
              Text(
                'Loại phương thức',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      'bank_transfer',
                      'Chuyển khoản',
                      Icons.account_balance,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTypeOption(
                      'qr_code',
                      'Quét QR',
                      Icons.qr_code_2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Show fields based on selected type
              if (_selectedType == 'bank_transfer') ..._buildBankTransferFields(),
              if (_selectedType == 'qr_code') ..._buildQRCodeFields(),

              // QR Code Upload (common for both types)
              Text(
                'Mã QR thanh toán *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.h),

              GestureDetector(
                onTap: _pickQRCode,
                child: Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _qrCodeImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Chọn ảnh QR code',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImagePreview(),
                        ),
                ),
              ),

              SizedBox(height: 24.h),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createPaymentMethod,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Thêm phương thức',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? context.appTheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.appTheme.primary : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? context.appTheme.primary : Colors.grey),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? context.appTheme.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBankTransferFields() {
    return [
      // Bank name
      TextFormField(
        controller: _bankNameController,
        decoration: InputDecoration(
          labelText: 'Tên ngân hàng *',
          hintText: 'VD: Vietcombank',
          prefixIcon: Icon(Icons.account_balance),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập tên ngân hàng';
          }
          return null;
        },
      ),
      SizedBox(height: 16.h),
      
      // Account number
      TextFormField(
        controller: _accountNumberController,
        decoration: InputDecoration(
          labelText: 'Số tài khoản *',
          hintText: 'VD: 1234567890',
          prefixIcon: Icon(Icons.credit_card),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập số tài khoản';
          }
          return null;
        },
      ),
      SizedBox(height: 16.h),
      
      // Account name
      TextFormField(
        controller: _accountNameController,
        decoration: InputDecoration(
          labelText: 'Tên chủ tài khoản *',
          hintText: 'VD: NGUYEN VAN A',
          prefixIcon: Icon(Icons.person),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập tên chủ tài khoản';
          }
          return null;
        },
      ),
      SizedBox(height: 20.h),
    ];
  }

  List<Widget> _buildQRCodeFields() {
    return [
      // QR Name (optional)
      TextFormField(
        controller: _qrNameController,
        decoration: InputDecoration(
          labelText: 'Tên phương thức (tùy chọn)',
          hintText: 'VD: Quét QR Vietcombank',
          prefixIcon: Icon(Icons.label),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      SizedBox(height: 20.h),
    ];
  }

  // Build image preview that works for both web and mobile
  Widget _buildImagePreview() {
    if (_qrCodeImage == null) {
      return SizedBox.shrink();
    }

    if (kIsWeb) {
      // For web: Use Image.network with the blob URL
      return Image.network(
        _qrCodeImage!.path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text(
                'Không thể hiển thị ảnh',
                style: TextStyle(color: Colors.red),
              ),
            ],
          );
        },
      );
    } else {
      // For mobile: Use Image.file
      return Image.file(
        File(_qrCodeImage!.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text(
                'Không thể hiển thị ảnh',
                style: TextStyle(color: Colors.red),
              ),
            ],
          );
        },
      );
    }
  }
}
