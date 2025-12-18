import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class ClubFilterDialog extends StatelessWidget {
  const ClubFilterDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ClubFilterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Lọc câu lạc bộ',
        overflow: TextOverflow.ellipsis,
        style: AppTypography.headingSmall,
      ),
      content: const Text('Tính năng lọc nâng cao đang được phát triển.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
