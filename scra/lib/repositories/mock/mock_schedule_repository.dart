import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockScheduleRepository extends MockRepositoryBase
    implements ScheduleRepository {
  MockScheduleRepository(this._store, {super.latency});

  final MockDataStore _store;

  List<ClassSessionModel> _between(
    Iterable<String> courseIds,
    DateTime from,
    DateTime to,
  ) {
    final ids = courseIds.toSet();
    return _store.sessions.values
        .where((s) =>
            ids.contains(s.courseId) &&
            !s.endTime.isBefore(from) &&
            s.startTime.isBefore(to))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<ClassSessionModel>> getStudentSessions(
    String studentId, {
    required DateTime from,
    required DateTime to,
  }) =>
      delay(() {
        final student = _store.students[studentId];
        if (student == null) return <ClassSessionModel>[];
        return _between(student.enrolledCourseIds, from, to);
      });

  @override
  Future<List<ClassSessionModel>> getLecturerSessions(
    String lecturerId, {
    required DateTime from,
    required DateTime to,
  }) =>
      delay(() {
        final ids = _store.courses.values
            .where((c) => c.lecturerId == lecturerId)
            .map((c) => c.id);
        return _between(ids, from, to);
      });

  @override
  Future<List<ClassSessionModel>> getCourseSessions(String courseId) =>
      delay(() => _store.sessions.values
          .where((s) => s.courseId == courseId)
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime)));

  @override
  Future<ClassSessionModel> getSession(String sessionId) => delay(() {
        final s = _store.sessions[sessionId];
        if (s == null) throw const NotFoundException('Class session not found.');
        return s;
      });

  @override
  Future<ScheduleModel> scheduleClass(ScheduleModel request) => delay(() {
        final course = _store.courses[request.courseId];
        if (course == null) throw const NotFoundException('Course not found.');
        final end = request.endTime;
        final clash = _store.sessions.values.any((s) =>
            s.lecturerId == course.lecturerId &&
            s.status != SessionStatus.cancelled &&
            s.startTime.isBefore(end) &&
            request.startTime.isBefore(s.endTime));
        if (clash) {
          throw const ValidationException(
            'You already have a class scheduled during this time.',
          );
        }
        final sessionId = _store.nextId('ses');
        final expected = _store.enrollments[course.id]?.length ?? 0;
        _store.sessions[sessionId] = ClassSessionModel(
          id: sessionId,
          courseId: course.id,
          courseCode: course.code,
          courseTitle: course.title,
          title: request.topic,
          startTime: request.startTime,
          endTime: end,
          lecturerId: course.lecturerId,
          lecturerName: course.lecturerName,
          room: request.room ?? course.room,
          mode: request.mode,
          expectedCount: expected,
        );
        final created = ScheduleModel(
          id: _store.nextId('sch'),
          courseId: course.id,
          courseCode: course.code,
          courseTitle: course.title,
          topic: request.topic,
          startTime: request.startTime,
          durationMinutes: request.durationMinutes,
          lateThresholdMinutes: request.lateThresholdMinutes,
          enableQuestions: request.enableQuestions,
          room: request.room ?? course.room,
          mode: request.mode,
          roomCode: '#SC-${course.code.replaceAll('-', '')}-'
              '${String.fromCharCode(65 + _store.schedules.length % 26)}',
          expectedStudents: expected,
          sessionId: sessionId,
          createdAt: DateTime.now(),
        );
        _store.schedules[created.id] = created;
        return created;
      });
}
