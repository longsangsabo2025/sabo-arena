import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcuts manager for iPad Pro
///
/// Supports common shortcuts:
/// - Cmd+N: New item/tournament
/// - Cmd+F: Search
/// - Cmd+R: Refresh
/// - Cmd+S: Save
/// - Cmd+W: Close
/// - Cmd+T: New tab
///
/// Usage:
/// ```dart
/// KeyboardShortcutsWrapper(
///   onNewItem: () => createTournament(),
///   onSearch: () => openSearch(),
///   onRefresh: () => refreshData(),
///   child: MyScreen(),
/// )
/// ```
class KeyboardShortcutsWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onNewItem; // Cmd+N
  final VoidCallback? onSearch; // Cmd+F
  final VoidCallback? onRefresh; // Cmd+R
  final VoidCallback? onSave; // Cmd+S
  final VoidCallback? onClose; // Cmd+W
  final VoidCallback? onNewTab; // Cmd+T

  const KeyboardShortcutsWrapper({
    Key? key,
    required this.child,
    this.onNewItem,
    this.onSearch,
    this.onRefresh,
    this.onSave,
    this.onClose,
    this.onNewTab,
  }) : super(key: key);

  @override
  State<KeyboardShortcutsWrapper> createState() =>
      _KeyboardShortcutsWrapperState();
}

class _KeyboardShortcutsWrapperState extends State<KeyboardShortcutsWrapper> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Check for Cmd/Ctrl key
    final isCmdPressed = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (!isCmdPressed) {
      return KeyEventResult.ignored;
    }

    // Handle specific shortcuts
    if (event.logicalKey == LogicalKeyboardKey.keyN &&
        widget.onNewItem != null) {
      widget.onNewItem!();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyF &&
        widget.onSearch != null) {
      widget.onSearch!();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyR &&
        widget.onRefresh != null) {
      widget.onRefresh!();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyS && widget.onSave != null) {
      widget.onSave!();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyW && widget.onClose != null) {
      widget.onClose!();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyT &&
        widget.onNewTab != null) {
      widget.onNewTab!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

/// Keyboard shortcut tooltip widget
///
/// Shows keyboard shortcut hint in tooltip
///
/// Usage:
/// ```dart
/// KeyboardShortcutTooltip(
///   message: 'Create New Tournament',
///   shortcut: 'Cmd+N',
///   child: IconButton(icon: Icon(Icons.add)),
/// )
/// ```
class KeyboardShortcutTooltip extends StatelessWidget {
  final String message;
  final String shortcut;
  final Widget child;

  const KeyboardShortcutTooltip({
    Key? key,
    required this.message,
    required this.shortcut,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$message ($shortcut)',
      child: child,
    );
  }
}

/// Global keyboard shortcuts configuration
class KeyboardShortcuts {
  static const Map<String, String> shortcuts = {
    'new': 'Cmd+N',
    'search': 'Cmd+F',
    'refresh': 'Cmd+R',
    'save': 'Cmd+S',
    'close': 'Cmd+W',
    'newTab': 'Cmd+T',
  };

  static String getShortcut(String action) {
    return shortcuts[action] ?? '';
  }

  /// Check if device supports keyboard shortcuts (iPad Pro with keyboard)
  static bool isSupported() {
    // In production, you might want to check for connected keyboard
    // For now, assume all iPads support it
    return true;
  }
}

/// Action button with keyboard shortcut hint
///
/// Usage:
/// ```dart
/// ActionButtonWithShortcut(
///   label: 'New Tournament',
///   icon: Icons.add,
///   shortcut: 'Cmd+N',
///   onPressed: () => createTournament(),
/// )
/// ```
class ActionButtonWithShortcut extends StatelessWidget {
  final String label;
  final IconData icon;
  final String shortcut;
  final VoidCallback onPressed;
  final Color? color;

  const ActionButtonWithShortcut({
    Key? key,
    required this.label,
    required this.icon,
    required this.shortcut,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardShortcutTooltip(
      message: label,
      shortcut: shortcut,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            Text(
              shortcut,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
        ),
      ),
    );
  }
}
