import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockAttendanceRepository extends MockRepositoryBase
    implements AttendanceRepository {
  MockAttendanceRepository(this._store, {super.latency});

  final MockDataStore _store;

  final Set<String> appealedRecordIds = {};

  List<AttendanceRecordModel> _studentRecords(String studentId,
          {String? courseId}) =>
      _store.attendance.values
          .where((r) =>
              r.studentId == studentId &&
              (courseId == null || r.courseId == courseId) &&
              _store.sessions[r.sessionId]?.status == SessionStatus.completed)
          .toList()
        ..sort((a, b) => b.sessionStart.compareTo(a.sessionStart));

  @override
  Future<AttendanceModel> getStudentSummary(String studentId,
          {String? courseId}) =>
      delay(() {
        final course = courseId == null ? null : _store.courses[courseId];
        return AttendanceModel.fromRecords(
          studentId,
          _studentRecords(studentId, courseId: courseId),
          courseId: courseId,
          courseCode: course?.code,
          courseTitle: course?.title,
          participationRate: 90,
          requiredPercentage: _store.systemSettings.minimumAttendance,
        );
      });

  @override
  Future<List<AttendanceRecordModel>> getStudentRecords(String studentId,
          {String? courseId}) =>
      delay(() => _studentRecords(studentId, courseId: courseId));

  @override
  Future<List<AttendanceRecordModel>> getSessionAttendance(String sessionId) =>
      delay(() => _store.sessionAttendance(sessionId));

  @override
  Future<List<AttendanceModel>> getCourseSummaries(String courseId) =>
      delay(() {
        final ids = _store.enrollments[courseId] ?? const [];
        return ids.map((id) {
          final records = _studentRecords(id, courseId: courseId);
          return AttendanceModel.fromRecords(
            id,
            records,
            courseId: courseId,
            requiredPercentage: _store.systemSettings.minimumAttendance,
          );
        }).toList();
      });

  ClassSessionModel _updateSession(String sessionId, bool active) {
    final s = _store.sessions[sessionId];
    if (s == null) throw const NotFoundException('Class session not found.');
    final updated = s.copyWith(attendanceActive: active);
    _store.sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<ClassSessionModel> startAttendance(String sessionId) =>
      delay(() => _updateSession(sessionId, true));

  @override
  Future<ClassSessionModel> endAttendance(String sessionId) => delay(() {
        final updated = _updateSession(sessionId, false);
        // Everyone without a record is marked absent when capture ends.
        final session = _store.sessions[sessionId]!;
        for (final studentId in _store.enrollments[session.courseId] ?? const <String>[]) {
          final id = 'att-$sessionId-$studentId';
          _store.attendance.putIfAbsent(id, () {
            final student = _store.students[studentId]!;
            return AttendanceRecordModel(
              id: id,
              sessionId: sessionId,
              studentId: studentId,
              studentName: student.user.fullName,
              matricule: student.matricule,
              courseId: session.courseId,
              courseCode: session.courseCode,
              courseTitle: session.courseTitle,
              status: AttendanceStatus.absent,
              sessionStart: session.startTime,
              sessionMinutes: session.duration.inMinutes,
              verificationMethod: 'No Check-in Recorded',
            );
          });
        }
        _emit(sessionId);
        return updated;
      });

  @override
  Future<AttendanceRecordModel> markAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) =>
      delay(() {
        final session = _store.sessions[sessionId];
        final student = _store.students[studentId];
        if (session == null || student == null) {
          throw const NotFoundException('Session or student not found.');
        }
        final id = 'att-$sessionId-$studentId';
        final existing = _store.attendance[id];
        final record = existing?.copyWith(
              status: status,
              note: 'Adjusted manually by lecturer',
            ) ??
            AttendanceRecordModel(
              id: id,
              sessionId: sessionId,
              studentId: studentId,
              studentName: student.user.fullName,
              matricule: student.matricule,
              courseId: session.courseId,
              courseCode: session.courseCode,
              courseTitle: session.courseTitle,
              status: status,
              sessionStart: session.startTime,
              checkedInAt: status.countsAsAttended ? DateTime.now() : null,
              sessionMinutes: session.duration.inMinutes,
              verificationMethod: 'Manual Check-in',
              note: 'Adjusted manually by lecturer',
            );
        _store.attendance[id] = record;
        _emit(sessionId);
        return record;
      });

  @override
  Future<AttendanceRecordModel> checkIn({
    required String sessionId,
    required String studentId,
  }) =>
      delay(() {
        final session = _store.sessions[sessionId];
        final student = _store.students[studentId];
        if (session == null || student == null) {
          throw const NotFoundException('Session or student not found.');
        }
        final id = 'att-$sessionId-$studentId';
        final existing = _store.attendance[id];
        if (existing != null && existing.status.countsAsAttended) {
          return existing;
        }
        final now = DateTime.now();
        final lateAfter = Duration(
          minutes: _store.systemSettings.lateThresholdMinutes,
        );
        final isLate = now.isAfter(session.startTime.add(lateAfter));
        final record = AttendanceRecordModel(
          id: id,
          sessionId: sessionId,
          studentId: studentId,
          studentName: student.user.fullName,
          matricule: student.matricule,
          courseId: session.courseId,
          courseCode: session.courseCode,
          courseTitle: session.courseTitle,
          status: isLate ? AttendanceStatus.late : AttendanceStatus.present,
          sessionStart: session.startTime,
          checkedInAt: now,
          sessionMinutes: session.duration.inMinutes,
          verificationMethod: 'Virtual classroom join',
          lecturerName: session.lecturerName,
          room: session.room,
        );
        _store.attendance[id] = record;
        _emit(sessionId);
        return record;
      });

  @override
  Future<void> submitAppeal({
    required String recordId,
    required String reason,
    String? documentName,
  }) =>
      delay(() {
        if (!_store.attendance.containsKey(recordId)) {
          throw const NotFoundException('Attendance record not found.');
        }
        if (reason.trim().isEmpty) {
          throw const ValidationException('Select a reason for the appeal.');
        }
        appealedRecordIds.add(recordId);
      });

  void _emit(String sessionId) =>
      _store.attendanceChannel(sessionId).add(_store.sessionAttendance(sessionId));

  @override
  Stream<List<AttendanceRecordModel>> watchSessionAttendance(String sessionId) =>
      _store.attendanceChannel(sessionId).stream;
}
