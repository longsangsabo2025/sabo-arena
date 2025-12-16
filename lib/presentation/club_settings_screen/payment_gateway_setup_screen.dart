import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentGatewaySetupScreen extends StatefulWidget {
  final String clubId;

  const PaymentGatewaySetupScreen({super.key, required this.clubId});

  @override
  State<PaymentGatewaySetupScreen> createState() =>
      _PaymentGatewaySetupScreenState();
}

class _PaymentGatewaySetupScreenState extends State<PaymentGatewaySetupScreen> {
  final _supabase = Supabase.instance.client;

  // MoMo
  final _momoPartnerCodeController = TextEditingController();
  final _momoAccessKeyController = TextEditingController();
  final _momoSecretKeyController = TextEditingController();
  bool _momoEnabled = false;

  // ZaloPay
  final _zaloAppIdController = TextEditingController();
  final _zaloKey1Controller = TextEditingController();
  final _zaloKey2Controller = TextEditingController();
  bool _zaloEnabled = false;

  // VNPay
  final _vnpayTmnCodeController = TextEditingController();
  final _vnpayHashSecretController = TextEditingController();
  bool _vnpayEnabled = false;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _momoPartnerCodeController.dispose();
    _momoAccessKeyController.dispose();
    _momoSecretKeyController.dispose();
    _zaloAppIdController.dispose();
    _zaloKey1Controller.dispose();
    _zaloKey2Controller.dispose();
    _vnpayTmnCodeController.dispose();
    _vnpayHashSecretController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('club_payment_config')
          .select()
          .eq('club_id', widget.clubId)
          .maybeSingle();

      if (response != null) {
        final config = response['config'] as Map<String, dynamic>?;
        if (config != null) {
          // MoMo
          final momo = config['momo'] as Map<String, dynamic>?;
          if (momo != null) {
            _momoPartnerCodeController.text = momo['partner_code'] ?? '';
            _momoAccessKeyController.text = momo['access_key'] ?? '';
            _momoSecretKeyController.text = momo['secret_key'] ?? '';
            _momoEnabled = momo['enabled'] ?? false;
          }

          // ZaloPay
          final zalo = config['zalopay'] as Map<String, dynamic>?;
          if (zalo != null) {
            _zaloAppIdController.text = zalo['app_id'] ?? '';
            _zaloKey1Controller.text = zalo['key1'] ?? '';
            _zaloKey2Controller.text = zalo['key2'] ?? '';
            _zaloEnabled = zalo['enabled'] ?? false;
          }

          // VNPay
          final vnpay = config['vnpay'] as Map<String, dynamic>?;
          if (vnpay != null) {
            _vnpayTmnCodeController.text = vnpay['tmn_code'] ?? '';
            _vnpayHashSecretController.text = vnpay['hash_secret'] ?? '';
            _vnpayEnabled = vnpay['enabled'] ?? false;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final config = {
        'momo': {
          'partner_code': _momoPartnerCodeController.text.trim(),
          'access_key': _momoAccessKeyController.text.trim(),
          'secret_key': _momoSecretKeyController.text.trim(),
          'enabled': _momoEnabled,
        },
        'zalopay': {
          'app_id': _zaloAppIdController.text.trim(),
          'key1': _zaloKey1Controller.text.trim(),
          'key2': _zaloKey2Controller.text.trim(),
          'enabled': _zaloEnabled,
        },
        'vnpay': {
          'tmn_code': _vnpayTmnCodeController.text.trim(),
          'hash_secret': _vnpayHashSecretController.text.trim(),
          'enabled': _vnpayEnabled,
        },
      };

      await _supabase.from('club_payment_config').upsert({
        'club_id': widget.clubId,
        'config': config,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu cấu hình'),
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
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Cổng thanh toán tự động'),
        backgroundColor: context.appTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveConfig,
              child: Text(
                'Lưu', overflow: TextOverflow.ellipsis, style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  SizedBox(height: 20.h),
                  _buildMoMoSection(),
                  SizedBox(height: 20.h),
                  _buildZaloPaySection(),
                  SizedBox(height: 20.h),
                  _buildVNPaySection(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 24),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thanh toán tự động', overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Nhập API keys để tự động xác nhận thanh toán. Không cần xác nhận thủ công!', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoMoSection() {
    return _buildGatewayCard(
      title: 'MoMo',
      subtitle: 'Ví điện tử MoMo',
      icon: Icons.account_balance_wallet,
      color: Color(0xFFD82D8B),
      enabled: _momoEnabled,
      onToggle: (value) => setState(() => _momoEnabled = value),
      docsUrl: 'https://developers.momo.vn/',
      fields: [
        _buildTextField(
          controller: _momoPartnerCodeController,
          label: 'Partner Code',
          hint: 'VD: MOMOXXX',
          enabled: _momoEnabled,
        ),
        _buildTextField(
          controller: _momoAccessKeyController,
          label: 'Access Key',
          hint: 'Nhập Access Key',
          enabled: _momoEnabled,
        ),
        _buildTextField(
          controller: _momoSecretKeyController,
          label: 'Secret Key',
          hint: 'Nhập Secret Key',
          enabled: _momoEnabled,
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildZaloPaySection() {
    return _buildGatewayCard(
      title: 'ZaloPay',
      subtitle: 'Ví điện tử ZaloPay',
      icon: Icons.payment,
      color: Color(0xFF0068FF),
      enabled: _zaloEnabled,
      onToggle: (value) => setState(() => _zaloEnabled = value),
      docsUrl: 'https://docs.zalopay.vn/',
      fields: [
        _buildTextField(
          controller: _zaloAppIdController,
          label: 'App ID',
          hint: 'VD: 2553',
          enabled: _zaloEnabled,
        ),
        _buildTextField(
          controller: _zaloKey1Controller,
          label: 'Key 1',
          hint: 'Nhập Key 1',
          enabled: _zaloEnabled,
          obscureText: true,
        ),
        _buildTextField(
          controller: _zaloKey2Controller,
          label: 'Key 2',
          hint: 'Nhập Key 2',
          enabled: _zaloEnabled,
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildVNPaySection() {
    return _buildGatewayCard(
      title: 'VNPay',
      subtitle: 'Cổng thanh toán VNPay',
      icon: Icons.credit_card,
      color: Color(0xFFFF6C00),
      enabled: _vnpayEnabled,
      onToggle: (value) => setState(() => _vnpayEnabled = value),
      docsUrl: 'https://sandbox.vnpayment.vn/apis/',
      fields: [
        _buildTextField(
          controller: _vnpayTmnCodeController,
          label: 'TMN Code',
          hint: 'VD: VNPAYXXX',
          enabled: _vnpayEnabled,
        ),
        _buildTextField(
          controller: _vnpayHashSecretController,
          label: 'Hash Secret',
          hint: 'Nhập Hash Secret',
          enabled: _vnpayEnabled,
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildGatewayCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required Function(bool) onToggle,
    required String docsUrl,
    required List<Widget> fields,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? color : Colors.grey.shade200,
          width: enabled ? 2 : 1,
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
              color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle, style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: onToggle, activeThumbColor: color),
              ],
            ),
          ),

          // Fields
          if (enabled)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...fields,
                  SizedBox(height: 12.h),
                  InkWell(
                    onTap: () {
                      // Open docs URL
                    },
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, size: 16, color: color),
                        SizedBox(width: 6.w),
                        Text(
                          'Xem hướng dẫn lấy API keys', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 13,
                            color: color,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
    bool obscureText = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: obscureText
              ? IconButton(
                  icon: Icon(Icons.visibility_off),
                  onPressed: () {
                    // Toggle visibility
                  },
                )
              : null,
        ),
      ),
    );
  }
}
