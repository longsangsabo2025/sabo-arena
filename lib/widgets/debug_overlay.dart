// =============================================
// 🛠 DEBUG OVERLAY WRAPPER
// =============================================
// Wraps the entire app with debug tools overlay
// Only active in debug mode
// Created: 2025-01-16

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'debug_helper.dart';

class DebugOverlay extends StatelessWidget {
  final Widget child;
  
  const DebugOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          const DebugHelper(),
        ],
      ),
    );
  }
}