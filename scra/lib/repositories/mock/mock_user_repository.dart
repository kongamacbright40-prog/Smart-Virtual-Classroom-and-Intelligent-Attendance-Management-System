import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockUserRepository extends MockRepositoryBase implements UserRepository {
  MockUserRepository(this._store, {super.latency});

  final MockDataStore _store;

  StudentModel _withStats(StudentModel s) {
    final records = _store.attendance.values
        .where((r) => r.studentId == s.id)
        .toList();
    final summary = AttendanceModel.fromRecords(s.id, records);
    final credits = s.enrolledCourseIds
        .map((id) => _store.courses[id]?.credits ?? 0)
        .fold<int>(0, (a, b) => a + b);
    return StudentModel(
      user: _store.users[s.id] ?? s.user,
      matricule: s.matricule,
      programme: s.programme,
      level: s.level,
      semester: s.semester,
      facultyName: s.facultyName,
      enrolledCourseIds: s.enrolledCourseIds,
      overallAttendance: summary.percentage,
      activeCredits: credits == 0 ? s.activeCredits : credits,
      gpa: s.gpa,
      campusPassValid: s.campusPassValid,
    );
  }

  @override
  Future<StudentModel> getStudentProfile(String userId) => delay(() {
    final s = _store.students[userId];
    if (s == null) throw const NotFoundException('Student not found.');
    return _withStats(s);
  });

  @override
  Future<LecturerModel> getLecturerProfile(String userId) => delay(() {
    final l = _store.lecturers[userId];
    if (l == null) throw const NotFoundException('Lecturer not found.');
    return l.copyWith(user: _store.users[userId]);
  });

  @override
  Future<AdminModel> getAdminProfile(String userId) => delay(() {
    final a = _store.admins[userId];
    if (a == null) throw const NotFoundException('Administrator not found.');
    return a.copyWith(user: _store.users[userId]);
  });

  @override
  Future<UserModel> updateProfile(UserModel user) => delay(() {
    if (!_store.users.containsKey(user.id)) {
      throw const NotFoundException('User not found.');
    }
    _store.users[user.id] = user;
    return user;
  });

  @override
  Future<List<StudentModel>> getCourseRoster(String courseId) => delay(() {
    final ids = _store.enrollments[courseId] ?? const [];
    return ids
        .map((id) => _store.students[id])
        .whereType<StudentModel>()
        .map(_withStats)
        .toList()
      ..sort((a, b) => a.user.fullName.compareTo(b.user.fullName));
  });
}
