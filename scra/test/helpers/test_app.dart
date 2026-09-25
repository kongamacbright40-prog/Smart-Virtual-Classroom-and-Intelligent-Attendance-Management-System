import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/app.dart';
import 'package:smart_class/core/constants/app_constants.dart';
import 'package:smart_class/core/di/app_dependencies.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/models/user_model.dart';
import 'package:smart_class/repositories/mock/mock_data_store.dart';
import 'package:smart_class/services/storage_service.dart';

/// Standard Android phone viewport used by widget tests (Pixel 7-ish).
const Size kPhoneSize = Size(412, 915);

/// Small Android phone viewport for overflow checks.
const Size kSmallPhoneSize = Size(360, 640);

void setViewport(WidgetTester tester, [Size size = kPhoneSize]) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Mock dependency graph with no artificial latency or background timers.
AppDependencies testDependencies({InMemoryStore? store}) =>
    AppDependencies.mock(
      storage: StorageService(store ?? InMemoryStore()),
      latency: Duration.zero,
      simulateLiveActivity: false,
    );

/// Pumps the full app and waits past the splash screen.
Future<AppDependencies> pumpApp(
  WidgetTester tester, {
  AppDependencies? deps,
  Size size = kPhoneSize,
}) async {
  setViewport(tester, size);
  final dependencies = deps ?? testDependencies();
  await tester.pumpWidget(SmartClassApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 500));
  return dependencies;
}

/// Pumps a few frames (for screens with indeterminate indicators where
/// `pumpAndSettle` would never settle).
Future<void> pumpFrames(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Signs in with a demo account through the real UI and lands on the
/// role home screen.
Future<void> signInAs(WidgetTester tester, UserRole role) async {
  final (identifier, route) = switch (role) {
    UserRole.student => (DemoAccounts.studentId, RouteNames.login),
    UserRole.lecturer => (DemoAccounts.lecturerId, RouteNames.login),
    UserRole.admin => (DemoAccounts.adminId, RouteNames.adminLogin),
  };
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.pushNamedAndRemoveUntil(
    route,
    (_) => false,
    arguments: role == UserRole.admin ? null : role,
  );
  await pumpFrames(tester);
  await tester.enterText(find.byKey(const Key('login_identifier')), identifier);
  await tester.enterText(
    find.byKey(const Key('login_password')),
    DemoAccounts.password,
  );
  await tapVisible(tester, find.byKey(const Key('login_submit')));
  await pumpFrames(tester, 10);
}

/// Store preloaded as if onboarding was completed earlier.
InMemoryStore onboardedStore() =>
    InMemoryStore({StorageKeys.onboardingCompleted: true});

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump();
}
