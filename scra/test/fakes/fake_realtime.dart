import 'dart:async';

import 'package:smart_class/services/webrtc_service.dart';
import 'package:smart_class/services/websocket_service.dart';

/// Connects instantly and loops sent events back, for tests.
class MockWebSocketService implements WebSocketService {
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _states = StreamController<RealtimeConnectionState>.broadcast();
  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;
  final List<RealtimeEvent> sent = [];

  @override
  RealtimeConnectionState get state => _state;

  @override
  Stream<RealtimeConnectionState> get stateChanges => _states.stream;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  void _setState(RealtimeConnectionState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  @override
  Future<void> connect(String path, {Map<String, String>? query}) async {
    _setState(RealtimeConnectionState.connecting);
    _setState(RealtimeConnectionState.connected);
  }

  /// Simulates a server push.
  void emit(RealtimeEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  @override
  void send(RealtimeEvent event) {
    if (!_state.isConnected) return;
    sent.add(event);
  }

  @override
  Future<void> disconnect() async =>
      _setState(RealtimeConnectionState.disconnected);

  @override
  Future<void> dispose() async {
    await _events.close();
    await _states.close();
  }
}

/// UI-only implementation: tracks toggles without touching hardware.
class MockWebRTCService implements WebRTCService {
  final _controller = StreamController<MediaState>.broadcast();
  MediaState _state = const MediaState();

  @override
  MediaState get state => _state;

  @override
  Stream<MediaState> get stateChanges => _controller.stream;

  void _set(MediaState s) {
    _state = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  @override
  Future<void> joinRoom({
    required String roomId,
    required String userId,
    bool audio = true,
    bool video = true,
  }) async {
    _set(_state.copyWith(connection: MediaConnectionState.connecting));
    _set(
      MediaState(
        connection: MediaConnectionState.connected,
        microphoneEnabled: audio,
        cameraEnabled: video,
      ),
    );
  }

  @override
  Future<void> leaveRoom() async =>
      _set(const MediaState(connection: MediaConnectionState.closed));

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async =>
      _set(_state.copyWith(microphoneEnabled: enabled));

  @override
  Future<void> setCameraEnabled(bool enabled) async =>
      _set(_state.copyWith(cameraEnabled: enabled));

  @override
  Future<void> switchCamera() async {}

  @override
  Future<void> startScreenShare() async =>
      _set(_state.copyWith(screenSharing: true));

  @override
  Future<void> stopScreenShare() async =>
      _set(_state.copyWith(screenSharing: false));

  @override
  Future<void> dispose() => _controller.close();
}
