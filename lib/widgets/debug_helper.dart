// =============================================
// 🛠 DEBUG HELPER WIDGET
// =============================================
// Debug floating action button for development testing
// Only shows in debug mode
// Created: 2025-01-16

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class DebugHelper extends StatelessWidget {
  const DebugHelper({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
      right: 20,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.orange,
        onPressed: () => _showDebugMenu(context),
        child: const Icon(
          Icons.bug_report,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showDebugMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🛠 DEBUG MENU',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.crossPlatformAuthTest);
              },
              icon: const Icon(Icons.login),
              label: const Text('🧪 Test Cross-Platform Auth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('❌ Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}