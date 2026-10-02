/// REST paths of the Smart Class FastAPI backend (`smart-classroom-api`),
/// relative to `AppConfig.apiBaseUrl + AppConfig.apiPrefix`.
///
/// Keep in sync with `docs/api.md` and the backend routers in `app/*/router.py`.
abstract final class ApiEndpoints {
  // Auth (app/auth/router.py)
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String passwordResetRequest = '/auth/password-reset/request';
  static const String passwordResetVerify = '/auth/password-reset/verify';
  static const String passwordResetConfirm = '/auth/password-reset/confirm';

  // Catalogue (app/courses/router.py)
  static const String faculties = '/faculties';
  static const String departments = '/departments';
  static String department(String id) => '/departments/$id';
  static String departmentArchive(String id) => '/departments/$id/archive';
  static const String courses = '/courses';
  static const String myCourses = '/courses/mine';
  static String course(String id) => '/courses/$id';
  static String courseAssignLecturer(String id) =>
      '/courses/$id/assign-lecturer';
  static String courseArchive(String id) => '/courses/$id/archive';
  static String courseRoster(String id) => '/courses/$id/roster';
  static const String publicDepartments = '/departments/public';

  /// Student self-enrollment: POST joins, DELETE leaves.
  static String courseEnroll(String id) => '/courses/$id/enroll';

  /// Admin enrollment of a student.
  static String courseEnrollments(String id) => '/courses/$id/enrollments';
  static String courseEnrollment(String id, String profileId) =>
      '/courses/$id/enrollments/$profileId';

  // Classes (app/classes/router.py)
  static const String classes = '/classes';
  static const String classSchedule = '/classes/schedule';
  static String classDetail(String id) => '/classes/$id';
  static String classStart(String id) => '/classes/$id/start';
  static String classEnd(String id) => '/classes/$id/end';
  static String classParticipants(String id) => '/classes/$id/participants';
  static String classHand(String id) => '/classes/$id/hand';
  static String classMessages(String id) => '/classes/$id/messages';

  // Attendance (app/attendance/router.py)
  static const String myAttendance = '/attendance/me';
  static String sessionAttendance(String id) => '/attendance/sessions/$id';
  static String sessionAttendanceMark(String id) =>
      '/attendance/sessions/$id/mark';
  static String sessionAppeals(String id) => '/attendance/sessions/$id/appeals';
  static String courseAttendanceSummary(String id) =>
      '/attendance/courses/$id/summary';

  // Live questions (app/participation/router.py)
  static String sessionQuestions(String id) =>
      '/participation/sessions/$id/questions';
  static String sessionOpenQuestions(String id) =>
      '/participation/sessions/$id/questions/open';
  static String questionLaunch(String id) =>
      '/participation/questions/$id/launch';
  static String questionRespond(String id) =>
      '/participation/questions/$id/respond';
  static String questionMyResponse(String id) =>
      '/participation/questions/$id/responses/me';
  static String questionClose(String id) =>
      '/participation/questions/$id/close';

  // Notifications, terms, settings, activity (app/campus/router.py)
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String academicTerms = '/academic-terms';
  static String academicTerm(String id) => '/academic-terms/$id';
  static const String systemSettings = '/settings/system';
  static const String adminActivity = '/admin/activity';

  // Administration (app/admin/router.py)
  static const String adminUsers = '/admin/users';
  static String adminUser(String id) => '/admin/users/$id';
  static String adminUserStatus(String id) => '/admin/users/$id/status';
  static const String adminSessions = '/admin/sessions';

  // Reports (app/reports/router.py)
  static const String reportOverview = '/reports/overview';
  static const String reportLecturer = '/reports/lecturer';
  static const String reportInstitution = '/reports/institution';

  /// Exports accept one of `session_id`, `course_id`, `lecturer_id`,
  /// `department_id` (none = whole institution, admins only).
  static const String attendancePdf = '/reports/attendance.pdf';
  static const String attendanceXlsx = '/reports/attendance.xlsx';
  static const String attendanceCsv = '/reports/attendance.csv';

  // WebSocket paths (relative to AppConfig.wsBaseUrl)

  /// WebRTC mesh signaling + attendance tracking (app/signaling/router.py).
  /// The access token is passed as `?token=`.
  static String signaling(String classId) => '/ws/signal/$classId';

  /// Classroom event stream used by `ClassroomController`. Not provided by
  /// the backend, so backend mode uses a disabled socket and polling.
  static String sessionEvents(String id) => '/ws/sessions/$id/events';
}
