import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_realtime.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_class/core/errors/app_exception.dart';
import 'package:smart_class/core/errors/error_handler.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/api/api_core_repositories.dart';
import 'package:smart_class/repositories/api/api_live_repositories.dart';
import 'package:smart_class/services/api_service.dart';
import 'package:smart_class/services/websocket_service.dart';

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

  group('API repositories', () {
    test('login posts credentials and parses the session', () async {
      late http.Request captured;
      final repo = ApiAuthRepository(
        service((r) async {
          captured = r;
          return http.Response(
            jsonEncode({
              'access_token': 'jwt',
              'user': {
                'id': 'stu-1',
                'full_name': 'Amina Bello',
                'email': 'a@b.edu',
                'role': 'student',
              },
            }),
            200,
          );
        }, token: null),
      );
      final session = await repo.login(
        role: UserRole.student,
        identifier: 'ICT1',
        password: 'pw123456',
      );
      expect(captured.url.path, '/api/v1/auth/login');
      expect(jsonDecode(captured.body), {
        'role': 'student',
        'identifier': 'ICT1',
        'password': 'pw123456',
      });
      expect(session.accessToken, 'jwt');
      expect(session.user.fullName, 'Amina Bello');
    });

    test('course list passes filters as query parameters', () async {
      late Uri url;
      final repo = ApiCourseRepository(
        service((r) async {
          url = r.url;
          return http.Response(
            jsonEncode([
              {
                'id': 'c1',
                'code': 'CS-301',
                'title': 'DSA',
                'credits': 4,
                'department_id': 'dep-cs',
                'status': 'active',
              },
            ]),
            200,
          );
        }),
      );
      final courses = await repo.getAllCourses(
        status: CourseStatus.active,
        query: 'cs',
      );
      expect(url.queryParameters, {'status': 'active', 'q': 'cs'});
      expect(courses.single.code, 'CS-301');
    });

    test('chat stream is fed by WebSocket events', () async {
      final socket = MockWebSocketService();
      final repo = ApiClassroomRepository(
        service((_) async => http.Response('[]', 200)),
        socket,
      );
      final future = repo.watchMessages('ses1').first;
      socket.emit(
        RealtimeEvent('chat.message', {
          'id': 'm1',
          'classroom_id': 'ses1',
          'sender_id': 'u1',
          'sender_name': 'Amina',
          'sender_role': 'student',
          'message': 'Hello',
          'timestamp': DateTime(2026).toIso8601String(),
        }),
      );
      expect((await future).message, 'Hello');
    });
  });
}
