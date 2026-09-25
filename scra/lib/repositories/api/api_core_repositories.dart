import '../../core/constants/api_endpoints.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'api_repository_base.dart';

class ApiAuthRepository extends ApiRepositoryBase implements AuthRepository {
  ApiAuthRepository(super.api);

  @override
  Future<AuthSessionModel> login({
    required UserRole role,
    required String identifier,
    required String password,
  }) => postOne(ApiEndpoints.login, {
    'role': role.value,
    'identifier': identifier,
    'password': password,
  }, AuthSessionModel.fromJson);

  @override
  Future<AuthSessionModel> activateStudent({
    required String matricule,
    required String email,
    required String password,
  }) => postOne(ApiEndpoints.activateStudent, {
    'matricule': matricule,
    'email': email,
    'password': password,
  }, AuthSessionModel.fromJson);

  @override
  Future<AuthSessionModel> registerLecturer({
    required String staffId,
    required String email,
    required String password,
  }) => postOne(ApiEndpoints.registerLecturer, {
    'staff_id': staffId,
    'email': email,
    'password': password,
  }, AuthSessionModel.fromJson);

  @override
  Future<void> requestPasswordReset(String email) => api.post(
    ApiEndpoints.passwordResetRequest,
    body: {'email': email},
    authenticated: false,
  );

  @override
  Future<void> verifyResetCode({required String email, required String code}) =>
      api.post(
        ApiEndpoints.passwordResetVerify,
        body: {'email': email, 'code': code},
        authenticated: false,
      );

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => api.post(
    ApiEndpoints.passwordResetConfirm,
    body: {'email': email, 'code': code, 'new_password': newPassword},
    authenticated: false,
  );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => api.post(
    ApiEndpoints.changePassword,
    body: {'current_password': currentPassword, 'new_password': newPassword},
  );

  @override
  Future<void> logout() => api.post(ApiEndpoints.logout);
}

class ApiUserRepository extends ApiRepositoryBase implements UserRepository {
  ApiUserRepository(super.api);

  @override
  Future<StudentModel> getStudentProfile(String userId) =>
      getOne(ApiEndpoints.student(userId), StudentModel.fromJson);

  @override
  Future<LecturerModel> getLecturerProfile(String userId) =>
      getOne(ApiEndpoints.lecturer(userId), LecturerModel.fromJson);

  @override
  Future<AdminModel> getAdminProfile(String userId) =>
      getOne(ApiEndpoints.admin(userId), AdminModel.fromJson);

  @override
  Future<UserModel> updateProfile(UserModel user) =>
      patchOne(ApiEndpoints.user(user.id), user.toJson(), UserModel.fromJson);

  @override
  Future<List<StudentModel>> getCourseRoster(String courseId) =>
      getMany(ApiEndpoints.courseRoster(courseId), StudentModel.fromJson);
}

class ApiCourseRepository extends ApiRepositoryBase
    implements CourseRepository {
  ApiCourseRepository(super.api);

  @override
  Future<List<CourseModel>> getStudentCourses(String studentId) =>
      getMany(ApiEndpoints.studentCourses(studentId), CourseModel.fromJson);

  @override
  Future<List<CourseModel>> getLecturerCourses(String lecturerId) =>
      getMany(ApiEndpoints.lecturerCourses(lecturerId), CourseModel.fromJson);

  @override
  Future<List<CourseModel>> getAllCourses({
    CourseStatus? status,
    String? departmentId,
    String? query,
  }) => getMany(
    ApiEndpoints.courses,
    CourseModel.fromJson,
    query: {'status': status?.value, 'department_id': departmentId, 'q': query},
  );

  @override
  Future<CourseModel> getCourse(String courseId) =>
      getOne(ApiEndpoints.course(courseId), CourseModel.fromJson);

  @override
  Future<CourseModel> createCourse(CourseModel course) =>
      postOne(ApiEndpoints.courses, course.toJson(), CourseModel.fromJson);

  @override
  Future<CourseModel> updateCourse(CourseModel course) => putOne(
    ApiEndpoints.course(course.id),
    course.toJson(),
    CourseModel.fromJson,
  );

  @override
  Future<CourseModel> assignLecturer({
    required String courseId,
    required String lecturerId,
  }) => postOne(ApiEndpoints.courseAssignLecturer(courseId), {
    'lecturer_id': lecturerId,
  }, CourseModel.fromJson);

  @override
  Future<CourseModel> archiveCourse(String courseId) =>
      postOne(ApiEndpoints.courseArchive(courseId), null, CourseModel.fromJson);
}

class ApiScheduleRepository extends ApiRepositoryBase
    implements ScheduleRepository {
  ApiScheduleRepository(super.api);

  Map<String, Object?> _range(DateTime from, DateTime to) => {
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
  };

  @override
  Future<List<ClassSessionModel>> getStudentSessions(
    String studentId, {
    required DateTime from,
    required DateTime to,
  }) => getMany(
    ApiEndpoints.studentSessions(studentId),
    ClassSessionModel.fromJson,
    query: _range(from, to),
  );

  @override
  Future<List<ClassSessionModel>> getLecturerSessions(
    String lecturerId, {
    required DateTime from,
    required DateTime to,
  }) => getMany(
    ApiEndpoints.lecturerSessions(lecturerId),
    ClassSessionModel.fromJson,
    query: _range(from, to),
  );

  @override
  Future<List<ClassSessionModel>> getCourseSessions(String courseId) => getMany(
    ApiEndpoints.courseSessions(courseId),
    ClassSessionModel.fromJson,
  );

  @override
  Future<ClassSessionModel> getSession(String sessionId) =>
      getOne(ApiEndpoints.session(sessionId), ClassSessionModel.fromJson);

  @override
  Future<ScheduleModel> scheduleClass(ScheduleModel request) =>
      postOne(ApiEndpoints.schedules, request.toJson(), ScheduleModel.fromJson);
}
