import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class ClubVerificationAgreementDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ClubVerificationAgreementDialog({
    super.key,
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onConfirm}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ClubVerificationAgreementDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.assignment_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            'Cam kết xác thực',
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
            Text(
              'Tôi cam kết rằng:',
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: 12),
            _buildCommitmentItem(
              '✓',
              'Tôi là chủ sở hữu hoặc người được ủy quyền đại diện cho câu lạc bộ này',
            ),
            _buildCommitmentItem(
              '✓',
              'Tất cả thông tin tôi cung cấp là chính xác và có thể xác minh',
            ),
            _buildCommitmentItem(
              '✓',
              'Tôi có đủ tài liệu chứng minh quyền sở hữu/quản lý câu lạc bộ',
            ),
            _buildCommitmentItem(
              '✓',
              'Tôi đồng ý với quy trình xác minh của Sabo Arena',
            ),
            _buildCommitmentItem(
              '✓',
              'Tôi hiểu rằng thông tin sai lệch sẽ dẫn đến từ chối đăng ký',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lưu ý: Việc cung cấp thông tin sai lệch hoặc giả mạo có thể dẫn đến khóa tài khoản vĩnh viễn.',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        DSButton(
          text: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
          variant: DSButtonVariant.ghost,
        ),
        DSButton(
          text: 'Tôi cam kết và tiếp tục',
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          variant: DSButtonVariant.primary,
        ),
      ],
    );
  }

  Widget _buildCommitmentItem(String checkmark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checkmark,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
