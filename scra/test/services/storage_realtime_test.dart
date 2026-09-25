import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_realtime.dart';

import 'package:smart_class/models/models.dart';
import 'package:smart_class/services/auth_service.dart';
import 'package:smart_class/services/storage_service.dart';
import 'package:smart_class/services/webrtc_service.dart';
import 'package:smart_class/services/websocket_service.dart';

void main() {
  const user = UserModel(
    id: 'stu-001',
    fullName: 'Konga Mac-Bright',
    email: 'k@univ.edu',
    role: UserRole.student,
  );

  group('StorageService', () {
    late StorageService storage;
    setUp(() => storage = StorageService(InMemoryStore()));

    test('defaults', () async {
      expect(await storage.isOnboardingCompleted(), isFalse);
      expect(await storage.getSelectedRole(), isNull);
      expect(await storage.getSession(), isNull);
      expect((await storage.getSettings()).themeMode, ThemeMode.light);
    });

    test('persists onboarding, role, session and settings', () async {
      await storage.setOnboardingCompleted(true);
      await storage.setSelectedRole(UserRole.lecturer);
      await storage.saveSession(
        const AuthSessionModel(user: user, accessToken: 't', refreshToken: 'r'),
      );
      await storage.saveSettings(
        const AppSettingsModel(themeMode: ThemeMode.dark),
      );

      expect(await storage.isOnboardingCompleted(), isTrue);
      expect(await storage.getSelectedRole(), UserRole.lecturer);
      final session = await storage.getSession();
      expect(session?.user, user);
      expect(session?.refreshToken, 'r');
      expect((await storage.getSettings()).themeMode, ThemeMode.dark);

      await storage.clearSession();
      expect(await storage.getSession(), isNull);
      expect(await storage.isOnboardingCompleted(), isTrue);
    });

    test('corrupted session data is discarded', () async {
      final store = InMemoryStore({
        'auth_token': 't',
        'current_user': '{not json',
      });
      final s = StorageService(store);
      expect(await s.getSession(), isNull);
      expect(await store.getString('auth_token'), isNull);
    });
  });

  group('AuthService', () {
    test('start / restore / clear', () async {
      final storage = StorageService(InMemoryStore());
      final auth = AuthService(storage);
      await auth.start(const AuthSessionModel(user: user, accessToken: 'tok'));
      expect(await auth.accessToken(), 'tok');

      final restored = AuthService(storage);
      expect((await restored.restore())?.user.id, 'stu-001');

      await restored.updateUser(user.copyWith(fullName: 'K. Mac-Bright'));
      expect((await storage.getSession())?.user.fullName, 'K. Mac-Bright');

      await restored.clear();
      expect(restored.isAuthenticated, isFalse);
      expect(await storage.getSession(), isNull);
    });

    test('expired sessions are not restored', () async {
      final storage = StorageService(InMemoryStore());
      await AuthService(storage).start(
        AuthSessionModel(
          user: user,
          accessToken: 'tok',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      expect(await AuthService(storage).restore(), isNull);
      expect(await storage.getSession(), isNull);
    });
  });

  group('Realtime mocks', () {
    test('MockWebSocketService tracks state, sends and emits', () async {
      final socket = MockWebSocketService();
      final states = <RealtimeConnectionState>[];
      socket.stateChanges.listen(states.add);
      socket.send(const RealtimeEvent('ignored'));
      await socket.connect('/ws/sessions/1/events');
      socket.send(const RealtimeEvent('chat.message', {'m': 1}));
      expect(socket.sent.single.type, 'chat.message');
      final next = socket.events.first;
      socket.emit(const RealtimeEvent('participant.joined'));
      expect((await next).type, 'participant.joined');
      await socket.disconnect();
      await Future<void>.delayed(Duration.zero);
      expect(states.last, RealtimeConnectionState.disconnected);
      expect(states, contains(RealtimeConnectionState.connected));
      await socket.dispose();
    });

    test('RealtimeEvent JSON', () {
      final e = RealtimeEvent.fromJson({
        'type': 'question.launched',
        'payload': {'id': 'q1'},
      });
      expect(e.type, 'question.launched');
      expect(e.toJson()['payload'], {'id': 'q1'});
      expect(RealtimeEvent.fromJson(const {}).type, 'unknown');
    });

    test('MockWebRTCService toggles media state', () async {
      final media = MockWebRTCService();
      await media.joinRoom(roomId: 'r', userId: 'u', audio: false, video: true);
      expect(media.state.connection, MediaConnectionState.connected);
      expect(media.state.microphoneEnabled, isFalse);
      await media.setMicrophoneEnabled(true);
      await media.startScreenShare();
      expect(media.state.microphoneEnabled, isTrue);
      expect(media.state.screenSharing, isTrue);
      await media.leaveRoom();
      expect(media.state.connection, MediaConnectionState.closed);
      await media.dispose();
    });
  });
}
