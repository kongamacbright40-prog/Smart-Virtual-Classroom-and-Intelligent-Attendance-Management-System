import '../../repositories/mock/mock_admin_repository.dart';
import '../../repositories/mock/mock_attendance_repository.dart';
import '../../repositories/mock/mock_auth_repository.dart';
import '../../repositories/mock/mock_classroom_repository.dart';
import '../../repositories/mock/mock_course_repository.dart';
import '../../repositories/mock/mock_data_store.dart';
import '../../repositories/mock/mock_notification_repository.dart';
import '../../repositories/mock/mock_question_repository.dart';
import '../../repositories/mock/mock_report_repository.dart';
import '../../repositories/mock/mock_schedule_repository.dart';
import '../../repositories/mock/mock_user_repository.dart';
import '../../repositories/repositories.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/webrtc_service.dart';
import '../../services/websocket_service.dart';
import '../constants/app_constants.dart';

/// Composition root: builds every service and repository once and hands
/// them to the widget tree (see `app.dart`).
///
/// Swapping mock data for the FastAPI backend only requires changing the
/// factory used here — no screen changes.
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
    this.mockStore,
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

  /// Present only when running on mock data.
  final MockDataStore? mockStore;

  /// Builds the dependency graph selected by [AppConfig].
  static Future<AppDependencies> create() async {
    final store = await SharedPreferencesStore.create();
    return mock(storage: StorageService(store));
  }

  /// Mock graph used for development, demos and tests.
  static AppDependencies mock({
    StorageService? storage,
    Duration? latency,
    bool simulateLiveActivity = true,
    DateTime? now,
  }) {
    final storageService = storage ?? StorageService(InMemoryStore());
    final authService = AuthService(storageService);
    final data = MockDataStore(now: now);
    final notifications = MockNotificationRepository(data, latency: latency);
    return AppDependencies(
      storage: storageService,
      authService: authService,
      apiService: ApiService(tokenProvider: authService.accessToken),
      webSocketService: MockWebSocketService(),
      webRTCService: AppConfig.enableRealtimeMedia
          ? FlutterWebRTCService()
          : MockWebRTCService(),
      notificationService: InAppNotificationService(notifications),
      authRepository: MockAuthRepository(data, latency: latency),
      userRepository: MockUserRepository(data, latency: latency),
      courseRepository: MockCourseRepository(data, latency: latency),
      scheduleRepository: MockScheduleRepository(data, latency: latency),
      attendanceRepository: MockAttendanceRepository(data, latency: latency),
      classroomRepository: MockClassroomRepository(data, latency: latency),
      questionRepository: MockQuestionRepository(
        data,
        latency: latency,
        simulateResponses: simulateLiveActivity,
      ),
      notificationRepository: notifications,
      adminRepository: MockAdminRepository(data, latency: latency),
      reportRepository: MockReportRepository(data, latency: latency),
      mockStore: data,
    );
  }

  Future<void> dispose() async {
    await webRTCService.dispose();
    await webSocketService.dispose();
    await notificationService.dispose();
    final q = questionRepository;
    if (q is MockQuestionRepository) q.dispose();
    await mockStore?.dispose();
    apiService.dispose();
  }
}
