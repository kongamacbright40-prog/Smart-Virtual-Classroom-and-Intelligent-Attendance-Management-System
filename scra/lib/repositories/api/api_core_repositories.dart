import '../../core/constants/api_endpoints.dart';
import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'api_repository_base.dart';
import 'backend_mappers.dart';

class ApiAuthRepository extends ApiRepositoryBase implements AuthRepository {
  ApiAuthRepository(super.api, super.context);

  @override
  Future<AuthSessionModel> login({
    required UserRole role,
    required String identifier,
    required String password,
  }) async {
    final email = identifier.trim();
    if (!email.contains('@')) {
      throw const ValidationException(
        'Sign in with your email address.',
        fieldErrors: {'identifier': 'Enter your email address.'},
      );
    }
    final tokens = asJson(
      await api.post(
        ApiEndpoints.login,
        body: {'email': email, 'password': password},
        authenticated: false,
      ),
    );
    final accessToken = tokens['access_token'] as String;
    final user = BackendMappers.user(
      asJson(await api.getWithToken(ApiEndpoints.me, accessToken)),
    );
    if (user.role != role) {
      throw ForbiddenException(
        'This account is registered as ${user.role.label}. '
        'Use the ${user.role.label} sign-in instead.',
      );
    }
    return AuthSessionModel(
      user: user,
      accessToken: accessToken,
      refreshToken: tokens['refresh_token'] as String?,
    );
  }

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
  }) async {
    final phoneNumber = phone?.trim() ?? '';
    final code = adminCode?.trim() ?? '';
    await api.post(
      ApiEndpoints.register,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': role.value,
        'matricule_number': identifier.trim(),
        if (phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (departmentId != null && departmentId.isNotEmpty)
          'department_id': BackendMappers.id(departmentId),
        if (code.isNotEmpty) 'admin_code': code,
      },
      authenticated: false,
    );
    return login(role: role, identifier: email, password: password);
  }

  @override
  Future<List<DepartmentModel>> getRegistrationDepartments() =>
      getArray(ApiEndpoints.publicDepartments, BackendMappers.department);

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

  /// JWTs are stateless on the backend; signing out only clears local state.
  @override
  Future<void> logout() async {}

  /// Exchanges [refreshToken] for a new token pair via `/auth/refresh`.
  Future<({String accessToken, String? refreshToken})> refresh(
    String refreshToken,
  ) async {
    final data = asJson(
      await api.post(
        ApiEndpoints.refresh,
        body: {'refresh_token': refreshToken},
        authenticated: false,
      ),
    );
    return (
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
    );
  }
}

class ApiUserRepository extends ApiRepositoryBase implements UserRepository {
  ApiUserRepository(super.api, super.context);

  /// The caller's own profile (`/auth/me`) or, for admins, any user.
  Future<Json> _profile(String userId) async {
    final me = asJson(await api.get(ApiEndpoints.me));
    if (me['id'].toString() == userId) return me;
    if (me['role'] == UserRole.admin.value) {
      final users = await api.getList(
        ApiEndpoints.adminUsers,
        query: {'page_size': backendPageSize},
      );
      for (final u in users) {
        if (u['id'].toString() == userId) return u;
      }
      throw const NotFoundException('User not found.');
    }
    throw const ForbiddenException('You can only view your own profile.');
  }

  bool _isMe(String userId) => context.currentUser?.id == userId;

  @override
  Future<StudentModel> getStudentProfile(String userId) async {
    if (!_isMe(userId)) return BackendMappers.student(await _profile(userId));
    // Independent requests: run them at the same time.
    final results = await Future.wait<Object>([
      _profile(userId),
      getMany(ApiEndpoints.myCourses, BackendMappers.course),
      getArray(
        ApiEndpoints.myAttendance,
        (r) => BackendMappers.myAttendance(r, context.currentUser),
      ),
    ]);
    final json = results[0] as Json;
    final courses = results[1] as List<CourseModel>;
    final records = results[2] as List<AttendanceRecordModel>;
    return BackendMappers.student(
      json,
      courseIds: [for (final c in courses) c.id],
      overallAttendance: records.isEmpty
          ? null
          : AttendanceModel.fromRecords(userId, records).percentage,
    );
  }

  @override
  Future<LecturerModel> getLecturerProfile(String userId) async {
    if (!_isMe(userId)) return BackendMappers.lecturer(await _profile(userId));
    final results = await Future.wait<Object>([
      _profile(userId),
      getMany(ApiEndpoints.myCourses, BackendMappers.course),
    ]);
    final json = results[0] as Json;
    final courses = results[1] as List<CourseModel>;
    return BackendMappers.lecturer(
      json,
      courseIds: [for (final c in courses) c.id],
      totalStudents: courses.fold(0, (sum, c) => sum + c.enrolledCount),
    );
  }

  @override
  Future<AdminModel> getAdminProfile(String userId) async =>
      BackendMappers.admin(await _profile(userId));

  /// Users can change their name and phone; the email is managed by admins.
  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final current = context.currentUser;
    if (current != null && current.email != user.email) {
      throw const ValidationException(
        'Your email can only be changed by an administrator.',
      );
    }
    return patchOne(ApiEndpoints.me, {
      'full_name': user.fullName,
      'phone_number': user.phone,
    }, BackendMappers.user);
  }

  @override
  Future<List<StudentModel>> getCourseRoster(String courseId) => getArray(
    ApiEndpoints.courseRoster(courseId),
    (json) => BackendMappers.student(json),
  );
}

class ApiCourseRepository extends ApiRepositoryBase
    implements CourseRepository {
  ApiCourseRepository(super.api, super.context);

  /// Enrolled courses (explicit enrolments + the student's department).
  @override
  Future<List<CourseModel>> getStudentCourses(String studentId) =>
      getMany(ApiEndpoints.myCourses, BackendMappers.course);

  /// Courses assigned to the lecturer.
  @override
  Future<List<CourseModel>> getLecturerCourses(String lecturerId) =>
      getMany(ApiEndpoints.myCourses, BackendMappers.course);

  @override
  Future<List<CourseModel>> getAllCourses({
    CourseStatus? status,
    String? departmentId,
    String? query,
  }) async {
    final all = await getMany(
      ApiEndpoints.courses,
      BackendMappers.course,
      query: {
        'department_id': departmentId,
        'q': (query?.trim().isEmpty ?? true) ? null : query!.trim(),
        'include_archived': status == null || status == CourseStatus.archived
            ? true
            : null,
      },
    );
    if (status == null) return all;
    return all.where((c) => c.status == status).toList();
  }

  @override
  Future<CourseModel> getCourse(String courseId) =>
      getOne(ApiEndpoints.course(courseId), BackendMappers.course);

  @override
  Future<CourseModel> createCourse(CourseModel course) =>
      postOne(ApiEndpoints.courses, {
        ...BackendMappers.courseBody(course),
        if (course.lecturerId != null && course.lecturerId!.isNotEmpty)
          'lecturer_id': BackendMappers.id(course.lecturerId!),
      }, BackendMappers.course);

  @override
  Future<CourseModel> updateCourse(CourseModel course) => patchOne(
    ApiEndpoints.course(course.id),
    BackendMappers.courseBody(course),
    BackendMappers.course,
  );

  @override
  Future<CourseModel> assignLecturer({
    required String courseId,
    required String lecturerId,
  }) async => postOne(ApiEndpoints.courseAssignLecturer(courseId), {
    'lecturer_id': BackendMappers.id(lecturerId),
  }, BackendMappers.course);

  @override
  Future<CourseModel> archiveCourse(String courseId) => postOne(
    ApiEndpoints.courseArchive(courseId),
    null,
    BackendMappers.course,
  );

  @override
  Future<CourseModel> enrollInCourse(String courseId) =>
      postOne(ApiEndpoints.courseEnroll(courseId), null, BackendMappers.course);

  @override
  Future<CourseModel> dropCourse(String courseId) async =>
      BackendMappers.course(
        asJson(await api.delete(ApiEndpoints.courseEnroll(courseId))),
      );

  @override
  Future<void> addStudentToCourse({
    required String courseId,
    required String studentId,
  }) => api.post(
    ApiEndpoints.courseEnrollments(courseId),
    body: {'profile_id': BackendMappers.id(studentId)},
  );

  @override
  Future<void> removeStudentFromCourse({
    required String courseId,
    required String studentId,
  }) => api.delete(ApiEndpoints.courseEnrollment(courseId, studentId));
}

class ApiScheduleRepository extends ApiRepositoryBase
    implements ScheduleRepository {
  ApiScheduleRepository(super.api, super.context);

  List<ClassSessionModel> _sorted(List<ClassSessionModel> sessions) =>
      sessions..sort((a, b) => a.startTime.compareTo(b.startTime));

  @override
  Future<List<ClassSessionModel>> getStudentSessions(
    String studentId, {
    required DateTime from,
    required DateTime to,
  }) async => _sorted(await fetchSessions(from: from, to: to));

  @override
  Future<List<ClassSessionModel>> getLecturerSessions(
    String lecturerId, {
    required DateTime from,
    required DateTime to,
  }) async => _sorted(await fetchSessions(from: from, to: to));

  @override
  Future<List<ClassSessionModel>> getCourseSessions(String courseId) async =>
      _sorted(await fetchSessions(courseId: courseId));

  @override
  Future<ClassSessionModel> getSession(String sessionId) =>
      fetchSession(sessionId);

  /// Future classes are scheduled (`/classes/schedule`, started later from
  /// the live classroom); classes set to start now or in the past are
  /// opened immediately (`POST /classes`).
  @override
  Future<ScheduleModel> scheduleClass(ScheduleModel request) async {
    final startsNow = !request.startTime.isAfter(
      DateTime.now().add(const Duration(minutes: 2)),
    );
    final title = request.topic.trim().isEmpty ? null : request.topic.trim();
    final data = asJson(
      await api.post(
        startsNow ? ApiEndpoints.classes : ApiEndpoints.classSchedule,
        body: {
          'course_id': BackendMappers.id(request.courseId),
          'title': title,
          'duration_minutes': request.durationMinutes,
          if (!startsNow)
            'scheduled_start': BackendMappers.iso(request.startTime),
        },
      ),
    );
    final session = mapSession(data);
    return ScheduleModel(
      id: session.id,
      courseId: session.courseId,
      courseCode: session.courseCode,
      courseTitle: session.courseTitle,
      topic: request.topic,
      startTime: session.startTime,
      durationMinutes: request.durationMinutes,
      lateThresholdMinutes: request.lateThresholdMinutes,
      enableQuestions: request.enableQuestions,
      room: request.room,
      mode: SessionMode.virtual,
      roomCode: '#SC-${session.id}',
      expectedStudents: session.expectedCount,
      sessionId: session.id,
      createdAt: DateTime.now(),
    );
  }
}
