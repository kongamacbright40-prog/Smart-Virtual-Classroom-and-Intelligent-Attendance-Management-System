import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_class/core/constants/app_constants.dart';
import 'package:smart_class/core/errors/app_exception.dart';
import 'package:smart_class/core/errors/error_handler.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/api/api_core_repositories.dart';
import 'package:smart_class/repositories/api/api_live_repositories.dart';
import 'package:smart_class/services/api_service.dart';
import 'package:smart_class/repositories/api/api_repository_base.dart';
import 'package:smart_class/repositories/api/backend_mappers.dart';
import 'package:smart_class/services/webrtc/signaling_service.dart';

void main() {
  const base = 'https://api.test/api/v1';

  ApiService service(
    MockClientHandler handler, {
    String? token = 'abc',
    Duration timeout = const Duration(seconds: 5),
    void Function()? onUnauthorized,
  }) => ApiService(
    client: MockClient(handler),
    baseUrl: base,
    tokenProvider: () async => token,
    timeout: timeout,
    onUnauthorized: onUnauthorized,
  );

  group('ApiService', () {
    test(
      'builds URLs from the central base URL and drops null query values',
      () {
        final api = service((_) async => http.Response('{}', 200));
        expect(
          api.buildUri('/courses', {'q': 'cs', 'status': null}).toString(),
          '$base/courses?q=cs',
        );
        expect(api.buildUri('courses').toString(), '$base/courses');
      },
    );

    test('sends JSON and bearer headers, decodes JSON', () async {
      late http.Request captured;
      final api = service((request) async {
        captured = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      });
      final result = await api.post('/things', body: {'a': 1});
      expect(result, {'ok': true});
      expect(captured.method, 'POST');
      expect(captured.headers['Authorization'], 'Bearer abc');
      expect(captured.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(captured.body), {'a': 1});
    });

    test('supports GET, PUT, PATCH and DELETE', () async {
      final methods = <String>[];
      final api = service((r) async {
        methods.add(r.method);
        return http.Response('', 204);
      });
      await api.get('/x');
      await api.put('/x', body: {});
      await api.patch('/x', body: {});
      await api.delete('/x');
      expect(methods, ['GET', 'PUT', 'PATCH', 'DELETE']);
    });

    test('omits auth header for unauthenticated calls', () async {
      late http.Request captured;
      final api = service((r) async {
        captured = r;
        return http.Response('{}', 200);
      });
      await api.post('/auth/login', body: {}, authenticated: false);
      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('maps 401 to AuthException and notifies', () async {
      var notified = false;
      final api = service(
        (_) async =>
            http.Response(jsonEncode({'detail': 'Token expired'}), 401),
        onUnauthorized: () => notified = true,
      );
      await expectLater(
        api.get('/me'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Token expired',
          ),
        ),
      );
      expect(notified, isTrue);
    });

    test('maps FastAPI 422 validation errors with field details', () async {
      final api = service(
        (_) async => http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'email'],
                'msg': 'value is not a valid email',
              },
            ],
          }),
          422,
        ),
      );
      await expectLater(
        api.post('/users', body: {}),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.fieldErrors['email'],
            'email',
            'value is not a valid email',
          ),
        ),
      );
    });

    test('maps 403, 404 and 5xx', () async {
      Future<void> expectStatus(int code, Matcher matcher) async {
        final api = service((_) async => http.Response('{}', code));
        await expectLater(api.get('/x'), throwsA(matcher));
      }

      await expectStatus(403, isA<ForbiddenException>());
      await expectStatus(404, isA<NotFoundException>());
      await expectStatus(503, isA<ServerException>());
    });

    test('maps timeouts and network failures', () async {
      final slow = service(
        (_) => Future.delayed(
          const Duration(milliseconds: 200),
          () => http.Response('{}', 200),
        ),
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(slow.get('/x'), throwsA(isA<TimeoutAppException>()));

      final offline = service(
        (_) async => throw http.ClientException('Connection refused'),
      );
      await expectLater(offline.get('/x'), throwsA(isA<NetworkException>()));
    });

    test('getList unwraps paginated {items: [...]} responses', () async {
      final api = service(
        (_) async => http.Response(
          jsonEncode({
            'items': [
              {'id': 1},
            ],
            'total': 1,
          }),
          200,
        ),
      );
      expect(await api.getList('/x'), [
        {'id': 1},
      ]);
    });
  });

  test('ErrorHandler normalizes unknown errors', () {
    expect(
      ErrorHandler.normalize(TimeoutException('t')),
      isA<TimeoutAppException>(),
    );
    expect(
      ErrorHandler.normalize(const FormatException('bad')),
      isA<ParsingException>(),
    );
    expect(ErrorHandler.normalize(StateError('x')), isA<UnknownException>());
    expect(ErrorHandler.message(const AuthException('Nope')), 'Nope');
  });

  test('errors from requests loaded together keep their message', () async {
    Object? caught;
    try {
      await (
        Future<int>.value(1),
        Future<int>.error(const NetworkException('Offline')),
      ).wait;
    } on Object catch (e) {
      caught = e;
    }
    expect(caught, isA<ParallelWaitError>());
    expect(ErrorHandler.message(caught!), 'Offline');
  });

  group('Backend API repositories', () {
    Json profile({String role = 'student'}) => {
      'id': 7,
      'full_name': 'Amina Bello',
      'email': 'a@b.edu',
      'phone_number': null,
      'matricule_number': 'ICT2024001',
      'role': role,
    };

    Json course() => {
      'id': 3,
      'code': 'CS-301',
      'title': 'Data Structures',
      'department': {
        'id': 2,
        'name': 'Computer Science',
        'faculty': {'id': 1, 'name': 'Faculty of Science'},
      },
    };

    Json page(List<Json> items) => {
      'items': items,
      'total': items.length,
      'page': 1,
      'page_size': 100,
    };

    test(
      'login posts email/password, then loads /auth/me with the new token',
      () async {
        final requests = <http.Request>[];
        final repo = ApiAuthRepository(
          service((r) async {
            requests.add(r);
            if (r.url.path.endsWith('/auth/login')) {
              return http.Response(
                jsonEncode({
                  'access_token': 'jwt',
                  'refresh_token': 'refresh',
                  'token_type': 'bearer',
                }),
                200,
              );
            }
            return http.Response(jsonEncode(profile()), 200);
          }, token: null),
          ApiContext(),
        );
        final session = await repo.login(
          role: UserRole.student,
          identifier: ' a@b.edu ',
          password: 'pw123456',
        );
        expect(requests.first.url.path, '/api/v1/auth/login');
        expect(jsonDecode(requests.first.body), {
          'email': 'a@b.edu',
          'password': 'pw123456',
        });
        expect(requests.last.url.path, '/api/v1/auth/me');
        expect(requests.last.headers['Authorization'], 'Bearer jwt');
        expect(session.accessToken, 'jwt');
        expect(session.refreshToken, 'refresh');
        expect(session.user.id, '7');
        expect(session.user.fullName, 'Amina Bello');
        expect(session.role, UserRole.student);
      },
    );

    test('login requires an email and the matching role', () async {
      var calls = 0;
      final repo = ApiAuthRepository(
        service((r) async {
          calls++;
          if (r.url.path.endsWith('/auth/login')) {
            return http.Response(jsonEncode({'access_token': 'jwt'}), 200);
          }
          return http.Response(jsonEncode(profile(role: 'lecturer')), 200);
        }, token: null),
        ApiContext(),
      );
      await expectLater(
        repo.login(
          role: UserRole.student,
          identifier: 'ICT2024001',
          password: 'x',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(calls, 0);
      await expectLater(
        repo.login(
          role: UserRole.student,
          identifier: 'a@b.edu',
          password: 'x',
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test(
      'student activation registers with the backend then signs in',
      () async {
        final bodies = <String, Object?>{};
        final repo = ApiAuthRepository(
          service((r) async {
            bodies[r.url.path] = r.body.isEmpty ? null : jsonDecode(r.body);
            if (r.url.path.endsWith('/auth/register')) {
              return http.Response(jsonEncode(profile()), 201);
            }
            if (r.url.path.endsWith('/auth/login')) {
              return http.Response(jsonEncode({'access_token': 'jwt'}), 200);
            }
            return http.Response(jsonEncode(profile()), 200);
          }, token: null),
          ApiContext(),
        );
        await repo.register(
          role: UserRole.student,
          fullName: ' Amina Bello ',
          email: 'amina.bello@b.edu',
          phone: '+237600000002',
          identifier: 'ICT2024001',
          password: 'Password123!',
        );
        expect(bodies['/api/v1/auth/register'], {
          'full_name': 'Amina Bello',
          'email': 'amina.bello@b.edu',
          'password': 'Password123!',
          'role': 'student',
          'matricule_number': 'ICT2024001',
          'phone_number': '+237600000002',
        });
        expect(bodies.containsKey('/api/v1/auth/login'), isTrue);
      },
    );

    test('admin registration sends the admin code', () async {
      Object? sent;
      final repo = ApiAuthRepository(
        service((r) async {
          if (r.url.path.endsWith('/auth/register')) {
            sent = jsonDecode(r.body);
            return http.Response(jsonEncode(profile()), 201);
          }
          if (r.url.path.endsWith('/auth/login')) {
            return http.Response(jsonEncode({'access_token': 'jwt'}), 200);
          }
          return http.Response(
            jsonEncode({...profile(), 'role': 'admin'}),
            200,
          );
        }, token: null),
        ApiContext(),
      );
      await repo.register(
        role: UserRole.admin,
        fullName: 'New Admin',
        email: 'admin2@b.edu',
        phone: '',
        identifier: 'ADM-002',
        password: 'Password123!',
        adminCode: ' S3CRET ',
      );
      expect(sent, {
        'full_name': 'New Admin',
        'email': 'admin2@b.edu',
        'password': 'Password123!',
        'role': 'admin',
        'matricule_number': 'ADM-002',
        'admin_code': 'S3CRET',
      });
    });

    test('admin creates users with or without an initial password', () async {
      final bodies = <Map<String, dynamic>>[];
      final repo = ApiAdminRepository(
        service((r) async {
          bodies.add(jsonDecode(r.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({
              'id': 9,
              'full_name': 'Second Admin',
              'email': 'admin2@uni.edu',
              'role': 'admin',
              'is_active': true,
            }),
            201,
          );
        }),
        ApiContext(),
      );
      const user = UserModel(
        id: '',
        fullName: 'Second Admin',
        email: 'admin2@uni.edu',
        role: UserRole.admin,
      );
      final created = await repo.createUser(user, password: 'Secret123');
      await repo.createUser(user);
      expect(created.role, UserRole.admin);
      expect(bodies[0]['password'], 'Secret123');
      expect(bodies[0]['role'], 'admin');
      expect(bodies[1].containsKey('password'), isFalse);
    });

    test('course list sends filters and maps lecturer and counts', () async {
      late Uri url;
      final repo = ApiCourseRepository(
        service((r) async {
          url = r.url;
          return http.Response(
            jsonEncode(
              page([
                {
                  ...course(),
                  'credits': 4,
                  'lecturer': {'id': 5, 'full_name': 'Kofi Mensah'},
                  'enrolled_count': 30,
                  'sessions_held': 6,
                },
              ]),
            ),
            200,
          );
        }),
        ApiContext(),
      );
      final courses = await repo.getAllCourses(
        query: 'cs',
        status: CourseStatus.active,
      );
      expect(url.path, '/api/v1/courses');
      expect(url.queryParameters, {'page_size': '100', 'q': 'cs'});
      final c = courses.single;
      expect(c.id, '3');
      expect(c.credits, 4);
      expect(c.lecturerName, 'Kofi Mensah');
      expect(c.status, CourseStatus.active);
      expect(c.enrolledCount, 30);
      expect(c.departmentName, 'Computer Science');
      expect(c.facultyName, 'Faculty of Science');
      expect(c.category, isNull);
    });

    test('future classes are scheduled, then loaded by id', () async {
      final requests = <http.Request>[];
      Json session(String status) => {
        'id': 11,
        'course_id': 3,
        'lecturer_id': 5,
        'title': 'Graphs',
        'scheduled_start': '2099-01-01T10:00:00Z',
        'duration_minutes': 90,
        'started_at': null,
        'ended_at': null,
        'status': status,
        'course': {'id': 3, 'code': 'CS-301', 'title': 'Data Structures'},
        'lecturer': {'id': 5, 'full_name': 'Kofi Mensah'},
        'participant_count': 0,
        'expected_count': 30,
      };
      final schedule = ApiScheduleRepository(
        service((r) async {
          requests.add(r);
          return http.Response(jsonEncode(session('scheduled')), 201);
        }),
        ApiContext(),
      );
      final result = await schedule.scheduleClass(
        ScheduleModel(
          id: '',
          courseId: '3',
          courseCode: 'CS-301',
          courseTitle: 'Data Structures',
          topic: 'Graphs',
          startTime: DateTime.utc(2099, 1, 1, 10).toLocal(),
          durationMinutes: 90,
        ),
      );
      expect(requests.first.url.path, '/api/v1/classes/schedule');
      expect(jsonDecode(requests.first.body), {
        'course_id': 3,
        'title': 'Graphs',
        'duration_minutes': 90,
        'scheduled_start': '2099-01-01T10:00:00.000Z',
      });
      expect(result.sessionId, '11');
      expect(result.expectedStudents, 30);

      final loaded = await schedule.getSession('11');
      expect(requests.last.url.path, '/api/v1/classes/11');
      expect(loaded.status, SessionStatus.scheduled);
      expect(loaded.title, 'Graphs');
      expect(loaded.courseCode, 'CS-301');
      expect(loaded.lecturerName, 'Kofi Mensah');
      expect(loaded.duration, const Duration(minutes: 90));
      expect(loaded.startTime, DateTime.utc(2099, 1, 1, 10).toLocal());
    });

    test('classes starting now are opened immediately', () async {
      late http.Request created;
      final schedule = ApiScheduleRepository(
        service((r) async {
          created = r;
          return http.Response(
            jsonEncode({
              'id': 12,
              'course_id': 3,
              'lecturer_id': 5,
              'started_at': '2026-09-28T10:00:00Z',
              'status': 'live',
              'course': {'id': 3, 'code': 'CS-301', 'title': 'Data Structures'},
            }),
            200,
          );
        }),
        ApiContext(),
      );
      await schedule.scheduleClass(
        ScheduleModel(
          id: '',
          courseId: '3',
          courseCode: 'CS-301',
          courseTitle: 'Data Structures',
          topic: '',
          startTime: DateTime.now(),
          durationMinutes: 60,
        ),
      );
      expect(created.url.path, '/api/v1/classes');
      expect(jsonDecode(created.body), {
        'course_id': 3,
        'title': null,
        'duration_minutes': 60,
      });
    });

    test('questions are created live or as drafts and map counts', () async {
      final requests = <http.Request>[];
      Json question({required bool open}) => {
        'id': 9,
        'session_id': 11,
        'question_type': 'mcq',
        'prompt': 'What is BFS?',
        'correct_answer': null,
        'is_open': open,
        'created_at': '2026-09-28T10:05:00Z',
        'options': [
          {
            'id': 21,
            'text': 'Queue based',
            'is_correct': true,
            'response_count': 3,
          },
          {
            'id': 22,
            'text': 'Stack based',
            'is_correct': false,
            'response_count': 1,
          },
        ],
      };
      final repo = ApiQuestionRepository(
        service((r) async {
          requests.add(r);
          final open =
              !r.url.path.endsWith('/questions') ||
              (jsonDecode(r.body) as Map)['launch'] == true;
          return http.Response(jsonEncode(question(open: open)), 200);
        }),
        ApiContext(),
      );
      const draft = QuestionModel(
        id: '',
        sessionId: '11',
        text: 'What is BFS?',
        correctOptionId: 'a',
        options: [
          QuestionOption(id: 'a', label: 'A', text: 'Queue based'),
          QuestionOption(id: 'b', label: 'B', text: 'Stack based'),
        ],
      );
      final launched = await repo.launchQuestion(draft);
      expect(
        requests.last.url.path,
        '/api/v1/participation/sessions/11/questions',
      );
      expect(jsonDecode(requests.last.body), {
        'question_type': 'mcq',
        'prompt': 'What is BFS?',
        'launch': true,
        'options': [
          {'text': 'Queue based', 'is_correct': true},
          {'text': 'Stack based', 'is_correct': false},
        ],
      });
      expect(launched.id, '9');
      expect(launched.status, QuestionStatus.active);
      expect(launched.options.map((o) => o.label), ['A', 'B']);
      expect(launched.options.map((o) => o.responseCount), [3, 1]);
      expect(launched.correctOptionId, '21');

      final saved = await repo.saveDraft(draft);
      expect((jsonDecode(requests.last.body) as Map)['launch'], false);
      await repo.launchQuestion(saved);
      expect(
        requests.last.url.path,
        '/api/v1/participation/questions/9/launch',
      );
    });

    test(
      'attendance maps partial to late and marks with backend values',
      () async {
        late http.Request marked;
        final repo = ApiAttendanceRepository(
          service((r) async {
            marked = r;
            return http.Response(
              jsonEncode({
                'id': 1,
                'session_id': 11,
                'profile': {
                  'id': 7,
                  'full_name': 'Amina Bello',
                  'matricule_number': 'ICT2024001',
                },
                'status': 'partial',
                'joined_at': '2026-09-28T10:02:00',
                'left_at': null,
                'duration_seconds': 600,
              }),
              200,
            );
          }),
          ApiContext(),
        );
        final record = await repo.markAttendance(
          sessionId: '11',
          studentId: '7',
          status: AttendanceStatus.late,
        );
        expect(marked.url.path, '/api/v1/attendance/sessions/11/mark');
        expect(jsonDecode(marked.body), {'profile_id': 7, 'status': 'partial'});
        expect(record.status, AttendanceStatus.late);
        expect(record.studentId, '7');
        expect(record.minutesLogged, 10);
        await repo.markAttendance(
          sessionId: '11',
          studentId: '7',
          status: AttendanceStatus.excused,
        );
        expect(jsonDecode(marked.body), {'profile_id': 7, 'status': 'excused'});
      },
    );

    test(
      'student history includes absences and appeals go per class',
      () async {
        final requests = <http.Request>[];
        final repo = ApiAttendanceRepository(
          service((r) async {
            requests.add(r);
            if (r.method == 'POST') return http.Response('{"id": 1}', 201);
            return http.Response(
              jsonEncode([
                {
                  'session': {
                    'id': 11,
                    'title': 'Graphs',
                    'started_at': '2026-09-28T10:00:00Z',
                    'ended_at': '2026-09-28T11:30:00Z',
                    'course': {'id': 3, 'code': 'CS-301', 'title': 'DSA'},
                    'lecturer': {'id': 5, 'full_name': 'Kofi Mensah'},
                  },
                  'record_id': 4,
                  'status': 'present',
                  'joined_at': '2026-09-28T10:01:00Z',
                  'duration_seconds': 5100,
                },
                {
                  'session': {
                    'id': 12,
                    'started_at': '2026-09-29T10:00:00Z',
                    'ended_at': '2026-09-29T11:00:00Z',
                    'course': {'id': 3, 'code': 'CS-301', 'title': 'DSA'},
                  },
                  'record_id': null,
                  'status': 'absent',
                  'duration_seconds': 0,
                },
              ]),
              200,
            );
          }),
          ApiContext(),
        );
        final summary = await repo.getStudentSummary('7', courseId: '3');
        expect(requests.first.url.path, '/api/v1/attendance/me');
        expect(requests.first.url.queryParameters, {'course_id': '3'});
        expect(summary.totalSessions, 2);
        expect(summary.presentCount, 1);
        expect(summary.absentCount, 1);
        expect(summary.percentage, 50);
        expect(summary.courseCode, 'CS-301');

        final records = await repo.getStudentRecords('7');
        expect(records.last.id, 'session-12');
        expect(records.first.sessionMinutes, 90);
        await repo.submitAppeal(recordId: records.last.id, reason: 'Sick');
        expect(
          requests.last.url.path,
          '/api/v1/attendance/sessions/12/appeals',
        );
        expect(jsonDecode(requests.last.body), {
          'reason': 'Sick',
          'document_name': null,
        });
      },
    );

    test('password reset uses the public reset endpoints', () async {
      final requests = <http.Request>[];
      final repo = ApiAuthRepository(
        service((r) async {
          requests.add(r);
          return http.Response('', 204);
        }),
        ApiContext(),
      );
      await repo.requestPasswordReset('a@b.edu');
      await repo.verifyResetCode(email: 'a@b.edu', code: '1234');
      await repo.resetPassword(
        email: 'a@b.edu',
        code: '1234',
        newPassword: 'Password123!',
      );
      expect(requests.map((r) => r.url.path), [
        '/api/v1/auth/password-reset/request',
        '/api/v1/auth/password-reset/verify',
        '/api/v1/auth/password-reset/confirm',
      ]);
      expect(requests.every((r) => r.headers['Authorization'] == null), isTrue);
    });

    test('report exports are scoped by the report id', () {
      expect(ApiReportRepository.exportScope('course-3'), {'course_id': '3'});
      expect(ApiReportRepository.exportScope('session-11'), {
        'session_id': '11',
      });
      expect(ApiReportRepository.exportScope('lecturer-5'), {
        'lecturer_id': '5',
      });
      expect(ApiReportRepository.exportScope('institution'), isEmpty);
    });
    test('401 refreshes the session once and retries the request', () async {
      final tokens = <String?>[];
      var current = 'old';
      final api = ApiService(
        client: MockClient((r) async {
          tokens.add(r.headers['Authorization']);
          return r.headers['Authorization'] == 'Bearer new'
              ? http.Response('{"ok": true}', 200)
              : http.Response('{"detail": "expired"}', 401);
        }),
        baseUrl: base,
        tokenProvider: () async => current,
      );
      var refreshes = 0;
      api.refreshSession = () async {
        refreshes++;
        current = 'new';
        return true;
      };
      expect(await api.get('/x'), {'ok': true});
      expect(refreshes, 1);
      expect(tokens, ['Bearer old', 'Bearer new']);
    });
  });

  group('Backend mapping', () {
    test('default URLs target the dev machine from the Android emulator', () {
      expect(AppConfig.apiBaseUrl, 'http://10.0.2.2:8000');
      expect(AppConfig.wsBaseUrl, 'ws://10.0.2.2:8000');
      expect(AppConfig.apiPrefix, '');
    });
    test('naive backend timestamps are UTC', () {
      expect(
        BackendMappers.utc('2026-09-28T10:00:00'),
        DateTime.utc(2026, 9, 28, 10).toLocal(),
      );
      expect(
        BackendMappers.utc('2026-09-28T10:00:00+01:00'),
        DateTime.utc(2026, 9, 28, 9).toLocal(),
      );
      expect(BackendMappers.utc(null), isNull);
    });

    test('signaling messages are normalized to {type, from, payload}', () {
      final service = SignalingService(
        roomId: '11',
        userId: '7',
        serverUrl: 'ws://localhost:8000',
        token: 'jwt',
      );
      expect(
        service.uri.toString(),
        'ws://localhost:8000/ws/signal/11?token=jwt',
      );
      Map<String, dynamic>? offer;
      Map<String, dynamic>? joined;
      List<String>? peers;
      service.onOffer = (d) => offer = d;
      service.onUserJoined = (d) => joined = d;
      service.onRoomState = (p) => peers = p;
      service.handleMessage(
        jsonEncode({
          'type': 'offer',
          'target_peer_id': 7,
          'from_peer_id': 3,
          'payload': {'sdp': 'x', 'type': 'offer'},
        }),
      );
      service.handleMessage(
        jsonEncode({'type': 'peer_joined', 'peer_id': 4, 'full_name': 'Kofi'}),
      );
      service.handleMessage(
        jsonEncode({
          'type': 'room_state',
          'peers': [3, 4],
        }),
      );
      expect(offer?['from'], '3');
      expect(offer?['payload'], {'sdp': 'x', 'type': 'offer'});
      expect(joined?['from'], '4');
      expect(peers, ['3', '4']);
    });
  });
}
