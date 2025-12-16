import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/presentation/leaderboard_screen/leaderboard_screen.dart';
import 'package:sizer/sizer.dart';

void main() {
  group('LeaderboardScreen Share Feature Tests', () {
    Widget createTestWidget() {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: const LeaderboardScreen(),
          );
        },
      );
    }

    testWidgets('Share button is visible in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find share button
      final shareButton = find.byIcon(Icons.share);
      expect(shareButton, findsOneWidget);

      // Verify button is in app bar
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
    });

    testWidgets('Share button has correct tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share);
      
      // Long press to show tooltip
      await tester.longPress(shareButton);
      await tester.pumpAndSettle();

      // Verify tooltip text
      expect(find.text('Chia sẻ bảng xếp hạng'), findsOneWidget);
    });

    testWidgets('Share button responds to tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Wait for initial loading to complete
      await tester.pump(const Duration(seconds: 2));

      final shareButton = find.byIcon(Icons.share);
      
      // Tap share button
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // Should not crash or show error
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('LeaderboardScreen loads without errors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify screen loads
      expect(find.byType(LeaderboardScreen), findsOneWidget);
      
      // Verify basic UI elements exist
      expect(find.text('Bảng xếp hạng'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}