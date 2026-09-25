import 'package:smart_class/core/di/app_dependencies.dart';
import 'package:smart_class/services/api_service.dart';
import 'package:smart_class/services/auth_service.dart';
import 'package:smart_class/services/notification_service.dart';
import 'package:smart_class/services/storage_service.dart';

import 'fake_realtime.dart';
import 'mock_admin_repository.dart';
import 'mock_attendance_repository.dart';
import 'mock_auth_repository.dart';
import 'mock_classroom_repository.dart';
import 'mock_course_repository.dart';
import 'mock_data_store.dart';
import 'mock_notification_repository.dart';
import 'mock_question_repository.dart';
import 'mock_report_repository.dart';
import 'mock_schedule_repository.dart';
import 'mock_user_repository.dart';

/// Dependency graph wired to in-memory fakes for widget and unit tests.
///
/// The fixture data lives only in `test/fakes/`; the production app always
/// talks to the real backend.
class FakeDependencies {
  FakeDependencies({
    StorageService? storage,
    Duration latency = Duration.zero,
    bool simulateResponses = false,
    DateTime? now,
  }) : store = MockDataStore(now: now) {
    final storageService = storage ?? StorageService(InMemoryStore());
    final authService = AuthService(storageService);
    final notifications = MockNotificationRepository(store, latency: latency);
    questions = MockQuestionRepository(
      store,
      latency: latency,
      simulateResponses: simulateResponses,
    );
    dependencies = AppDependencies(
      storage: storageService,
      authService: authService,
      apiService: ApiService(tokenProvider: authService.accessToken),
      webSocketService: MockWebSocketService(),
      webRTCService: MockWebRTCService(),
      notificationService: InAppNotificationService(notifications),
      authRepository: MockAuthRepository(store, latency: latency),
      userRepository: MockUserRepository(store, latency: latency),
      courseRepository: MockCourseRepository(store, latency: latency),
      scheduleRepository: MockScheduleRepository(store, latency: latency),
      attendanceRepository: MockAttendanceRepository(store, latency: latency),
      classroomRepository: MockClassroomRepository(store, latency: latency),
      questionRepository: questions,
      notificationRepository: notifications,
      adminRepository: MockAdminRepository(store, latency: latency),
      reportRepository: MockReportRepository(store, latency: latency),
    );
  }

  final MockDataStore store;
  late final MockQuestionRepository questions;
  late final AppDependencies dependencies;

  Future<void> dispose() async {
    questions.dispose();
    await dependencies.dispose();
    await store.dispose();
  }
}
