import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class ClubRegistrationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ClubRegistrationDialog({
    super.key,
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context,
      {required VoidCallback onConfirm}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ClubRegistrationDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.verified_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            'Xác thực quyền sở hữu',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headingSmall,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chỉ chủ sở hữu hoặc quản lý câu lạc bộ mới có thể đăng ký',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Để đảm bảo tính xác thực, bạn cần cung cấp:',
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: 12),
            _buildVerificationRequirement(
              '📋',
              'Giấy phép kinh doanh',
              'Giấy phép kinh doanh có tên bạn hoặc câu lạc bộ',
            ),
            _buildVerificationRequirement(
              '🏢',
              'Địa chỉ cụ thể',
              'Địa chỉ thực tế của câu lạc bộ (có thể xác minh)',
            ),
            _buildVerificationRequirement(
              '📞',
              'Số điện thoại liên hệ',
              'SĐT chính thức của câu lạc bộ để xác minh',
            ),
            _buildVerificationRequirement(
              '🆔',
              'CCCD/CMND',
              'Chứng minh nhân dân của người đại diện',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Quy trình xác thực:',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildProcessStep('1', 'Gửi thông tin và tài liệu'),
                  _buildProcessStep('2', 'Admin sẽ xác minh trong 1-2 ngày'),
                  _buildProcessStep('3', 'Thông báo kết quả qua email/SMS'),
                  _buildProcessStep('4', 'Kích hoạt câu lạc bộ nếu hợp lệ'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Lợi ích sau khi xác thực:',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem('⭐', 'Huy hiệu "Đã xác thực" tin cậy'),
                  _buildBenefitItem('🔍', 'Ưu tiên hiển thị trong tìm kiếm'),
                  _buildBenefitItem('🛠️', 'Công cụ quản lý chuyên nghiệp'),
                  _buildBenefitItem('💰', 'Tăng khả năng thu hút khách hàng'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        DSButton(
          text: 'Hủy',
          onPressed: () => Navigator.of(context).pop(),
          variant: DSButtonVariant.ghost,
        ),
        DSButton(
          text: 'Tôi hiểu và đồng ý',
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          variant: DSButtonVariant.primary,
        ),
      ],
    );
  }

  Widget _buildVerificationRequirement(
    String icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gray200),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
