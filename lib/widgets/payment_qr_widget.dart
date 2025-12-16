import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sabo_arena/services/qr_payment_service.dart';
import 'package:sabo_arena/theme/app_theme.dart';

class PaymentQRWidget extends StatefulWidget {
  final String paymentMethod; // 'bank', 'momo', 'zalopay', 'viettelpay'
  final Map<String, dynamic> paymentInfo;
  final double? amount;
  final String? description;
  final String? invoiceId;

  const PaymentQRWidget({
    super.key,
    required this.paymentMethod,
    required this.paymentInfo,
    this.amount,
    this.description,
    this.invoiceId,
  });

  @override
  State<PaymentQRWidget> createState() => _PaymentQRWidgetState();
}

class _PaymentQRWidgetState extends State<PaymentQRWidget> {
  String? qrData;
  String? qrImageUrl;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      if (widget.paymentMethod == 'bank') {
        // Tạo QR Code cho ngân hàng
        final bankName = widget.paymentInfo['bankName'] as String;
        final accountNumber = widget.paymentInfo['accountNumber'] as String;
        final accountName = widget.paymentInfo['accountName'] as String;

        // Validate thông tin ngân hàng
        if (!QRPaymentService.validateBankInfo(
          bankName: bankName,
          accountNumber: accountNumber,
          accountName: accountName,
        )) {
          throw Exception('Thông tin ngân hàng không hợp lệ');
        }

        // Tạo URL VietQR (khuyến nghị)
        qrImageUrl = QRPaymentService.generateBankQRUrl(
          bankName: bankName,
          accountNumber: accountNumber,
          accountName: accountName,
          amount: widget.amount,
          description:
              widget.description ??
              (widget.invoiceId != null
                  ? 'Thanh toan ${widget.invoiceId}'
                  : null),
        );

        // Backup: Tạo QR data local
        qrData = QRPaymentService.generateBankQRData(
          bankName: bankName,
          accountNumber: accountNumber,
          accountName: accountName,
          amount: widget.amount,
          description:
              widget.description ??
              (widget.invoiceId != null
                  ? 'Thanh toan ${widget.invoiceId}'
                  : null),
        );
      } else {
        // Tạo QR Code cho ví điện tử
        final phoneNumber = widget.paymentInfo['phoneNumber'] as String;
        final receiverName = widget.paymentInfo['receiverName'] as String;

        if (!QRPaymentService.validateEWalletInfo(
          walletType: widget.paymentMethod,
          phoneNumber: phoneNumber,
          receiverName: receiverName,
        )) {
          throw Exception('Thông tin ví điện tử không hợp lệ');
        }

        qrData = QRPaymentService.generateEWalletQRData(
          walletType: widget.paymentMethod,
          phoneNumber: phoneNumber,
          receiverName: receiverName,
          amount: widget.amount,
          note:
              widget.description ??
              (widget.invoiceId != null
                  ? 'Thanh toan ${widget.invoiceId}'
                  : null),
        );
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildQRSection(),
          const SizedBox(height: 20),
          _buildPaymentInfo(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon;
    String title;
    Color color;

    switch (widget.paymentMethod) {
      case 'bank':
        icon = Icons.account_balance;
        title = 'Chuyển khoản ngân hàng';
        color = AppTheme.primaryLight;
        break;
      case 'momo':
        icon = Icons.phone_android;
        title = 'Thanh toán MoMo';
        color = const Color(0xFFD82D8B);
        break;
      case 'zalopay':
        icon = Icons.payment;
        title = 'Thanh toán ZaloPay';
        color = const Color(0xFF0068FF);
        break;
      case 'viettelpay':
        icon = Icons.account_balance_wallet;
        title = 'Thanh toán ViettelPay';
        color = const Color(0xFFFF6B35);
        break;
      default:
        icon = Icons.qr_code;
        title = 'Thanh toán QR';
        color = AppTheme.primaryLight;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimaryLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.amount != null)
                Text(
                  'Số tiền: ${_formatCurrency(widget.amount!)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQRSection() {
    if (isLoading) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 12),
              Text(
                'Lỗi tạo QR Code',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(color: Colors.red[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _generateQRCode,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Hiển thị QR Code
          if (qrImageUrl != null && widget.paymentMethod == 'bank')
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                qrImageUrl!,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback về QR local nếu VietQR API lỗi
                  return QrImageView(
                    data: qrData!,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  );
                },
              ),
            )
          else if (qrData != null)
            QrImageView(
              data: qrData!,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),

          const SizedBox(height: 12),
          Text(
            'Quét mã QR để thanh toán',
            style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    List<Widget> infoItems = [];

    if (widget.paymentMethod == 'bank') {
      infoItems.addAll([
        _buildInfoItem(
          'Ngân hàng',
          widget.paymentInfo['bankName'],
          Icons.account_balance,
        ),
        _buildInfoItem(
          'Số tài khoản',
          widget.paymentInfo['accountNumber'],
          Icons.credit_card,
          copyable: true,
        ),
        _buildInfoItem(
          'Chủ tài khoản',
          widget.paymentInfo['accountName'],
          Icons.person,
        ),
      ]);
    } else {
      infoItems.addAll([
        _buildInfoItem(
          'Ví điện tử',
          widget.paymentMethod.toUpperCase(),
          Icons.account_balance_wallet,
        ),
        _buildInfoItem(
          'Số điện thoại',
          widget.paymentInfo['phoneNumber'],
          Icons.phone,
          copyable: true,
        ),
        _buildInfoItem(
          'Người nhận',
          widget.paymentInfo['receiverName'],
          Icons.person,
        ),
      ]);
    }

    if (widget.amount != null) {
      infoItems.add(
        _buildInfoItem(
          'Số tiền',
          _formatCurrency(widget.amount!),
          Icons.attach_money,
          copyable: true,
        ),
      );
    }

    if (widget.description != null) {
      infoItems.add(
        _buildInfoItem(
          'Nội dung',
          widget.description!,
          Icons.note,
          copyable: true,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin thanh toán',
            style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...infoItems,
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondaryLight),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(text: '$label: '),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () => _copyToClipboard(value),
              icon: Icon(Icons.copy, size: 16, color: AppTheme.primaryLight),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareQRCode(),
            icon: const Icon(Icons.share),
            label: const Text('Chia sẻ'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _copyQRData(),
            icon: const Icon(Icons.content_copy),
            label: const Text('Sao chép'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã sao chép: $text'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyQRData() {
    if (qrData != null) {
      Clipboard.setData(ClipboardData(text: qrData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã sao chép dữ liệu QR'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareQRCode() {
    if (qrData != null) {
      String shareText = 'Thông tin thanh toán:\n';
      shareText += 'Phương thức: ${widget.paymentMethod.toUpperCase()}\n';

      if (widget.amount != null) {
        shareText += 'Số tiền: ${_formatCurrency(widget.amount!)}\n';
      }

      if (widget.description != null) {
        shareText += 'Nội dung: ${widget.description!}\n';
      }

      shareText += 'Mã QR: $qrData';

      Share.share(shareText, subject: 'Thông tin thanh toán QR');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không có dữ liệu QR để chia sẻ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }
}
