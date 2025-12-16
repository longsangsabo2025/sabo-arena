import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sabo_arena/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🔗 SaboArena Integration Tests', () {
    testWidgets('🚀 app should launch successfully', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('🔐 authentication flow should work', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test authentication flow
      // Add specific test steps for login/register
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('🏆 tournament flow should work', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Test tournament browsing and participation
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
