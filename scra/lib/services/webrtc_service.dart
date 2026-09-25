import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/error_handler.dart';
import 'webrtc/peer_connection_manager.dart';
import 'webrtc/signaling_service.dart';

enum MediaConnectionState {
  idle,
  connecting,
  connected,
  failed,
  closed;

  bool get isActive =>
      this == MediaConnectionState.connecting ||
      this == MediaConnectionState.connected;
}

/// Snapshot of the local media session.
class MediaState {
  const MediaState({
    this.connection = MediaConnectionState.idle,
    this.microphoneEnabled = false,
    this.cameraEnabled = false,
    this.screenSharing = false,
    this.remotePeerIds = const [],
    this.errorMessage,
  });

  final MediaConnectionState connection;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final bool screenSharing;
  final List<String> remotePeerIds;
  final String? errorMessage;

  MediaState copyWith({
    MediaConnectionState? connection,
    bool? microphoneEnabled,
    bool? cameraEnabled,
    bool? screenSharing,
    List<String>? remotePeerIds,
    String? errorMessage,
  }) => MediaState(
    connection: connection ?? this.connection,
    microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
    cameraEnabled: cameraEnabled ?? this.cameraEnabled,
    screenSharing: screenSharing ?? this.screenSharing,
    remotePeerIds: remotePeerIds ?? this.remotePeerIds,
    errorMessage: errorMessage,
  );
}

/// Audio/video layer of the live classroom.
abstract interface class WebRTCService {
  MediaState get state;
  Stream<MediaState> get stateChanges;

  Future<void> joinRoom({
    required String roomId,
    required String userId,
    bool audio = true,
    bool video = true,
  });
  Future<void> leaveRoom();
  Future<void> setMicrophoneEnabled(bool enabled);
  Future<void> setCameraEnabled(bool enabled);
  Future<void> switchCamera();
  Future<void> startScreenShare();
  Future<void> stopScreenShare();
  Future<void> dispose();
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

/// Mesh WebRTC implementation built on the project's existing
/// [SignalingService] (`/ws/classroom/{roomId}/{userId}`) and
/// [PeerConnectionManager]: one camera stream shared across one peer
/// connection per remote participant.
class FlutterWebRTCService implements WebRTCService {
  FlutterWebRTCService({String? serverUrl})
    : _serverUrl = serverUrl ?? AppConfig.wsBaseUrl;

  final String _serverUrl;
  final _controller = StreamController<MediaState>.broadcast();
  MediaState _state = const MediaState();

  SignalingService? _signaling;
  MediaStream? _localStream;
  MediaStream? _screenStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final Map<String, PeerConnectionManager> _peers = {};
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  bool _rendererReady = false;

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
    try {
      if (!_rendererReady) {
        await localRenderer.initialize();
        _rendererReady = true;
      }
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': true,
      });
      localRenderer.srcObject = _localStream;
      _applyTrackState(audio: audio, video: video);

      final signaling = SignalingService(
        roomId: roomId,
        userId: userId,
        serverUrl: _serverUrl,
      );
      _signaling = signaling;

      // Existing participants make the offer to newcomers.
      signaling.onUserJoined = (data) async {
        final peerId = data['from'] as String;
        final manager = await _createPeer(peerId);
        await manager.createOffer();
      };
      signaling.onOffer = (data) async {
        final peerId = data['from'] as String;
        final manager = _peers[peerId] ?? await _createPeer(peerId);
        await manager.handleOffer(
          Map<String, dynamic>.from(data['payload'] as Map),
        );
      };
      signaling.onAnswer = (data) async {
        await _peers[data['from'] as String]?.handleAnswer(
          Map<String, dynamic>.from(data['payload'] as Map),
        );
      };
      signaling.onCandidate = (data) async {
        await _peers[data['from'] as String]?.handleCandidate(
          Map<String, dynamic>.from(data['payload'] as Map),
        );
      };
      signaling.onUserLeft = (data) => _removePeer(data['from'] as String);
      signaling.onDisconnected = () => _set(
        _state.copyWith(
          connection: MediaConnectionState.failed,
          errorMessage: 'Disconnected from the media server.',
        ),
      );

      await signaling.connect();
      _set(
        _state.copyWith(
          connection: MediaConnectionState.connected,
          microphoneEnabled: audio,
          cameraEnabled: video,
        ),
      );
    } on Object catch (e) {
      ErrorHandler.log(e);
      _set(
        _state.copyWith(
          connection: MediaConnectionState.failed,
          errorMessage: 'Could not start camera or microphone.',
        ),
      );
    }
  }

  Future<PeerConnectionManager> _createPeer(String peerId) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    remoteRenderers[peerId] = renderer;
    final manager = PeerConnectionManager(
      signaling: _signaling!,
      remoteUserId: peerId,
      localStream: _localStream!,
    );
    manager.onRemoteStream = (stream) {
      renderer.srcObject = stream;
      _set(_state.copyWith(remotePeerIds: remoteRenderers.keys.toList()));
    };
    await manager.init();
    _peers[peerId] = manager;
    _set(_state.copyWith(remotePeerIds: remoteRenderers.keys.toList()));
    return manager;
  }

  Future<void> _removePeer(String peerId) async {
    await _peers.remove(peerId)?.dispose();
    await remoteRenderers.remove(peerId)?.dispose();
    _set(_state.copyWith(remotePeerIds: remoteRenderers.keys.toList()));
  }

  void _applyTrackState({bool? audio, bool? video}) {
    final stream = _localStream;
    if (stream == null) return;
    if (audio != null) {
      for (final t in stream.getAudioTracks()) {
        t.enabled = audio;
      }
    }
    if (video != null) {
      for (final t in stream.getVideoTracks()) {
        t.enabled = video;
      }
    }
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    _applyTrackState(audio: enabled);
    _set(_state.copyWith(microphoneEnabled: enabled));
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    _applyTrackState(video: enabled);
    _set(_state.copyWith(cameraEnabled: enabled));
  }

  @override
  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? const [];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  @override
  Future<void> startScreenShare() async {
    try {
      _screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
      });
      _set(_state.copyWith(screenSharing: true));
    } on Object catch (e) {
      ErrorHandler.log(e);
      _set(_state.copyWith(errorMessage: 'Screen sharing is not available.'));
    }
  }

  @override
  Future<void> stopScreenShare() async {
    for (final t in _screenStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _screenStream?.dispose();
    _screenStream = null;
    _set(_state.copyWith(screenSharing: false));
  }

  @override
  Future<void> leaveRoom() async {
    for (final id in _peers.keys.toList()) {
      await _removePeer(id);
    }
    await stopScreenShare();
    for (final t in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    if (_rendererReady) localRenderer.srcObject = null;
    _signaling?.disconnect();
    _signaling = null;
    _set(const MediaState(connection: MediaConnectionState.closed));
  }

  @override
  Future<void> dispose() async {
    await leaveRoom();
    if (_rendererReady) await localRenderer.dispose();
    await _controller.close();
  }
}
