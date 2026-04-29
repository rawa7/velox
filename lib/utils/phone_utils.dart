/// Helpers so login accepts the same Iraqi number in several shapes as stored at signup
/// (e.g. [+9647507746088], [07507746088], [7507746088]).
class PhoneUtils {
  PhoneUtils._();

  /// Returns a canonical string for the login API. For Iraq mobiles, matches signup:
  /// `+964` + national digits without a leading `0`.
  static String normalizeLoginPhone(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (s.isEmpty) return raw;

    final digitsOnly = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 10) return raw;

    // Iraq: 07xxxxxxxxx → +9647xxxxxxxxx
    if (digitsOnly.length == 11 && digitsOnly.startsWith('07')) {
      return '+964${digitsOnly.substring(1)}';
    }
    // Iraq national: 7xxxxxxxx (10 digits)
    if (digitsOnly.length == 10 && digitsOnly.startsWith('7')) {
      return '+964$digitsOnly';
    }
    // International without +: 964… (12–13 digits)
    if (digitsOnly.startsWith('964') && digitsOnly.length >= 12 && digitsOnly.length <= 13) {
      return '+$digitsOnly';
    }

    // Explicit +… (other countries or already normalized)
    if (s.startsWith('+')) {
      return s;
    }

    return raw;
  }
}
