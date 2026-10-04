/// Utility class for validating and formatting South African mobile numbers.
class PhoneValidator {
  /// Regular expression to match South African mobile numbers:
  /// - Supports +27, 0027, 27 (with optional leading 0, e.g. +270821234567 or +27821234567)
  /// - Supports standard national format starting with 0 (e.g. 0821234567)
  /// - Supports 9-digit format starting directly with mobile prefix [6-8]
  /// - Matches 9 digits after country/trunk prefix (valid mobile network prefixes in SA are 6x, 7x, 8x).
  static final RegExp _saMobileRegex =
      RegExp(r'^(?:(?:\+27|0027|27)\s*0?|0)?[6-8]\d{8}$');

  /// Strips formatting characters (spaces, dashes, parentheses, dots).
  static String clean(String? phone) {
    if (phone == null) return '';
    return phone.trim().replaceAll(RegExp(r'[\s\-().]'), '');
  }

  /// Validates a South African mobile number.
  ///
  /// If [isRequired] is `false`, empty or null strings are considered valid (returns `null`).
  /// Otherwise, returns an error message if empty or if the format is invalid.
  static String? validateSouthAfricanMobile(
    String? phone, {
    bool isRequired = true,
    String? requiredMessage,
    String? invalidMessage,
  }) {
    final trimmed = phone?.trim() ?? '';
    if (trimmed.isEmpty) {
      if (!isRequired) return null;
      return requiredMessage ?? 'Please enter phone number';
    }

    final cleaned = clean(trimmed);
    if (!_saMobileRegex.hasMatch(cleaned)) {
      return invalidMessage ??
          'Please enter a valid South African mobile number (e.g. 082 123 4567 or +27 82 123 4567)';
    }
    return null;
  }

  /// Checks if a phone number is a valid South African mobile number.
  static bool isValidSouthAfricanMobile(
    String? phone, {
    bool isRequired = true,
  }) {
    return validateSouthAfricanMobile(phone, isRequired: isRequired) == null;
  }

  /// Normalizes a valid South African mobile number.
  ///
  /// When [international] is `true`, returns format `+27821234567`.
  /// When [international] is `false`, returns format `0821234567`.
  static String normalize(String? phone, {bool international = false}) {
    final cleaned = clean(phone);
    if (!_saMobileRegex.hasMatch(cleaned)) return phone?.trim() ?? '';

    final match = RegExp(r'[6-8]\d{8}$').firstMatch(cleaned);
    if (match == null) return cleaned;
    final coreDigits = match.group(0)!;

    return international ? '+27$coreDigits' : '0$coreDigits';
  }

  /// Extracts the country code (defaults to '+27' for South Africa).
  static String getCountryCode(String? phone) {
    final cleaned = clean(phone);
    if (cleaned.isEmpty) return '+27';

    if (cleaned.startsWith('+27') ||
        cleaned.startsWith('0027') ||
        cleaned.startsWith('27') ||
        _saMobileRegex.hasMatch(cleaned)) {
      return '+27';
    }

    if (cleaned.startsWith('+')) {
      // Match 1 to 3 digits for standard international dial codes (e.g. +1, +44, +91)
      if (cleaned.startsWith('+1')) return '+1';
      if (cleaned.startsWith('+44')) return '+44';
      if (cleaned.startsWith('+91')) return '+91';
      final match = RegExp(r'^\+\d{1,3}').firstMatch(cleaned);
      if (match != null) return match.group(0)!;
    }
    return '+27';
  }
}
