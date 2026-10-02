import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/features/admin/activity/activity_log_screen.dart';
import 'package:smart_class/features/admin/departments/departments_screen.dart';
import 'package:smart_class/features/admin/departments/faculties_screen.dart';
import 'package:smart_class/features/admin/sessions/live_classes_screen.dart';
import 'package:smart_class/features/student/courses/course_catalog_screen.dart';
import 'package:smart_class/models/user_model.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('student enrolls in and drops a course from the Courses tab', (
    tester,
  ) async {
    final deps = await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
    );
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('Courses').last);
    await pumpFrames(tester, 8);
    await tapVisible(tester, find.byKey(const Key('open_course_catalog')));
    await pumpFrames(tester, 8);
    expect(find.byType(CourseCatalogScreen), findsOneWidget);

    final enrollButton = find.byWidgetPredicate(
      (w) =>
          w is FilledButton &&
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('enroll_'),
    );
    expect(enrollButton, findsWidgets);
    final key = tester.widget<FilledButton>(enrollButton.first).key!;
    final courseId = (key as ValueKey<String>).value.substring(
      'enroll_'.length,
    );

    await tapVisible(tester, find.byKey(key));
    await pumpFrames(tester, 8);
    expect(find.byKey(Key('drop_$courseId')), findsOneWidget);
    final user = deps.authService.currentUser!;
    expect(
      (await deps.courseRepository.getStudentCourses(user.id))
          .any((c) => c.id == courseId),
      isTrue,
    );

    await tapVisible(tester, find.byKey(Key('drop_$courseId')));
    await pumpFrames(tester, 8);
    expect(find.byKey(Key('enroll_$courseId')), findsOneWidget);
  });

  testWidgets('admin can add a faculty and open active classes', (
    tester,
  ) async {
    final deps = await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
    );
    await signInAs(tester, UserRole.admin);

    // Dashboard numbers are tappable.
    await tapVisible(tester, find.text('Active Classes'));
    await pumpFrames(tester, 8);
    expect(find.byType(LiveClassesScreen), findsOneWidget);
    await tester.pageBack();
    await pumpFrames(tester, 8);

    await tapVisible(tester, find.text('Faculties'));
    await pumpFrames(tester, 8);
    expect(find.byType(FacultiesScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('create_faculty')));
    await pumpFrames(tester, 4);
    await tester.enterText(
      find.byKey(const Key('faculty_name')),
      'Faculty of Testing',
    );
    await tester.tap(find.byKey(const Key('faculty_save')));
    await pumpFrames(tester, 8);
    expect(
      (await deps.adminRepository.getFaculties()).any(
        (f) => f.name == 'Faculty of Testing',
      ),
      isTrue,
    );
    expect(find.text('Faculty "Faculty of Testing" created.'), findsOneWidget);
  });

  testWidgets('admin adds a student to a course from Course Details', (
    tester,
  ) async {
    final deps = await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
    );
    await signInAs(tester, UserRole.admin);
    final course = (await deps.courseRepository.getAllCourses()).first;
    final before = await deps.userRepository.getCourseRoster(course.id);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(RouteNames.adminCourseDetails, arguments: course.id);
    await pumpFrames(tester, 10);
    await tapVisible(tester, find.byKey(const Key('course_add_student')));
    await pumpFrames(tester, 8);
    await tester.tap(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListTile),
          )
          .first,
    );
    await pumpFrames(tester, 10);

    final after = await deps.userRepository.getCourseRoster(course.id);
    expect(after.length, before.length + 1);
  });

  testWidgets('admin settings open the full activity log', (tester) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    await signInAs(tester, UserRole.admin);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamedAndRemoveUntil(
          RouteNames.adminDashboard,
          (_) => false,
          arguments: AdminTabs.settings,
        );
    await pumpFrames(tester, 10);
    await tester.scrollUntilVisible(
      find.byKey(const Key('open_activity_log')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tapVisible(tester, find.byKey(const Key('open_activity_log')));
    await pumpFrames(tester, 8);
    expect(find.byType(ActivityLogScreen), findsOneWidget);
    expect(find.textContaining('Geofencing'), findsNothing);
  });

  testWidgets('Departments opened from the dashboard has a back arrow', (
    tester,
  ) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    await signInAs(tester, UserRole.admin);
    await tapVisible(tester, find.text('Add & manage departments'));
    await pumpFrames(tester, 8);
    expect(find.byType(DepartmentsScreen), findsOneWidget);
    expect(find.byKey(const Key('admin_menu')), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await pumpFrames(tester, 8);
    expect(find.byType(DepartmentsScreen), findsNothing);
    expect(find.text('Administration Dashboard'), findsOneWidget);
  });

  testWidgets('create department asks only for name and faculty', (
    tester,
  ) async {
    final deps = await pumpApp(
      tester,
      deps: testDependencies(store: onboardedStore()),
    );
    await signInAs(tester, UserRole.admin);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(RouteNames.departments);
    await pumpFrames(tester, 10);
    await tester.tap(find.byKey(const Key('create_department')));
    await pumpFrames(tester, 6);
    expect(find.text('HOD'), findsNothing);
    expect(find.text('Code'), findsNothing);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('department_name')),
        matching: find.byType(TextFormField),
      ),
      'Cyber Security',
    );
    await tapVisible(tester, find.byKey(const Key('save_department')));
    await pumpFrames(tester, 8);
    expect(
      (await deps.adminRepository.getDepartments()).any(
        (d) => d.name == 'Cyber Security',
      ),
      isTrue,
    );
  });
}
