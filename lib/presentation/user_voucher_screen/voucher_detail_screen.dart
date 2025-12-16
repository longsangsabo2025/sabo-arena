import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../models/user_achievement.dart';
import '../../core/design_system/design_system.dart';
import '../../widgets/custom_app_bar.dart';

class VoucherDetailScreen extends StatefulWidget {
  final UserVoucher voucher;

  const VoucherDetailScreen({super.key, required this.voucher});

  @override
  State<VoucherDetailScreen> createState() => _VoucherDetailScreenState();
}

class _VoucherDetailScreenState extends State<VoucherDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chi tiết voucher',
        backgroundColor: _getHeaderColor(),
      ),
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Voucher Header Card
            _buildVoucherHeader(),

            SizedBox(height: 16.sp),

            // Voucher Details
            _buildVoucherDetails(),

            SizedBox(height: 16.sp),

            // Terms & Conditions
            _buildTermsConditions(),

            SizedBox(height: 16.sp),

            // Usage Instructions
            if (widget.voucher.isUsable) _buildUsageInstructions(),

            SizedBox(height: 80.sp), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: widget.voucher.isUsable
          ? _buildBottomActions()
          : null,
    );
  }

  Widget _buildVoucherHeader() {
    return Container(
      margin: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getHeaderColor(), _getHeaderColor().withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.sp),
        boxShadow: [
          BoxShadow(
            color: _getHeaderColor().withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Voucher Icon
                Container(
                  width: 60.sp,
                  height: 60.sp,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.sp),
                  ),
                  child: Icon(
                    _getVoucherIcon(),
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 32.sp,
                  ),
                ),

                SizedBox(width: 16.sp),

                // Voucher Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.voucher.title, style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        widget.voucher.clubName, style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                _buildStatusBadge(),
              ],
            ),

            SizedBox(height: 16.sp),

            // Discount Amount
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.sp),
              ),
              child: Text(
                _getDiscountText(),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),

            SizedBox(height: 16.sp),

            // Description
            Text(
              widget.voucher.description, style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),

            // Voucher Code (if usable)
            if (widget.voucher.isUsable) ...[
              SizedBox(height: 16.sp),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.sp),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã voucher', overflow: TextOverflow.ellipsis, style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          widget.voucher.voucherCode, style: TextStyle(
                            fontSize: 18.sp,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _copyVoucherCode,
                      icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.onPrimary, size: 20.sp),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherDetails() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin chi tiết', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 12.sp),

          _buildDetailRow('Loại ưu đãi', _getVoucherTypeText()),
          _buildDetailRow('Nguồn voucher', _getSourceText()),

          if (widget.voucher.minOrderAmount != null)
            _buildDetailRow(
              'Đơn tối thiểu',
              '${widget.voucher.minOrderAmount!.toInt()}k VNĐ',
            ),

          _buildDetailRow(
            'Ngày phát hành',
            _formatDate(widget.voucher.issuedAt),
          ),
          _buildDetailRow(
            'Ngày hết hạn',
            _formatDate(widget.voucher.expiresAt),
          ),

          if (widget.voucher.usedAt != null)
            _buildDetailRow(
              'Ngày sử dụng',
              _formatDate(widget.voucher.usedAt!),
            ),

          // Expiry Warning
          if (widget.voucher.isUsable && widget.voucher.daysUntilExpiry <= 7)
            Container(
              margin: EdgeInsets.only(top: 12.sp),
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.sp),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.warning, size: 16.sp),
                  SizedBox(width: 6.sp),
                  Text(
                    'Voucher sắp hết hạn trong ${widget.voucher.daysUntilExpiry} ngày', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.sp,
            child: Text(
              label, style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value, style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsConditions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điều khoản sử dụng', overflow: TextOverflow.ellipsis, style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 12.sp),

          ..._getTermsAndConditions().map(
            (term) => Padding(
              padding: EdgeInsets.only(bottom: 6.sp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ', overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      term, style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInstructions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.success, size: 20.sp),
              SizedBox(width: 8.sp),
              Text(
                'Hướng dẫn sử dụng', overflow: TextOverflow.ellipsis, style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.sp),

          ..._getUsageInstructions().map(
            (instruction) => Padding(
              padding: EdgeInsets.only(bottom: 6.sp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getUsageInstructions().indexOf(instruction) + 1}. ',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      instruction, style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color color;

    switch (widget.voucher.status) {
      case VoucherStatus.active:
        if (widget.voucher.isExpired) {
          text = 'Hết hạn';
          color = AppColors.error;
        } else {
          text = 'Khả dụng';
          color = AppColors.success;
        }
        break;
      case VoucherStatus.used:
        text = 'Đã sử dụng';
        color = AppColors.info;
        break;
      case VoucherStatus.expired:
        text = 'Hết hạn';
        color = AppColors.textTertiary;
        break;
      case VoucherStatus.cancelled:
        text = 'Đã hủy';
        color = AppColors.error;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6.sp),
      ),
      child: Text(
        text, style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _copyVoucherCode,
              icon: Icon(Icons.copy, size: 16.sp),
              label: const Text('Sao chép mã'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.sp),
              ),
            ),
          ),

          SizedBox(width: 12.sp),

          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _navigateToClub,
              icon: Icon(Icons.store, size: 16.sp),
              label: const Text('Đến CLB sử dụng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getHeaderColor(),
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: 12.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getHeaderColor() {
    switch (widget.voucher.status) {
      case VoucherStatus.active:
        return widget.voucher.isExpired ? AppColors.textTertiary : AppColors.primary;
      case VoucherStatus.used:
        return AppColors.info;
      case VoucherStatus.expired:
        return AppColors.textTertiary;
      case VoucherStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getVoucherIcon() {
    switch (widget.voucher.type) {
      case VoucherType.percentageDiscount:
        return Icons.percent;
      case VoucherType.fixedDiscount:
        return Icons.attach_money;
      case VoucherType.freeService:
        return Icons.free_breakfast;
      case VoucherType.bonusTime:
        return Icons.access_time;
      case VoucherType.freeDrink:
        return Icons.local_drink;
    }
  }

  String _getDiscountText() {
    if (widget.voucher.discountPercentage != null) {
      return 'GIẢM ${widget.voucher.discountPercentage!.toInt()}%';
    } else if (widget.voucher.discountAmount != null) {
      return 'GIẢM ${widget.voucher.discountAmount!.toInt()}K';
    } else {
      return 'MIỄN PHÍ';
    }
  }

  String _getVoucherTypeText() {
    switch (widget.voucher.type) {
      case VoucherType.percentageDiscount:
        return 'Giảm giá theo %';
      case VoucherType.fixedDiscount:
        return 'Giảm giá cố định';
      case VoucherType.freeService:
        return 'Dịch vụ miễn phí';
      case VoucherType.bonusTime:
        return 'Tặng thời gian chơi';
      case VoucherType.freeDrink:
        return 'Đồ uống miễn phí';
    }
  }

  String _getSourceText() {
    switch (widget.voucher.source) {
      case VoucherSource.achievement:
        return 'Thành tựu';
      case VoucherSource.event:
        return 'Sự kiện';
      case VoucherSource.referral:
        return 'Giới thiệu bạn bè';
      case VoucherSource.birthday:
        return 'Sinh nhật';
      case VoucherSource.loyalty:
        return 'Thành viên thân thiết';
      case VoucherSource.manual:
        return 'Tặng thủ công';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<String> _getTermsAndConditions() {
    return [
      'Voucher chỉ áp dụng tại câu lạc bộ ${widget.voucher.clubName}',
      'Không áp dụng cùng với các chương trình khuyến mãi khác',
      'Voucher không thể quy đổi thành tiền mặt',
      if (widget.voucher.minOrderAmount != null)
        'Áp dụng cho hóa đơn từ ${widget.voucher.minOrderAmount!.toInt()}k VNĐ trở lên',
      'Voucher chỉ sử dụng được một lần duy nhất',
      'Voucher sẽ hết hạn vào ngày ${_formatDate(widget.voucher.expiresAt)}',
    ];
  }

  List<String> _getUsageInstructions() {
    return [
      'Đến câu lạc bộ ${widget.voucher.clubName}',
      'Xuất trình mã voucher ${widget.voucher.voucherCode} cho nhân viên',
      'Nhân viên sẽ xác nhận và áp dụng ưu đãi cho bạn',
      'Thanh toán phần còn lại (nếu có) và tận hưởng dịch vụ',
    ];
  }

  void _copyVoucherCode() {
    Clipboard.setData(ClipboardData(text: widget.voucher.voucherCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã voucher: ${widget.voucher.voucherCode}'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToClub() {
    // TODO: Navigate to club detail or map
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang dẫn đến ${widget.voucher.clubName}...'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
