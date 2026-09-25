import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockAuthRepository extends MockRepositoryBase implements AuthRepository {
  MockAuthRepository(this._store, {super.latency});

  final MockDataStore _store;
  final Map<String, String> _resetCodes = {};

  /// Recovery code issued by the mock (exposed for tests / demo).
  static const String demoRecoveryCode = '8429';

  UserModel? _findUser(UserRole role, String identifier) {
    final id = identifier.trim().toLowerCase();
    switch (role) {
      case UserRole.student:
        for (final s in _store.students.values) {
          if (s.matricule.toLowerCase() == id ||
              s.user.email.toLowerCase() == id) {
            return s.user;
          }
        }
      case UserRole.lecturer:
        for (final l in _store.lecturers.values) {
          if (l.staffId.toLowerCase() == id ||
              l.user.email.toLowerCase() == id) {
            return l.user;
          }
        }
      case UserRole.admin:
        for (final a in _store.admins.values) {
          if (a.adminId.toLowerCase() == id ||
              a.user.email.toLowerCase() == id) {
            return a.user;
          }
        }
    }
    return null;
  }

  AuthSessionModel _session(UserModel user) => AuthSessionModel(
        user: user,
        accessToken: 'mock-token-${user.id}-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock-refresh-${user.id}',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );

  @override
  Future<AuthSessionModel> login({
    required UserRole role,
    required String identifier,
    required String password,
  }) =>
      delay(() {
        final user = _findUser(role, identifier);
        if (user == null || _store.passwords[user.id] != password) {
          throw const AuthException(
            'Invalid institutional ID or password for this portal.',
          );
        }
        if (!user.isActive) {
          throw const ForbiddenException(
            'This account has been deactivated. Contact your administrator.',
          );
        }
        final active = user.copyWith(lastActiveAt: DateTime.now());
        _store.users[user.id] = active;
        return _session(active);
      });

  @override
  Future<AuthSessionModel> activateStudent({
    required String matricule,
    required String email,
    required String password,
  }) =>
      delay(() {
        final existing = _findUser(UserRole.student, matricule);
        if (existing != null) {
          if (existing.email.toLowerCase() != email.trim().toLowerCase()) {
            throw const ValidationException(
              'The email does not match the matricule on record.',
            );
          }
          _store.passwords[existing.id] = password;
          return _session(existing);
        }
        final id = _store.nextId('stu');
        final user = UserModel(
          id: id,
          fullName: email.split('@').first.replaceAll('.', ' '),
          email: email.trim(),
          role: UserRole.student,
          createdAt: DateTime.now(),
        );
        _store.users[id] = user;
        _store.passwords[id] = password;
        _store.students[id] = StudentModel(
          user: user,
          matricule: matricule.trim().toUpperCase(),
          programme: 'Undeclared',
          level: 100,
          semester: 1,
        );
        return _session(user);
      });

  @override
  Future<AuthSessionModel> registerLecturer({
    required String staffId,
    required String email,
    required String password,
  }) =>
      delay(() {
        final existing = _findUser(UserRole.lecturer, staffId);
        if (existing != null) {
          _store.passwords[existing.id] = password;
          return _session(existing);
        }
        final id = _store.nextId('lec');
        final user = UserModel(
          id: id,
          fullName: email.split('@').first.replaceAll('.', ' '),
          email: email.trim(),
          role: UserRole.lecturer,
          createdAt: DateTime.now(),
        );
        _store.users[id] = user;
        _store.passwords[id] = password;
        _store.lecturers[id] = LecturerModel(
          user: user,
          staffId: staffId.trim().toUpperCase(),
          title: 'Dr.',
        );
        return _session(user);
      });

  UserModel? _userByEmail(String email) {
    final e = email.trim().toLowerCase();
    for (final u in _store.users.values) {
      if (u.email.toLowerCase() == e) return u;
    }
    return null;
  }

  @override
  Future<void> requestPasswordReset(String email) => delay(() {
        // Always succeeds so the UI never reveals whether an account exists.
        _resetCodes[email.trim().toLowerCase()] = demoRecoveryCode;
      });

  @override
  Future<void> verifyResetCode({required String email, required String code}) =>
      delay(() {
        if (_resetCodes[email.trim().toLowerCase()] != code) {
          throw const ValidationException('The recovery code is incorrect.');
        }
      });

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      delay(() {
        final key = email.trim().toLowerCase();
        if (_resetCodes[key] != code) {
          throw const ValidationException('The recovery code is incorrect.');
        }
        final user = _userByEmail(email);
        if (user != null) _store.passwords[user.id] = newPassword;
        _resetCodes.remove(key);
      });

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      delay(() {});

  @override
  Future<void> logout() => delay(() {});
}
