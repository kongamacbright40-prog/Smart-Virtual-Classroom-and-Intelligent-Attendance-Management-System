import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/core/routing/app_router.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/features/authentication/presentation/admin_login_screen.dart';
import 'package:smart_class/features/authentication/presentation/forgot_password_screen.dart';
import 'package:smart_class/features/authentication/presentation/lecturer_registration_screen.dart';
import 'package:smart_class/features/authentication/presentation/login_screen.dart';
import 'package:smart_class/features/authentication/presentation/student_activation_screen.dart';
import 'package:smart_class/models/user_model.dart';

import '../fakes/mock_auth_repository.dart';
import '../fakes/mock_data_store.dart';

import 'package:smart_class/widgets/navigation/admin_navigation.dart';
import 'package:smart_class/widgets/navigation/lecturer_navigation.dart';
import 'package:smart_class/widgets/navigation/student_navigation.dart';

import '../helpers/test_app.dart';

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

void main() {
  testWidgets('student logs in and lands on the student shell', (tester) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    expect(find.byType(LoginScreen), findsOneWidget);
    await signInAs(tester, UserRole.student);
    expect(find.byType(StudentNavigation), findsOneWidget);
  });

  testWidgets('lecturer logs in and lands on the lecturer shell', (
    tester,
  ) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    await tester.tap(find.byKey(const Key('login_role_lecturer')));
    await tester.pump();
    await signInAs(tester, UserRole.lecturer);
    expect(find.byType(LecturerNavigation), findsOneWidget);
  });

  testWidgets('admin logs in through the institutional gateway', (
    tester,
  ) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    await signInAs(tester, UserRole.admin);
    expect(find.byType(AdminNavigation), findsOneWidget);
  });

  testWidgets('empty form shows validation errors', (tester) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.text('Institutional ID or email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('wrong password shows an authentication error', (tester) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    await tester.enterText(
      find.byKey(const Key('login_identifier')),
      DemoAccounts.studentId,
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'NotThePassword1',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await pumpFrames(tester);
    expect(find.byKey(const Key('login_error')), findsOneWidget);
    expect(find.byType(StudentNavigation), findsNothing);
  });

  testWidgets('selecting Admin on the login toggle opens the admin gateway', (
    tester,
  ) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    await tester.tap(find.byKey(const Key('login_role_admin')));
    await tester.pumpAndSettle();
    expect(find.byType(AdminLoginScreen), findsOneWidget);
  });

  testWidgets('first-time links open activation and registration', (
    tester,
  ) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    await tapVisible(tester, find.byKey(const Key('login_first_time')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentActivationScreen), findsOneWidget);

    _navigator(tester).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login_role_lecturer')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('login_first_time')));
    await tester.pumpAndSettle();
    expect(find.byType(LecturerRegistrationScreen), findsOneWidget);
  });

  testWidgets('student activation validates and signs the student in', (
    tester,
  ) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    _navigator(tester).pushNamed(RouteNames.studentActivation);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('setup_submit')));
    await tester.pump();
    expect(find.text('Student matricule is required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('setup_id')), 'MAT-2024-9148');
    await tester.enterText(
      find.byKey(const Key('setup_email')),
      'alex.rivers@campus.edu',
    );
    await tester.enterText(
      find.byKey(const Key('setup_password')),
      'Secure123!',
    );
    await tester.enterText(
      find.byKey(const Key('setup_confirm')),
      'Secure123!',
    );
    await tapVisible(tester, find.byKey(const Key('setup_submit')));
    await tester.pump();
    expect(
      find.text('Please accept the institutional terms to continue.'),
      findsOneWidget,
    );

    await tapVisible(tester, find.byKey(const Key('setup_ack')));
    await tapVisible(tester, find.byKey(const Key('setup_submit')));
    await pumpFrames(tester, 10);
    expect(find.byType(StudentNavigation), findsOneWidget);
  });

  testWidgets('forgot password completes the three recovery steps', (
    tester,
  ) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    _navigator(tester).pushNamed(RouteNames.forgotPassword);
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('recovery_email')),
      DemoAccounts.studentEmail,
    );
    await tester.tap(find.byKey(const Key('recovery_send')));
    await pumpFrames(tester);
    expect(find.text('Code Sent ✓'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('recovery_code')),
      MockAuthRepository.demoRecoveryCode,
    );
    await pumpFrames(tester);
    expect(find.byKey(const Key('recovery_password')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('recovery_password')),
      'BrandNew123!',
    );
    await tester.enterText(
      find.byKey(const Key('recovery_confirm')),
      'BrandNew123!',
    );
    await tapVisible(tester, find.byKey(const Key('recovery_update')));
    await pumpFrames(tester);
    expect(find.byKey(const Key('recovery_success')), findsOneWidget);
  });

  group('role-based routing', () {
    testWidgets('unauthenticated users are redirected to login', (
      tester,
    ) async {
      await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
      _navigator(tester).pushNamed(RouteNames.studentCourses);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsWidgets);

      _navigator(tester).pushNamed(RouteNames.departments);
      await tester.pumpAndSettle();
      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });

    testWidgets('a student cannot open lecturer or admin screens', (
      tester,
    ) async {
      await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
      await signInAs(tester, UserRole.student);

      _navigator(tester).pushNamed(RouteNames.scheduleClass);
      await pumpFrames(tester);
      expect(find.byType(AccessDeniedScreen), findsOneWidget);

      _navigator(tester).pushNamed(RouteNames.userDetails);
      await pumpFrames(tester);
      expect(find.byType(AccessDeniedScreen), findsNWidgets(1));
    });

    testWidgets('a lecturer cannot open admin screens', (tester) async {
      await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
      await tester.tap(find.byKey(const Key('login_role_lecturer')));
      await tester.pump();
      await signInAs(tester, UserRole.lecturer);
      _navigator(tester).pushNamed(RouteNames.adminReports);
      await pumpFrames(tester);
      expect(find.byType(AccessDeniedScreen), findsOneWidget);
    });

    test('route prefixes map to roles', () {
      expect(AppRouter.requiredRole(RouteNames.studentHome), UserRole.student);
      expect(AppRouter.requiredRole(RouteNames.whiteboard), UserRole.lecturer);
      expect(AppRouter.requiredRole(RouteNames.faculties), UserRole.admin);
      expect(AppRouter.requiredRole(RouteNames.adminLogin), isNull);
      expect(AppRouter.requiresAuth(RouteNames.notifications), isTrue);
      expect(AppRouter.requiresAuth(RouteNames.login), isFalse);
      expect(AppRouter.homeFor(UserRole.admin), RouteNames.adminDashboard);
    });
  });

  testWidgets('a remembered session skips login on restart', (tester) async {
    final store = onboardedStore();
    await pumpApp(tester, deps: testDependencies(store: store));
    await signInAs(tester, UserRole.student);
    expect(find.byType(StudentNavigation), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, deps: testDependencies(store: store));
    expect(find.byType(StudentNavigation), findsOneWidget);
  });
}
