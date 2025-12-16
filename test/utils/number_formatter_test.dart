import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/utils/number_formatter.dart';

void main() {
  group('NumberFormatter Tests', () {
    test('formatCurrency should format with thousand separator (dot)', () {
      expect(NumberFormatter.formatCurrency(500000), '500.000');
      expect(NumberFormatter.formatCurrency(1000000), '1.000.000');
      expect(NumberFormatter.formatCurrency(50), '50');
      expect(NumberFormatter.formatCurrency(5000), '5.000');
      expect(NumberFormatter.formatCurrency(123456789), '123.456.789');
    });

    test('formatCurrency should handle string input', () {
      expect(NumberFormatter.formatCurrency('500000'), '500.000');
      expect(NumberFormatter.formatCurrency('1000000'), '1.000.000');
    });

    test('formatCurrency should handle null', () {
      expect(NumberFormatter.formatCurrency(null), '0');
    });

    test('formatWithUnit should format with unit', () {
      expect(NumberFormatter.formatWithUnit(500000, 'SPA'), '500.000 SPA');
      expect(NumberFormatter.formatWithUnit(1000000, 'VND'), '1.000.000 VND');
    });

    test('formatCompact should use compact notation', () {
      expect(NumberFormatter.formatCompact(1000000000), '1.0B');
      expect(NumberFormatter.formatCompact(50000000), '50.0M');
      expect(NumberFormatter.formatCompact(5000), '5.0K');
      expect(NumberFormatter.formatCompact(500), '500');
    });

    test('formatCompact with thousand separator', () {
      expect(
        NumberFormatter.formatCompact(500000, useThousandSeparator: true),
        '500.000',
      );
    });
  });
}
