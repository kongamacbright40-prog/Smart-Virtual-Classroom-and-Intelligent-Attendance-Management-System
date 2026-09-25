import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_realtime.dart';

import 'package:smart_class/core/errors/app_exception.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/providers/classroom_controller.dart';

import '../fakes/mock_admin_repository.dart';
import '../fakes/mock_attendance_repository.dart';
import '../fakes/mock_classroom_repository.dart';
import '../fakes/mock_course_repository.dart';
import '../fakes/mock_data_store.dart';
import '../fakes/mock_notification_repository.dart';
import '../fakes/mock_question_repository.dart';
import '../fakes/mock_report_repository.dart';
import '../fakes/mock_schedule_repository.dart';
import '../fakes/mock_user_repository.dart';

import 'package:smart_class/services/websocket_service.dart';

void main() {
  late MockDataStore store;
  const zero = Duration.zero;

  setUp(() => store = MockDataStore());
  tearDown(() => store.dispose());

  group('Course & schedule repositories', () {
    test(
      'student sees enrolled courses; lecturer sees assigned courses',
      () async {
        final repo = MockCourseRepository(store, latency: zero);
        final student = await repo.getStudentCourses(
          MockDataStore.currentStudentId,
        );
        expect(
          student.map((c) => c.code),
          containsAll(['CS-301', 'MTH-1221', 'CS-305', 'ENG-210']),
        );
        final lecturer = await repo.getLecturerCourses(
          MockDataStore.currentLecturerId,
        );
        expect(lecturer.every((c) => c.lecturerId == 'lec-001'), isTrue);
      },
    );

    test('create, search, assign and archive courses', () async {
      final repo = MockCourseRepository(store, latency: zero);
      final created = await repo.createCourse(
        const CourseModel(
          id: '',
          code: 'ai-500',
          title: 'Applied AI',
          credits: 3,
          departmentId: 'dep-cs',
        ),
      );
      expect(created.code, 'AI-500');
      expect(created.status, CourseStatus.pendingLecturer);
      await expectLater(
        repo.createCourse(created),
        throwsA(isA<ValidationException>()),
      );
      expect(
        (await repo.getAllCourses(query: 'applied')).single.id,
        created.id,
      );
      final assigned = await repo.assignLecturer(
        courseId: created.id,
        lecturerId: 'lec-002',
      );
      expect(assigned.status, CourseStatus.active);
      expect(assigned.lecturerName, 'Dr. Mamadou Kaba');
      final archived = await repo.archiveCourse(created.id);
      expect(archived.status, CourseStatus.archived);
    });

    test(
      'there is always a live class and schedule clashes are rejected',
      () async {
        final repo = MockScheduleRepository(store, latency: zero);
        final live = await repo.getSession(MockDataStore.liveSessionId);
        expect(live.isLive, isTrue);
        final now = DateTime.now();
        final today = await repo.getStudentSessions(
          MockDataStore.currentStudentId,
          from: DateTime(now.year, now.month, now.day),
          to: DateTime(now.year, now.month, now.day, 23, 59),
        );
        expect(today.any((s) => s.id == MockDataStore.liveSessionId), isTrue);

        await expectLater(
          repo.scheduleClass(
            ScheduleModel(
              id: '',
              courseId: 'crs-cs301',
              courseCode: 'CS-301',
              courseTitle: 'DSA',
              topic: 'Clash',
              startTime: live.startTime.add(const Duration(minutes: 10)),
              durationMinutes: 60,
            ),
          ),
          throwsA(isA<ValidationException>()),
        );

        final created = await repo.scheduleClass(
          ScheduleModel(
            id: '',
            courseId: 'crs-cs301',
            courseCode: 'CS-301',
            courseTitle: 'DSA',
            topic: 'Binary Search Trees & Balancing (AVL)',
            startTime: now.add(const Duration(days: 20)),
            durationMinutes: 90,
          ),
        );
        expect(created.roomCode, startsWith('#SC-CS301-'));
        expect(created.expectedStudents, 42);
        final session = await repo.getSession(created.sessionId!);
        expect(session.title, 'Binary Search Trees & Balancing (AVL)');
      },
    );
  });

  group('Attendance repository', () {
    test('student summary reflects history', () async {
      final repo = MockAttendanceRepository(store, latency: zero);
      final summary = await repo.getStudentSummary(
        MockDataStore.currentStudentId,
      );
      expect(summary.totalSessions, greaterThan(30));
      expect(summary.percentage, inInclusiveRange(85, 100));
      final records = await repo.getStudentRecords(
        MockDataStore.currentStudentId,
      );
      expect(
        records.first.sessionStart.isAfter(records.last.sessionStart),
        isTrue,
      );
    });

    test('check-in marks the student present once', () async {
      final repo = MockAttendanceRepository(store, latency: zero);
      final record = await repo.checkIn(
        sessionId: MockDataStore.liveSessionId,
        studentId: MockDataStore.currentStudentId,
      );
      expect(
        record.status,
        AttendanceStatus.late,
        reason: 'the live class started 45 minutes ago',
      );
      final again = await repo.checkIn(
        sessionId: MockDataStore.liveSessionId,
        studentId: MockDataStore.currentStudentId,
      );
      expect(again.id, record.id);
    });

    test('lecturer can mark attendance and receives live updates', () async {
      final repo = MockAttendanceRepository(store, latency: zero);
      final updates = repo
          .watchSessionAttendance(MockDataStore.liveSessionId)
          .first;
      await repo.markAttendance(
        sessionId: MockDataStore.liveSessionId,
        studentId: 'stu-005',
        status: AttendanceStatus.excused,
      );
      final list = await updates;
      expect(
        list.firstWhere((r) => r.studentId == 'stu-005').status,
        AttendanceStatus.excused,
      );
    });

    test('ending attendance marks missing students absent', () async {
      final repo = MockAttendanceRepository(store, latency: zero);
      await repo.endAttendance(MockDataStore.liveSessionId);
      final records = await repo.getSessionAttendance(
        MockDataStore.liveSessionId,
      );
      expect(records.length, 42);
      expect(
        records
            .firstWhere((r) => r.studentId == MockDataStore.currentStudentId)
            .status,
        AttendanceStatus.absent,
      );
    });
  });

  group('Questions', () {
    test('students answer once; results reveal correctness', () async {
      final repo = MockQuestionRepository(store, latency: zero);
      final active = await repo
          .watchActiveQuestion(MockDataStore.liveSessionId)
          .first;
      expect(active, isNotNull);
      final before = active!.responseCount;

      final response = await repo.submitResponse(
        questionId: active.id,
        studentId: MockDataStore.currentStudentId,
        optionId: active.correctOptionId!,
      );
      expect(response.status, ResponseStatus.synced);
      await expectLater(
        repo.submitResponse(
          questionId: active.id,
          studentId: MockDataStore.currentStudentId,
          optionId: active.correctOptionId!,
        ),
        throwsA(isA<ValidationException>()),
      );
      final results = await repo.broadcastResults(active.id);
      expect(results.status, QuestionStatus.closed);
      expect(results.responseCount, before + 1);
      final mine = await repo.getResponse(
        questionId: active.id,
        studentId: MockDataStore.currentStudentId,
      );
      expect(mine?.isCorrect, isTrue);
    });

    test('launching a question replaces the active one', () async {
      final repo = MockQuestionRepository(store, latency: zero);
      final launched = await repo.launchQuestion(
        const QuestionModel(
          id: '',
          sessionId: MockDataStore.liveSessionId,
          text: 'Which traversal uses a queue?',
          options: [
            QuestionOption(id: '', label: 'A', text: 'BFS'),
            QuestionOption(id: '', label: 'B', text: 'DFS'),
          ],
          correctOptionId: '',
          durationSeconds: 30,
        ),
      );
      expect(launched.status, QuestionStatus.active);
      expect(launched.options.first.id, '${launched.id}-A');
      expect(store.questions['q-live-1']!.status, QuestionStatus.closed);
      final active = await repo
          .watchActiveQuestion(MockDataStore.liveSessionId)
          .first;
      expect(active?.id, launched.id);
      repo.dispose();
    });
  });

  group('Classroom, notifications, admin, reports', () {
    test('chat messages are stored and streamed', () async {
      final repo = MockClassroomRepository(store, latency: zero);
      final next = repo.watchMessages(MockDataStore.liveSessionId).first;
      final sent = await repo.sendMessage(
        ChatMessageModel(
          id: 'local-1',
          classroomId: MockDataStore.liveSessionId,
          senderId: MockDataStore.currentStudentId,
          senderName: 'Konga',
          senderRole: UserRole.student,
          message: 'Hello',
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
        ),
      );
      expect(sent.status, MessageStatus.sent);
      expect(sent.id.startsWith('local-'), isFalse);
      expect((await next).id, sent.id);
    });

    test('notifications can be marked read', () async {
      final repo = MockNotificationRepository(store, latency: zero);
      final list = await repo.getNotifications(MockDataStore.currentStudentId);
      expect(list.any((n) => !n.isRead), isTrue);
      await repo.markAllAsRead(MockDataStore.currentStudentId);
      final after = await repo.getNotifications(MockDataStore.currentStudentId);
      expect(after.every((n) => n.isRead), isTrue);
    });

    test('admin user management', () async {
      final repo = MockAdminRepository(store, latency: zero);
      final lecturers = await repo.getUsers(role: UserRole.lecturer);
      expect(lecturers.every((u) => u.role == UserRole.lecturer), isTrue);
      expect(
        (await repo.getUsers(query: 'ICT20251181')).single.id,
        MockDataStore.currentStudentId,
      );
      final created = await repo.createUser(
        const UserModel(
          id: '',
          fullName: 'New Student',
          email: 'new.student@univ.edu',
          role: UserRole.student,
          departmentId: 'dep-cs',
        ),
      );
      expect(store.students.containsKey(created.id), isTrue);
      await expectLater(
        repo.createUser(created),
        throwsA(isA<ValidationException>()),
      );
      expect((await repo.setUserActive(created.id, false)).isActive, isFalse);
      await expectLater(
        repo.deleteUser(MockDataStore.currentAdminId),
        throwsA(isA<ForbiddenException>()),
      );
      final settings = await repo.updateSystemSettings(
        (await repo.getSystemSettings()).copyWith(lateThresholdMinutes: 10),
      );
      expect(settings.lateThresholdMinutes, 10);
      await expectLater(
        repo.updateSystemSettings(settings.copyWith(participationWeight: 150)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('profiles include computed attendance', () async {
      final repo = MockUserRepository(store, latency: zero);
      final student = await repo.getStudentProfile(
        MockDataStore.currentStudentId,
      );
      expect(student.overallAttendance, greaterThan(80));
      expect(student.activeCredits, 13);
      final roster = await repo.getCourseRoster('crs-cs301');
      expect(roster.length, 42);
    });

    test('reports expose metrics and breakdowns', () async {
      final repo = MockReportRepository(store, latency: zero);
      final lecturer = await repo.getLecturerReport(
        MockDataStore.currentLecturerId,
      );
      expect(lecturer.metric('average_rate'), greaterThan(70));
      expect(lecturer.breakdown, isNotEmpty);
      final institution = await repo.getInstitutionReport();
      expect(institution.trend.length, 8);
      final file = await repo.exportReport(
        institution.id,
        format: ReportFormat.csv,
      );
      expect(file, endsWith('.csv'));
    });
  });

  group('ClassroomController', () {
    ClassroomController controller(UserModel user) => ClassroomController(
      sessionId: MockDataStore.liveSessionId,
      user: user,
      classroomRepository: MockClassroomRepository(store, latency: zero),
      questionRepository: MockQuestionRepository(store, latency: zero),
      attendanceRepository: MockAttendanceRepository(store, latency: zero),
      scheduleRepository: MockScheduleRepository(store, latency: zero),
      webRTCService: MockWebRTCService(),
      webSocketService: MockWebSocketService(),
    );

    test('student joins, is checked in, chats and answers', () async {
      final c = controller(store.users[MockDataStore.currentStudentId]!);
      await c.init();
      await Future<void>.delayed(Duration.zero);
      expect(c.errorMessage, isNull);
      expect(c.joined, isTrue);
      expect(c.connectionState, RealtimeConnectionState.connected);
      expect(c.myAttendance?.status.countsAsAttended, isTrue);
      expect(c.micEnabled, isFalse, reason: 'joins muted by default');
      expect(c.participants.any((p) => p.userId == c.user.id), isTrue);
      expect(c.lecturer?.name, 'Prof. Kwame Mensah');

      await c.sendMessage('Great lecture!');
      await Future<void>.delayed(Duration.zero);
      expect(c.messages.last.message, 'Great lecture!');
      expect(c.messages.last.status, MessageStatus.sent);
      expect(c.messages.where((m) => m.message == 'Great lecture!').length, 1);

      expect(c.activeQuestion, isNotNull);
      final error = await c.submitAnswer(c.activeQuestion!.options[2].id);
      expect(error, isNull);
      expect(c.myResponse, isNotNull);

      await c.toggleHand();
      await Future<void>.delayed(Duration.zero);
      expect(c.handRaised, isTrue);

      await c.leave();
      expect(c.joined, isFalse);
      c.dispose();
    });

    test('students cannot join a class that is not live', () async {
      final c = ClassroomController(
        sessionId: 'ses-cs305-today',
        user: store.users[MockDataStore.currentStudentId]!,
        classroomRepository: MockClassroomRepository(store, latency: zero),
        questionRepository: MockQuestionRepository(store, latency: zero),
        attendanceRepository: MockAttendanceRepository(store, latency: zero),
        scheduleRepository: MockScheduleRepository(store, latency: zero),
        webRTCService: MockWebRTCService(),
        webSocketService: MockWebSocketService(),
      );
      await c.init();
      expect(c.errorMessage, isNotNull);
      expect(c.joined, isFalse);
      c.dispose();
    });

    test(
      'lecturer launches a question, manages attendance and ends class',
      () async {
        final c = controller(store.users[MockDataStore.currentLecturerId]!);
        await c.init();
        expect(c.sessionAttendance, isNotEmpty);
        expect(c.micEnabled, isTrue);

        final q = await c.launchQuestion(
          const QuestionModel(
            id: '',
            sessionId: MockDataStore.liveSessionId,
            text: 'Which traversal uses a queue?',
            options: [
              QuestionOption(id: '', label: 'A', text: 'BFS'),
              QuestionOption(id: '', label: 'B', text: 'DFS'),
            ],
          ),
        );
        expect(c.activeQuestion?.id, q.id);
        await c.broadcastResults();
        expect(c.activeQuestion, isNull);
        expect(c.lastQuestion?.status, QuestionStatus.closed);

        await c.markAttendance('stu-005', AttendanceStatus.present);
        await Future<void>.delayed(Duration.zero);
        expect(
          c.sessionAttendance
              .firstWhere((r) => r.studentId == 'stu-005')
              .status,
          AttendanceStatus.present,
        );

        await c.endClass();
        expect(c.session?.status, SessionStatus.completed);
        expect(c.joined, isFalse);
        c.dispose();
      },
    );
  });
}
