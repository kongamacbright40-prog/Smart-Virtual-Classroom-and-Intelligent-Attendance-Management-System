import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'package:smart_class/core/di/app_dependencies.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/models/user_model.dart';
import 'package:smart_class/repositories/mock/mock_data_store.dart';

Future<AppDependencies> pumpLecturerApp(
  WidgetTester tester, {
  Size size = kPhoneSize,
}) async {
  final deps = await pumpApp(
    tester,
    deps: testDependencies(store: onboardedStore()),
    size: size,
  );
  await signInAs(tester, UserRole.lecturer);
  await pumpFrames(tester, 10);
  return deps;
}

void main() {
  testWidgets('lecturer can complete the core phase five flow', (tester) async {
    await pumpLecturerApp(tester);
    expect(find.text('Lecturer Dashboard'), findsWidgets);

    await tester.tap(find.text('Courses').last);
    await pumpFrames(tester, 10);
    expect(find.text('Assigned Courses'), findsOneWidget);
    await tapVisible(tester, find.text('Data Structures & Algorithms').first);
    await pumpFrames(tester, 10);
    expect(find.text('Course Management'), findsOneWidget);
    Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
    await pumpFrames(tester, 6);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed(RouteNames.scheduleClass, arguments: 'crs-cs301');
    await pumpFrames(tester, 8);
    await tester.enterText(
      find.byKey(const Key('schedule_topic')),
      'Phase 5 Test Session',
    );
    await tapVisible(tester, find.byKey(const Key('schedule_submit')));
    await pumpFrames(tester, 10);
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await pumpFrames(tester, 4);
    expect(find.text('Class Scheduled!'), findsOneWidget);
    await tapVisible(tester, find.text('View Class'));
    await pumpFrames(tester, 12);
    expect(find.byKey(const Key('end_class')), findsOneWidget);

    navigator.pushNamed(
      RouteNames.createQuestion,
      arguments: MockDataStore.liveSessionId,
    );
    await pumpFrames(tester, 10);
    await tapVisible(tester, find.byKey(const Key('launch_question')));
    await pumpFrames(tester, 8);
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await pumpFrames(tester, 3);
    expect(find.text('Live Broadcast Active'), findsWidgets);
    await tapVisible(tester, find.text('Broadcast Results').last);
    await pumpFrames(tester, 6);

    navigator.pushNamed(
      RouteNames.liveAttendance,
      arguments: MockDataStore.liveSessionId,
    );
    await pumpFrames(tester, 10);
    expect(find.text('Live Attendance'), findsOneWidget);

    navigator.pushNamedAndRemoveUntil(
      RouteNames.lecturerDashboard,
      (_) => false,
      arguments: 3,
    );
    await pumpFrames(tester, 10);
    expect(find.text('Attendance Reports'), findsWidgets);
    navigator.pushNamed(RouteNames.lecturerProfile);
    await pumpFrames(tester, 10);
    expect(find.text('Faculty Profile'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -1600));
    await pumpFrames(tester, 4);
    await tapVisible(tester, find.text('Sign Out of Lecturer Portal'));
    await pumpFrames(tester, 3);
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await pumpFrames(tester, 12);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule form shows required topic validation', (tester) async {
    await pumpLecturerApp(tester);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed(RouteNames.scheduleClass, arguments: 'crs-cs301');
    await pumpFrames(tester, 8);
    await tapVisible(tester, find.byKey(const Key('schedule_submit')));
    await pumpFrames(tester, 4);
    expect(find.text('Session topic is required'), findsOneWidget);
  });

  testWidgets('question form validates short prompts', (tester) async {
    await pumpLecturerApp(tester);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed(
      RouteNames.createQuestion,
      arguments: MockDataStore.liveSessionId,
    );
    await pumpFrames(tester, 10);
    await tester.enterText(find.byKey(const Key('question_prompt')), 'Bad');
    await tapVisible(tester, find.byKey(const Key('launch_question')));
    await pumpFrames(tester, 4);
    expect(find.text('Question is too short'), findsOneWidget);
  });

  testWidgets('main lecturer screens fit on a small phone', (tester) async {
    await pumpLecturerApp(tester, size: kSmallPhoneSize);
    expect(tester.takeException(), isNull);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    for (final route in [
      RouteNames.courseRoster,
      RouteNames.scheduleClass,
      RouteNames.lecturerLiveClassroom,
      RouteNames.whiteboard,
      RouteNames.createQuestion,
      RouteNames.liveAttendance,
      RouteNames.attendanceReports,
      RouteNames.lecturerProfile,
    ]) {
      final argument = switch (route) {
        RouteNames.courseRoster => 'crs-cs301',
        RouteNames.scheduleClass => 'crs-cs301',
        RouteNames.lecturerLiveClassroom => MockDataStore.liveSessionId,
        RouteNames.whiteboard => MockDataStore.liveSessionId,
        RouteNames.createQuestion => MockDataStore.liveSessionId,
        RouteNames.liveAttendance => MockDataStore.liveSessionId,
        RouteNames.attendanceReports => 'crs-cs301',
        _ => null,
      };
      navigator.pushNamed(route, arguments: argument);
      await pumpFrames(tester, 10);
      expect(tester.takeException(), isNull, reason: route);
      navigator.pop();
      await pumpFrames(tester, 4);
    }
  });
}
