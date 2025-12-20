import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../widgets/common/app_button.dart';

class ClubSearchDialog extends StatefulWidget {
  final String initialQuery;
  final Function(String) onSearch;

  const ClubSearchDialog({
    super.key,
    required this.initialQuery,
    required this.onSearch,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialQuery,
    required Function(String) onSearch,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ClubSearchDialog(
        initialQuery: initialQuery,
        onSearch: onSearch,
      ),
    );
  }

  @override
  State<ClubSearchDialog> createState() => _ClubSearchDialogState();
}

class _ClubSearchDialogState extends State<ClubSearchDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Tìm kiếm câu lạc bộ',
        overflow: TextOverflow.ellipsis,
        style: AppTypography.headingSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Nhập tên câu lạc bộ...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            autofocus: true,
            onSubmitted: (value) {
              widget.onSearch(value);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        AppButton(
          label: 'Tìm kiếm',
          type: AppButtonType.primary,
          size: AppButtonSize.medium,
          onPressed: () {
            widget.onSearch(_controller.text);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
