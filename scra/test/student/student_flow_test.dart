import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/features/authentication/presentation/login_screen.dart';
import 'package:smart_class/models/models.dart';

import '../helpers/test_app.dart';

Future<void> _loginStudent(
  WidgetTester tester, {
  Size size = kPhoneSize,
}) async {
  await pumpApp(
    tester,
    deps: testDependencies(store: onboardedStore()),
    size: kPhoneSize,
  );
  await signInAs(tester, UserRole.student);
  await pumpFrames(tester, 12);
  if (size != kPhoneSize) {
    setViewport(tester, size);
    await pumpFrames(tester, 4);
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tapVisible(tester, find.text(text).first);
  await pumpFrames(tester, 8);
}

Future<void> _tapContains(WidgetTester tester, String text) async {
  await tapVisible(tester, find.textContaining(text).first);
  await pumpFrames(tester, 8);
}

Future<void> _popRoute(WidgetTester tester, [int frames = 6]) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await pumpFrames(tester, frames);
}

void main() {
  testWidgets(
    'student full path covers classroom, question, attendance, notifications, profile and settings',
    (tester) async {
      await _loginStudent(tester);

      expect(find.text('My Classes'), findsOneWidget);
      await _tapContains(tester, 'View All');
      expect(find.text('My Courses'), findsOneWidget);

      await _tapText(tester, 'View Course');
      expect(find.text('Course Details'), findsOneWidget);
      await _popRoute(tester);
      await _popRoute(tester);

      await _tapText(tester, 'Schedule');
      expect(find.text('Schedule'), findsWidgets);
      await _tapText(tester, 'Home');
      await tester.tap(find.byKey(const Key('join_live_session')).first);
      await pumpFrames(tester, 18);
      expect(find.textContaining('Attendance Logged'), findsWidgets);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
      await pumpFrames(tester, 10);
      expect(find.text('Classroom Chat'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('chat_input')),
        'Great explanation, Prof.',
      );
      await tester.tap(find.byKey(const Key('chat_send')));
      await pumpFrames(tester, 12);
      expect(find.text('Great explanation, Prof.'), findsOneWidget);
      await _popRoute(tester, 8);

      await tester.tap(find.byIcon(Icons.quiz_outlined).last);
      await pumpFrames(tester, 10);
      await tester.tap(find.byKey(const Key('question_option_C')));
      await pumpFrames(tester, 2);
      await tapVisible(tester, find.byKey(const Key('submit_answer')));
      await pumpFrames(tester, 12);
      expect(find.text('Response Synced to Session'), findsOneWidget);
      await _popRoute(tester);
      await _popRoute(tester, 8);

      await _tapText(tester, 'Attendance');
      expect(find.text('My Attendance'), findsOneWidget);
      await _tapContains(tester, 'Absent');
      expect(find.textContaining('Submit Medical Slip'), findsWidgets);

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pushNamed(RouteNames.notifications);
      await pumpFrames(tester, 10);
      expect(find.text('Notifications'), findsOneWidget);
      await _tapText(tester, 'Classes');
      await _popRoute(tester);

      await _tapText(tester, 'Profile');
      expect(find.text('Student Profile'), findsOneWidget);
      await _tapText(tester, 'Settings / Change Password');
      expect(find.text('Settings'), findsOneWidget);
      final firstSwitch = find.byType(Switch).first;
      await tester.tap(firstSwitch);
      await pumpFrames(tester, 6);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('absent attendance appeal submits deterministically', (
    tester,
  ) async {
    await _loginStudent(tester);
    await _tapText(tester, 'Attendance');
    await _tapContains(tester, 'Absent');
    await _tapContains(tester, 'Submit Medical Slip');
    expect(find.text('Attendance Review'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'doctor-note.pdf');
    await tester.tap(find.text('Submit for Faculty Approval'));
    await pumpFrames(tester, 10);
    expect(find.text('Review request opened'), findsOneWidget);
  });

  testWidgets('profile logout returns to login screen', (tester) async {
    await _loginStudent(tester);
    await _tapText(tester, 'Profile');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign Out'));
    await pumpFrames(tester, 4);
    expect(find.text('Log out of Smart Class?'), findsOneWidget);
    await tester.tap(find.text('Log Out').last);
    await pumpFrames(tester, 60);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('student main screens do not overflow on a small phone', (
    tester,
  ) async {
    await _loginStudent(tester, size: kSmallPhoneSize);
    expect(tester.takeException(), isNull);

    await _tapContains(tester, 'View All');
    expect(tester.takeException(), isNull);

    await _tapText(tester, 'View Course');
    expect(tester.takeException(), isNull);
    await _popRoute(tester, 4);
    await _popRoute(tester, 4);

    await _tapText(tester, 'Schedule');
    expect(tester.takeException(), isNull);

    await _tapText(tester, 'Home');
    await tester.tap(find.byKey(const Key('join_live_session')).first);
    await pumpFrames(tester, 14);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
    await pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);
    await _popRoute(tester, 6);

    await tester.tap(find.byIcon(Icons.quiz_outlined).last);
    await pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);
    await _popRoute(tester, 4);
    await _popRoute(tester, 6);

    await _tapText(tester, 'Attendance');
    expect(tester.takeException(), isNull);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed(RouteNames.notifications);
    await pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);
    await _popRoute(tester, 4);

    await _tapText(tester, 'Profile');
    expect(tester.takeException(), isNull);
    await _tapText(tester, 'Settings / Change Password');
    expect(tester.takeException(), isNull);
  });
}
