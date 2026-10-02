import '../models/models.dart';

/// Contracts between the UI/state layer and data sources.
///
/// The app uses the API implementations in `repositories/api/` (FastAPI
/// backend). Tests substitute in-memory fakes from `test/fakes/`. Screens
/// depend only on these interfaces.

abstract interface class AuthRepository {
  Future<AuthSessionModel> login({
    required UserRole role,
    required String identifier,
    required String password,
  });

  /// Creates (or activates an admin-created) account, then signs in.
  /// [adminCode] is needed to register as admin once an admin exists.
  Future<AuthSessionModel> register({
    required UserRole role,
    required String fullName,
    required String email,
    String? phone,
    required String identifier,
    required String password,
    String? departmentId,
    String? adminCode,
  });

  /// Active departments, loaded before sign-in for the registration forms.
  Future<List<DepartmentModel>> getRegistrationDepartments();

  /// Sends a recovery code to [email].
  Future<void> requestPasswordReset(String email);

  Future<void> verifyResetCode({required String email, required String code});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();
}

abstract interface class UserRepository {
  Future<StudentModel> getStudentProfile(String userId);
  Future<LecturerModel> getLecturerProfile(String userId);
  Future<AdminModel> getAdminProfile(String userId);
  Future<UserModel> updateProfile(UserModel user);

  /// Students enrolled in [courseId].
  Future<List<StudentModel>> getCourseRoster(String courseId);
}

abstract interface class CourseRepository {
  Future<List<CourseModel>> getStudentCourses(String studentId);
  Future<List<CourseModel>> getLecturerCourses(String lecturerId);
  Future<List<CourseModel>> getAllCourses({
    CourseStatus? status,
    String? departmentId,
    String? query,
  });
  Future<CourseModel> getCourse(String courseId);
  Future<CourseModel> createCourse(CourseModel course);
  Future<CourseModel> updateCourse(CourseModel course);
  Future<CourseModel> assignLecturer({
    required String courseId,
    required String lecturerId,
  });
  Future<CourseModel> archiveCourse(String courseId);

  /// Student: joins [courseId] on top of their department's courses.
  Future<CourseModel> enrollInCourse(String courseId);

  /// Student: leaves a course they joined individually (department courses
  /// can't be dropped).
  Future<CourseModel> dropCourse(String courseId);

  /// Admin: adds [studentId] to [courseId].
  Future<void> addStudentToCourse({
    required String courseId,
    required String studentId,
  });

  /// Admin: removes a student added individually to [courseId].
  Future<void> removeStudentFromCourse({
    required String courseId,
    required String studentId,
  });
}

abstract interface class ScheduleRepository {
  Future<List<ClassSessionModel>> getStudentSessions(
    String studentId, {
    required DateTime from,
    required DateTime to,
  });
  Future<List<ClassSessionModel>> getLecturerSessions(
    String lecturerId, {
    required DateTime from,
    required DateTime to,
  });
  Future<List<ClassSessionModel>> getCourseSessions(String courseId);
  Future<ClassSessionModel> getSession(String sessionId);

  /// Creates a class session and its virtual room.
  Future<ScheduleModel> scheduleClass(ScheduleModel request);
}

abstract interface class AttendanceRepository {
  Future<AttendanceModel> getStudentSummary(
    String studentId, {
    String? courseId,
  });
  Future<List<AttendanceRecordModel>> getStudentRecords(
    String studentId, {
    String? courseId,
  });
  Future<List<AttendanceRecordModel>> getSessionAttendance(String sessionId);

  /// Per-student summaries for a course (lecturer roster / reports).
  Future<List<AttendanceModel>> getCourseSummaries(String courseId);

  Future<ClassSessionModel> startAttendance(String sessionId);
  Future<ClassSessionModel> endAttendance(String sessionId);
  Future<AttendanceRecordModel> markAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  });

  /// Records the current user as present when they join a live class.
  Future<AttendanceRecordModel> checkIn({
    required String sessionId,
    required String studentId,
  });

  Future<void> submitAppeal({
    required String recordId,
    required String reason,
    String? documentName,
  });

  /// Live attendance updates for a session.
  Stream<List<AttendanceRecordModel>> watchSessionAttendance(String sessionId);
}

abstract interface class ClassroomRepository {
  Future<ClassSessionModel> startClass(String sessionId);
  Future<ClassSessionModel> endClass(String sessionId);
  Future<void> joinClass(String sessionId, UserModel user);
  Future<void> leaveClass(String sessionId, String userId);
  Future<void> setHandRaised(String sessionId, String userId, bool raised);
  Future<void> updateMediaState(
    String sessionId,
    String userId, {
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
  });

  Stream<List<ParticipantModel>> watchParticipants(String sessionId);

  Future<List<ChatMessageModel>> getMessages(String sessionId);
  Stream<ChatMessageModel> watchMessages(String sessionId);
  Future<ChatMessageModel> sendMessage(ChatMessageModel message);
}

abstract interface class QuestionRepository {
  Future<List<QuestionModel>> getSessionQuestions(String sessionId);
  Future<QuestionModel> saveDraft(QuestionModel question);
  Future<QuestionModel> launchQuestion(QuestionModel question);
  Future<QuestionModel> closeQuestion(String questionId);
  Future<QuestionModel> broadcastResults(String questionId);
  Future<QuestionResponseModel> submitResponse({
    required String questionId,
    required String studentId,
    required String optionId,
  });
  Future<QuestionResponseModel?> getResponse({
    required String questionId,
    required String studentId,
  });

  /// Emits the active question for a session (or null when none).
  Stream<QuestionModel?> watchActiveQuestion(String sessionId);
}

abstract interface class NotificationRepository {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Stream<NotificationModel> watchNotifications(String userId);
}

abstract interface class AdminRepository {
  Future<List<UserModel>> getUsers({UserRole? role, String? query});
  Future<UserModel> getUser(String userId);

  /// Classes running right now (started, not ended).
  Future<List<ClassSessionModel>> getLiveSessions();

  /// Without [password] the account is created pending activation; with it
  /// the person can sign in straight away.
  Future<UserModel> createUser(UserModel user, {String? password});
  Future<UserModel> updateUser(UserModel user);
  Future<UserModel> setUserActive(String userId, bool active);
  Future<void> deleteUser(String userId);

  Future<List<FacultyModel>> getFaculties();
  Future<FacultyModel> createFaculty(String name);
  Future<List<DepartmentModel>> getDepartments({String? facultyId});
  Future<DepartmentModel> saveDepartment(DepartmentModel department);
  Future<DepartmentModel> archiveDepartment(String departmentId);

  Future<List<AcademicTermModel>> getAcademicTerms();
  Future<AcademicTermModel> saveAcademicTerm(AcademicTermModel term);

  Future<SystemSettingsModel> getSystemSettings();
  Future<SystemSettingsModel> updateSystemSettings(
    SystemSettingsModel settings,
  );

  Future<List<ActivityLogModel>> getRecentActivity({int limit = 20});
}

abstract interface class ReportRepository {
  /// Headline numbers for the admin dashboard.
  Future<ReportModel> getAdminDashboard();

  /// Attendance analytics across a lecturer's courses (optionally one).
  Future<ReportModel> getLecturerReport(String lecturerId, {String? courseId});

  /// Institution-wide analytics (optionally filtered).
  Future<ReportModel> getInstitutionReport({
    String? departmentId,
    String? termId,
  });

  /// Returns the generated file name / download URL.
  Future<String> exportReport(
    String reportId, {
    required ReportFormat format,
    bool includeMatricule = true,
    bool includeGeolocation = false,
  });
}
