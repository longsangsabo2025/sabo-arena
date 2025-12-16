import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/user_achievement.dart';
import '../../../theme/app_theme.dart';

class VoucherCardWidget extends StatelessWidget {
  final UserVoucher voucher;
  final VoidCallback? onTap;

  const VoucherCardWidget({super.key, required this.voucher, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sp)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.sp),
        child: Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.sp),
            gradient: _getGradientByStatus(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Voucher Icon
                  Container(
                    width: 48.sp,
                    height: 48.sp,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Icon(
                      _getIconByType(),
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24.sp,
                    ),
                  ),

                  SizedBox(width: 12.sp),

                  // Voucher Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          voucher.clubName,
                          style: TextStyle(
                            fontSize: 12.sp,
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

              SizedBox(height: 12.sp),

              // Description
              Text(
                voucher.description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12.sp),

              // Discount Info & Expiry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Discount Amount
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.sp,
                      vertical: 4.sp,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    child: Text(
                      _getDiscountText(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),

                  // Expiry Info
                  Text(
                    _getExpiryText(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),

              // Voucher Code
              if (voucher.isUsable) ...[
                SizedBox(height: 8.sp),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.sp,
                    vertical: 6.sp,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.sp),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mã: ${voucher.voucherCode}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.copy,
                        size: 16.sp,
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradientByStatus() {
    switch (voucher.status) {
      case VoucherStatus.active:
        if (voucher.isExpired) {
          return LinearGradient(
            colors: [Colors.grey[600]!, Colors.grey[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        }
        return LinearGradient(
          colors: [AppTheme.primaryLight, Colors.green[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case VoucherStatus.used:
        return LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case VoucherStatus.expired:
        return LinearGradient(
          colors: [Colors.grey[600]!, Colors.grey[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case VoucherStatus.cancelled:
        return LinearGradient(
          colors: [Colors.red[600]!, Colors.red[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getIconByType() {
    switch (voucher.type) {
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

  Widget _buildStatusBadge() {
    String text;
    Color color;

    switch (voucher.status) {
      case VoucherStatus.active:
        if (voucher.isExpired) {
          text = 'Hết hạn';
          color = Colors.red;
        } else {
          text = 'Khả dụng';
          color = Colors.green;
        }
        break;
      case VoucherStatus.used:
        text = 'Đã dùng';
        color = Colors.blue;
        break;
      case VoucherStatus.expired:
        text = 'Hết hạn';
        color = Colors.grey;
        break;
      case VoucherStatus.cancelled:
        text = 'Đã hủy';
        color = Colors.red;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _getDiscountText() {
    if (voucher.discountPercentage != null) {
      return '${voucher.discountPercentage!.toInt()}% OFF';
    } else if (voucher.discountAmount != null) {
      return '-${voucher.discountAmount!.toInt()}k';
    } else {
      return 'Miễn phí';
    }
  }

  String _getExpiryText() {
    if (voucher.status == VoucherStatus.used) {
      return 'Đã sử dụng';
    } else if (voucher.isExpired) {
      return 'Đã hết hạn';
    } else {
      final days = voucher.daysUntilExpiry;
      if (days <= 0) {
        return 'Hết hạn hôm nay';
      } else if (days == 1) {
        return 'Hết hạn ngày mai';
      } else if (days <= 7) {
        return 'Còn $days ngày';
      } else {
        return 'HSD: ${voucher.expiresAt.day}/${voucher.expiresAt.month}';
      }
    }
  }
}
