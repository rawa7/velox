import 'package:intl/intl.dart';

/// App display currency: Iraqi Dinar (د.ع / IQD)
class AppCurrency {
  static const String symbol = 'د.ع';
  static const String code = 'IQD';
  static const String name = 'dinar';

  /// Format amount in dinar (no decimals for whole numbers, or 0 decimals)
  static String format(num amount) {
    final n = amount is int ? amount.toDouble() : amount;
    return '${NumberFormat('#,##0').format(n)} $symbol';
  }

  /// Format with decimals if needed
  static String formatWithDecimals(num amount) {
    final n = amount is int ? amount.toDouble() : amount;
    return '${NumberFormat('#,##0.00').format(n)} $symbol';
  }
}
