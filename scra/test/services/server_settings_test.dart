import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_class/core/constants/app_constants.dart';
import 'package:smart_class/services/api_service.dart';
import 'package:smart_class/services/server_settings.dart';
import 'package:smart_class/services/storage_service.dart';

void main() {
  tearDown(() => AppConfig.useServer(null));

  group('ServerSettings.normalize', () {
    test('accepts an address with or without http://', () {
      expect(
        ServerSettings.normalize(' 10.194.53.114:8000 '),
        'http://10.194.53.114:8000',
      );
      expect(
        ServerSettings.normalize('http://10.194.53.114:8000/'),
        'http://10.194.53.114:8000',
      );
      expect(
        ServerSettings.normalize('https://smart-class.onrender.com'),
        'https://smart-class.onrender.com',
      );
    });

    test('rejects addresses the app cannot use', () {
      for (final bad in [
        '',
        '   ',
        'ftp://host',
        'http://',
        'host/path',
        'http://a b',
      ]) {
        expect(ServerSettings.normalize(bad), isNull, reason: bad);
      }
    });
  });

  test('an in-app server address replaces the built-in one everywhere', () {
    final api = ApiService(
      client: MockClient((_) async => http.Response('', 200)),
    );
    final builtIn = AppConfig.builtInApiBaseUrl;
    expect(AppConfig.apiBaseUrl, builtIn);
    expect(AppConfig.hasServerOverride, isFalse);

    AppConfig.useServer('http://10.194.53.114:8000/');
    expect(AppConfig.apiBaseUrl, 'http://10.194.53.114:8000');
    expect(AppConfig.wsBaseUrl, 'ws://10.194.53.114:8000');
    // Services created before the change pick it up on the next request.
    expect(
      api.buildUri('/health').toString(),
      'http://10.194.53.114:8000/health',
    );

    AppConfig.useServer(null);
    expect(AppConfig.apiBaseUrl, builtIn);
  });

  test('the chosen address is saved and survives signing out', () async {
    final storage = StorageService(InMemoryStore());
    await ServerSettings.apply(storage, 'http://10.194.53.114:8000');
    await storage.clearSession();
    expect(await storage.getServerUrl(), 'http://10.194.53.114:8000');
    expect(AppConfig.apiBaseUrl, 'http://10.194.53.114:8000');
    await ServerSettings.apply(storage, null);
    expect(await storage.getServerUrl(), isNull);
  });

  test('reachability checks GET /health', () async {
    final ok = MockClient(
      (r) async => r.url.path == '/health'
          ? http.Response('{"status":"ok"}', 200)
          : http.Response('', 404),
    );
    expect(
      await ServerSettings.isReachable('http://pc:8000', client: ok),
      isTrue,
    );
    final down = MockClient((_) async => throw http.ClientException('refused'));
    expect(
      await ServerSettings.isReachable('http://pc:8000', client: down),
      isFalse,
    );
  });
}
