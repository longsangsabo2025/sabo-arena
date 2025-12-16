import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/unified_bracket_service.dart';
import '../helpers/test_env_helper.dart';

void main() {
  setUpAll(() async {
    await TestEnvHelper.initializeSupabase();
  });

  group('UnifiedBracketService', () {
    test('Instance should be available', () {
      final service = UnifiedBracketService.instance;
      expect(service, isNotNull);
    });

    test('supportedFormats should contain all required formats', () {
      final formats = UnifiedBracketService.supportedFormats;
      expect(formats, contains('single_elimination'));
      expect(formats, contains('double_elimination'));
      expect(formats, contains('sabo_de16'));
      expect(formats, contains('sabo_de24'));
      expect(formats, contains('sabo_de32'));
      expect(formats, contains('sabo_de64'));
      expect(formats, contains('round_robin'));
      expect(formats, contains('swiss'));
    });

    group('isValidConfiguration', () {
      test('Single Elimination validation', () {
        expect(UnifiedBracketService.isValidConfiguration('single_elimination', 2), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('single_elimination', 64), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('single_elimination', 1), isFalse);
        expect(UnifiedBracketService.isValidConfiguration('single_elimination', 65), isFalse);
      });

      test('Double Elimination validation', () {
        expect(UnifiedBracketService.isValidConfiguration('double_elimination', 4), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('double_elimination', 32), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('double_elimination', 3), isFalse);
        expect(UnifiedBracketService.isValidConfiguration('double_elimination', 33), isFalse);
      });

      test('Sabo DE16 validation', () {
        expect(UnifiedBracketService.isValidConfiguration('sabo_de16', 16), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('sabo_de16', 15), isFalse);
        expect(UnifiedBracketService.isValidConfiguration('sabo_de16', 17), isFalse);
      });

      test('Round Robin validation', () {
        expect(UnifiedBracketService.isValidConfiguration('round_robin', 2), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('round_robin', 16), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('round_robin', 17), isFalse);
      });

      test('Swiss validation', () {
        expect(UnifiedBracketService.isValidConfiguration('swiss', 4), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('swiss', 32), isTrue);
        expect(UnifiedBracketService.isValidConfiguration('swiss', 3), isFalse);
        expect(UnifiedBracketService.isValidConfiguration('swiss', 33), isFalse);
      });
    });
  });
}
