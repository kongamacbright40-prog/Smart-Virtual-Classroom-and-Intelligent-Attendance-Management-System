import '../../core/constants/api_endpoints.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../repositories.dart';
import 'api_core_repositories.dart';
import 'api_repository_base.dart';

class ApiAttendanceRepository extends ApiRepositoryBase
    implements AttendanceRepository {
  ApiAttendanceRepository(super.api, this._socket);

  final WebSocketService _socket;

  @override
  Future<AttendanceModel> getStudentSummary(String studentId,
          {String? courseId}) =>
      getOne(ApiEndpoints.studentAttendanceSummary(studentId),
          AttendanceModel.fromJson,
          query: {'course_id': courseId});

  @override
  Future<List<AttendanceRecordModel>> getStudentRecords(String studentId,
          {String? courseId}) =>
      getMany(ApiEndpoints.studentAttendance(studentId),
          AttendanceRecordModel.fromJson,
          query: {'course_id': courseId});

  @override
  Future<List<AttendanceRecordModel>> getSessionAttendance(String sessionId) =>
      getMany(ApiEndpoints.sessionAttendance(sessionId),
          AttendanceRecordModel.fromJson);

  @override
  Future<List<AttendanceModel>> getCourseSummaries(String courseId) => getMany(
      ApiEndpoints.courseAttendanceSummaries(courseId), AttendanceModel.fromJson);

  @override
  Future<ClassSessionModel> startAttendance(String sessionId) => postOne(
      ApiEndpoints.sessionAttendanceStart(sessionId),
      null,
      ClassSessionModel.fromJson);

  @override
  Future<ClassSessionModel> endAttendance(String sessionId) => postOne(
      ApiEndpoints.sessionAttendanceEnd(sessionId),
      null,
      ClassSessionModel.fromJson);

  @override
  Future<AttendanceRecordModel> markAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) =>
      putOne(ApiEndpoints.sessionAttendanceStudent(sessionId, studentId),
          {'status': status.value}, AttendanceRecordModel.fromJson);

  @override
  Future<AttendanceRecordModel> checkIn({
    required String sessionId,
    required String studentId,
  }) =>
      postOne(ApiEndpoints.sessionAttendanceCheckIn(sessionId),
          {'student_id': studentId}, AttendanceRecordModel.fromJson);

  @override
  Future<void> submitAppeal({
    required String recordId,
    required String reason,
    String? documentName,
  }) =>
      api.post(ApiEndpoints.attendanceAppeals(recordId),
          body: {'reason': reason, 'document_name': documentName});

  @override
  Stream<List<AttendanceRecordModel>> watchSessionAttendance(
          String sessionId) =>
      refetchOnEvents(
          _socket, 'attendance.', () => getSessionAttendance(sessionId));
}

class ApiClassroomRepository extends ApiRepositoryBase
    implements ClassroomRepository {
  ApiClassroomRepository(super.api, this._socket);

  final WebSocketService _socket;

  @override
  Future<ClassSessionModel> startClass(String sessionId) => postOne(
      ApiEndpoints.sessionStart(sessionId), null, ClassSessionModel.fromJson);

  @override
  Future<ClassSessionModel> endClass(String sessionId) => postOne(
      ApiEndpoints.sessionEnd(sessionId), null, ClassSessionModel.fromJson);

  @override
  Future<void> joinClass(String sessionId, UserModel user) =>
      api.post(ApiEndpoints.sessionJoin(sessionId));

  @override
  Future<void> leaveClass(String sessionId, String userId) =>
      api.post(ApiEndpoints.sessionLeave(sessionId));

  @override
  Future<void> setHandRaised(String sessionId, String userId, bool raised) =>
      api.patch(ApiEndpoints.sessionParticipant(sessionId, userId),
          body: {'is_hand_raised': raised});

  @override
  Future<void> updateMediaState(
    String sessionId,
    String userId, {
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
  }) =>
      api.patch(ApiEndpoints.sessionParticipant(sessionId, userId), body: {
        'is_muted': ?isMuted,
        'is_video_on': ?isVideoOn,
        'is_screen_sharing': ?isScreenSharing,
      });

  Future<List<ParticipantModel>> _participants(String sessionId) => getMany(
      ApiEndpoints.sessionParticipants(sessionId), ParticipantModel.fromJson);

  @override
  Stream<List<ParticipantModel>> watchParticipants(String sessionId) =>
      refetchOnEvents(_socket, 'participant.', () => _participants(sessionId));

  @override
  Future<List<ChatMessageModel>> getMessages(String sessionId) => getMany(
      ApiEndpoints.sessionMessages(sessionId), ChatMessageModel.fromJson);

  @override
  Stream<ChatMessageModel> watchMessages(String sessionId) => _socket.events
      .where((e) => e.type == 'chat.message')
      .map((e) => ChatMessageModel.fromJson(e.payload))
      .where((m) => m.classroomId == sessionId);

  @override
  Future<ChatMessageModel> sendMessage(ChatMessageModel message) => postOne(
      ApiEndpoints.sessionMessages(message.classroomId),
      {'message': message.message, 'is_question': message.isQuestion},
      ChatMessageModel.fromJson);
}

class ApiQuestionRepository extends ApiRepositoryBase
    implements QuestionRepository {
  ApiQuestionRepository(super.api, this._socket);

  final WebSocketService _socket;

  @override
  Future<List<QuestionModel>> getSessionQuestions(String sessionId) => getMany(
      ApiEndpoints.sessionQuestions(sessionId), QuestionModel.fromJson);

  @override
  Future<QuestionModel> saveDraft(QuestionModel question) =>
      postOne(ApiEndpoints.questions, question.toJson(), QuestionModel.fromJson);

  @override
  Future<QuestionModel> launchQuestion(QuestionModel question) async {
    final saved = question.id.isEmpty ? await saveDraft(question) : question;
    return postOne(
        ApiEndpoints.questionLaunch(saved.id), null, QuestionModel.fromJson);
  }

  @override
  Future<QuestionModel> closeQuestion(String questionId) => postOne(
      ApiEndpoints.questionClose(questionId), null, QuestionModel.fromJson);

  @override
  Future<QuestionModel> broadcastResults(String questionId) => postOne(
      ApiEndpoints.questionBroadcast(questionId), null, QuestionModel.fromJson);

  @override
  Future<QuestionResponseModel> submitResponse({
    required String questionId,
    required String studentId,
    required String optionId,
  }) =>
      postOne(ApiEndpoints.questionResponses(questionId),
          {'selected_option_id': optionId}, QuestionResponseModel.fromJson);

  @override
  Future<QuestionResponseModel?> getResponse({
    required String questionId,
    required String studentId,
  }) async {
    final data =
        await api.get(ApiEndpoints.questionResponse(questionId, studentId));
    return data is Map ? QuestionResponseModel.fromJson(asJson(data)) : null;
  }

  @override
  Stream<QuestionModel?> watchActiveQuestion(String sessionId) async* {
    final all = await getSessionQuestions(sessionId);
    yield all.where((q) => q.status == QuestionStatus.active).firstOrNull;
    await for (final event in _socket.events) {
      if (!event.type.startsWith('question.')) continue;
      final q = QuestionModel.fromJson(event.payload);
      if (q.sessionId != sessionId) continue;
      yield q.status == QuestionStatus.active ? q : null;
    }
  }
}

class ApiNotificationRepository extends ApiRepositoryBase
    implements NotificationRepository {
  ApiNotificationRepository(super.api, this._socket);

  final WebSocketService _socket;

  @override
  Future<List<NotificationModel>> getNotifications(String userId) => getMany(
      ApiEndpoints.userNotifications(userId), NotificationModel.fromJson);

  @override
  Future<void> markAsRead(String notificationId) =>
      api.post(ApiEndpoints.notificationRead(notificationId));

  @override
  Future<void> markAllAsRead(String userId) =>
      api.post(ApiEndpoints.userNotificationsReadAll(userId));

  @override
  Stream<NotificationModel> watchNotifications(String userId) => _socket.events
      .where((e) => e.type == 'notification.created')
      .map((e) => NotificationModel.fromJson(e.payload))
      .where((n) => n.userId == userId);
}

class ApiAdminRepository extends ApiRepositoryBase implements AdminRepository {
  ApiAdminRepository(super.api);

  @override
  Future<List<UserModel>> getUsers({UserRole? role, String? query}) => getMany(
      ApiEndpoints.users, UserModel.fromJson,
      query: {'role': role?.value, 'q': query});

  @override
  Future<UserModel> getUser(String userId) =>
      getOne(ApiEndpoints.user(userId), UserModel.fromJson);

  @override
  Future<UserModel> createUser(UserModel user) =>
      postOne(ApiEndpoints.users, user.toJson(), UserModel.fromJson);

  @override
  Future<UserModel> updateUser(UserModel user) =>
      putOne(ApiEndpoints.user(user.id), user.toJson(), UserModel.fromJson);

  @override
  Future<UserModel> setUserActive(String userId, bool active) => patchOne(
      ApiEndpoints.userStatus(userId), {'is_active': active}, UserModel.fromJson);

  @override
  Future<void> deleteUser(String userId) =>
      api.delete(ApiEndpoints.user(userId));

  @override
  Future<List<FacultyModel>> getFaculties() =>
      getMany(ApiEndpoints.faculties, FacultyModel.fromJson);

  @override
  Future<List<DepartmentModel>> getDepartments({String? facultyId}) => getMany(
      ApiEndpoints.departments, DepartmentModel.fromJson,
      query: {'faculty_id': facultyId});

  @override
  Future<DepartmentModel> saveDepartment(DepartmentModel department) =>
      department.id.isEmpty
          ? postOne(ApiEndpoints.departments, department.toJson(),
              DepartmentModel.fromJson)
          : putOne(ApiEndpoints.department(department.id), department.toJson(),
              DepartmentModel.fromJson);

  @override
  Future<DepartmentModel> archiveDepartment(String departmentId) => postOne(
      ApiEndpoints.departmentArchive(departmentId),
      null,
      DepartmentModel.fromJson);

  @override
  Future<List<AcademicTermModel>> getAcademicTerms() =>
      getMany(ApiEndpoints.academicTerms, AcademicTermModel.fromJson);

  @override
  Future<AcademicTermModel> saveAcademicTerm(AcademicTermModel term) =>
      term.id.isEmpty
          ? postOne(ApiEndpoints.academicTerms, term.toJson(),
              AcademicTermModel.fromJson)
          : putOne(ApiEndpoints.academicTerm(term.id), term.toJson(),
              AcademicTermModel.fromJson);

  @override
  Future<SystemSettingsModel> getSystemSettings() =>
      getOne(ApiEndpoints.systemSettings, SystemSettingsModel.fromJson);

  @override
  Future<SystemSettingsModel> updateSystemSettings(
          SystemSettingsModel settings) =>
      putOne(ApiEndpoints.systemSettings, settings.toJson(),
          SystemSettingsModel.fromJson);

  @override
  Future<List<ActivityLogModel>> getRecentActivity({int limit = 20}) =>
      getMany(ApiEndpoints.adminActivity, ActivityLogModel.fromJson,
          query: {'limit': limit});
}

class ApiReportRepository extends ApiRepositoryBase implements ReportRepository {
  ApiReportRepository(super.api);

  @override
  Future<ReportModel> getAdminDashboard() =>
      getOne(ApiEndpoints.adminDashboardReport, ReportModel.fromJson);

  @override
  Future<ReportModel> getLecturerReport(String lecturerId,
          {String? courseId}) =>
      getOne(ApiEndpoints.lecturerReport(lecturerId), ReportModel.fromJson,
          query: {'course_id': courseId});

  @override
  Future<ReportModel> getInstitutionReport({
    String? departmentId,
    String? termId,
  }) =>
      getOne(ApiEndpoints.institutionReport, ReportModel.fromJson,
          query: {'department_id': departmentId, 'term_id': termId});

  @override
  Future<String> exportReport(
    String reportId, {
    required ReportFormat format,
    bool includeMatricule = true,
    bool includeGeolocation = false,
  }) async {
    final data = asJson(await api.post(ApiEndpoints.reportExport(reportId), body: {
      'format': format.value,
      'include_matricule': includeMatricule,
      'include_geolocation': includeGeolocation,
    }));
    return (data['url'] ?? data['file_name']).toString();
  }
}

/// Convenience factory so the composition root stays short.
class ApiRepositories {
  ApiRepositories(ApiService api, WebSocketService socket)
      : auth = ApiAuthRepository(api),
        users = ApiUserRepository(api),
        courses = ApiCourseRepository(api),
        schedule = ApiScheduleRepository(api),
        attendance = ApiAttendanceRepository(api, socket),
        classroom = ApiClassroomRepository(api, socket),
        questions = ApiQuestionRepository(api, socket),
        notifications = ApiNotificationRepository(api, socket),
        admin = ApiAdminRepository(api),
        reports = ApiReportRepository(api);

  final AuthRepository auth;
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
