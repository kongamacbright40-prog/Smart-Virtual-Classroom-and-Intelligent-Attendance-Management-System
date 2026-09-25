import '../constants/app_constants.dart';
import 'date_utils.dart';

/// Centralized form validators. Each returns `null` when valid, or an error
/// message suitable for [TextFormField.validator].
abstract final class Validators {
  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _phone = RegExp(r'^\+?[0-9]{7,15}$');
  static final RegExp _studentId = RegExp(r'^[A-Z]{2,4}-?\d{4}-?\d{3,6}$');
  static final RegExp _staffId = RegExp(r'^[A-Z]{2,4}-?\d{4}-?\d{3,6}$');
  static final RegExp _adminId = RegExp(r'^[A-Z]{3}-\d{3,6}(-[A-Z]{2,5})?$');
  static final RegExp _courseCode = RegExp(r'^[A-Z]{2,5}-?\d{3,4}[A-Z]?$');
  static final RegExp _time24h = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _special = RegExp(
    r'[!@#$%^&*(),.?":{}|<>_\-+=~`\[\]\\/;]',
  );

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Email that must belong to one of the institution's [domains].
  static String? institutionalEmail(String? value, List<String> domains) {
    final base = email(value);
    if (base != null) return base;
    final v = value!.trim().toLowerCase();
    final ok = domains.any((d) => v.endsWith(d.toLowerCase()));
    return ok ? null : 'Use your institutional email (${domains.join(' or ')})';
  }

  /// Accepts either an institutional email or an institutional ID.
  static String? identifier(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Institutional ID or email is required';
    if (v.contains('@')) return email(v);
    if (v.length < 4) return 'Enter a valid institutional ID';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  /// Password used when creating credentials: length + upper + digit.
  static String? newPassword(String? value) {
    final base = password(value);
    if (base != null) return base;
    final v = value!;
    if (!_upper.hasMatch(v)) return 'Include at least one uppercase letter';
    if (!_digit.hasMatch(v)) return 'Include at least one number';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value, {bool isRequired = true}) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s()\-]'), '');
    if (v.isEmpty) return isRequired ? 'Phone number is required' : null;
    if (!_phone.hasMatch(v)) return 'Enter a valid phone number';
    return null;
  }

  static String? studentId(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Student matricule is required';
    if (!_studentId.hasMatch(v)) {
      return 'Use your matricule, e.g. ICT20251181 or MAT-2024-9148';
    }
    return null;
  }

  static String? staffId(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Staff ID is required';
    if (!_staffId.hasMatch(v)) return 'Use the format FAC-2024-8192';
    return null;
  }

  static String? adminId(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Administrator ID is required';
    if (!_adminId.hasMatch(v)) return 'Use the format ADM-9021-SYS';
    return null;
  }

  static String? courseCode(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Course code is required';
    if (!_courseCode.hasMatch(v)) return 'Use a code like CS-301 or MTH1221';
    return null;
  }

  static String? courseTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Course title is required';
    if (v.length < 3) return 'Course title is too short';
    return null;
  }

  static String? credits(String? value) {
    final v = int.tryParse(value?.trim() ?? '');
    if (v == null) return 'Enter the number of credits';
    if (v < 1 || v > 12) return 'Credits must be between 1 and 12';
    return null;
  }

  static String? positiveInt(String? value, {String field = 'Value'}) {
    final v = int.tryParse(value?.trim() ?? '');
    if (v == null || v <= 0) return '$field must be a positive number';
    return null;
  }

  static String? time24h(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Time is required';
    if (!_time24h.hasMatch(v)) return 'Use HH:MM (24-hour)';
    return null;
  }

  /// Validates a class time window. Times are minutes since midnight.
  static String? classTimeRange(int? startMinutes, int? endMinutes) {
    if (startMinutes == null) return 'Select a start time';
    if (endMinutes == null) return 'Select an end time';
    if (endMinutes <= startMinutes) return 'End time must be after start time';
    if (endMinutes - startMinutes < 15) {
      return 'A class must be at least 15 minutes long';
    }
    return null;
  }

  static String? classDate(DateTime? date, {DateTime? now}) {
    if (date == null) return 'Select a date';
    final today = AppDateUtils.dateOnly(now ?? DateTime.now());
    if (AppDateUtils.dateOnly(date).isBefore(today)) {
      return 'Date cannot be in the past';
    }
    return null;
  }

  static String? questionText(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Question text is required';
    if (v.length < 5) return 'Question is too short';
    if (v.length > 300) return 'Question must be under 300 characters';
    return null;
  }

  /// Validates the options of a multiple-choice question.
  static String? questionOptions(List<String> options, int? correctIndex) {
    final filled = options.where((o) => o.trim().isNotEmpty).toList();
    if (filled.length < AppConstants.minQuestionOptions) {
      return 'Provide at least ${AppConstants.minQuestionOptions} answer options';
    }
    if (filled.length != options.length) {
      return 'Answer options cannot be empty';
    }
    final unique = filled.map((o) => o.trim().toLowerCase()).toSet();
    if (unique.length != filled.length) return 'Answer options must be unique';
    if (correctIndex == null ||
        correctIndex < 0 ||
        correctIndex >= options.length) {
      return 'Select the correct answer';
    }
    return null;
  }

  static String? recoveryCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.length != AppConstants.recoveryCodeLength ||
        int.tryParse(v) == null) {
      return 'Enter the ${AppConstants.recoveryCodeLength}-digit code';
    }
    return null;
  }

  /// Returns the rules satisfied by [password], used by strength meters.
  static PasswordStrength passwordStrength(String password) {
    return PasswordStrength(
      hasMinLength: password.length >= AppConstants.minPasswordLength,
      hasUppercase: _upper.hasMatch(password),
      hasDigit: _digit.hasMatch(password),
      hasSpecial: _special.hasMatch(password),
    );
  }
}

class PasswordStrength {
  const PasswordStrength({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasDigit,
    required this.hasSpecial,
  });

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasDigit;
  final bool hasSpecial;

  int get score =>
      [hasMinLength, hasUppercase, hasDigit, hasSpecial].where((r) => r).length;

  String get label => switch (score) {
    0 || 1 => 'Weak',
    2 => 'Fair',
    3 => 'Strong',
    _ => 'Very Strong',
  };
}
