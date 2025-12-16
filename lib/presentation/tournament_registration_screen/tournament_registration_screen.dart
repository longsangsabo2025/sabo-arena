import 'package:flutter/material.dart';
import 'package:sabo_arena/utils/size_extensions.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';
import '../../models/payment_method.dart';
import '../../services/payment_method_service.dart';
import '../../services/payment_gateway_service.dart';
import '../../services/auth_service.dart';
import '../../config/payment_config.dart';
import '../../utils/payment_error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_system/design_system.dart';
import 'widgets/payment_method_selector.dart';
import 'widgets/momo_payment_button.dart';
import 'widgets/payment_loading_overlay.dart';
import 'package:sabo_arena/utils/production_logger.dart'; // ELON_MODE_AUTO_FIX

class TournamentRegistrationScreen extends StatefulWidget {
  final String tournamentId;
  final String clubId;
  final double entryFee;
  final String tournamentName;

  const TournamentRegistrationScreen({
    super.key,
    required this.tournamentId,
    required this.clubId,
    required this.entryFee,
    required this.tournamentName,
  });

  @override
  State<TournamentRegistrationScreen> createState() =>
      _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState
    extends State<TournamentRegistrationScreen> {
  final _paymentService = PaymentMethodService.instance;
  final _gatewayService = PaymentGatewayService.instance;
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();

  PaymentMethod? _selectedPaymentMethod;
  XFile? _proofImage;
  bool _isLoading = true;
  bool _isSubmitting = false;
  TournamentPayment? _existingPayment;

  // Payment type: 'manual' or 'momo'
  String _paymentType = 'manual';

  // Auto-refresh timer
  Timer? _pollingTimer;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _referenceController.dispose();
    _stopPolling();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Load payment methods
      final methods = await _paymentService.getClubPaymentMethods(
        widget.clubId,
      );

      // Check existing payment
      final existingPayment = await _paymentService.getUserTournamentPayment(
        tournamentId: widget.tournamentId,
        userId: userId,
      );

      setState(() {
        _paymentMethods = methods;
        _selectedPaymentMethod = methods.firstWhere(
          (m) => m.isDefault,
          orElse: () => methods.first,
        );
        _existingPayment = existingPayment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickProofImage() async {
    final image = await _paymentService.pickQRCodeImage();
    if (image != null) {
      setState(() => _proofImage = image);
    }
  }

  Future<void> _submitRegistration() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng upload ảnh chuyển khoản'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Create payment if not exists
      TournamentPayment payment;
      if (_existingPayment == null) {
        payment = await _paymentService.createTournamentPayment(
          tournamentId: widget.tournamentId,
          userId: userId,
          clubId: widget.clubId,
          paymentMethodId: _selectedPaymentMethod!.id,
          amount: widget.entryFee,
        );
      } else {
        payment = _existingPayment!;
      }

      // Upload proof
      await _paymentService.uploadPaymentProof(
        paymentId: payment.id,
        proofImage: _proofImage!,
        transactionNote: _noteController.text.trim(),
        transactionReference: _referenceController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã gửi thông tin thanh toán. Vui lòng chờ xác nhận.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text('Đăng ký tham gia'),
        backgroundColor: context.appTheme.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _existingPayment != null &&
                _existingPayment!.status != PaymentStatus.rejected
          ? _buildExistingPaymentView()
          : _buildRegistrationForm(),
    );
  }

  Widget _buildExistingPaymentView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildStatusCard(),
          SizedBox(height: 20.h),

          // Show polling indicator if payment is pending and polling is active
          if (_isPolling && _existingPayment!.status == PaymentStatus.pending)
            _buildPollingIndicator()
          else
            _buildPaymentInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _existingPayment!.status;
    IconData icon;
    String title;
    String message;
    Color color;

    switch (status) {
      case PaymentStatus.pending:
        icon = Icons.schedule;
        title = 'Chờ thanh toán';
        message = 'Vui lòng chuyển khoản và upload ảnh xác nhận';
        color = AppColors.warning;
        break;
      case PaymentStatus.verifying:
        icon = Icons.hourglass_empty;
        title = 'Đang xác minh';
        message = 'CLB đang xác minh thanh toán của bạn';
        color = AppColors.info;
        break;
      case PaymentStatus.verified:
        icon = Icons.check_circle;
        title = 'Đã xác nhận';
        message = 'Thanh toán đã được xác nhận. Bạn đã đăng ký thành công!';
        color = AppColors.success;
        break;
      case PaymentStatus.rejected:
        icon = Icons.cancel;
        title = 'Từ chối';
        message =
            _existingPayment!.rejectionReason ?? 'Thanh toán không hợp lệ';
        color = AppColors.error;
        break;
      default:
        icon = Icons.info;
        title = 'Đang xử lý';
        message = 'Vui lòng chờ';
        color = AppColors.textTertiary;
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          SizedBox(height: 16.h),
          Text(
            title, style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin thanh toán', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('Số tiền', '${widget.entryFee.toStringAsFixed(0)} VNĐ'),
          _buildInfoRow(
            'Thời gian',
            _formatDateTime(_existingPayment!.createdAt),
          ),
          if (_existingPayment!.transactionReference != null)
            _buildInfoRow(
              'Mã giao dịch',
              _existingPayment!.transactionReference!,
            ),
          if (_existingPayment!.proofImageUrl != null) ...[
            SizedBox(height: 16.h),
            Text(
              'Ảnh xác nhận', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () =>
                  _showImageFullScreen(_existingPayment!.proofImageUrl!),
              child: Container(
                height: 200.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _existingPayment!.proofImageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTournamentInfoCard(),
          SizedBox(height: 20.h),
          _buildPaymentMethodCard(),

          // Only show upload & transaction info for manual payment
          if (_paymentType == 'manual') ...[
            SizedBox(height: 20.h),
            _buildProofUploadCard(),
            SizedBox(height: 20.h),
            _buildTransactionInfoCard(),
            SizedBox(height: 20.h),
            _buildSubmitButton(),
          ],

          // Show polling indicator for MoMo payment
          if (_paymentType == 'momo' && _isPolling) ...[
            SizedBox(height: 20.h),
            _buildPollingIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.appTheme.primary,
            context.appTheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.textOnPrimary, size: 28),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  widget.tournamentName, style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phí đăng ký', overflow: TextOverflow.ellipsis, style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  '${widget.entryFee.toStringAsFixed(0)} VNĐ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Start polling for payment status updates
  void _startPolling() {
    if (_isPolling) return;

    setState(() => _isPolling = true);

    // Poll every 5 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _checkPaymentStatus();
    });

    ProductionLogger.debug('Debug log', tag: 'AutoFix');
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    if (_isPolling) {
      setState(() => _isPolling = false);
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  /// Check payment status
  Future<void> _checkPaymentStatus() async {
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) return;

      final payment = await _paymentService.getUserTournamentPayment(
        tournamentId: widget.tournamentId,
        userId: userId,
      );

      // Check if payment status changed
      if (payment != null && payment.status != _existingPayment?.status) {
        ProductionLogger.debug('Debug log', tag: 'AutoFix');

        setState(() {
          _existingPayment = payment;
        });

        // Stop polling if payment is verified or rejected
        if (payment.status == PaymentStatus.verified ||
            payment.status == PaymentStatus.rejected) {
          _stopPolling();

          if (mounted) {
            if (payment.status == PaymentStatus.verified) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.textOnPrimary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '✅ Thanh toán thành công! Bạn đã đăng ký giải đấu.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 5),
                ),
              );
            } else if (payment.status == 'rejected') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error, color: AppColors.textOnPrimary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '❌ Thanh toán thất bại: ${payment.rejectionReason ?? "Vui lòng thử lại"}',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      ProductionLogger.debug('Debug log', tag: 'AutoFix');
    }
  }

  Future<void> _payWithMoMo() async {
    setState(() => _isSubmitting = true);
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final orderId =
          'TOUR_${widget.tournamentId}_${DateTime.now().millisecondsSinceEpoch}';

      // Create pending payment record first with retry
      final payment = await PaymentErrorHandler.retryWithBackoff(
        operation: () => _paymentService.createTournamentPayment(
          tournamentId: widget.tournamentId,
          userId: userId,
          clubId: widget.clubId,
          paymentMethodId: 'momo',
          amount: widget.entryFee,
        ),
        maxAttempts: 2,
      );

      // Update with transaction reference
      await Supabase.instance.client
          .from('tournament_payments')
          .update({
            'transaction_reference': orderId,
            'transaction_note': 'MoMo payment - Pending',
          })
          .eq('id', payment.id);

      // Create MoMo payment with retry
      final result = await PaymentErrorHandler.retryWithBackoff(
        operation: () => _gatewayService.createMoMoPayment(
          partnerCode: PaymentConfig.currentPartnerCode,
          accessKey: PaymentConfig.currentAccessKey,
          secretKey: PaymentConfig.currentSecretKey,
          orderId: orderId,
          amount: widget.entryFee,
          orderInfo: 'Thanh toán ${widget.tournamentName}',
          returnUrl: PaymentConfig.momoReturnUrl,
          notifyUrl: PaymentConfig.momoNotifyUrl,
          extraData: userId,
        ),
        maxAttempts: 2,
      );

      if (result['success'] == true) {
        final payUrl = result['payUrl'] as String;

        // Open MoMo payment URL
        final uri = Uri.parse(payUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.textOnPrimary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã mở app MoMo. Đang chờ xác nhận thanh toán...',
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );

            // Start auto-refresh polling
            _startPolling();
          }
        } else {
          throw 'Không thể mở app MoMo. Vui lòng cài đặt app MoMo.';
        }
      } else {
        throw result['message'] ?? 'Lỗi tạo thanh toán MoMo';
      }
    } catch (e) {
      if (mounted) {
        // Show user-friendly error message
        PaymentErrorHandler.showErrorSnackBar(context: context, error: e);

        // Show retry dialog if error is retryable
        if (PaymentErrorHandler.isRetryable(e)) {
          final shouldRetry = await PaymentErrorHandler.showErrorDialog(
            context: context,
            title: 'Lỗi thanh toán',
            error: e,
            showRetry: true,
          );

          if (shouldRetry) {
            // Retry payment
            _payWithMoMo();
            return;
          }
        }
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPaymentMethodCard() {
    if (_selectedPaymentMethod == null) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('Không có phương thức thanh toán'),
      );
    }

    return Column(
      children: [
        // Payment type selector - Beautiful new widget
        PaymentMethodSelector(
          selectedMethod: _paymentType,
          onMethodChanged: (method) => setState(() => _paymentType = method),
          showMoMo: PaymentConfig.isMoMoConfigured,
          showCash: true,
        ),

        SizedBox(height: 20.h),

        // MoMo payment button - Beautiful new widget
        if (_paymentType == 'momo')
          MoMoPaymentButton(
            amount: widget.entryFee,
            isLoading: _isSubmitting,
            onPressed: _payWithMoMo,
          ),

        // Manual payment (QR code)
        if (_paymentType == 'manual') _buildManualPaymentCard(),

        // Cash payment (At counter)
        if (_paymentType == 'cash') _buildCashPaymentCard(),
      ],
    );
  }

  Widget _buildPollingIndicator() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated indicator
          PaymentStatusIndicator(
            status: _existingPayment?.status.value ?? 'pending',
            isPolling: true,
          ),

          SizedBox(height: 16.h),

          Text(
            'Đang chờ xác nhận thanh toán từ MoMo...', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          Text(
            'Vui lòng hoàn tất thanh toán trong app MoMo', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16.h),

          // Cancel button
          TextButton.icon(
            onPressed: () {
              _stopPolling();
              setState(() => _paymentType = 'manual');
            },
            icon: Icon(Icons.close, size: 18),
            label: Text('Hủy và chọn phương thức khác'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildManualPaymentCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chuyển khoản', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('Ngân hàng', _selectedPaymentMethod!.bankName ?? ''),
          _buildInfoRow(
            'Số tài khoản',
            _selectedPaymentMethod!.accountNumber ?? '',
          ),
          _buildInfoRow(
            'Tên tài khoản',
            _selectedPaymentMethod!.accountName ?? '',
          ),
          if (_selectedPaymentMethod!.qrCodeUrl != null) ...[
            SizedBox(height: 16.h),
            Text(
              'Quét mã QR để chuyển khoản', overflow: TextOverflow.ellipsis, style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () =>
                  _showImageFullScreen(_selectedPaymentMethod!.qrCodeUrl!),
              child: Container(
                height: 300.h,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _selectedPaymentMethod!.qrCodeUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCashPaymentCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warning500, AppColors.warning600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.store, color: AppColors.textOnPrimary, size: 28),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thanh toán tại quầy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Trả tiền mặt trực tiếp tại quán',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Instructions
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.warning50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, 
                      color: AppColors.warning700, 
                      size: 20,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Hướng dẫn thanh toán',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildInstructionStep('1', 'Nhấn nút "Xác nhận đăng ký" bên dưới'),
                SizedBox(height: 8.h),
                _buildInstructionStep('2', 'Đến quầy của CLB để thanh toán'),
                SizedBox(height: 8.h),
                _buildInstructionStep('3', 'Xuất trình mã đăng ký cho nhân viên'),
                SizedBox(height: 8.h),
                _buildInstructionStep('4', 'CLB sẽ xác nhận sau khi nhận tiền'),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Amount display
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warning500, AppColors.warning600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số tiền thanh toán',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  '${widget.entryFee.toStringAsFixed(0)} VNĐ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _registerWithCashPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning600,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.surface,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20),
                        SizedBox(width: 8.w),
                        Text(
                          'Xác nhận đăng ký',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: 12.h),

          // Note
          Text(
            '💡 Lưu ý: Bạn cần đến quầy thanh toán trong vòng 24h để hoàn tất đăng ký.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.warning600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _registerWithCashPayment() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // Create payment record with cash method and pending status
      final payment = await _paymentService.createTournamentPayment(
        tournamentId: widget.tournamentId,
        userId: userId,
        clubId: widget.clubId,
        paymentMethodId: 'cash',
        amount: widget.entryFee,
      );

      // Update with note about cash payment
      await Supabase.instance.client
          .from('tournament_payments')
          .update({
            'transaction_note': 'Thanh toán tiền mặt tại quầy - Chờ xác nhận',
            'transaction_reference': 'CASH_${payment.id.substring(0, 8).toUpperCase()}',
          })
          .eq('id', payment.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.textOnPrimary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Đăng ký thành công! Vui lòng đến quầy thanh toán trong 24h.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildProofUploadCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ảnh xác nhận chuyển khoản *', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            'Chụp ảnh màn hình giao dịch thành công', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _pickProofImage,
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _proofImage == null
                      ? AppColors.gray300
                      : context.appTheme.primary,
                  width: 2,
                ),
              ),
              child: _proofImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 60,
                          color: AppColors.gray400,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Chọn ảnh từ thư viện', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_proofImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin bổ sung (tùy chọn)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: 'Mã giao dịch',
              hintText: 'VD: FT23123456789',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Ghi chú',
              hintText: 'Thêm ghi chú nếu cần',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.appTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.surface,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Xác nhận đăng ký', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value, style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.shadowDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, color: AppColors.textOnPrimary),
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

