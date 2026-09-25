import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/features/authentication/providers/auth_provider.dart';
import 'package:smart_class/models/user_model.dart';

import '../fakes/mock_auth_repository.dart';
import '../fakes/mock_data_store.dart';

import 'package:smart_class/services/auth_service.dart';
import 'package:smart_class/services/storage_service.dart';

void main() {
  late InMemoryStore store;
  late StorageService storage;
  late AuthProvider auth;

  AuthProvider buildProvider() {
    final data = MockDataStore();
    return AuthProvider(
      repository: MockAuthRepository(data, latency: Duration.zero),
      authService: AuthService(storage),
      storage: storage,
    );
  }

  setUp(() {
    store = InMemoryStore();
    storage = StorageService(store);
    auth = buildProvider();
  });

  group('login', () {
    test('student signs in with matricule', () async {
      final ok = await auth.login(
        role: UserRole.student,
        identifier: DemoAccounts.studentId,
        password: DemoAccounts.password,
      );
      expect(ok, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.role, UserRole.student);
      expect(auth.user?.fullName, 'Konga Mac-Bright');
    });

    test('lecturer signs in with institutional email', () async {
      final ok = await auth.login(
        role: UserRole.lecturer,
        identifier: DemoAccounts.lecturerEmail,
        password: DemoAccounts.password,
      );
      expect(ok, isTrue);
      expect(auth.role, UserRole.lecturer);
    });

    test('admin signs in with admin ID (case-insensitive)', () async {
      final ok = await auth.login(
        role: UserRole.admin,
        identifier: DemoAccounts.adminId.toLowerCase(),
        password: DemoAccounts.password,
      );
      expect(ok, isTrue);
      expect(auth.role, UserRole.admin);
    });

    test('wrong password is rejected with a readable error', () async {
      final ok = await auth.login(
        role: UserRole.student,
        identifier: DemoAccounts.studentId,
        password: 'WrongPass1',
      );
      expect(ok, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.errorMessage, contains('Invalid'));
    });

    test('credentials cannot be used on another role portal', () async {
      final ok = await auth.login(
        role: UserRole.admin,
        identifier: DemoAccounts.studentId,
        password: DemoAccounts.password,
      );
      expect(ok, isFalse);
      expect(auth.role, isNull);
    });
  });

  group('session persistence', () {
    test('remember me persists the session across restarts', () async {
      await auth.login(
        role: UserRole.lecturer,
        identifier: DemoAccounts.lecturerId,
        password: DemoAccounts.password,
        rememberMe: true,
      );
      final restarted = buildProvider();
      await restarted.bootstrap();
      expect(restarted.isAuthenticated, isTrue);
      expect(restarted.role, UserRole.lecturer);
      expect(restarted.selectedRole, UserRole.lecturer);
    });

    test('without remember me the session is not persisted', () async {
      await auth.login(
        role: UserRole.student,
        identifier: DemoAccounts.studentId,
        password: DemoAccounts.password,
        rememberMe: false,
      );
      final restarted = buildProvider();
      await restarted.bootstrap();
      expect(restarted.isAuthenticated, isFalse);
      expect(restarted.status, AuthStatus.unauthenticated);
    });

    test('logout clears the session', () async {
      await auth.login(
        role: UserRole.student,
        identifier: DemoAccounts.studentId,
        password: DemoAccounts.password,
      );
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(await storage.getSession(), isNull);
      final restarted = buildProvider();
      await restarted.bootstrap();
      expect(restarted.isAuthenticated, isFalse);
    });

    test('onboarding completion and role selection are stored', () async {
      await auth.completeOnboarding();
      await auth.selectRole(UserRole.admin);
      final restarted = buildProvider();
      await restarted.bootstrap();
      expect(restarted.onboardingCompleted, isTrue);
      expect(restarted.selectedRole, UserRole.admin);
    });
  });

  group('account setup', () {
    test('student activation signs the student in', () async {
      final ok = await auth.activateStudent(
        matricule: 'mat-2024-9148',
        email: 'alex.rivers@campus.edu',
        password: 'Secure123!',
      );
      expect(ok, isTrue);
      expect(auth.role, UserRole.student);
    });

    test(
      'activation rejects an email that does not match the matricule',
      () async {
        final ok = await auth.activateStudent(
          matricule: DemoAccounts.studentId,
          email: 'someone.else@campus.edu',
          password: 'Secure123!',
        );
        expect(ok, isFalse);
        expect(auth.errorMessage, contains('does not match'));
      },
    );

    test('lecturer registration signs the lecturer in', () async {
      final ok = await auth.registerLecturer(
        staffId: 'FAC-2025-0001',
        email: 'new.lecturer@faculty.edu',
        password: 'Secure123!',
      );
      expect(ok, isTrue);
      expect(auth.role, UserRole.lecturer);
    });
  });

  group('password recovery', () {
    test('reset flow updates the password', () async {
      const email = DemoAccounts.studentEmail;
      expect(await auth.requestPasswordReset(email), isTrue);
      expect(
        await auth.verifyResetCode(email, '0000'),
        isFalse,
        reason: 'wrong code must fail',
      );
      expect(
        await auth.verifyResetCode(email, MockAuthRepository.demoRecoveryCode),
        isTrue,
      );
      expect(
        await auth.resetPassword(
          email: email,
          code: MockAuthRepository.demoRecoveryCode,
          newPassword: 'BrandNew123!',
        ),
        isTrue,
      );
      expect(
        await auth.login(
          role: UserRole.student,
          identifier: email,
          password: 'BrandNew123!',
        ),
        isTrue,
      );
    });
  });
}
