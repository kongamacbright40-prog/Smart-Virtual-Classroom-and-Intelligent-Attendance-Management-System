import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_class/core/di/app_dependencies.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/features/authentication/providers/auth_provider.dart';
import 'package:smart_class/features/student/attendance/student_attendance_screen.dart';
import 'package:smart_class/features/student/classroom/classroom_chat_screen.dart';
import 'package:smart_class/features/student/classroom/live_question_screen.dart';
import 'package:smart_class/features/student/classroom/student_live_classroom_screen.dart';
import 'package:smart_class/features/student/courses/course_details_screen.dart';
import 'package:smart_class/features/student/courses/student_courses_screen.dart';
import 'package:smart_class/features/student/home/student_home_screen.dart';
import 'package:smart_class/features/student/notifications/student_notifications_screen.dart';
import 'package:smart_class/features/student/profile/student_profile_screen.dart';
import 'package:smart_class/features/student/schedule/student_schedule_screen.dart';
import 'package:smart_class/features/student/settings/student_settings_screen.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/providers/classroom_registry.dart';
import 'package:smart_class/providers/settings_provider.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/services/api_service.dart';
import 'package:smart_class/services/auth_service.dart';
import 'package:smart_class/services/notification_service.dart';
import 'package:smart_class/services/storage_service.dart';
import 'package:smart_class/services/webrtc_service.dart';
import 'package:smart_class/services/websocket_service.dart';

import '../fakes/fake_dependencies.dart';
import '../fakes/mock_data_store.dart';

const Size kPhoneSize = Size(412, 915);
const Size kSmallPhoneSize = Size(360, 640);

void _setViewport(WidgetTester tester, [Size size = kPhoneSize]) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpFrames(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pumpStudentApp(
  WidgetTester tester, {
  Widget? home,
  Size size = kPhoneSize,
}) async {
  _setViewport(tester, size);
  final fake = FakeDependencies(simulateResponses: true);
  addTearDown(fake.dispose);
  final deps = fake.dependencies;
  final auth = AuthProvider(
    repository: deps.authRepository,
    authService: deps.authService,
    storage: deps.storage,
    notificationService: deps.notificationService,
  );
  addTearDown(auth.dispose);
  final ok = await auth.login(
    role: UserRole.student,
    identifier: DemoAccounts.studentId,
    password: DemoAccounts.password,
  );
  expect(ok, isTrue);
  final settings = SettingsProvider(deps.storage)..load();
  addTearDown(settings.dispose);
  final classrooms = ClassroomRegistry(deps);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: deps),
        Provider<StorageService>.value(value: deps.storage),
        Provider<AuthService>.value(value: deps.authService),
        Provider<ApiService>.value(value: deps.apiService),
        Provider<WebSocketService>.value(value: deps.webSocketService),
        Provider<WebRTCService>.value(value: deps.webRTCService),
        Provider<NotificationService>.value(value: deps.notificationService),
        Provider<AuthRepository>.value(value: deps.authRepository),
        Provider<UserRepository>.value(value: deps.userRepository),
        Provider<CourseRepository>.value(value: deps.courseRepository),
        Provider<ScheduleRepository>.value(value: deps.scheduleRepository),
        Provider<AttendanceRepository>.value(value: deps.attendanceRepository),
        Provider<ClassroomRepository>.value(value: deps.classroomRepository),
        Provider<QuestionRepository>.value(value: deps.questionRepository),
        Provider<NotificationRepository>.value(
          value: deps.notificationRepository,
        ),
        Provider<AdminRepository>.value(value: deps.adminRepository),
        Provider<ReportRepository>.value(value: deps.reportRepository),
        Provider<ClassroomRegistry>.value(value: classrooms),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: MaterialApp(
        home: home ?? const StudentHomeScreen(),
        onGenerateRoute: _route,
      ),
    ),
  );
  await _pumpFrames(tester, 12);
}

Route<dynamic> _route(RouteSettings settings) {
  final args = settings.arguments;
  final page = switch (settings.name) {
    RouteNames.studentCourses => const StudentCoursesScreen(),
    RouteNames.courseDetails => CourseDetailsScreen(courseId: args! as String),
    RouteNames.studentLiveClassroom => StudentLiveClassroomScreen(
      sessionId: args! as String,
    ),
    RouteNames.classroomChat => ClassroomChatScreen(sessionId: args! as String),
    RouteNames.liveQuestion => LiveQuestionScreen(sessionId: args! as String),
    RouteNames.notifications => const StudentNotificationsScreen(),
    RouteNames.studentSettings => const StudentSettingsScreen(),
    RouteNames.login => const Scaffold(body: Center(child: Text('Signed out'))),
    _ => const StudentHomeScreen(),
  };
  return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
}

Future<void> _popRoute(WidgetTester tester, [int frames = 6]) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await _pumpFrames(tester, frames);
}

void main() {
  testWidgets('student screens use repository data through the main flows', (
    tester,
  ) async {
    await _pumpStudentApp(tester);

    expect(find.text('My Classes'), findsOneWidget);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(RouteNames.studentCourses);
    await _pumpFrames(tester, 8);
    expect(find.text('My Courses'), findsOneWidget);
    expect(find.textContaining('Academic Session'), findsNothing);

    await _tapVisible(tester, find.text('View Course').first);
    await _pumpFrames(tester, 12);
    expect(find.text('Course Details'), findsOneWidget);
    await _popRoute(tester);
    await _popRoute(tester);

    await tester.tap(find.byKey(const Key('join_live_session')).first);
    await _pumpFrames(tester, 18);
    expect(find.textContaining('Attendance Logged'), findsWidgets);

    await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
    await _pumpFrames(tester, 10);
    expect(find.text('Classroom Chat'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('chat_input')),
      'Great explanation, Prof.',
    );
    await tester.tap(find.byKey(const Key('chat_send')));
    await _pumpFrames(tester, 12);
    expect(find.text('Great explanation, Prof.'), findsOneWidget);
    await _popRoute(tester, 8);

    await tester.tap(find.byIcon(Icons.quiz_outlined).last);
    await _pumpFrames(tester, 10);
    await tester.tap(find.byKey(const Key('question_option_C')));
    await _pumpFrames(tester, 2);
    await _tapVisible(tester, find.byKey(const Key('submit_answer')));
    await _pumpFrames(tester, 12);
    expect(find.text('Response Synced to Session'), findsOneWidget);
  });

  testWidgets('absent attendance appeal submits deterministically', (
    tester,
  ) async {
    await _pumpStudentApp(tester, home: const StudentAttendanceScreen());
    await _tapVisible(tester, find.textContaining('Absent').first);
    await _tapVisible(tester, find.textContaining('Submit Medical Slip').first);
    expect(find.text('Attendance Review'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'doctor-note.pdf');
    await _tapVisible(tester, find.text('Submit for Faculty Approval'));
    await _pumpFrames(tester, 10);
    expect(find.text('Review request submitted'), findsOneWidget);
  });

  testWidgets('profile and settings avoid removed dummy profile text', (
    tester,
  ) async {
    await _pumpStudentApp(tester, home: const StudentProfileScreen());
    expect(find.text('Student Profile'), findsOneWidget);
    expect(find.textContaining('Hall 4'), findsNothing);
    expect(find.textContaining('v2.4.1'), findsNothing);

    await _pumpStudentApp(tester, home: const StudentSettingsScreen());
    expect(find.text('Settings'), findsOneWidget);
    expect(find.textContaining('Last updated 3 months ago'), findsNothing);
  });

  testWidgets('student main screens do not overflow on a small phone', (
    tester,
  ) async {
    await _pumpStudentApp(tester, size: kSmallPhoneSize);
    expect(tester.takeException(), isNull);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(RouteNames.studentCourses);
    await _pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.text('View Course').first);
    await _pumpFrames(tester, 12);
    expect(tester.takeException(), isNull);
    await _popRoute(tester, 4);
    await _popRoute(tester, 4);

    await _pumpStudentApp(
      tester,
      home: const StudentScheduleScreen(),
      size: kSmallPhoneSize,
    );
    expect(tester.takeException(), isNull);

    await _pumpStudentApp(
      tester,
      home: const StudentAttendanceScreen(),
      size: kSmallPhoneSize,
    );
    expect(tester.takeException(), isNull);
  });
}
