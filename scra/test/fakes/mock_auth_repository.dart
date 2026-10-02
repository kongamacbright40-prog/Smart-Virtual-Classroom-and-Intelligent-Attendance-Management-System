import 'package:smart_class/core/errors/app_exception.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';

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
          if (a.adminId?.toLowerCase() == id ||
              a.user.email.toLowerCase() == id) {
            return a.user;
          }
        }
    }
    return null;
  }

  AuthSessionModel _session(UserModel user) => AuthSessionModel(
    user: user,
    accessToken:
        'mock-token-${user.id}-${DateTime.now().millisecondsSinceEpoch}',
    refreshToken: 'mock-refresh-${user.id}',
    expiresAt: DateTime.now().add(const Duration(hours: 12)),
  );

  @override
  Future<AuthSessionModel> login({
    required UserRole role,
    required String identifier,
    required String password,
  }) => delay(() {
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

  /// Code the mock accepts for admin self-registration.
  static const String demoAdminCode = 'ADMIN-CODE';

  @override
  Future<AuthSessionModel> register({
    required UserRole role,
    required String fullName,
    required String email,
    String? phone,
    required String identifier,
    required String password,
    String? departmentId,
    String? adminCode,
  }) => delay(() {
    final idValue = identifier.trim().toUpperCase();
    final existing = _findUser(role, idValue);
    if (existing != null) {
      if (existing.email.toLowerCase() != email.trim().toLowerCase()) {
        throw const ValidationException(
          'The email does not match the ID on record.',
        );
      }
      _store.passwords[existing.id] = password;
      return _session(existing);
    }
    if (role == UserRole.admin && adminCode?.trim() != demoAdminCode) {
      throw const ForbiddenException('Invalid admin registration code');
    }
    final id = _store.nextId(switch (role) {
      UserRole.student => 'stu',
      UserRole.lecturer => 'lec',
      UserRole.admin => 'adm',
    });
    final user = UserModel(
      id: id,
      fullName: fullName.trim(),
      email: email.trim(),
      role: role,
      phone: (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
      departmentId: departmentId,
      departmentName: _store.departments[departmentId]?.name,
      createdAt: DateTime.now(),
    );
    _store.users[id] = user;
    _store.passwords[id] = password;
    switch (role) {
      case UserRole.student:
        _store.students[id] = StudentModel(
          user: user,
          matricule: idValue,
          programme: 'Undeclared',
          level: 100,
          semester: 1,
        );
      case UserRole.lecturer:
        _store.lecturers[id] = LecturerModel(
          user: user,
          staffId: idValue,
          title: 'Dr.',
        );
      case UserRole.admin:
        _store.admins[id] = AdminModel(user: user, adminId: idValue);
    }
    return _session(user);
  });

  @override
  Future<List<DepartmentModel>> getRegistrationDepartments() => delay(
    () =>
        _store.departments.values.where((d) => d.isActive).toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
  );

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
  }) => delay(() {
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
  }) => delay(() {});

  @override
  Future<void> logout() => delay(() {});
}
