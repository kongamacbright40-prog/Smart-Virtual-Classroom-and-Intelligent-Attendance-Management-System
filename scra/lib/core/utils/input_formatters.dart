import 'package:flutter/services.dart';

/// Keystroke filters for credential fields, used together with [Validators].
abstract final class AppInputFormatters {
  /// Names: letters (any alphabet), spaces, hyphens and apostrophes only.
  static final List<TextInputFormatter> fullName = [
    FilteringTextInputFormatter.allow(RegExp(r"[\p{L} '’\-]", unicode: true)),
    LengthLimitingTextInputFormatter(80),
  ];

  /// Matricules (ICTU20233736): letters and digits, upper-cased.
  static final List<TextInputFormatter> matricule = [
    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
    const UpperCaseTextFormatter(),
    LengthLimitingTextInputFormatter(12),
  ];

  /// Administrator IDs (ADM-001): letters, digits and hyphens, upper-cased.
  static final List<TextInputFormatter> adminId = [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
    const UpperCaseTextFormatter(),
    LengthLimitingTextInputFormatter(15),
  ];

  /// Emails never contain spaces.
  static final List<TextInputFormatter> email = [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    LengthLimitingTextInputFormatter(120),
  ];
}

class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
