import '../constants/app_constants.dart';
import 'date_utils.dart';

/// Centralized form validators. Each returns `null` when valid, or an error
/// message suitable for [TextFormField.validator].
abstract final class Validators {
  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _phone = RegExp(r'^\+?[0-9]{7,15}$');
  static final RegExp _adminId = RegExp(r'^[A-Z]{3}-\d{3,6}(-[A-Z]{2,5})?$');

  /// Student / lecturer matricule: ICTU + 4-digit year + 4 digits.
  static final RegExp _matricule = RegExp(r'^ICTU(19|20)\d{6}$');

  /// Any ID accepted at sign-in (new and older formats).
  static final RegExp _loginId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-_/]{2,29}$');

  /// One name: letters (any alphabet), optionally joined by `-` or `'`.
  static final RegExp _nameWord = RegExp(
    r"^\p{L}+(?:['’\-]\p{L}+)*$",
    unicode: true,
  );
  static final RegExp _courseCode = RegExp(r'^[A-Z]{2,5}-?\d{3,4}[A-Z]?$');
  static final RegExp _time24h = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _special = RegExp(r'[^A-Za-z0-9\s]');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  /// At least two names (first and last), each of 2+ letters. Only letters,
  /// hyphens and apostrophes are allowed.
  static String? fullName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Full name is required';
    final words = v.split(RegExp(r'\s+'));
    if (words.length < 2) return 'Enter at least two names (first and last)';
    for (final w in words) {
      if (!_nameWord.hasMatch(w)) {
        return 'Names may only contain letters, hyphens and apostrophes';
      }
      if (w.replaceAll(RegExp(r"['’\-]"), '').length < 2) {
        return 'Each name must have at least 2 letters';
      }
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Email that must belong to one of the institution's [domains]
  /// (defaults to [AppConstants.institutionEmailDomains]).
  static String? institutionalEmail(
    String? value, [
    List<String> domains = AppConstants.institutionEmailDomains,
  ]) {
    final base = email(value);
    if (base != null) return base;
    final host = value!.trim().toLowerCase().split('@').last;
    final allowed = domains.map((d) => d.toLowerCase().replaceFirst('@', ''));
    if (allowed.contains(host)) return null;
    return 'Use your institutional email '
        '(${allowed.map((d) => 'name@$d').join(' or ')})';
  }

  /// Sign-in identifier: an email or a matricule / staff / admin ID. Only the
  /// shape is checked: accounts created before the ICTU matricule format
  /// (e.g. `UNI12345`, `LEC0000`) must still be able to sign in.
  static String? identifier(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email or matricule is required';
    if (v.contains('@')) return email(v);
    if (!_loginId.hasMatch(v)) {
      return 'Enter your email or your matricule '
          '(e.g. ${AppConstants.matriculeExample})';
    }
    return null;
  }

  /// Password typed to sign in (or as the current password): only required,
  /// so accounts created under older, shorter rules can still sign in.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  /// Password used when creating credentials: at least
  /// [AppConstants.minPasswordLength] characters with an uppercase letter, a
  /// lowercase letter, a digit and a special character.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    final missing = [
      if (v.length < AppConstants.minPasswordLength)
        '${AppConstants.minPasswordLength}+ characters',
      if (!_upper.hasMatch(v)) 'an uppercase letter',
      if (!_lower.hasMatch(v)) 'a lowercase letter',
      if (!_digit.hasMatch(v)) 'a number',
      if (!_special.hasMatch(v)) 'a special character',
    ];
    if (missing.isEmpty) return null;
    return 'Password needs ${missing.join(', ')}';
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

  /// Student matricule: ICTU + 4-digit year + 4 digits (e.g. ICTU20233736).
  static String? studentId(String? value) =>
      _matriculeOf(value, field: 'Student matricule');

  /// Lecturer staff ID: same format as student matricules.
  static String? staffId(String? value) =>
      _matriculeOf(value, field: 'Staff ID');

  static String? _matriculeOf(String? value, {required String field}) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return '$field is required';
    if (!_matricule.hasMatch(v)) {
      return '$field must look like ${AppConstants.matriculeExample} '
          '(ICTU + year + 4 digits)';
    }
    return null;
  }

  static String? adminId(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Administrator ID is required';
    if (!_adminId.hasMatch(v)) return 'Enter a valid administrator ID';
    return null;
  }

  static String? courseCode(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Course code is required';
    if (!_courseCode.hasMatch(v)) return 'Use a course code such as ABC-101';
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
  /// All of them are required for a new password ([newPassword]).
  static PasswordStrength passwordStrength(String password) {
    return PasswordStrength(
      hasMinLength: password.length >= AppConstants.minPasswordLength,
      hasUppercase: _upper.hasMatch(password),
      hasLowercase: _lower.hasMatch(password),
      hasDigit: _digit.hasMatch(password),
      hasSpecial: _special.hasMatch(password),
    );
  }
}

class PasswordStrength {
  const PasswordStrength({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecial,
  });

  static const int total = 5;

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecial;

  int get score => [
    hasMinLength,
    hasUppercase,
    hasLowercase,
    hasDigit,
    hasSpecial,
  ].where((r) => r).length;

  /// Whether every required rule is met.
  bool get isValid => score == total;

  String get label => switch (score) {
    0 || 1 || 2 => 'Weak',
    3 || 4 => 'Fair',
    _ => 'Strong',
  };
}
