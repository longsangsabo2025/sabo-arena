import 'package:flutter/material.dart';
import '../../../models/payment_method.dart';
import '../../../services/payment_method_service.dart';
import '../../../services/auth_service.dart';
import 'bank_transfer_qr_dialog.dart';

class PaymentOptionsDialog extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final double entryFee;
  final String clubId;
  final Function(String paymentMethod)? onPaymentConfirmed;

  const PaymentOptionsDialog({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.entryFee,
    required this.clubId,
    this.onPaymentConfirmed,
  });

  @override
  State<PaymentOptionsDialog> createState() => _PaymentOptionsDialogState();
}

class _PaymentOptionsDialogState extends State<PaymentOptionsDialog> {
  final _paymentService = PaymentMethodService.instance;
  List<PaymentMethod> _availableMethods = [];
  PaymentMethod? _selectedMethod;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await _paymentService.getClubPaymentMethods(
        widget.clubId,
      );

      // Filter: only active AND developed methods
      final available = methods
          .where((m) => m.isActive && m.type.isDeveloped)
          .toList();

      setState(() {
        _availableMethods = available;
        _selectedMethod = available.isNotEmpty ? available.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải phương thức thanh toán: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 400,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: Colors.green.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xác nhận đăng ký',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          Text(
                            widget.tournamentName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Fee info - Compact
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${widget.entryFee.toStringAsFixed(0)} VNĐ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment methods title
                Text(
                  'Chọn phương thức thanh toán',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),

                // Loading or Payment methods
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_availableMethods.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.payment_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Chưa có phương thức thanh toán',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Dynamic payment methods
                  ..._availableMethods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final method = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _availableMethods.length - 1 ? 10 : 0,
                      ),
                      child: _buildDynamicPaymentOption(method),
                    );
                  }),

                if (!_isLoading && _availableMethods.isNotEmpty)
                  const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _selectedMethod != null && !_isLoading
                            ? () => _handlePayment()
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _getButtonColor(),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Thanh toán',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getButtonColor() {
    if (_selectedMethod?.type == PaymentMethodType.momo) {
      return Color(0xFFAE2070); // MoMo pink
    }
    return Colors.green;
  }

  Future<void> _handlePayment() async {
    if (_selectedMethod == null) return;

    // If bank transfer, show QR dialog
    if (_selectedMethod!.type == PaymentMethodType.bankTransfer) {
      // Get current user ID for transfer content
      final authService = AuthService.instance;
      final currentUser = authService.currentUser;
      final userId = currentUser?.id ?? 'USERUSER';
      
      // Super short transfer content: 8 chars only (4 tournament + 4 user)
      final transferContent = '${widget.tournamentId.substring(0, 4).toUpperCase()}${userId.substring(0, 4).toUpperCase()}';
      
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => BankTransferQRDialog(
          paymentMethod: _selectedMethod!,
          amount: widget.entryFee,
          transferContent: transferContent,
        ),
      );

      if (confirmed == true && mounted) {
        // User confirmed they transferred money
        Navigator.of(context).pop();
        widget.onPaymentConfirmed?.call(_selectedMethod!.id);
      }
      return;
    }

    // For other payment methods (cash, momo), proceed normally
    Navigator.of(context).pop();
    widget.onPaymentConfirmed?.call(_selectedMethod!.id);
  }

  Widget _buildDynamicPaymentOption(PaymentMethod method) {
    final isSelected = _selectedMethod?.id == method.id;
    final momoColor = Color(0xFFAE2070);
    final primaryColor = method.type == PaymentMethodType.momo
        ? momoColor
        : Colors.green;

    // Get subtitle based on method type
    String subtitle;
    String? badge;

    switch (method.type) {
      case PaymentMethodType.cash:
        subtitle = 'Thanh toán khi đến thi đấu';
        break;
      case PaymentMethodType.momo:
        subtitle = 'Tự động xác nhận ngay';
        badge = 'Nhanh';
        break;
      case PaymentMethodType.bankTransfer:
        subtitle = method.bankName ?? 'Chuyển khoản ngân hàng';
        break;
      default:
        subtitle = 'Thanh toán qua ${method.type.displayName}';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio + Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      method.type.icon,
                      color: isSelected ? primaryColor : Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Text
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade900,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Old methods removed - now using dynamic _buildDynamicPaymentOption
}
