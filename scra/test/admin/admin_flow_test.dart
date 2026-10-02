import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/features/authentication/presentation/admin_login_screen.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/models/models.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> pumpSignedInAdmin(
    WidgetTester tester, {
    Size size = kPhoneSize,
  }) async {
    await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
      size: size,
    );
    await signInAs(tester, UserRole.admin);
    await pumpFrames(tester, 12);
  }

  testWidgets('admin end-to-end application flow', (tester) async {
    final deps = await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
    );
    await signInAs(tester, UserRole.admin);
    await pumpFrames(tester, 12);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(find.text('Administration Dashboard'), findsOneWidget);

    await tester.tap(find.text('Users'));
    await pumpFrames(tester, 8);
    await tester.enterText(find.byType(TextField).first, 'Konga');
    await pumpFrames(tester, 6);
    await tester.tap(find.textContaining('Students').first);
    await pumpFrames(tester, 6);
    expect(find.text('Konga Mac-Bright'), findsOneWidget);

    await tester.tap(find.byTooltip('User actions').first);
    await pumpFrames(tester, 2);
    await tester.tap(find.text('Edit Account').last);
    await pumpFrames(tester, 8);
    expect(find.text('User Details'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('user_phone')),
      '+233302999999',
    );
    await tester.tap(find.byKey(const Key('save_user')));
    await pumpFrames(tester, 8);

    navigator.pushNamed(RouteNames.userDetails);
    await pumpFrames(tester, 8);
    await tester.enterText(
      find.byKey(const Key('user_full_name')),
      'Test Admin Student',
    );
    await tester.enterText(
      find.byKey(const Key('user_email')),
      'test.admin.student@smartclass.edu.ac',
    );
    await tester.enterText(
      find.byKey(const Key('user_phone')),
      '+233302777777',
    );
    await tapVisible(tester, find.byKey(const Key('save_user')));
    await pumpFrames(tester, 10);
    expect(
      (await deps.adminRepository.getUsers(query: 'Test Admin Student'))
          .single
          .fullName,
      'Test Admin Student',
    );

    navigator.pushNamed(RouteNames.departments);
    await pumpFrames(tester, 8);
    expect(find.text('Campus Structure Overview'), findsOneWidget);

    navigator.pushNamed(RouteNames.academicTerms);
    await pumpFrames(tester, 8);
    expect(find.text('CURRENT SEMESTER', skipOffstage: false), findsWidgets);

    navigator.pushNamedAndRemoveUntil(
      RouteNames.adminDashboard,
      (_) => false,
      arguments: AdminTabs.courses,
    );
    await pumpFrames(tester, 10);
    expect(find.text('Courses'), findsWidgets);
    await tapVisible(tester, find.text('New Course').first);
    await pumpFrames(tester, 4);
    await tester.enterText(find.byKey(const Key('course_code')), 'TST-401');
    await tester.enterText(
      find.byKey(const Key('course_title')),
      'Testing Administration Systems',
    );
    await tester.enterText(find.byKey(const Key('course_credits')), '3');
    await tester.enterText(
      find.byKey(const Key('course_category')),
      'Core Major',
    );
    await tester.tap(find.text('Create Course').last);
    await pumpFrames(tester, 10);
    expect(
      (await deps.courseRepository.getAllCourses(query: 'TST-401')).single.code,
      'TST-401',
    );

    await tester.scrollUntilVisible(
      find.text('EEE-402'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, 2);
    await tester.tap(find.text('Assign Lecturer Now'));
    await pumpFrames(tester, 4);
    await tester.tap(find.text('Prof. Kwame Mensah').last);
    await pumpFrames(tester, 8);
    expect(
      (await deps.courseRepository.getCourse('crs-eee402')).lecturerId,
      isNotNull,
    );

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(RouteNames.adminReports);
    await pumpFrames(tester, 8);
    await tester.tap(find.byKey(const Key('export_report')));
    await pumpFrames(tester, 4);
    await tester.tap(find.text('Export File'));
    await pumpFrames(tester, 8);
    expect(find.textContaining('Export ready'), findsOneWidget);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamedAndRemoveUntil(
          RouteNames.adminDashboard,
          (_) => false,
          arguments: AdminTabs.settings,
        );
    await pumpFrames(tester, 8);
    await tapVisible(tester, find.text('Late Arrival Threshold'));
    await pumpFrames(tester, 4);
    await tester.tap(find.text('20m'));
    await tester.tap(find.byKey(const Key('save_threshold')));
    await pumpFrames(tester, 8);
    expect(
      (await deps.adminRepository.getSystemSettings()).lateThresholdMinutes,
      20,
    );

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(RouteNames.adminProfile);
    await pumpFrames(tester, 8);
    await tester.scrollUntilVisible(
      find.byKey(const Key('admin_logout')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(tester, find.byKey(const Key('admin_logout')));
    await pumpFrames(tester, 3);
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await pumpFrames(tester, 6);
    expect(find.byType(AdminLoginScreen), findsOneWidget);
  });

  testWidgets('admin main screens fit on a small phone', (tester) async {
    await pumpSignedInAdmin(tester, size: kSmallPhoneSize);
    expect(tester.takeException(), isNull);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    for (final route in [
      RouteNames.departments,
      RouteNames.faculties,
      RouteNames.academicTerms,
      RouteNames.adminReports,
      RouteNames.adminProfile,
    ]) {
      navigator.pushNamed(route);
      await pumpFrames(tester, 8);
      expect(tester.takeException(), isNull);
      navigator.pop();
      await pumpFrames(tester, 3);
    }

    navigator.pushNamedAndRemoveUntil(
      RouteNames.adminDashboard,
      (_) => false,
      arguments: AdminTabs.users,
    );
    await pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);
    navigator.pushNamedAndRemoveUntil(
      RouteNames.adminDashboard,
      (_) => false,
      arguments: AdminTabs.courses,
    );
    await pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamedAndRemoveUntil(
          RouteNames.adminDashboard,
          (_) => false,
          arguments: AdminTabs.settings,
        );
    await pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin forms show validation errors', (tester) async {
    await pumpSignedInAdmin(tester);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed(RouteNames.userDetails);
    await pumpFrames(tester, 8);
    await tester.tap(find.byKey(const Key('save_user')));
    await pumpFrames(tester, 4);
    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    // The initial password is optional, but validated when given.
    expect(find.textContaining('Password must be'), findsNothing);
    await tester.enterText(find.byKey(const Key('user_password')), 'abc');
    await tapVisible(tester, find.byKey(const Key('save_user')));
    await pumpFrames(tester, 4);
    expect(find.text('Password must be at least 4 characters'), findsOneWidget);

    navigator.pushNamedAndRemoveUntil(
      RouteNames.adminDashboard,
      (_) => false,
      arguments: AdminTabs.courses,
    );
    await pumpFrames(tester, 8);
    await tapVisible(tester, find.text('New Course').first);
    await pumpFrames(tester, 4);
    await tester.tap(find.text('Create Course').last);
    await pumpFrames(tester, 4);
    expect(find.text('Course code is required'), findsOneWidget);
    expect(find.text('Course title is required'), findsOneWidget);
  });
}
