import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_class/services/webrtc/ice_config.dart';
import 'package:smart_class/services/webrtc_service.dart';

void main() {
  group('IceConfig', () {
    test('uses the default STUN servers when the server gives none', () {
      final servers = IceConfig.configuration()['iceServers'] as List;
      expect(servers, hasLength(1));
      expect((servers.first as Map)['urls'], contains(startsWith('stun:')));
    });

    test('uses the servers (incl. TURN relay) provided by the backend', () {
      final turn = {
        'urls': ['turn:relay.example.com:3478'],
        'username': 'u',
        'credential': 'p',
      };
      final servers =
          IceConfig.configuration([
                {
                  'urls': ['stun:stun.example.com:3478'],
                },
                turn,
              ])['iceServers']
              as List;
      expect(servers, hasLength(2));
      expect(servers.last, turn);
    });

    test('fetch reads ice_servers with the access token', () async {
      late http.Request seen;
      final client = MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode({
            'ice_servers': [
              {
                'urls': ['stun:stun.l.google.com:19302'],
              },
              {
                'urls': ['turn:relay.example.com:3478'],
                'username': 'u',
                'credential': 'p',
              },
            ],
            'turn_configured': true,
          }),
          200,
        );
      });
      final info = await IceConfig.fetch(
        token: 'tok',
        client: client,
        baseUrl: 'https://api.example.com',
      );
      expect(
        seen.url.toString(),
        'https://api.example.com/signaling/ice-servers',
      );
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(info!.turnConfigured, isTrue);
      expect(info.servers, hasLength(2));
      expect(info.servers.last['username'], 'u');
    });

    test('fetch falls back (null) on errors and old backends', () async {
      final notFound = MockClient((_) async => http.Response('{}', 404));
      expect(
        await IceConfig.fetch(token: 't', client: notFound, baseUrl: 'x:'),
        isNull,
      );
      final broken = MockClient((_) async => throw Exception('offline'));
      expect(
        await IceConfig.fetch(
          token: 't',
          client: broken,
          baseUrl: 'https://api.example.com',
        ),
        isNull,
      );
    });
  });

  group('MediaState.notice', () {
    test('no notice while everything connects', () {
      expect(const MediaState().notice, isNull);
    });

    test('explains a missing TURN relay when audio/video fails', () {
      const state = MediaState(
        connection: MediaConnectionState.connected,
        failedPeerIds: ['7'],
        relayAvailable: false,
      );
      expect(state.notice, contains('TURN relay'));
      expect(state.copyWith(relayAvailable: true).notice, contains('Retrying'));
      expect(state.copyWith(failedPeerIds: const []).notice, isNull);
    });

    test('shows the classroom-server error when signaling failed', () {
      const state = MediaState(
        connection: MediaConnectionState.failed,
        errorMessage: 'Could not connect to the classroom server.',
      );
      expect(state.notice, 'Could not connect to the classroom server.');
    });
  });
}
