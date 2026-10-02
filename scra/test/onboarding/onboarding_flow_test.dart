import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/core/constants/app_constants.dart';
import 'package:smart_class/features/authentication/presentation/admin_login_screen.dart';
import 'package:smart_class/features/authentication/presentation/login_screen.dart';
import 'package:smart_class/features/onboarding/presentation/splash_screen.dart';
import 'package:smart_class/models/user_model.dart';
import 'package:smart_class/services/storage_service.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('first launch goes from the logo straight to login', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.textContaining('EduVerse'), findsNothing);
  });

  testWidgets('returning lecturer lands on the lecturer login', (tester) async {
    await pumpApp(
      tester,
      deps: testDependencies(
        store: InMemoryStore({StorageKeys.selectedRole: 'lecturer'}),
      ),
    );
    final login = tester.widget<LoginScreen>(find.byType(LoginScreen));
    expect(login.initialRole, UserRole.lecturer);
  });

  testWidgets('returning admin lands on the admin login', (tester) async {
    await pumpApp(
      tester,
      deps: testDependencies(
        store: InMemoryStore({StorageKeys.selectedRole: 'admin'}),
      ),
    );
    expect(find.byType(AdminLoginScreen), findsOneWidget);
  });

  testWidgets('login fits a small phone without overflow', (tester) async {
    await pumpApp(tester, size: kSmallPhoneSize);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
