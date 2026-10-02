import '../../core/constants/api_endpoints.dart';
import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/file_saver.dart';
import '../repositories.dart';
import 'api_core_repositories.dart';
import 'api_repository_base.dart';
import 'backend_mappers.dart';

bool _sameRecords(
  List<AttendanceRecordModel> a,
  List<AttendanceRecordModel> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.id != y.id ||
        x.status != y.status ||
        x.checkedInAt != y.checkedInAt ||
        x.leftAt != y.leftAt ||
        x.minutesLogged != y.minutesLogged) {
      return false;
    }
  }
  return true;
}

class ApiAttendanceRepository extends ApiRepositoryBase
    implements AttendanceRepository {
  ApiAttendanceRepository(super.api, super.context);

  @override
  Future<AttendanceModel> getStudentSummary(
    String studentId, {
    String? courseId,
  }) async {
    final records = await getStudentRecords(studentId, courseId: courseId);
    final first = records.firstOrNull;
    return AttendanceModel.fromRecords(
      studentId,
      records,
      courseId: courseId,
      courseCode: courseId == null ? null : first?.courseCode,
      courseTitle: courseId == null ? null : first?.courseTitle,
    );
  }

  /// Every finished class of the student's courses (absences included).
  @override
  Future<List<AttendanceRecordModel>> getStudentRecords(
    String studentId, {
    String? courseId,
  }) => getArray(
    ApiEndpoints.myAttendance,
    (json) => BackendMappers.myAttendance(json, context.currentUser),
    query: {'course_id': courseId},
  );

  @override
  Future<List<AttendanceRecordModel>> getSessionAttendance(
    String sessionId,
  ) async {
    final session = context.sessions[sessionId];
    return getMany(
      ApiEndpoints.sessionAttendance(sessionId),
      (json) => BackendMappers.attendance(json, session: session),
    );
  }

  @override
  Future<List<AttendanceModel>> getCourseSummaries(String courseId) async {
    final course = await getOne(
      ApiEndpoints.course(courseId),
      BackendMappers.course,
    );
    return getArray(
      ApiEndpoints.courseAttendanceSummary(courseId),
      (json) => BackendMappers.courseSummary(json, course: course),
    );
  }

  /// The backend records attendance automatically while participants are
  /// connected; the lecturer's capture toggle is kept locally.
  Future<ClassSessionModel> _setCapture(String sessionId, bool active) async {
    context.attendanceCapture[sessionId] = active;
    return fetchSession(sessionId);
  }

  @override
  Future<ClassSessionModel> startAttendance(String sessionId) =>
      _setCapture(sessionId, true);

  @override
  Future<ClassSessionModel> endAttendance(String sessionId) =>
      _setCapture(sessionId, false);

  @override
  Future<AttendanceRecordModel> markAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) async => postOne(
    ApiEndpoints.sessionAttendanceMark(sessionId),
    {
      'profile_id': BackendMappers.id(studentId),
      'status': BackendMappers.attendanceStatusValue(status),
    },
    (json) =>
        BackendMappers.attendance(json, session: context.sessions[sessionId]),
  );

  /// The backend records check-in when the student connects to the class
  /// signaling socket; this reads the resulting record.
  @override
  Future<AttendanceRecordModel> checkIn({
    required String sessionId,
    required String studentId,
  }) async {
    for (final r in await getSessionAttendance(sessionId)) {
      if (r.studentId == studentId) return r;
    }
    throw const NotFoundException(
      'You are not checked in yet. Rejoin the class to be marked present.',
    );
  }

  /// Student record ids are `session-<class id>` (see
  /// [BackendMappers.myAttendance]); appeals are filed per class.
  @override
  Future<void> submitAppeal({
    required String recordId,
    required String reason,
    String? documentName,
  }) async {
    final sessionId = recordId.startsWith(BackendMappers.myRecordPrefix)
        ? recordId.substring(BackendMappers.myRecordPrefix.length)
        : null;
    if (sessionId == null) {
      throw const ValidationException('This record cannot be appealed.');
    }
    await api.post(
      ApiEndpoints.sessionAppeals(sessionId),
      body: {'reason': reason, 'document_name': documentName},
    );
  }

  @override
  Stream<List<AttendanceRecordModel>> watchSessionAttendance(
    String sessionId,
  ) => poll(
    () => getSessionAttendance(sessionId),
    // Attendance changes slowly (joins / leaves); keeps the server load low
    // with many students. Chat and questions keep the faster default.
    interval: const Duration(seconds: 10),
    equals: _sameRecords,
  );
}

class ApiClassroomRepository extends ApiRepositoryBase
    implements ClassroomRepository {
  ApiClassroomRepository(super.api, super.context);

  @override
  Future<ClassSessionModel> startClass(String sessionId) async =>
      mapSession(asJson(await api.post(ApiEndpoints.classStart(sessionId))));

  @override
  Future<ClassSessionModel> endClass(String sessionId) async =>
      mapSession(asJson(await api.post(ApiEndpoints.classEnd(sessionId))));

  /// Presence is tracked by the signaling socket (see `SignalingService`).
  @override
  Future<void> joinClass(String sessionId, UserModel user) async {}

  @override
  Future<void> leaveClass(String sessionId, String userId) async {}

  @override
  Future<void> setHandRaised(
    String sessionId,
    String userId,
    bool raised,
  ) async {
    await api.put(ApiEndpoints.classHand(sessionId), body: {'raised': raised});
  }

  /// Media state is local to each device; the backend does not track it.
  @override
  Future<void> updateMediaState(
    String sessionId,
    String userId, {
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
  }) async {}

  Future<List<ParticipantModel>> _participants(String sessionId) => getArray(
    ApiEndpoints.classParticipants(sessionId),
    BackendMappers.participant,
  );

  @override
  Stream<List<ParticipantModel>> watchParticipants(String sessionId) => poll(
    () => _participants(sessionId),
    interval: const Duration(seconds: 5),
    equals: (a, b) =>
        a.length == b.length &&
        [
          for (var i = 0; i < a.length; i++)
            a[i].userId == b[i].userId &&
                a[i].isHandRaised == b[i].isHandRaised,
        ].every((same) => same),
  );

  @override
  Future<List<ChatMessageModel>> getMessages(String sessionId) =>
      getArray(ApiEndpoints.classMessages(sessionId), BackendMappers.message);

  /// New messages only (polled with `after_id`).
  @override
  Stream<ChatMessageModel> watchMessages(String sessionId) async* {
    int? lastId;
    final existing = await getMessages(sessionId);
    if (existing.isNotEmpty) lastId = int.tryParse(existing.last.id);
    await for (final batch in poll(
      () => getArray(
        ApiEndpoints.classMessages(sessionId),
        BackendMappers.message,
        query: {'after_id': lastId},
      ),
    )) {
      for (final message in batch) {
        lastId = int.tryParse(message.id) ?? lastId;
        yield message;
      }
    }
  }

  @override
  Future<ChatMessageModel> sendMessage(ChatMessageModel message) => postOne(
    ApiEndpoints.classMessages(message.classroomId),
    {'message': message.message, 'is_question': message.isQuestion},
    BackendMappers.message,
  );
}

class ApiQuestionRepository extends ApiRepositoryBase
    implements QuestionRepository {
  ApiQuestionRepository(super.api, super.context);

  int _expected(String sessionId) =>
      context.sessions[sessionId]?.expectedCount ?? 0;

  /// Lecturers see every question of their class (with answers and counts);
  /// students only see open ones.
  @override
  Future<List<QuestionModel>> getSessionQuestions(String sessionId) => getMany(
    context.role == UserRole.lecturer
        ? ApiEndpoints.sessionQuestions(sessionId)
        : ApiEndpoints.sessionOpenQuestions(sessionId),
    (json) =>
        BackendMappers.question(json, expectedResponders: _expected(sessionId)),
  );

  bool _saved(QuestionModel q) => q.id.isNotEmpty && int.tryParse(q.id) != null;

  @override
  Future<QuestionModel> saveDraft(QuestionModel question) async {
    if (_saved(question)) return question;
    return postOne(
      ApiEndpoints.sessionQuestions(question.sessionId),
      BackendMappers.questionCreate(question, launch: false),
      BackendMappers.question,
    );
  }

  /// Launching closes any other live question of the class.
  @override
  Future<QuestionModel> launchQuestion(QuestionModel question) async {
    if (_saved(question)) {
      return postOne(
        ApiEndpoints.questionLaunch(question.id),
        null,
        (json) => BackendMappers.question(
          json,
          expectedResponders: _expected(question.sessionId),
        ),
      );
    }
    return postOne(
      ApiEndpoints.sessionQuestions(question.sessionId),
      BackendMappers.questionCreate(question, launch: true),
      (json) => BackendMappers.question(
        json,
        expectedResponders: _expected(question.sessionId),
      ),
    );
  }

  @override
  Future<QuestionModel> closeQuestion(String questionId) => postOne(
    ApiEndpoints.questionClose(questionId),
    null,
    BackendMappers.question,
  );

  /// Students see whether they were right as soon as they answer; closing
  /// the question publishes the final result counts.
  @override
  Future<QuestionModel> broadcastResults(String questionId) =>
      closeQuestion(questionId);

  @override
  Future<QuestionResponseModel> submitResponse({
    required String questionId,
    required String studentId,
    required String optionId,
  }) async => postOne(ApiEndpoints.questionRespond(questionId), {
    'selected_option_id': BackendMappers.id(optionId),
  }, (json) => BackendMappers.response(json, studentId: studentId));

  @override
  Future<QuestionResponseModel?> getResponse({
    required String questionId,
    required String studentId,
  }) async {
    final data = await api.get(ApiEndpoints.questionMyResponse(questionId));
    return data is Map
        ? BackendMappers.response(asJson(data), studentId: studentId)
        : null;
  }

  @override
  Stream<QuestionModel?> watchActiveQuestion(String sessionId) => poll(
    () async =>
        (await getSessionQuestions(sessionId))
            .where((q) => q.status == QuestionStatus.active)
            .lastOrNull,
    equals: (a, b) =>
        a?.id == b?.id &&
        a?.status == b?.status &&
        a?.responseCount == b?.responseCount,
  );
}

class ApiNotificationRepository extends ApiRepositoryBase
    implements NotificationRepository {
  ApiNotificationRepository(super.api, super.context);

  @override
  Future<List<NotificationModel>> getNotifications(String userId) =>
      getMany(ApiEndpoints.notifications, BackendMappers.notification);

  @override
  Future<void> markAsRead(String notificationId) =>
      api.post(ApiEndpoints.notificationRead(notificationId));

  @override
  Future<void> markAllAsRead(String userId) =>
      api.post(ApiEndpoints.notificationsReadAll);

  /// Emits notifications that arrive after listening starts (polled).
  @override
  Stream<NotificationModel> watchNotifications(String userId) async* {
    var seen = <String>{};
    var primed = false;
    await for (final batch in poll(
      () => getMany(
        ApiEndpoints.notifications,
        BackendMappers.notification,
        query: {'unread_only': true},
      ),
      interval: const Duration(seconds: 15),
    )) {
      final ids = {for (final n in batch) n.id};
      if (primed) {
        for (final n in batch.reversed) {
          if (!seen.contains(n.id)) yield n;
        }
      }
      seen = {...seen, ...ids};
      primed = true;
    }
  }
}

class ApiAdminRepository extends ApiRepositoryBase implements AdminRepository {
  ApiAdminRepository(super.api, super.context);

  @override
  Future<List<UserModel>> getUsers({UserRole? role, String? query}) => getMany(
    ApiEndpoints.adminUsers,
    BackendMappers.user,
    query: {
      'role': role?.value,
      'q': (query?.trim().isEmpty ?? true) ? null : query!.trim(),
    },
  );

  @override
  Future<List<ClassSessionModel>> getLiveSessions() => getMany(
    ApiEndpoints.adminSessions,
    mapSession,
    query: {'live_only': true},
  );

  @override
  Future<UserModel> getUser(String userId) async {
    for (final u in await getUsers()) {
      if (u.id == userId) return u;
    }
    throw const NotFoundException('User not found.');
  }

  /// Without a password the person activates the account from the app
  /// (student activation / lecturer registration / admin "Forgot password").
  /// With an initial password they can sign in immediately.
  @override
  Future<UserModel> createUser(UserModel user, {String? password}) async =>
      postOne(ApiEndpoints.adminUsers, {
        'full_name': user.fullName,
        'email': user.email,
        'role': user.role.value,
        'phone_number': user.phone,
        if (user.departmentId != null && user.departmentId!.isNotEmpty)
          'department_id': BackendMappers.id(user.departmentId!),
        if (password != null && password.isNotEmpty) 'password': password,
      }, BackendMappers.user);

  @override
  Future<UserModel> updateUser(UserModel user) async =>
      patchOne(ApiEndpoints.adminUser(user.id), {
        'full_name': user.fullName,
        'email': user.email,
        'phone_number': user.phone,
        'department_id': user.departmentId == null || user.departmentId!.isEmpty
            ? null
            : BackendMappers.id(user.departmentId!),
      }, BackendMappers.user);

  @override
  Future<UserModel> setUserActive(String userId, bool active) => patchOne(
    ApiEndpoints.adminUserStatus(userId),
    {'is_active': active},
    BackendMappers.user,
  );

  @override
  Future<void> deleteUser(String userId) =>
      api.delete(ApiEndpoints.adminUser(userId));

  @override
  Future<List<FacultyModel>> getFaculties() =>
      getMany(ApiEndpoints.faculties, BackendMappers.faculty);

  @override
  Future<FacultyModel> createFaculty(String name) => postOne(
    ApiEndpoints.faculties,
    {'name': name.trim()},
    BackendMappers.faculty,
  );

  @override
  Future<List<DepartmentModel>> getDepartments({String? facultyId}) => getMany(
    ApiEndpoints.departments,
    BackendMappers.department,
    query: {'faculty_id': facultyId},
  );

  @override
  Future<DepartmentModel> saveDepartment(DepartmentModel department) async =>
      department.id.isEmpty
      ? postOne(ApiEndpoints.departments, {
          'name': department.name,
          'faculty_id': BackendMappers.id(department.facultyId),
        }, BackendMappers.department)
      : patchOne(ApiEndpoints.department(department.id), {
          'name': department.name,
          if (department.facultyId.isNotEmpty)
            'faculty_id': BackendMappers.id(department.facultyId),
        }, BackendMappers.department);

  @override
  Future<DepartmentModel> archiveDepartment(String departmentId) => postOne(
    ApiEndpoints.departmentArchive(departmentId),
    null,
    BackendMappers.department,
  );

  @override
  Future<List<AcademicTermModel>> getAcademicTerms() =>
      getArray(ApiEndpoints.academicTerms, BackendMappers.term);

  @override
  Future<AcademicTermModel> saveAcademicTerm(AcademicTermModel term) =>
      term.id.isEmpty
      ? postOne(
          ApiEndpoints.academicTerms,
          BackendMappers.termBody(term),
          BackendMappers.term,
        )
      : putOne(
          ApiEndpoints.academicTerm(term.id),
          BackendMappers.termBody(term),
          BackendMappers.term,
        );

  @override
  Future<SystemSettingsModel> getSystemSettings() =>
      getOne(ApiEndpoints.systemSettings, BackendMappers.settings);

  @override
  Future<SystemSettingsModel> updateSystemSettings(
    SystemSettingsModel settings,
  ) => putOne(
    ApiEndpoints.systemSettings,
    BackendMappers.settingsBody(settings),
    BackendMappers.settings,
  );

  @override
  Future<List<ActivityLogModel>> getRecentActivity({int limit = 20}) =>
      getArray(
        ApiEndpoints.adminActivity,
        BackendMappers.activity,
        query: {'limit': limit},
      );
}

class ApiReportRepository extends ApiRepositoryBase
    implements ReportRepository {
  ApiReportRepository(super.api, super.context);

  @override
  Future<ReportModel> getAdminDashboard() =>
      getOne(ApiEndpoints.reportOverview, BackendMappers.report);

  @override
  Future<ReportModel> getLecturerReport(
    String lecturerId, {
    String? courseId,
  }) => getOne(
    ApiEndpoints.reportLecturer,
    BackendMappers.report,
    query: {
      'course_id': courseId,
      if (context.role == UserRole.admin) 'lecturer_id': lecturerId,
    },
  );

  @override
  Future<ReportModel> getInstitutionReport({
    String? departmentId,
    String? termId,
  }) => getOne(
    ApiEndpoints.reportInstitution,
    BackendMappers.report,
    query: {'department_id': departmentId},
  );

  /// Report ids name their scope: `session-<id>`, `course-<id>`,
  /// `lecturer-<id>`, `department-<id>` or the whole institution.
  static Map<String, Object?> exportScope(String reportId) {
    final match = RegExp(r'^(session|course|lecturer|department)-(\d+)$')
        .firstMatch(reportId);
    if (match == null) return const {};
    return {'${match.group(1)}_id': match.group(2)};
  }

  @override
  Future<String> exportReport(
    String reportId, {
    required ReportFormat format,
    bool includeMatricule = true,
    bool includeGeolocation = false,
  }) async {
    final path = switch (format) {
      ReportFormat.pdf => ApiEndpoints.attendancePdf,
      ReportFormat.xlsx => ApiEndpoints.attendanceXlsx,
      ReportFormat.csv => ApiEndpoints.attendanceCsv,
    };
    final file = await api.download(
      path,
      query: {
        ...exportScope(reportId),
        // Join / leave times in the report are shown in this device's clock.
        'utc_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
      },
    );
    return saveDownloadedFile(
      file.bytes,
      fileName: file.fileName ?? 'attendance_report.${format.value}',
      contentType: file.contentType,
    );
  }
}

/// Convenience factory so the composition root stays short.
class ApiRepositories {
  ApiRepositories(ApiService api, {UserModel? Function()? currentUser})
    : this._(api, ApiContext(currentUser: currentUser));

  ApiRepositories._(ApiService api, this.context)
    : auth = ApiAuthRepository(api, context),
      users = ApiUserRepository(api, context),
      courses = ApiCourseRepository(api, context),
      schedule = ApiScheduleRepository(api, context),
      attendance = ApiAttendanceRepository(api, context),
      classroom = ApiClassroomRepository(api, context),
      questions = ApiQuestionRepository(api, context),
      notifications = ApiNotificationRepository(api, context),
      admin = ApiAdminRepository(api, context),
      reports = ApiReportRepository(api, context);

  final ApiContext context;
  final ApiAuthRepository auth;
  final UserRepository users;
  final CourseRepository courses;
  final ScheduleRepository schedule;
  final AttendanceRepository attendance;
  final ClassroomRepository classroom;
  final QuestionRepository questions;
  final NotificationRepository notifications;
  final AdminRepository admin;
  final ReportRepository reports;
}
