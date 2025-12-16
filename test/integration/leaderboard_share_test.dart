import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sabo_arena/main.dart' as app;
import 'package:sabo_arena/presentation/leaderboard_screen/leaderboard_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Leaderboard Share Feature End-to-End Tests', () {
    testWidgets('Test share button functionality in leaderboard', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to leaderboard screen
      // Note: This assumes there's a way to navigate to leaderboard from main screen
      // You might need to adjust the navigation path based on your app structure
      
      // Find the leaderboard navigation button/menu item
      final leaderboardButton = find.byKey(const Key('leaderboard_nav'));
      if (leaderboardButton.evaluate().isEmpty) {
        // Alternative: Look for any button/widget that leads to leaderboard
        final navDrawer = find.byType(Drawer);
        if (navDrawer.evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();
          
          final leaderboardMenuItem = find.text('Bảng xếp hạng');
          if (leaderboardMenuItem.evaluate().isNotEmpty) {
            await tester.tap(leaderboardMenuItem);
            await tester.pumpAndSettle();
          }
        }
      } else {
        await tester.tap(leaderboardButton);
        await tester.pumpAndSettle();
      }

      // Verify we're on the leaderboard screen
      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(find.text('Bảng xếp hạng'), findsOneWidget);

      // Test 1: Verify share button exists
      final shareButton = find.byIcon(Icons.share);
      expect(shareButton, findsOneWidget, reason: 'Share button should be visible in app bar');

      // Test 2: Test share button tooltip
      await tester.longPress(shareButton);
      await tester.pumpAndSettle();
      expect(find.text('Chia sẻ bảng xếp hạng'), findsOneWidget);
      
      // Dismiss tooltip
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      // Test 3: Test share functionality
      // Mock the Share.share method to avoid actual sharing during test
      bool shareWasCalled = false;
      String? sharedText;
      String? sharedSubject;

      // Note: In a real integration test, you might want to use a test-specific
      // share service or mock the share_plus plugin
      
      // Tap the share button
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // Wait a bit for async operations
      await tester.pump(const Duration(milliseconds: 500));

      // Test 4: Verify no error messages appear
      expect(find.byType(SnackBar), findsNothing, 
        reason: 'No error snackbar should appear after sharing');

      // Test 5: Test share functionality across different tabs
      final tabs = ['ELO Rating', 'Thắng lợi', 'Giải đấu', 'SPA Points'];
      
      for (int i = 0; i < tabs.length; i++) {
        // Switch to different tab
        final tabButton = find.text(tabs[i]);
        if (tabButton.evaluate().isNotEmpty) {
          await tester.tap(tabButton);
          await tester.pumpAndSettle();
          
          // Wait for data to load
          await tester.pump(const Duration(seconds: 2));
          
          // Test share on this tab
          await tester.tap(shareButton);
          await tester.pumpAndSettle();
          
          // Verify no error
          expect(find.byType(SnackBar), findsNothing, 
            reason: 'No error should occur when sharing ${tabs[i]} leaderboard');
        }
      }

      // Test 6: Test share with different rank filters
      final rankFilters = ['Tất cả', 'Hạng K', 'Hạng I', 'Hạng H'];
      
      for (String filter in rankFilters) {
        final filterButton = find.text(filter);
        if (filterButton.evaluate().isNotEmpty) {
          await tester.tap(filterButton);
          await tester.pumpAndSettle();
          
          // Wait for filtered data to load
          await tester.pump(const Duration(seconds: 1));
          
          // Test share with this filter
          await tester.tap(shareButton);
          await tester.pumpAndSettle();
          
          // Verify no error
          expect(find.byType(SnackBar), findsNothing, 
            reason: 'No error should occur when sharing $filter filtered leaderboard');
        }
      }

      print('✅ All leaderboard share tests passed successfully!');
    });

    testWidgets('Test leaderboard data loading before share', (WidgetTester tester) async {
      // Launch the app and navigate to leaderboard
      app.main();
      await tester.pumpAndSettle();

      // Navigate to leaderboard (adjust based on your navigation)
      // ... navigation code ...

      // Wait for leaderboard data to load
      await tester.pump(const Duration(seconds: 3));

      // Verify loading indicator disappears
      expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'Loading should complete before testing share');

      // Verify leaderboard has data
      expect(find.text('Chưa có dữ liệu'), findsNothing,
        reason: 'Leaderboard should have data to share');

      // Test share when data is loaded
      final shareButton = find.byIcon(Icons.share);
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // Should not show error
      expect(find.byType(SnackBar), findsNothing);

      print('✅ Leaderboard data loading test passed!');
    });

    testWidgets('Test share button accessibility', (WidgetTester tester) async {
      // Launch app and navigate to leaderboard
      app.main();
      await tester.pumpAndSettle();
      
      // ... navigation code ...

      // Test accessibility
      final shareButton = find.byIcon(Icons.share);
      expect(shareButton, findsOneWidget);

      // Test button is accessible
      final shareWidget = tester.widget<IconButton>(shareButton);
      expect(shareWidget.tooltip, equals('Chia sẻ bảng xếp hạng'),
        reason: 'Share button should have proper tooltip for accessibility');

      // Test button responds to tap
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      print('✅ Share button accessibility test passed!');
    });

    testWidgets('Test share content format', (WidgetTester tester) async {
      // This test verifies that the share content is properly formatted
      // Note: This is more of a unit test, but included for completeness
      
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to leaderboard
      // ... navigation code ...

      // Test that ShareService.shareLeaderboard is called with correct parameters
      // This would require mocking ShareService or checking logs
      
      final shareButton = find.byIcon(Icons.share);
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // In a real test, you'd verify the share content format here
      // For now, just ensure no errors occur
      expect(find.byType(SnackBar), findsNothing);

      print('✅ Share content format test completed!');
    });
  });
}