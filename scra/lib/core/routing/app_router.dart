import 'package:flutter/material.dart';

import '../../features/admin/academic_terms/academic_terms_screen.dart';
import '../../features/admin/courses/admin_course_details_screen.dart';
import '../../features/admin/departments/departments_screen.dart';
import '../../features/admin/departments/faculties_screen.dart';
import '../../features/admin/profile/admin_profile_screen.dart';
import '../../features/admin/reports/admin_reports_screen.dart';
import '../../features/admin/users/user_details_screen.dart';
import '../../features/authentication/presentation/admin_login_screen.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/lecturer_registration_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/student_activation_screen.dart';
import '../../features/authentication/providers/auth_provider.dart';
import '../../features/lecturer/attendance/live_attendance_screen.dart';
import '../../features/lecturer/classroom/lecturer_live_classroom_screen.dart';
import '../../features/lecturer/classroom/whiteboard_screen.dart';
import '../../features/lecturer/courses/course_roster_screen.dart';
import '../../features/lecturer/profile/lecturer_profile_screen.dart';
import '../../features/lecturer/questions/create_question_screen.dart';
import '../../features/lecturer/reports/attendance_reports_screen.dart';
import '../../features/lecturer/schedule/schedule_class_screen.dart';
import '../../features/onboarding/presentation/attendance_intro_screen.dart';
import '../../features/onboarding/presentation/participation_intro_screen.dart';
import '../../features/onboarding/presentation/role_selection_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/student/classroom/classroom_chat_screen.dart';
import '../../features/student/classroom/live_question_screen.dart';
import '../../features/student/classroom/student_live_classroom_screen.dart';
import '../../features/student/courses/course_details_screen.dart';
import '../../features/student/courses/student_courses_screen.dart';
import '../../features/student/notifications/student_notifications_screen.dart';
import '../../features/student/settings/student_settings_screen.dart';
import '../../models/user_model.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/navigation/admin_navigation.dart';
import '../../widgets/navigation/lecturer_navigation.dart';
import '../../widgets/navigation/student_navigation.dart';
import '../constants/app_strings.dart';
import 'route_names.dart';

/// Central route table with role-based guards.
///
/// * `/student/**` requires a student, `/lecturer/**` a lecturer and
///   `/admin/**` an administrator.
/// * Unauthenticated users are sent to the matching login screen.
/// * Authenticated users opening another role's route see an
///   "access denied" page.
class AppRouter {
  AppRouter(this._auth);

  final AuthProvider _auth;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Landing route for a role after login / session restore.
  static String homeFor(UserRole role) => switch (role) {
    UserRole.student => RouteNames.studentHome,
    UserRole.lecturer => RouteNames.lecturerDashboard,
    UserRole.admin => RouteNames.adminDashboard,
  };

  /// Role required to open [route], or null for public routes.
  static UserRole? requiredRole(String route) {
    if (route == RouteNames.adminLogin) return null;
    if (route.startsWith('/student')) return UserRole.student;
    if (route.startsWith('/lecturer')) return UserRole.lecturer;
    if (route.startsWith('/admin')) return UserRole.admin;
    return null;
  }

  static bool requiresAuth(String route) =>
      requiredRole(route) != null || route == RouteNames.notifications;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? RouteNames.splash;
    final args = settings.arguments;

    if (requiresAuth(name) && !_auth.isAuthenticated) {
      final role = requiredRole(name);
      return _page(
        RouteSettings(name: RouteNames.login, arguments: role),
        role == UserRole.admin
            ? const AdminLoginScreen()
            : LoginScreen(initialRole: role),
      );
    }
    final required = requiredRole(name);
    if (required != null && _auth.role != required) {
      return _page(settings, const AccessDeniedScreen());
    }

    final Widget? page = _build(name, args);
    return _page(settings, page ?? const _UnknownRouteScreen());
  }

  Widget? _build(String name, Object? args) {
    String id() => args is String ? args : '';
    String? optionalId() => args is String ? args : null;
    int tab() => args is int ? args : 0;

    return switch (name) {
      // Onboarding
      RouteNames.splash => const SplashScreen(),
      RouteNames.welcome => const WelcomeScreen(),
      RouteNames.attendanceIntro => const AttendanceIntroScreen(),
      RouteNames.participationIntro => const ParticipationIntroScreen(),
      RouteNames.roleSelection => const RoleSelectionScreen(),

      // Authentication
      RouteNames.login => LoginScreen(
        initialRole: args is UserRole ? args : null,
      ),
      RouteNames.studentActivation => const StudentActivationScreen(),
      RouteNames.lecturerRegistration => const LecturerRegistrationScreen(),
      RouteNames.adminLogin => const AdminLoginScreen(),
      RouteNames.forgotPassword => const ForgotPasswordScreen(),

      // Shared
      RouteNames.notifications => const StudentNotificationsScreen(),

      // Student
      RouteNames.studentHome => StudentNavigation(initialIndex: tab()),
      RouteNames.studentCourses => const StudentCoursesScreen(),
      RouteNames.courseDetails => CourseDetailsScreen(courseId: id()),
      RouteNames.studentLiveClassroom => StudentLiveClassroomScreen(
        sessionId: id(),
      ),
      RouteNames.classroomChat => ClassroomChatScreen(sessionId: id()),
      RouteNames.liveQuestion => LiveQuestionScreen(sessionId: id()),
      RouteNames.studentSettings => const StudentSettingsScreen(),

      // Lecturer
      RouteNames.lecturerDashboard => LecturerNavigation(initialIndex: tab()),
      RouteNames.courseRoster => CourseRosterScreen(courseId: id()),
      RouteNames.scheduleClass => ScheduleClassScreen(courseId: optionalId()),
      RouteNames.lecturerLiveClassroom => LecturerLiveClassroomScreen(
        sessionId: id(),
      ),
      RouteNames.whiteboard => WhiteboardScreen(sessionId: id()),
      RouteNames.createQuestion => CreateQuestionScreen(sessionId: id()),
      RouteNames.lecturerChat => ClassroomChatScreen(sessionId: id()),
      RouteNames.liveAttendance => LiveAttendanceScreen(
        sessionId: optionalId(),
      ),
      RouteNames.attendanceReports => AttendanceReportsScreen(
        courseId: optionalId(),
      ),
      RouteNames.lecturerProfile => const LecturerProfileScreen(),

      // Admin
      RouteNames.adminDashboard => AdminNavigation(initialIndex: tab()),
      RouteNames.userDetails => UserDetailsScreen(userId: optionalId()),
      RouteNames.departments => const DepartmentsScreen(),
      RouteNames.faculties => const FacultiesScreen(),
      RouteNames.academicTerms => const AcademicTermsScreen(),
      RouteNames.adminCourseDetails => AdminCourseDetailsScreen(courseId: id()),
      RouteNames.adminReports => const AdminReportsScreen(),
      RouteNames.adminProfile => const AdminProfileScreen(),
      _ => null,
    };
  }

  static Route<dynamic> _page(RouteSettings settings, Widget child) =>
      MaterialPageRoute<dynamic>(settings: settings, builder: (_) => child);
}

/// Shown when a signed-in user opens a route reserved for another role.
class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ErrorState(
        title: 'Access denied',
        message: AppStrings.accessDenied,
        retryLabel: 'Go Back',
        onRetry: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            navigator.pushReplacementNamed(RouteNames.splash);
          }
        },
      ),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const ErrorState(
        title: 'Page not found',
        message: 'The page you are looking for does not exist.',
      ),
    );
  }
}
