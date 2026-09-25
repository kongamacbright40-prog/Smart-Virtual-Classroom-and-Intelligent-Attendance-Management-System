import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/models/models.dart';

T roundTrip<T>(T model, Json Function(T) toJson, T Function(Json) fromJson) =>
    fromJson(toJson(model));

void main() {
  final now = DateTime(2026, 9, 25, 10, 0);
  const user = UserModel(
    id: 'u1',
    fullName: 'Prof. Kwame Mensah',
    email: 'k.mensah@smartclass.edu.ac',
    role: UserRole.lecturer,
    phone: '+233 302 765 400',
    departmentId: 'dep-cs',
  );

  group('UserModel', () {
    test('round-trips through JSON', () {
      final copy = roundTrip(user, (u) => u.toJson(), UserModel.fromJson);
      expect(copy, user);
      expect(copy.toJson()['role'], 'lecturer');
    });

    test('firstName strips academic titles', () {
      expect(user.firstName, 'Kwame');
    });

    test('unknown role falls back to student', () {
      expect(UserRole.fromJson('robot'), UserRole.student);
      expect(UserRole.tryParse('robot'), isNull);
    });
  });

  test('Student / Lecturer / Admin models round-trip', () {
    const student = StudentModel(
      user: UserModel(
          id: 's1', fullName: 'Amina Bello', email: 'a@b.edu', role: UserRole.student),
      matricule: 'ICT20251002',
      programme: 'Software Engineering',
      level: 200,
      semester: 1,
      enrolledCourseIds: ['c1', 'c2'],
      overallAttendance: 94.5,
      gpa: 3.8,
    );
    final s = roundTrip(student, (m) => m.toJson(), StudentModel.fromJson);
    expect(s.matricule, 'ICT20251002');
    expect(s.enrolledCourseIds, ['c1', 'c2']);
    expect(s.gpa, 3.8);
    expect(s.user.role, UserRole.student);

    const lecturer = LecturerModel(
      user: user,
      staffId: 'FAC-2024-8192',
      title: 'Prof.',
      courseIds: ['c1'],
      rating: 4.8,
    );
    final l = roundTrip(lecturer, (m) => m.toJson(), LecturerModel.fromJson);
    expect(l.staffId, 'FAC-2024-8192');
    expect(l.courseIds, ['c1']);

    final admin = AdminModel(
      user: user.copyWith(role: UserRole.admin),
      adminId: 'ADM-001',
      accessLevel: AdminAccessLevel.system,
      permissions: const ['users'],
      lastLoginAt: now,
    );
    final a = roundTrip(admin, (m) => m.toJson(), AdminModel.fromJson);
    expect(a.accessLevel, AdminAccessLevel.system);
    expect(a.lastLoginAt, now);
  });

  test('CourseModel round-trips and computes progress', () {
    const course = CourseModel(
      id: 'c1',
      code: 'CS-301',
      title: 'Data Structures',
      credits: 4,
      departmentId: 'dep-cs',
      lecturerId: 'u1',
      status: CourseStatus.pendingLecturer,
      totalSessions: 16,
      sessionsHeld: 12,
      topics: ['Graphs'],
    );
    final c = roundTrip(course, (m) => m.toJson(), CourseModel.fromJson);
    expect(c.status, CourseStatus.pendingLecturer);
    expect(c.toJson()['status'], 'pending_lecturer');
    expect(c.progress, 0.75);
    expect(c.hasLecturer, isTrue);
    expect(c.topics, ['Graphs']);
  });

  test('ClassSessionModel round-trips and computes progress', () {
    final session = ClassSessionModel(
      id: 'ses1',
      courseId: 'c1',
      courseCode: 'CS-301',
      courseTitle: 'Data Structures',
      title: 'Lecture 13',
      startTime: now,
      endTime: now.add(const Duration(minutes: 90)),
      status: SessionStatus.live,
      mode: SessionMode.hybrid,
      attendanceActive: true,
    );
    final s =
        roundTrip(session, (m) => m.toJson(), ClassSessionModel.fromJson);
    expect(s.status, SessionStatus.live);
    expect(s.isLive, isTrue);
    expect(s.duration.inMinutes, 90);
    expect(s.progressAt(now.add(const Duration(minutes: 45))), 0.5);
    expect(s.progressAt(now.add(const Duration(hours: 5))), 1);
  });

  test('ScheduleModel round-trips and derives end time', () {
    final schedule = ScheduleModel(
      id: 'sch1',
      courseId: 'c1',
      courseCode: 'CS-301',
      courseTitle: 'Data Structures',
      topic: 'AVL Trees',
      startTime: now,
      durationMinutes: 90,
      lateThresholdMinutes: 15,
      roomCode: '#SC-CS301-B',
    );
    final s = roundTrip(schedule, (m) => m.toJson(), ScheduleModel.fromJson);
    expect(s.endTime, now.add(const Duration(minutes: 90)));
    expect(s.lateThresholdMinutes, 15);
    expect(s.roomCode, '#SC-CS301-B');
  });

  group('Attendance', () {
    AttendanceRecordModel record(AttendanceStatus status, {int late = 0}) =>
        AttendanceRecordModel(
          id: 'r$status$late',
          sessionId: 'ses1',
          studentId: 's1',
          studentName: 'Amina Bello',
          courseId: 'c1',
          courseCode: 'CS-301',
          courseTitle: 'Data Structures',
          status: status,
          sessionStart: now,
          checkedInAt: status.countsAsAttended
              ? now.add(Duration(minutes: late))
              : null,
          minutesLogged: 45,
          sessionMinutes: 90,
        );

    test('record round-trips and computes lateness', () {
      final r = roundTrip(record(AttendanceStatus.late, late: 18),
          (m) => m.toJson(), AttendanceRecordModel.fromJson);
      expect(r.status, AttendanceStatus.late);
      expect(r.minutesLate, 18);
      expect(r.durationPercent, 50);
    });

    test('summary percentage excludes excused sessions', () {
      final summary = AttendanceModel.fromRecords('s1', [
        record(AttendanceStatus.present),
        record(AttendanceStatus.present),
        record(AttendanceStatus.late),
        record(AttendanceStatus.absent),
        record(AttendanceStatus.excused),
      ]);
      expect(summary.totalSessions, 5);
      expect(summary.attendedCount, 3);
      expect(summary.percentage, 75);
      expect(summary.meetsRequirement, isTrue);
      final copy = roundTrip(summary, (m) => m.toJson(), AttendanceModel.fromJson);
      expect(copy.percentage, 75);
    });

    test('empty summary is 0%', () {
      expect(AttendanceModel.fromRecords('s1', const []).percentage, 0);
    });
  });

  group('Questions', () {
    final question = QuestionModel(
      id: 'q1',
      sessionId: 'ses1',
      text: 'Binary search complexity?',
      options: const [
        QuestionOption(id: 'a', label: 'A', text: 'O(1)', responseCount: 1),
        QuestionOption(id: 'c', label: 'C', text: 'O(log n)', responseCount: 3),
      ],
      correctOptionId: 'c',
      durationSeconds: 45,
      status: QuestionStatus.active,
      launchedAt: now,
      expectedResponders: 8,
    );

    test('round-trips with options', () {
      final q = roundTrip(question, (m) => m.toJson(), QuestionModel.fromJson);
      expect(q.options.length, 2);
      expect(q.correctOptionId, 'c');
      expect(q.status, QuestionStatus.active);
    });

    test('computes counts, percentages and countdown', () {
      expect(question.responseCount, 4);
      expect(question.responseRate, 50);
      expect(question.percentFor('c'), 75);
      expect(question.remainingAt(now.add(const Duration(seconds: 15))),
          const Duration(seconds: 30));
      expect(question.remainingAt(now.add(const Duration(minutes: 5))),
          Duration.zero);
    });

    test('response round-trips', () {
      final response = QuestionResponseModel(
        id: 'r1',
        questionId: 'q1',
        studentId: 's1',
        selectedOptionId: 'c',
        submittedAt: now,
        status: ResponseStatus.synced,
        isCorrect: true,
      );
      final r = roundTrip(
          response, (m) => m.toJson(), QuestionResponseModel.fromJson);
      expect(r.status, ResponseStatus.synced);
      expect(r.isCorrect, isTrue);
    });
  });

  test('Chat, notification and participant models round-trip', () {
    final msg = ChatMessageModel(
      id: 'm1',
      classroomId: 'ses1',
      senderId: 'u1',
      senderName: 'Prof. Kwame Mensah',
      senderRole: UserRole.lecturer,
      message: 'Welcome!',
      timestamp: now,
      status: MessageStatus.delivered,
      isPinned: true,
    );
    final m = roundTrip(msg, (x) => x.toJson(), ChatMessageModel.fromJson);
    expect(m.status, MessageStatus.delivered);
    expect(m.isPinned, isTrue);

    final n = roundTrip(
      NotificationModel(
        id: 'n1',
        userId: 'u1',
        title: 'Live',
        body: 'Class started',
        type: NotificationType.liveQuestion,
        createdAt: now,
      ),
      (x) => x.toJson(),
      NotificationModel.fromJson,
    );
    expect(n.type, NotificationType.liveQuestion);
    expect(n.toJson()['type'], 'live_question');
    expect(n.copyWith(isRead: true).isRead, isTrue);

    final p = roundTrip(
      ParticipantModel(
        userId: 'u1',
        name: 'Amina',
        role: UserRole.student,
        joinedAt: now,
        isHandRaised: true,
      ),
      (x) => x.toJson(),
      ParticipantModel.fromJson,
    );
    expect(p.isHandRaised, isTrue);
  });

  test('Academic structure models round-trip', () {
    const faculty = FacultyModel(
        id: 'f1', name: 'Faculty of CS', code: 'FCS', departmentCount: 5);
    expect(roundTrip(faculty, (x) => x.toJson(), FacultyModel.fromJson).code,
        'FCS');

    const dept = DepartmentModel(
      id: 'd1',
      name: 'Computer Science',
      code: 'CSE',
      facultyId: 'f1',
      averageAttendance: 92.4,
    );
    expect(
        roundTrip(dept, (x) => x.toJson(), DepartmentModel.fromJson)
            .averageAttendance,
        92.4);

    final term = AcademicTermModel(
      id: 't1',
      name: 'Fall Semester 2026',
      code: 'FA26-REGULAR',
      academicYear: '2026/2027',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 12, 22),
      status: TermStatus.active,
    );
    final t = roundTrip(term, (x) => x.toJson(), AcademicTermModel.fromJson);
    expect(t.status, TermStatus.active);
    expect(t.totalWeeks, 16);
    expect(t.weekAt(DateTime(2026, 10, 8)), 6);
    expect(t.weekAt(DateTime(2026, 8, 1)), 0);
  });

  test('ReportModel round-trips metrics, trend and breakdown', () {
    final report = ReportModel(
      id: 'r1',
      title: 'Institution',
      type: ReportType.institution,
      generatedAt: now,
      periodStart: now,
      periodEnd: now,
      metrics: const {'overall_rate': 89.4},
      trend: const [ReportDataPoint(label: 'W1', value: 86.2, extra: 1180)],
      breakdown: const [
        ReportBreakdown(
            id: 'c1', label: 'CS-301', value: 94.2, meta: {'students': '42'}),
      ],
    );
    final r = roundTrip(report, (x) => x.toJson(), ReportModel.fromJson);
    expect(r.metric('overall_rate'), 89.4);
    expect(r.metric('missing', 7), 7);
    expect(r.trend.single.extra, 1180);
    expect(r.breakdown.single.meta['students'], '42');
  });

  test('Settings models round-trip with defaults', () {
    const settings = AppSettingsModel(
      themeMode: ThemeMode.dark,
      joinWithCameraOff: true,
    );
    final s =
        roundTrip(settings, (x) => x.toJson(), AppSettingsModel.fromJson);
    expect(s.themeMode, ThemeMode.dark);
    expect(s.joinWithCameraOff, isTrue);
    expect(AppSettingsModel.fromJson(const {}).themeMode, ThemeMode.light);

    const system = SystemSettingsModel(lateThresholdMinutes: 10);
    expect(
        roundTrip(system, (x) => x.toJson(), SystemSettingsModel.fromJson)
            .lateThresholdMinutes,
        10);
  });

  test('AuthSessionModel handles expiry', () {
    final session = AuthSessionModel(
      user: user,
      accessToken: 'token',
      expiresAt: now,
    );
    final s = roundTrip(session, (x) => x.toJson(), AuthSessionModel.fromJson);
    expect(s.role, UserRole.lecturer);
    expect(s.isExpiredAt(now.add(const Duration(seconds: 1))), isTrue);
    expect(s.isExpiredAt(now.subtract(const Duration(seconds: 1))), isFalse);
  });

  test('JsonX tolerates numeric strings and bad input', () {
    expect(JsonX.toInt('12'), 12);
    expect(JsonX.toDouble('12.5'), 12.5);
    expect(JsonX.toDouble(null, 3), 3);
    expect(JsonX.stringList(null), isEmpty);
    expect(() => JsonX.date(42.5), throwsFormatException);
  });
}
