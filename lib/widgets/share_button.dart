import 'package:flutter/material.dart';

/// Share Button Widget
/// Used across Tournament Cards, Match Cards, Brackets, Leaderboards
class ShareButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final bool showLabel;
  final String? label;

  const ShareButton({
    super.key,
    required this.onPressed,
    this.size = 24,
    this.color,
    this.showLabel = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;

    if (showLabel) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.share, size: size, color: buttonColor),
        label: Text(
          label ?? 'Chia sẻ',
          style: TextStyle(
            color: buttonColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.share, size: size, color: buttonColor),
      tooltip: 'Chia sẻ',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: size + 8,
        minHeight: size + 8,
      ),
    );
  }
}

/// Share Button with Badge (for floating action button)
class ShareButtonFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String? label;

  const ShareButtonFAB({
    super.key,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: const Icon(Icons.share),
        label: Text(label!),
        backgroundColor: Theme.of(context).colorScheme.primary,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.share),
    );
  }
}
