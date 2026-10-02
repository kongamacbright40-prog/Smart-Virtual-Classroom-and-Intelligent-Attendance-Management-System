import 'package:flutter/foundation.dart';

/// Application-wide configuration.
///
/// Values can be overridden at build time with `--dart-define`, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000`.
abstract final class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _wsBaseUrl = String.fromEnvironment('WS_BASE_URL');

  /// Base URL of the FastAPI backend (REST). Defaults to the development
  /// machine: `127.0.0.1` in the browser, `10.0.2.2` on the Android emulator
  /// (the host as seen from the emulator). Physical phones need the PC's LAN
  /// IP via `API_BASE_URL`. (`localhost` is avoided because Windows tries IPv6
  /// first, adding ~0.2 s to every new connection to a backend on 0.0.0.0.)
  static String get apiBaseUrl => _apiBaseUrl.isNotEmpty
      ? _apiBaseUrl
      : kIsWeb
      ? 'http://127.0.0.1:8000'
      : 'http://10.0.2.2:8000';

  /// Prefix applied to every REST endpoint. The Smart Class FastAPI backend
  /// mounts its routers at the root, so this is empty by default.
  static const String apiPrefix = String.fromEnvironment(
    'API_PREFIX',
    defaultValue: '',
  );

  /// Base URL for WebSocket connections (WebRTC signaling). Derived from
  /// [apiBaseUrl] (`http` → `ws`, `https` → `wss`) unless `WS_BASE_URL` is set.
  static String get wsBaseUrl => _wsBaseUrl.isNotEmpty
      ? _wsBaseUrl
      : apiBaseUrl.replaceFirst(RegExp('^http'), 'ws');

  static const Duration requestTimeout = Duration(seconds: 20);
}

abstract final class AppConstants {
  static const String appName = 'Smart Class';
  static const String appVersion = '1.0.0';

  /// Shortest password accepted (must match the backend's MIN_PASSWORD_LENGTH).
  static const int minPasswordLength = 4;

  /// Length the strength meter treats as "strong"; advice only, not enforced.
  static const int recommendedPasswordLength = 8;
  static const int recoveryCodeLength = 4;
  static const int minQuestionOptions = 2;
  static const int maxQuestionOptions = 6;

  /// Attendance percentage below which a student is flagged as at risk.
  static const double attendanceWarningThreshold = 75;
}

/// Keys used by [StorageService]. Kept in one place so persisted data is
/// never read with a mistyped key.
abstract final class StorageKeys {
  static const String onboardingCompleted = 'onboarding_completed';
  static const String selectedRole = 'selected_role';
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String sessionExpiresAt = 'session_expires_at';
  static const String currentUser = 'current_user';
  static const String rememberMe = 'remember_me';
  static const String appSettings = 'app_settings';
}
