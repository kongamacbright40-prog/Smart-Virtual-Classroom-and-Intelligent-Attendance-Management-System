/// Every named route in the app. Role-scoped routes are prefixed with the
/// role (`/student`, `/lecturer`, `/admin`) so [AppRouter] can guard them.
abstract final class RouteNames {
  // Launch
  static const String splash = '/';

  // Authentication
  static const String login = '/login';
  static const String studentActivation = '/activate-student';
  static const String lecturerRegistration = '/register-lecturer';
  static const String adminRegistration = '/register-admin';
  static const String adminLogin = '/admin-login';
  static const String forgotPassword = '/forgot-password';

  // Shared (any authenticated user)
  static const String notifications = '/notifications';

  // Student
  static const String studentHome = '/student';
  static const String studentCourses = '/student/courses';
  static const String courseCatalog = '/student/course-catalog';
  static const String courseDetails = '/student/course-details';
  static const String studentLiveClassroom = '/student/classroom';
  static const String classroomChat = '/student/classroom/chat';
  static const String liveQuestion = '/student/classroom/question';
  static const String studentSettings = '/student/settings';

  // Lecturer
  static const String lecturerDashboard = '/lecturer';
  static const String courseRoster = '/lecturer/course-roster';
  static const String scheduleClass = '/lecturer/schedule-class';
  static const String lecturerLiveClassroom = '/lecturer/classroom';
  static const String whiteboard = '/lecturer/classroom/whiteboard';
  static const String createQuestion = '/lecturer/classroom/question';
  static const String lecturerChat = '/lecturer/classroom/chat';
  static const String liveAttendance = '/lecturer/live-attendance';
  static const String attendanceReports = '/lecturer/reports';
  static const String lecturerProfile = '/lecturer/profile';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminLiveClasses = '/admin/live-classes';
  static const String adminActivity = '/admin/activity';
  static const String userDetails = '/admin/user-details';
  static const String departments = '/admin/departments';
  static const String faculties = '/admin/faculties';
  static const String academicTerms = '/admin/academic-terms';
  static const String adminCourseDetails = '/admin/course-details';
  static const String adminReports = '/admin/reports';
  static const String adminProfile = '/admin/profile';
}

/// Tab indexes of the role shells (pass as the route argument of the
/// shell route to open a specific tab).
abstract final class StudentTabs {
  static const int home = 0;
  static const int courses = 1;
  static const int schedule = 2;
  static const int attendance = 3;
  static const int profile = 4;
}

abstract final class LecturerTabs {
  static const int dashboard = 0;
  static const int courses = 1;
  static const int attendance = 2;
  static const int reports = 3;
}

abstract final class AdminTabs {
  static const int dashboard = 0;
  static const int users = 1;
  static const int courses = 2;
  static const int settings = 3;
}
