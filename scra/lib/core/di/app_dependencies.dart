import '../../repositories/api/api_live_repositories.dart';
import '../../repositories/repositories.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/webrtc_service.dart';
import '../../services/websocket_service.dart';

/// Composition root: builds every service and repository once and hands
/// them to the widget tree (see `app.dart`). Tests pass in-memory fakes
/// through the constructor instead.
class AppDependencies {
  AppDependencies({
    required this.storage,
    required this.authService,
    required this.apiService,
    required this.webSocketService,
    required this.webRTCService,
    required this.notificationService,
    required this.authRepository,
    required this.userRepository,
    required this.courseRepository,
    required this.scheduleRepository,
    required this.attendanceRepository,
    required this.classroomRepository,
    required this.questionRepository,
    required this.notificationRepository,
    required this.adminRepository,
    required this.reportRepository,
  });

  final StorageService storage;
  final AuthService authService;
  final ApiService apiService;
  final WebSocketService webSocketService;
  final WebRTCService webRTCService;
  final NotificationService notificationService;

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final CourseRepository courseRepository;
  final ScheduleRepository scheduleRepository;
  final AttendanceRepository attendanceRepository;
  final ClassroomRepository classroomRepository;
  final QuestionRepository questionRepository;
  final NotificationRepository notificationRepository;
  final AdminRepository adminRepository;
  final ReportRepository reportRepository;

  /// Builds the production dependency graph (always the FastAPI backend).
  static Future<AppDependencies> create() async {
    final storage = StorageService(await SharedPreferencesStore.create());
    return api(storage: storage);
  }

  /// Graph backed by the FastAPI REST API. The backend has no classroom event
  /// socket yet, so live data is polled and WebRTC uses the signaling socket.
  static AppDependencies api({required StorageService storage}) {
    final authService = AuthService(storage);
    final apiService = ApiService(tokenProvider: authService.accessToken);
    final repos = ApiRepositories(
      apiService,
      currentUser: () => authService.currentUser,
    );
    apiService.refreshSession = () async {
      final refreshToken = authService.session?.refreshToken;
      if (refreshToken == null) return false;
      final tokens = await repos.auth.refresh(refreshToken);
      await authService.updateTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return true;
    };
    return AppDependencies(
      storage: storage,
      authService: authService,
      apiService: apiService,
      webSocketService: DisabledWebSocketService(),
      webRTCService: FlutterWebRTCService(
        tokenProvider: authService.accessToken,
      ),
      notificationService: InAppNotificationService(repos.notifications),
      authRepository: repos.auth,
      userRepository: repos.users,
      courseRepository: repos.courses,
      scheduleRepository: repos.schedule,
      attendanceRepository: repos.attendance,
      classroomRepository: repos.classroom,
      questionRepository: repos.questions,
      notificationRepository: repos.notifications,
      adminRepository: repos.admin,
      reportRepository: repos.reports,
    );
  }

  Future<void> dispose() async {
    await webRTCService.dispose();
    await webSocketService.dispose();
    await notificationService.dispose();
    apiService.dispose();
  }
}
