import 'package:smart_class/core/errors/app_exception.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';

import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockAdminRepository extends MockRepositoryBase
    implements AdminRepository {
  MockAdminRepository(this._store, {super.latency});

  final MockDataStore _store;

  @override
  Future<List<UserModel>> getUsers({UserRole? role, String? query}) =>
      delay(() {
        final q = query?.trim().toLowerCase() ?? '';
        return _store.users.values.where((u) {
          if (role != null && u.role != role) return false;
          if (q.isEmpty) return true;
          final ident = switch (u.role) {
            UserRole.student => _store.students[u.id]?.matricule,
            UserRole.lecturer => _store.lecturers[u.id]?.staffId,
            UserRole.admin => _store.admins[u.id]?.adminId,
          };
          return u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              (ident?.toLowerCase().contains(q) ?? false);
        }).toList()..sort((a, b) {
          final r = a.role.index.compareTo(b.role.index);
          return r != 0 ? -r : a.fullName.compareTo(b.fullName);
        });
      });

  /// Institutional identifier (matricule / staff ID / admin ID) for a user.
  String? identifierFor(String userId) =>
      _store.students[userId]?.matricule ??
      _store.lecturers[userId]?.staffId ??
      _store.admins[userId]?.adminId;

  @override
  Future<List<ClassSessionModel>> getLiveSessions() => delay(
    () => _store.sessions.values
        .where((s) => s.status == SessionStatus.live)
        .toList(),
  );

  @override
  Future<UserModel> getUser(String userId) => delay(() {
    final u = _store.users[userId];
    if (u == null) throw const NotFoundException('User not found.');
    return u;
  });

  @override
  Future<UserModel> createUser(UserModel user, {String? password}) => delay(() {
    final exists = _store.users.values.any(
      (u) => u.email.toLowerCase() == user.email.toLowerCase(),
    );
    if (exists) {
      throw const ValidationException('A user with this email already exists.');
    }
    final prefix = switch (user.role) {
      UserRole.student => 'stu',
      UserRole.lecturer => 'lec',
      UserRole.admin => 'adm',
    };
    final id = _store.nextId(prefix);
    final created = UserModel(
      id: id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      phone: user.phone,
      departmentId: user.departmentId,
      departmentName:
          _store.departments[user.departmentId]?.name ?? user.departmentName,
      createdAt: DateTime.now(),
    );
    _store.users[id] = created;
    switch (created.role) {
      case UserRole.student:
        _store.students[id] = StudentModel(
          user: created,
          matricule: 'ICT${DateTime.now().year}${id.split('-').last}',
          programme: created.departmentName ?? 'Undeclared',
          level: 100,
          semester: 1,
        );
      case UserRole.lecturer:
        _store.lecturers[id] = LecturerModel(
          user: created,
          staffId: 'FAC-${DateTime.now().year}-${id.split('-').last}',
          title: 'Dr.',
        );
      case UserRole.admin:
        _store.admins[id] = AdminModel(
          user: created,
          adminId: 'ADM-${id.split('-').last}',
          accessLevel: AdminAccessLevel.departmental,
        );
    }
    _store.activity.insert(
      0,
      ActivityLogModel(
        id: _store.nextId('act'),
        title: 'User created',
        description: '${created.fullName} (${created.role.label}) was added.',
        timestamp: DateTime.now(),
        actorName: 'System Administrator',
        severity: ActivitySeverity.success,
        category: 'users',
      ),
    );
    return created;
  });

  @override
  Future<UserModel> updateUser(UserModel user) => delay(() {
    if (!_store.users.containsKey(user.id)) {
      throw const NotFoundException('User not found.');
    }
    _store.users[user.id] = user;
    return user;
  });

  @override
  Future<UserModel> setUserActive(String userId, bool active) => delay(() {
    final u = _store.users[userId];
    if (u == null) throw const NotFoundException('User not found.');
    final updated = u.copyWith(isActive: active);
    _store.users[userId] = updated;
    return updated;
  });

  @override
  Future<void> deleteUser(String userId) => delay(() {
    if (userId == MockDataStore.currentAdminId) {
      throw const ForbiddenException('You cannot delete your own account.');
    }
    _store.users.remove(userId);
    _store.students.remove(userId);
    _store.lecturers.remove(userId);
    _store.admins.remove(userId);
  });

  @override
  Future<List<FacultyModel>> getFaculties() =>
      delay(() => _store.faculties.values.toList());

  @override
  Future<FacultyModel> createFaculty(String name) => delay(() {
    final trimmed = name.trim();
    if (_store.faculties.values.any(
      (f) => f.name.toLowerCase() == trimmed.toLowerCase(),
    )) {
      throw const ValidationException('Faculty already exists.');
    }
    final id = _store.nextId('fac');
    final faculty = FacultyModel(id: id, name: trimmed, code: id.toUpperCase());
    _store.faculties[id] = faculty;
    return faculty;
  });

  @override
  Future<List<DepartmentModel>> getDepartments({String? facultyId}) => delay(
    () => _store.departments.values
        .where((d) => facultyId == null || d.facultyId == facultyId)
        .toList(),
  );

  @override
  Future<DepartmentModel> saveDepartment(DepartmentModel department) =>
      delay(() {
        final id = department.id.isEmpty ? _store.nextId('dep') : department.id;
        final saved = DepartmentModel(
          id: id,
          name: department.name,
          code: department.code.toUpperCase(),
          facultyId: department.facultyId,
          facultyName: _store.faculties[department.facultyId]?.name,
          description: department.description,
          headName: department.headName,
          courseCount: department.courseCount,
          studentCount: department.studentCount,
          staffCount: department.staffCount,
          liveSessions: department.liveSessions,
          averageAttendance: department.averageAttendance,
          isActive: department.isActive,
        );
        _store.departments[id] = saved;
        return saved;
      });

  @override
  Future<DepartmentModel> archiveDepartment(String departmentId) => delay(() {
    final d = _store.departments[departmentId];
    if (d == null) throw const NotFoundException('Department not found.');
    final updated = d.copyWith(isActive: false);
    _store.departments[departmentId] = updated;
    return updated;
  });

  @override
  Future<List<AcademicTermModel>> getAcademicTerms() => delay(
    () =>
        _store.terms.values.toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate)),
  );

  @override
  Future<AcademicTermModel> saveAcademicTerm(AcademicTermModel term) =>
      delay(() {
        if (!term.endDate.isAfter(term.startDate)) {
          throw const ValidationException('End date must be after start date.');
        }
        final id = term.id.isEmpty ? _store.nextId('term') : term.id;
        final saved = AcademicTermModel(
          id: id,
          name: term.name,
          code: term.code,
          academicYear: term.academicYear,
          startDate: term.startDate,
          endDate: term.endDate,
          status: term.status,
          termType: term.termType,
          teachingDays: term.teachingDays,
          enrollmentOpen: term.enrollmentOpen,
          addDropDeadline: term.addDropDeadline,
          enrolledStudents: term.enrolledStudents,
          courseCount: term.courseCount,
          averageAttendance: term.averageAttendance,
          notes: term.notes,
        );
        _store.terms[id] = saved;
        return saved;
      });

  @override
  Future<SystemSettingsModel> getSystemSettings() =>
      delay(() => _store.systemSettings);

  @override
  Future<SystemSettingsModel> updateSystemSettings(
    SystemSettingsModel settings,
  ) => delay(() {
    if (settings.participationWeight < 0 ||
        settings.participationWeight > 100) {
      throw const ValidationException(
        'Participation weight must be between 0 and 100%.',
      );
    }
    _store.systemSettings = settings;
    return settings;
  });

  @override
  Future<List<ActivityLogModel>> getRecentActivity({int limit = 20}) =>
      delay(() => _store.activity.take(limit).toList());
}
