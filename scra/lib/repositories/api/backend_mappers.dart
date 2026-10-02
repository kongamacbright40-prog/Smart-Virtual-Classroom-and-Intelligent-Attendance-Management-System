import '../../core/errors/app_exception.dart';
import '../../models/models.dart';

/// Converts payloads of the Smart Class FastAPI backend (`smart-classroom-api`)
/// into the app's models, and app values back into backend request bodies.
///
/// The backend uses integer ids and UTC timestamps (with or without a `Z`);
/// fields it does not provide stay `null` so screens can hide them.
abstract final class BackendMappers {
  /// Backend timestamps are UTC; naive ones (no zone suffix) too.
  static DateTime? utc(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
    return DateTime.parse(hasZone ? value : '${value}Z').toLocal();
  }

  /// UTC ISO-8601 string for request bodies.
  static String iso(DateTime value) => value.toUtc().toIso8601String();

  /// Backend ids are integers; the app keeps ids as strings.
  static int id(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw ValidationException('Invalid id "$value" for the server.');
    }
    return parsed;
  }

  static String? _str(Object? value) => value?.toString();

  static Json _map(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  /// `ProfileOut` / `AdminUserOut` / `StudentOut`.
  static UserModel user(Json json) {
    final department = _map(json['department']);
    return UserModel(
      id: json['id'].toString(),
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromJson(json['role'] ?? 'student'),
      phone: json['phone_number'] as String?,
      departmentId: _str(department['id'] ?? json['department_id']),
      departmentName: department['name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: utc(json['created_at']),
      lastActiveAt: utc(json['last_login_at']),
    );
  }

  static StudentModel student(
    Json json, {
    List<String> courseIds = const [],
    double? overallAttendance,
  }) {
    final department = _map(json['department']);
    return StudentModel(
      user: user(json),
      matricule: json['matricule_number'] as String? ?? '',
      programme: '',
      facultyName: _map(department['faculty'])['name'] as String?,
      enrolledCourseIds: courseIds,
      overallAttendance: overallAttendance,
    );
  }

  static LecturerModel lecturer(
    Json json, {
    List<String> courseIds = const [],
    int totalStudents = 0,
  }) => LecturerModel(
    user: user(json),
    staffId: json['matricule_number'] as String? ?? '',
    title: '',
    courseIds: courseIds,
    totalStudents: totalStudents,
  );

  static AdminModel admin(Json json) =>
      AdminModel(user: user(json), lastLoginAt: utc(json['last_login_at']));

  // ---------------------------------------------------------------------------
  // Catalogue
  // ---------------------------------------------------------------------------

  static String _initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && w[0].toUpperCase() != w[0].toLowerCase())
      .map((w) => w[0].toUpperCase())
      .join();

  static FacultyModel faculty(Json json) {
    final name = json['name'] as String? ?? '';
    return FacultyModel(
      id: json['id'].toString(),
      name: name,
      code: _initials(name),
      departmentCount: JsonX.toInt(json['department_count']),
      courseCount: JsonX.toInt(json['course_count']),
      studentCount: JsonX.toInt(json['student_count']),
      staffCount: JsonX.toInt(json['staff_count']),
    );
  }

  static DepartmentModel department(Json json) {
    final name = json['name'] as String? ?? '';
    final faculty = _map(json['faculty']);
    return DepartmentModel(
      id: json['id'].toString(),
      name: name,
      code: _initials(name),
      facultyId: _str(faculty['id'] ?? json['faculty_id']) ?? '',
      facultyName: faculty['name'] as String?,
      courseCount: JsonX.toInt(json['course_count']),
      studentCount: JsonX.toInt(json['student_count']),
      staffCount: JsonX.toInt(json['staff_count']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static CourseModel course(Json json) {
    final department = _map(json['department']);
    final faculty = _map(department['faculty']);
    final lecturer = _map(json['lecturer']);
    final archived = json['is_archived'] as bool? ?? false;
    return CourseModel(
      id: json['id'].toString(),
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      credits: json['credits'] == null ? null : JsonX.toInt(json['credits']),
      departmentId: _str(department['id'] ?? json['department_id']) ?? '',
      departmentName: department['name'] as String?,
      facultyName: faculty['name'] as String?,
      lecturerId: _str(lecturer['id']),
      lecturerName: lecturer['full_name'] as String?,
      status: archived
          ? CourseStatus.archived
          : lecturer.isEmpty
          ? CourseStatus.pendingLecturer
          : CourseStatus.active,
      enrolledCount: JsonX.toInt(json['enrolled_count']),
      sessionsHeld: JsonX.toInt(json['sessions_held']),
      enrollment: CourseEnrollment.tryParse(json['enrollment']),
    );
  }

  static Json courseBody(CourseModel course) => {
    'code': course.code,
    'title': course.title,
    'department_id': id(course.departmentId),
    'description': course.description.isEmpty ? null : course.description,
    'credits': course.credits,
  };

  // ---------------------------------------------------------------------------
  // Classes
  // ---------------------------------------------------------------------------

  /// `ClassSessionOut`.
  static ClassSessionModel session(Json json, {bool? attendanceActive}) {
    final course = _map(json['course']);
    final lecturer = _map(json['lecturer']);
    final started = utc(json['started_at']);
    final ended = utc(json['ended_at']);
    final scheduled = utc(json['scheduled_start']);
    final start = started ?? scheduled ?? DateTime.now();
    final minutes = json['duration_minutes'] == null
        ? 60
        : JsonX.toInt(json['duration_minutes'], 60);
    final status = switch (json['status']) {
      'completed' => SessionStatus.completed,
      'live' => SessionStatus.live,
      _ =>
        ended != null
            ? SessionStatus.completed
            : started != null
            ? SessionStatus.live
            : SessionStatus.scheduled,
    };
    final courseTitle = course['title'] as String? ?? '';
    final title = json['title'] as String?;
    return ClassSessionModel(
      id: json['id'].toString(),
      courseId: json['course_id'].toString(),
      courseCode: course['code'] as String? ?? '',
      courseTitle: courseTitle,
      title: (title == null || title.trim().isEmpty) ? courseTitle : title,
      startTime: start,
      endTime: ended ?? start.add(Duration(minutes: minutes)),
      lecturerId: _str(json['lecturer_id'] ?? lecturer['id']),
      lecturerName: lecturer['full_name'] as String?,
      mode: SessionMode.virtual,
      status: status,
      participantCount: JsonX.toInt(json['participant_count']),
      expectedCount: JsonX.toInt(json['expected_count']),
      attendanceActive:
          (attendanceActive ?? true) && status == SessionStatus.live,
    );
  }

  static ParticipantModel participant(Json json) => ParticipantModel(
    userId: json['user_id'].toString(),
    name: json['name'] as String? ?? '',
    role: UserRole.fromJson(json['role']),
    joinedAt: utc(json['joined_at']) ?? DateTime.now(),
    isHandRaised: json['is_hand_raised'] as bool? ?? false,
  );

  static ChatMessageModel message(Json json) => ChatMessageModel(
    id: json['id'].toString(),
    classroomId: json['session_id'].toString(),
    senderId: json['sender_id'].toString(),
    senderName: json['sender_name'] as String? ?? '',
    senderRole: UserRole.fromJson(json['sender_role']),
    message: json['message'] as String? ?? '',
    timestamp: utc(json['created_at']) ?? DateTime.now(),
    isQuestion: json['is_question'] as bool? ?? false,
  );

  // ---------------------------------------------------------------------------
  // Attendance
  // ---------------------------------------------------------------------------

  /// Backend statuses are `present | partial | absent | excused`; `partial`
  /// is a late arrival.
  static AttendanceStatus attendanceStatus(Object? value) => switch (value) {
    'present' => AttendanceStatus.present,
    'partial' => AttendanceStatus.late,
    'excused' => AttendanceStatus.excused,
    _ => AttendanceStatus.absent,
  };

  static String attendanceStatusValue(AttendanceStatus status) =>
      switch (status) {
        AttendanceStatus.present => 'present',
        AttendanceStatus.late => 'partial',
        AttendanceStatus.absent => 'absent',
        AttendanceStatus.excused => 'excused',
      };

  /// `AttendanceOut` (lecturer view of one class).
  static AttendanceRecordModel attendance(
    Json json, {
    ClassSessionModel? session,
  }) {
    final profile = _map(json['profile']);
    final joined = utc(json['joined_at']);
    final sessionStart = session?.startTime ?? joined ?? DateTime.now();
    return AttendanceRecordModel(
      id: json['id'].toString(),
      sessionId: json['session_id'].toString(),
      studentId: _str(profile['id'] ?? json['profile_id']) ?? '',
      studentName: profile['full_name'] as String? ?? '',
      matricule: profile['matricule_number'] as String?,
      courseId: session?.courseId ?? '',
      courseCode: session?.courseCode ?? '',
      courseTitle: session?.courseTitle ?? '',
      status: attendanceStatus(json['status']),
      sessionStart: sessionStart,
      checkedInAt: joined,
      leftAt: utc(json['left_at']),
      minutesLogged: (JsonX.toInt(json['duration_seconds']) / 60).round(),
      sessionMinutes: session?.duration.inMinutes ?? 0,
      verificationMethod: 'Live classroom connection',
      lecturerName: session?.lecturerName,
    );
  }

  /// Prefix of the ids given to a student's own attendance entries; the
  /// class id follows (used to file appeals).
  static const String myRecordPrefix = 'session-';

  /// `MyAttendanceOut` (student history, including absences).
  static AttendanceRecordModel myAttendance(Json json, UserModel? me) {
    final session = _map(json['session']);
    final course = _map(session['course']);
    final lecturer = _map(session['lecturer']);
    final started = utc(session['started_at']);
    final ended = utc(session['ended_at']);
    final sessionStart = started ?? DateTime.now();
    final sessionMinutes = ended != null
        ? ended.difference(sessionStart).inMinutes
        : JsonX.toInt(session['duration_minutes'], 0);
    return AttendanceRecordModel(
      id: '$myRecordPrefix${session['id']}',
      sessionId: session['id'].toString(),
      studentId: me?.id ?? '',
      studentName: me?.fullName ?? '',
      courseId: course['id'].toString(),
      courseCode: course['code'] as String? ?? '',
      courseTitle: course['title'] as String? ?? '',
      status: attendanceStatus(json['status']),
      sessionStart: sessionStart,
      checkedInAt: utc(json['joined_at']),
      leftAt: utc(json['left_at']),
      minutesLogged: (JsonX.toInt(json['duration_seconds']) / 60).round(),
      sessionMinutes: sessionMinutes,
      verificationMethod: json['record_id'] == null
          ? null
          : 'Live classroom connection',
      lecturerName: lecturer['full_name'] as String?,
    );
  }

  /// `CourseAttendanceSummary`.
  static AttendanceModel courseSummary(Json json, {CourseModel? course}) {
    final profile = _map(json['profile']);
    return AttendanceModel(
      studentId: profile['id'].toString(),
      courseId: course?.id,
      courseCode: course?.code,
      courseTitle: course?.title,
      totalSessions: JsonX.toInt(json['total_sessions']),
      presentCount: JsonX.toInt(json['present_count']),
      lateCount: JsonX.toInt(json['late_count']),
      absentCount: JsonX.toInt(json['absent_count']),
      excusedCount: JsonX.toInt(json['excused_count']),
    );
  }

  // ---------------------------------------------------------------------------
  // Questions
  // ---------------------------------------------------------------------------

  static const _optionLabels = 'ABCDEFGHIJ';

  /// `QuestionOutLecturer` / `QuestionOutStudent`.
  static QuestionModel question(Json json, {int expectedResponders = 0}) {
    final raw = json['options'] is List ? json['options'] as List : const [];
    final options = <QuestionOption>[];
    String? correctId;
    for (var i = 0; i < raw.length; i++) {
      final o = Map<String, dynamic>.from(raw[i] as Map);
      final id = o['id'].toString();
      if (o['is_correct'] == true) correctId = id;
      options.add(
        QuestionOption(
          id: id,
          label: i < _optionLabels.length ? _optionLabels[i] : '${i + 1}',
          text: o['text'] as String? ?? '',
          responseCount: JsonX.toInt(o['response_count']),
        ),
      );
    }
    final created = utc(json['created_at']);
    final open = json['is_open'] as bool? ?? false;
    final hasResponses = options.any((o) => o.responseCount > 0);
    return QuestionModel(
      id: json['id'].toString(),
      sessionId: json['session_id'].toString(),
      text: json['prompt'] as String? ?? '',
      options: options,
      correctOptionId: correctId,
      status: open
          ? QuestionStatus.active
          : (hasResponses ? QuestionStatus.closed : QuestionStatus.draft),
      createdAt: created,
      launchedAt: open || hasResponses ? created : null,
      expectedResponders: expectedResponders,
    );
  }

  /// `QuestionCreate` body for an app MCQ.
  static Json questionCreate(QuestionModel question, {required bool launch}) =>
      {
        'question_type': 'mcq',
        'prompt': question.text,
        'launch': launch,
        'options': [
          for (final o in question.options)
            {'text': o.text, 'is_correct': o.id == question.correctOptionId},
        ],
      };

  /// `ResponseOut`.
  static QuestionResponseModel response(
    Json json, {
    required String studentId,
  }) => QuestionResponseModel(
    id: json['id'].toString(),
    questionId: json['question_id'].toString(),
    studentId: studentId,
    selectedOptionId: _str(json['selected_option_id']) ?? '',
    submittedAt: utc(json['responded_at']) ?? DateTime.now(),
    status: ResponseStatus.synced,
    isCorrect: json['is_correct'] as bool?,
  );

  // ---------------------------------------------------------------------------
  // Notifications, activity, terms, settings, reports
  // ---------------------------------------------------------------------------

  static NotificationModel notification(Json json) => NotificationModel(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    type: NotificationType.fromJson(json['type']),
    createdAt: utc(json['created_at']) ?? DateTime.now(),
    isRead: json['is_read'] as bool? ?? false,
    referenceId: _str(json['reference_id']),
    actionLabel: json['action_label'] as String?,
  );

  static ActivityLogModel activity(Json json) => ActivityLogModel.fromJson({
    ...json,
    'timestamp': (utc(json['timestamp']) ?? DateTime.now()).toIso8601String(),
  });

  static AcademicTermModel term(Json json) => AcademicTermModel.fromJson({
    ...json,
    'start_date': utc(json['start_date'])?.toIso8601String(),
    'end_date': utc(json['end_date'])?.toIso8601String(),
    'add_drop_deadline': utc(json['add_drop_deadline'])?.toIso8601String(),
  });

  static Json termBody(AcademicTermModel term) => {
    'name': term.name,
    'code': term.code,
    'academic_year': term.academicYear,
    'start_date': iso(term.startDate),
    'end_date': iso(term.endDate),
    'status': term.status.value,
    'term_type': term.termType,
    'teaching_days': term.teachingDays,
    'enrollment_open': term.enrollmentOpen,
    'add_drop_deadline': term.addDropDeadline == null
        ? null
        : iso(term.addDropDeadline!),
    'notes': term.notes,
  };

  static SystemSettingsModel settings(Json json) =>
      SystemSettingsModel.fromJson({
        ...json,
        'last_synced_at': utc(json['last_synced_at'])?.toIso8601String(),
      });

  static Json settingsBody(SystemSettingsModel s) => {
    'late_threshold_minutes': s.lateThresholdMinutes,
    'auto_join_leave_recording': s.autoJoinLeaveRecording,
    'participation_weight': s.participationWeight,
    'strict_geofencing': s.strictGeofencing,
    'session_timeout_minutes': s.sessionTimeoutMinutes,
    'enforce_sso': s.enforceSso,
    'minimum_attendance': s.minimumAttendance,
  };

  static ReportModel report(Json json) => ReportModel.fromJson({
    ...json,
    'generated_at': utc(json['generated_at'])?.toIso8601String(),
    'period_start': utc(json['period_start'])?.toIso8601String(),
    'period_end': utc(json['period_end'])?.toIso8601String(),
  });
}
