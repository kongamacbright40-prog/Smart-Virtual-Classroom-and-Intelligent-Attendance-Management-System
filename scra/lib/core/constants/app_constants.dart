/// Application-wide configuration.
///
/// Values can be overridden at build time with `--dart-define`, e.g.
/// `flutter run --dart-define=API_BASE_URL=https://api.example.edu --dart-define=USE_MOCK_DATA=false`.
abstract final class AppConfig {
  /// Base URL of the FastAPI backend (REST). `10.0.2.2` is the host machine
  /// as seen from the Android emulator.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Prefix applied to every REST endpoint.
  static const String apiPrefix = String.fromEnvironment(
    'API_PREFIX',
    defaultValue: '/api/v1',
  );

  /// Base URL for WebSocket connections (classroom events, signaling).
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://10.0.2.2:8000',
  );

  /// When true, the app uses in-memory mock repositories instead of the API.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  /// When true, the live classroom uses real camera/microphone via
  /// flutter_webrtc and the signaling server. Otherwise a mock media layer
  /// is used so the UI can be exercised without a backend.
  static const bool enableRealtimeMedia = bool.fromEnvironment(
    'ENABLE_REALTIME_MEDIA',
    defaultValue: false,
  );

  static const Duration requestTimeout = Duration(seconds: 20);
  static const Duration mockLatency = Duration(milliseconds: 350);
}

abstract final class AppConstants {
  static const String appName = 'Smart Class';
  static const String suiteName = 'EduVerse Suite';
  static const String appVersion = '1.0.0';

  static const int minPasswordLength = 8;
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
