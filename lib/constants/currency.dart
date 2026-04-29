import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// App display currency: Iraqi Dinar (د.ع / IQD)
class AppCurrency {
  static const String symbol = 'د.ع';
  static const String code = 'IQD';
  static const String name = 'dinar';

  /// English uses `IQD`; Arabic/Kurdish use `د.ع`. Pass [context] from UI.
  static String _suffix(BuildContext? context) {
    if (context == null) return symbol;
    try {
      return Localizations.localeOf(context).languageCode == 'en'
          ? code
          : symbol;
    } catch (_) {
      return symbol;
    }
  }

  /// Format amount in dinar (no decimals for whole numbers, or 0 decimals)
  static String format(num amount, [BuildContext? context]) {
    final n = amount is int ? amount.toDouble() : amount;
    return '${NumberFormat('#,##0').format(n)} ${_suffix(context)}';
  }

  /// Format with decimals if needed
  static String formatWithDecimals(num amount, [BuildContext? context]) {
    final n = amount is int ? amount.toDouble() : amount;
    return '${NumberFormat('#,##0.00').format(n)} ${_suffix(context)}';
  }
}
