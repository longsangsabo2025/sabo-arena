import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/user_achievement.dart';

class VoucherCardWidget extends StatelessWidget {
  final UserVoucher voucher;
  final VoidCallback? onTap;

  const VoucherCardWidget({super.key, required this.voucher, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.sp),
        boxShadow: [
          BoxShadow(
            color: _getColorByStatus().withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.sp),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: _getGradientByStatus(),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -20.sp,
                    top: -20.sp,
                    child: Container(
                      width: 100.sp,
                      height: 100.sp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30.sp,
                    bottom: -30.sp,
                    child: Container(
                      width: 120.sp,
                      height: 120.sp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Voucher Icon with glow effect
                            Container(
                              width: 48.sp,
                              height: 48.sp,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12.sp),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getIconByType(),
                                color: Colors.white,
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
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.sp),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.store_rounded,
                                        size: 12.sp,
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                      ),
                                      SizedBox(width: 4.sp),
                                      Expanded(
                                        child: Text(
                                          voucher.clubName,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8.sp),

                            // Status Badge
                            _buildStatusBadge(context),
                          ],
                        ),

                        SizedBox(height: 12.sp),

                        // Description with better styling
                        Container(
                          padding: EdgeInsets.all(12.sp),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                          child: Text(
                            voucher.description,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        SizedBox(height: 16.sp),

                        // Discount Info & Expiry
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Discount Amount with prominent styling
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.sp,
                                vertical: 10.sp,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.sp),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _getDiscountText(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _getColorByStatus(),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),

                            // Expiry Info with icon
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.sp,
                                vertical: 8.sp,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.sp),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14.sp,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  SizedBox(width: 4.sp),
                                  Text(
                                    _getExpiryText(),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Voucher Code with copy functionality
                        if (voucher.isUsable) ...[
                          SizedBox(height: 12.sp),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.sp,
                              vertical: 12.sp,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.sp),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MÃ VOUCHER',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: _getColorByStatus()
                                            .withValues(alpha: 0.7),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2.sp),
                                    Text(
                                      voucher.voucherCode,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontFamily: 'monospace',
                                        color: _getColorByStatus(),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.all(8.sp),
                                  decoration: BoxDecoration(
                                    color: _getColorByStatus()
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.sp),
                                  ),
                                  child: Icon(
                                    Icons.content_copy_rounded,
                                    size: 20.sp,
                                    color: _getColorByStatus(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            colors: [Colors.grey[700]!, Colors.grey[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        }
        return LinearGradient(
          colors: [
            const Color(0xFF00B4DB),
            const Color(0xFF0083B0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case VoucherStatus.used:
        return LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case VoucherStatus.expired:
        return LinearGradient(
          colors: [Colors.grey[700]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case VoucherStatus.cancelled:
        return LinearGradient(
          colors: [Colors.red[700]!, Colors.red[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getColorByStatus() {
    switch (voucher.status) {
      case VoucherStatus.active:
        if (voucher.isExpired) {
          return Colors.grey[700]!;
        }
        return const Color(0xFF00B4DB);
      case VoucherStatus.used:
        return Colors.blue[700]!;
      case VoucherStatus.expired:
        return Colors.grey[700]!;
      case VoucherStatus.cancelled:
        return Colors.red[700]!;
    }
  }

  IconData _getIconByType() {
    switch (voucher.type) {
      case VoucherType.percentageDiscount:
        return Icons.percent_rounded;
      case VoucherType.fixedDiscount:
        return Icons.payments_rounded;
      case VoucherType.freeService:
        return Icons.card_giftcard_rounded;
      case VoucherType.bonusTime:
        return Icons.access_time_rounded;
      case VoucherType.freeDrink:
        return Icons.local_cafe_rounded;
    }
  }

  Widget _buildStatusBadge(BuildContext context) {
    String text;
    Color backgroundColor;
    Color textColor;

    switch (voucher.status) {
      case VoucherStatus.active:
        if (voucher.isExpired) {
          text = 'Hết hạn';
          backgroundColor = Colors.red[100]!;
          textColor = Colors.red[900]!;
        } else {
          text = 'Khả dụng';
          backgroundColor = Colors.green[100]!;
          textColor = Colors.green[900]!;
        }
        break;
      case VoucherStatus.used:
        text = 'Đã dùng';
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case VoucherStatus.expired:
        text = 'Hết hạn';
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[900]!;
        break;
      case VoucherStatus.cancelled:
        text = 'Đã hủy';
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.sp),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.3,
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
