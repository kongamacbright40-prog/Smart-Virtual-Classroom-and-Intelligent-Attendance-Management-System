import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/di/app_dependencies.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'features/authentication/providers/auth_provider.dart';
import 'providers/classroom_registry.dart';
import 'providers/settings_provider.dart';
import 'repositories/repositories.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/webrtc_service.dart';
import 'services/websocket_service.dart';

/// Root widget: exposes dependencies and app-level state, then builds the
/// themed [MaterialApp] with role-guarded routing.
class SmartClassApp extends StatefulWidget {
  const SmartClassApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SmartClassApp> createState() => _SmartClassAppState();
}

class _SmartClassAppState extends State<SmartClassApp> {
  late final AuthProvider _auth;
  late final SettingsProvider _settings;
  late final AppRouter _router;
  late final ClassroomRegistry _classrooms;

  AppDependencies get _deps => widget.dependencies;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider(
      repository: _deps.authRepository,
      authService: _deps.authService,
      storage: _deps.storage,
      notificationService: _deps.notificationService,
    );
    _settings = SettingsProvider(_deps.storage)..load();
    _router = AppRouter(_auth);
    _classrooms = ClassroomRegistry(_deps);
    _deps.apiService.onUnauthorized = _onUnauthorized;
  }

  Future<void> _onUnauthorized() async {
    if (!_auth.isAuthenticated) return;
    await _auth.handleSessionExpired();
    AppRouter.navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
  }

  @override
  void dispose() {
    _auth.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: _deps),
        Provider<StorageService>.value(value: _deps.storage),
        Provider<AuthService>.value(value: _deps.authService),
        Provider<ApiService>.value(value: _deps.apiService),
        Provider<WebSocketService>.value(value: _deps.webSocketService),
        Provider<WebRTCService>.value(value: _deps.webRTCService),
        Provider<NotificationService>.value(value: _deps.notificationService),
        Provider<AuthRepository>.value(value: _deps.authRepository),
        Provider<UserRepository>.value(value: _deps.userRepository),
        Provider<CourseRepository>.value(value: _deps.courseRepository),
        Provider<ScheduleRepository>.value(value: _deps.scheduleRepository),
        Provider<AttendanceRepository>.value(
            value: _deps.attendanceRepository),
        Provider<ClassroomRepository>.value(value: _deps.classroomRepository),
        Provider<QuestionRepository>.value(value: _deps.questionRepository),
        Provider<NotificationRepository>.value(
            value: _deps.notificationRepository),
        Provider<AdminRepository>.value(value: _deps.adminRepository),
        Provider<ReportRepository>.value(value: _deps.reportRepository),
        Provider<ClassroomRegistry>.value(value: _classrooms),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<SettingsProvider>.value(value: _settings),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: AppRouter.navigatorKey,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.themeMode,
          initialRoute: RouteNames.splash,
          onGenerateRoute: _router.onGenerateRoute,
          builder: (context, child) {
            // Keep text readable but prevent extreme scaling from breaking
            // dense layouts on small phones.
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(maxScaleFactor: 1.3),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
