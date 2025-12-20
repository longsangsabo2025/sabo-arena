import 'package:intl/intl.dart';

/// Utility class for formatting numbers with Vietnamese locale
class NumberFormatter {
  /// Format number with thousand separator (dot)
  /// Example: 500000 -> 500.000
  static String formatCurrency(dynamic value) {
    if (value == null) return '0';

    // Convert to int or double
    num amount;
    if (value is String) {
      amount = num.tryParse(value) ?? 0;
    } else if (value is num) {
      amount = value;
    } else {
      return '0';
    }

    // Format with dot as thousand separator (Vietnamese style)
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount).replaceAll(',', '.');
  }

  /// Format number with suffix (K, M, B)
  /// Example: 1000000 -> 1M or 1.000.000 based on preference
  static String formatCompact(dynamic value,
      {bool useThousandSeparator = false}) {
    if (value == null) return '0';

    num amount;
    if (value is String) {
      amount = num.tryParse(value) ?? 0;
    } else if (value is num) {
      amount = value;
    } else {
      return '0';
    }

    if (useThousandSeparator) {
      return formatCurrency(amount);
    }

    // Use compact notation
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toString();
    }
  }

  /// Format with currency unit (SPA, VND, etc.)
  /// Example: 500000 SPA -> 500.000 SPA
  static String formatWithUnit(dynamic value, String unit) {
    return '${formatCurrency(value)} $unit';
  }
}
