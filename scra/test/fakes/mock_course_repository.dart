import 'package:smart_class/core/errors/app_exception.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';

import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockCourseRepository extends MockRepositoryBase
    implements CourseRepository {
  MockCourseRepository(this._store, {super.latency});

  final MockDataStore _store;

  @override
  Future<List<CourseModel>> getStudentCourses(String studentId) => delay(() {
    final student = _store.students[studentId];
    if (student == null) return <CourseModel>[];
    return student.enrolledCourseIds
        .map((id) => _store.courses[id])
        .whereType<CourseModel>()
        .toList();
  });

  @override
  Future<List<CourseModel>> getLecturerCourses(String lecturerId) => delay(
    () => _store.courses.values
        .where(
          (c) =>
              c.lecturerId == lecturerId && c.status != CourseStatus.archived,
        )
        .toList(),
  );

  @override
  Future<List<CourseModel>> getAllCourses({
    CourseStatus? status,
    String? departmentId,
    String? query,
  }) => delay(() {
    final q = query?.trim().toLowerCase() ?? '';
    return _store.courses.values.where((c) {
      if (status != null && c.status != status) return false;
      if (departmentId != null && c.departmentId != departmentId) {
        return false;
      }
      if (q.isNotEmpty &&
          !c.code.toLowerCase().contains(q) &&
          !c.title.toLowerCase().contains(q) &&
          !(c.lecturerName?.toLowerCase().contains(q) ?? false)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => a.code.compareTo(b.code));
  });

  @override
  Future<CourseModel> getCourse(String courseId) => delay(() {
    final c = _store.courses[courseId];
    if (c == null) throw const NotFoundException('Course not found.');
    return c;
  });

  @override
  Future<CourseModel> createCourse(CourseModel course) => delay(() {
    final duplicate = _store.courses.values.any(
      (c) => c.code.toUpperCase() == course.code.toUpperCase(),
    );
    if (duplicate) {
      throw ValidationException(
        'A course with code ${course.code} already exists.',
      );
    }
    final id = course.id.isEmpty ? _store.nextId('crs') : course.id;
    final created = CourseModel(
      id: id,
      code: course.code.toUpperCase(),
      title: course.title,
      description: course.description,
      category: course.category,
      credits: course.credits,
      departmentId: course.departmentId,
      departmentName:
          _store.departments[course.departmentId]?.name ??
          course.departmentName,
      lecturerId: course.lecturerId,
      lecturerName: course.lecturerName,
      termId: course.termId ?? MockDataStore.activeTermId,
      status: course.hasLecturer
          ? CourseStatus.active
          : CourseStatus.pendingLecturer,
      capacity: course.capacity,
      totalSessions: course.totalSessions,
      scheduleSummary: course.scheduleSummary,
      room: course.room,
    );
    _store.courses[id] = created;
    _store.enrollments[id] = [];
    return created;
  });

  @override
  Future<CourseModel> updateCourse(CourseModel course) => delay(() {
    if (!_store.courses.containsKey(course.id)) {
      throw const NotFoundException('Course not found.');
    }
    _store.courses[course.id] = course;
    return course;
  });

  @override
  Future<CourseModel> assignLecturer({
    required String courseId,
    required String lecturerId,
  }) => delay(() {
    final c = _store.courses[courseId];
    final l = _store.lecturers[lecturerId];
    if (c == null || l == null) {
      throw const NotFoundException('Course or lecturer not found.');
    }
    final updated = c.copyWith(
      lecturerId: l.id,
      lecturerName: l.user.fullName,
      status: c.status == CourseStatus.pendingLecturer
          ? CourseStatus.active
          : c.status,
    );
    _store.courses[courseId] = updated;
    return updated;
  });

  @override
  Future<CourseModel> archiveCourse(String courseId) => delay(() {
    final c = _store.courses[courseId];
    if (c == null) throw const NotFoundException('Course not found.');
    final updated = c.copyWith(status: CourseStatus.archived);
    _store.courses[courseId] = updated;
    return updated;
  });

  /// The mock always acts as the demo student.
  @override
  Future<CourseModel> enrollInCourse(String courseId) => delay(() {
    _setEnrolled(courseId, MockDataStore.currentStudentId, true);
    return _store.courses[courseId]!.copyWith(
      enrollment: CourseEnrollment.explicit,
    );
  });

  @override
  Future<CourseModel> dropCourse(String courseId) => delay(() {
    _setEnrolled(courseId, MockDataStore.currentStudentId, false);
    return _store.courses[courseId]!.copyWith(clearEnrollment: true);
  });

  @override
  Future<void> addStudentToCourse({
    required String courseId,
    required String studentId,
  }) => delay(() => _setEnrolled(courseId, studentId, true));

  @override
  Future<void> removeStudentFromCourse({
    required String courseId,
    required String studentId,
  }) => delay(() => _setEnrolled(courseId, studentId, false));

  void _setEnrolled(String courseId, String studentId, bool enrolled) {
    final course = _store.courses[courseId];
    final student = _store.students[studentId];
    if (course == null || student == null) {
      throw const NotFoundException('Course or student not found.');
    }
    final cohort = _store.enrollments.putIfAbsent(courseId, () => []);
    final ids = [...student.enrolledCourseIds]..remove(courseId);
    cohort.remove(studentId);
    if (enrolled) {
      ids.add(courseId);
      cohort.add(studentId);
    }
    _store.students[studentId] = student.copyWith(enrolledCourseIds: ids);
    _store.courses[courseId] = course.copyWith(enrolledCount: cohort.length);
  }
}
