import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/features/authentication/presentation/login_screen.dart';
import 'package:smart_class/features/onboarding/presentation/attendance_intro_screen.dart';
import 'package:smart_class/features/onboarding/presentation/participation_intro_screen.dart';
import 'package:smart_class/features/onboarding/presentation/role_selection_screen.dart';
import 'package:smart_class/features/onboarding/presentation/welcome_screen.dart';
import 'package:smart_class/models/user_model.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('first launch walks through onboarding to the login screen', (
    tester,
  ) async {
    final deps = await pumpApp(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Welcome to Smart Class'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceIntroScreen), findsOneWidget);
    expect(find.text('Automatic Attendance'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.byType(ParticipationIntroScreen), findsOneWidget);
    expect(find.text('Interactive Participation'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(await deps.storage.isOnboardingCompleted(), isTrue);

    await tester.ensureVisible(find.byKey(const Key('portal_lecturer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('portal_lecturer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('role_continue')));
    await pumpFrames(tester);

    final login = tester.widget<LoginScreen>(find.byType(LoginScreen));
    expect(login.initialRole, UserRole.lecturer);
    expect(await deps.storage.getSelectedRole(), UserRole.lecturer);
  });

  testWidgets('Back returns to the previous onboarding page', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('Skip jumps straight to role selection', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('onboarding_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
  });

  testWidgets('returning users skip onboarding', (tester) async {
    await pumpApp(tester, deps: testDependencies(store: onboardedStore()));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('onboarding fits a small phone without overflow', (tester) async {
    await pumpApp(tester, size: kSmallPhoneSize);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
