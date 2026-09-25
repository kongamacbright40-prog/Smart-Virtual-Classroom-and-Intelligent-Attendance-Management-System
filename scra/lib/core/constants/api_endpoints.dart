/// REST paths of the FastAPI backend, relative to
/// `AppConfig.apiBaseUrl + AppConfig.apiPrefix` (e.g. `/api/v1`).
///
/// This is the proposed contract documented in `docs/api.md`; keep both in
/// sync when the backend team finalizes routes.
abstract final class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String activateStudent = '/auth/activate-student';
  static const String registerLecturer = '/auth/register-lecturer';
  static const String passwordResetRequest = '/auth/password-reset/request';
  static const String passwordResetVerify = '/auth/password-reset/verify';
  static const String passwordResetConfirm = '/auth/password-reset/confirm';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';

  // Users & profiles
  static const String users = '/users';
  static String user(String id) => '/users/$id';
  static String userStatus(String id) => '/users/$id/status';
  static String student(String id) => '/students/$id';
  static String lecturer(String id) => '/lecturers/$id';
  static String admin(String id) => '/admins/$id';

  // Courses
  static const String courses = '/courses';
  static String course(String id) => '/courses/$id';
  static String courseRoster(String id) => '/courses/$id/roster';
  static String courseAssignLecturer(String id) => '/courses/$id/assign-lecturer';
  static String courseArchive(String id) => '/courses/$id/archive';
  static String courseSessions(String id) => '/courses/$id/sessions';
  static String courseAttendanceSummaries(String id) =>
      '/courses/$id/attendance/summaries';
  static String studentCourses(String id) => '/students/$id/courses';
  static String lecturerCourses(String id) => '/lecturers/$id/courses';

  // Sessions & scheduling
  static const String schedules = '/schedules';
  static String session(String id) => '/sessions/$id';
  static String studentSessions(String id) => '/students/$id/sessions';
  static String lecturerSessions(String id) => '/lecturers/$id/sessions';

  // Live classroom
  static String sessionStart(String id) => '/sessions/$id/start';
  static String sessionEnd(String id) => '/sessions/$id/end';
  static String sessionJoin(String id) => '/sessions/$id/join';
  static String sessionLeave(String id) => '/sessions/$id/leave';
  static String sessionParticipants(String id) => '/sessions/$id/participants';
  static String sessionParticipant(String id, String userId) =>
      '/sessions/$id/participants/$userId';
  static String sessionMessages(String id) => '/sessions/$id/messages';

  // Attendance
  static String studentAttendance(String id) => '/students/$id/attendance';
  static String studentAttendanceSummary(String id) =>
      '/students/$id/attendance/summary';
  static String sessionAttendance(String id) => '/sessions/$id/attendance';
  static String sessionAttendanceStart(String id) =>
      '/sessions/$id/attendance/start';
  static String sessionAttendanceEnd(String id) =>
      '/sessions/$id/attendance/end';
  static String sessionAttendanceCheckIn(String id) =>
      '/sessions/$id/attendance/check-in';
  static String sessionAttendanceStudent(String id, String studentId) =>
      '/sessions/$id/attendance/$studentId';
  static String attendanceAppeals(String recordId) =>
      '/attendance/$recordId/appeals';

  // Live questions
  static String sessionQuestions(String id) => '/sessions/$id/questions';
  static const String questions = '/questions';
  static String question(String id) => '/questions/$id';
  static String questionLaunch(String id) => '/questions/$id/launch';
  static String questionClose(String id) => '/questions/$id/close';
  static String questionBroadcast(String id) => '/questions/$id/broadcast';
  static String questionResponses(String id) => '/questions/$id/responses';
  static String questionResponse(String id, String studentId) =>
      '/questions/$id/responses/$studentId';

  // Notifications
  static String userNotifications(String id) => '/users/$id/notifications';
  static String userNotificationsReadAll(String id) =>
      '/users/$id/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  // Administration
  static const String faculties = '/faculties';
  static const String departments = '/departments';
  static String department(String id) => '/departments/$id';
  static String departmentArchive(String id) => '/departments/$id/archive';
  static const String academicTerms = '/academic-terms';
  static String academicTerm(String id) => '/academic-terms/$id';
  static const String systemSettings = '/settings/system';
  static const String adminActivity = '/admin/activity';

  // Reports
  static const String adminDashboardReport = '/reports/admin-dashboard';
  static String lecturerReport(String id) => '/reports/lecturers/$id';
  static const String institutionReport = '/reports/institution';
  static String reportExport(String id) => '/reports/$id/export';

  // WebSocket paths (relative to AppConfig.wsBaseUrl)
  static String sessionEvents(String id) => '/ws/sessions/$id/events';
  static String userEvents(String id) => '/ws/users/$id/events';

  /// Existing WebRTC signaling endpoint used by `SignalingService`.
  static String signaling(String roomId, String userId) =>
      '/ws/classroom/$roomId/$userId';
}
