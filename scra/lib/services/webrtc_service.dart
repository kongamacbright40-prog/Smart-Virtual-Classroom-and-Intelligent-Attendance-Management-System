import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/error_handler.dart';
import 'screen_capture_service.dart';
import 'webrtc/ice_config.dart';
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
    this.failedPeerIds = const [],
    this.relayAvailable = true,
    this.errorMessage,
  });

  final MediaConnectionState connection;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final bool screenSharing;
  final List<String> remotePeerIds;

  /// Participants whose audio/video could not connect (no network path).
  final List<String> failedPeerIds;

  /// Whether a TURN relay is configured (needed across different networks).
  final bool relayAvailable;
  final String? errorMessage;

  /// A problem with audio/video worth showing in the classroom, if any.
  String? get notice {
    if (connection == MediaConnectionState.failed) return errorMessage;
    if (failedPeerIds.isEmpty) return null;
    final who = failedPeerIds.length == 1
        ? 'a participant'
        : '${failedPeerIds.length} participants';
    return relayAvailable
        ? 'Audio/video with $who could not connect. Retrying…'
        : 'Audio/video with $who could not connect: your networks block '
              'direct calls and the server has no TURN relay configured.';
  }

  MediaState copyWith({
    MediaConnectionState? connection,
    bool? microphoneEnabled,
    bool? cameraEnabled,
    bool? screenSharing,
    List<String>? remotePeerIds,
    List<String>? failedPeerIds,
    bool? relayAvailable,
    String? errorMessage,
  }) => MediaState(
    connection: connection ?? this.connection,
    microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
    cameraEnabled: cameraEnabled ?? this.cameraEnabled,
    screenSharing: screenSharing ?? this.screenSharing,
    remotePeerIds: remotePeerIds ?? this.remotePeerIds,
    failedPeerIds: failedPeerIds ?? this.failedPeerIds,
    relayAvailable: relayAvailable ?? this.relayAvailable,
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

  /// Whiteboard messages from the lecturer (`board` / `board_state`).
  Stream<Map<String, dynamic>> get boardMessages;

  /// Lecturer: sends a whiteboard operation to everyone in the class.
  void sendBoard(Map<String, dynamic> operation);
  Future<void> dispose();
}

/// Mesh WebRTC implementation built on [SignalingService]
/// (`/ws/signal/{classId}?token=`) and [PeerConnectionManager]: one camera
/// stream shared across one peer connection per remote participant.
class FlutterWebRTCService implements WebRTCService {
  FlutterWebRTCService({String? serverUrl, this.tokenProvider})
    : _serverUrl = serverUrl ?? AppConfig.wsBaseUrl;

  final String _serverUrl;

  /// Supplies the access token the signaling socket authenticates with.
  final Future<String?> Function()? tokenProvider;
  final _controller = StreamController<MediaState>.broadcast();
  final _board = StreamController<Map<String, dynamic>>.broadcast();
  MediaState _state = const MediaState();

  SignalingService? _signaling;
  MediaStream? _localStream;
  MediaStream? _screenStream;
  Map<String, dynamic> _iceConfiguration = IceConfig.configuration();
  final Set<String> _failedPeers = {};
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final Map<String, Future<PeerConnectionManager>> _peerFutures = {};

  /// Video renderers of remote participants, keyed by peer (profile) id.
  final Map<String, RTCVideoRenderer> remoteRenderers = {};

  /// Renderers of remote participants' shared screens (video + its sound).
  final Map<String, RTCVideoRenderer> remoteScreenRenderers = {};
  bool _rendererReady = false;

  /// Whether [localRenderer] can be shown (initialized and has a stream).
  bool get hasLocalVideo => _rendererReady && _localStream != null;

  @override
  MediaState get state => _state;

  @override
  Stream<MediaState> get stateChanges => _controller.stream;

  @override
  Stream<Map<String, dynamic>> get boardMessages => _board.stream;

  @override
  void sendBoard(Map<String, dynamic> operation) =>
      _signaling?.sendBoard(operation);

  void _set(MediaState s) {
    _state = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  /// Camera + microphone, falling back to whatever is available. A user
  /// without a camera / microphone (or who denied access) still joins the
  /// class to watch and listen.
  Future<MediaStream> _openLocalMedia() async {
    const attempts = <Map<String, dynamic>>[
      {
        'video': {'facingMode': 'user'},
        'audio': true,
      },
      {'audio': true},
      {
        'video': {'facingMode': 'user'},
      },
    ];
    for (final constraints in attempts) {
      try {
        return await navigator.mediaDevices.getUserMedia(constraints);
      } on Object catch (e) {
        ErrorHandler.log(e);
      }
    }
    return createLocalMediaStream('local');
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
      final token = await tokenProvider?.call();
      // Ask the server for its STUN/TURN relay while the camera opens.
      final (local, ice) = await (
        _openLocalMedia(),
        IceConfig.fetch(token: token),
      ).wait;
      _iceConfiguration = IceConfig.configuration(ice?.servers);
      _failedPeers.clear();
      _localStream = local;
      localRenderer.srcObject = local;
      _applyTrackState(audio: audio, video: video);
      final hasCamera = local.getVideoTracks().isNotEmpty;
      final hasMic = local.getAudioTracks().isNotEmpty;
      _set(
        _state.copyWith(
          failedPeerIds: const [],
          relayAvailable:
              (ice?.turnConfigured ?? false) || IceConfig.hasBuiltInTurn,
        ),
      );

      final signaling = SignalingService(
        roomId: roomId,
        userId: userId,
        serverUrl: _serverUrl,
        token: token,
      );
      _signaling = signaling;

      // Existing participants make the offer to newcomers.
      signaling.onUserJoined = (data) => _guard(() async {
        final peerId = data['from'] as String;
        // A rejoin (e.g. after a network drop) replaces the old connection.
        if (_peerFutures.containsKey(peerId)) await _removePeer(peerId);
        final peer = await _peerFor(peerId);
        peer.initiator = true;
        await peer.createOffer();
      });
      signaling.onOffer = (data) => _guard(() async {
        final manager = await _peerFor(data['from'] as String);
        await manager.handleOffer(
          Map<String, dynamic>.from(data['payload'] as Map),
        );
      });
      signaling.onAnswer = (data) => _guard(() async {
        final manager = await _peerFutures[data['from'] as String];
        await manager?.handleAnswer(
          Map<String, dynamic>.from(data['payload'] as Map),
        );
        // A screen share started while this answer was pending.
        await manager?.offerIfNeeded();
      });
      // Candidates can arrive before the offer is processed: create the peer
      // so they are queued instead of dropped.
      signaling.onCandidate = (data) => _guard(() async {
        final manager = await _peerFor(data['from'] as String);
        await manager.handleCandidate(
          Map<String, dynamic>.from(data['payload'] as Map),
        );
      });
      signaling.onUserLeft = (data) =>
          _guard(() => _removePeer(data['from'] as String));
      signaling.onBoard = (data) {
        if (!_board.isClosed) _board.add(data);
      };
      signaling.onSessionEnded = () => _set(
        _state.copyWith(
          connection: MediaConnectionState.closed,
          errorMessage: 'The lecturer ended this class.',
        ),
      );
      signaling.onDisconnected = () {
        if (_state.connection == MediaConnectionState.closed) return;
        _set(
          _state.copyWith(
            connection: MediaConnectionState.failed,
            errorMessage: 'Disconnected from the media server.',
          ),
        );
      };

      try {
        await signaling.connect();
      } on Object catch (e) {
        ErrorHandler.log(e);
        _set(
          _state.copyWith(
            connection: MediaConnectionState.failed,
            errorMessage: 'Could not connect to the classroom server.',
          ),
        );
        return;
      }
      _set(
        _state.copyWith(
          connection: MediaConnectionState.connected,
          microphoneEnabled: audio && hasMic,
          cameraEnabled: video && hasCamera,
          errorMessage: hasCamera && hasMic
              ? null
              : !hasCamera && !hasMic
              ? 'No camera or microphone available: you can watch and listen.'
              : !hasCamera
              ? 'No camera available: others can hear you but not see you.'
              : 'No microphone available: others can see you but not hear you.',
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

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      ErrorHandler.log(e);
    }
  }

  /// One connection per remote peer, created at most once even when several
  /// signaling messages for that peer arrive at the same time.
  Future<PeerConnectionManager> _peerFor(String peerId) =>
      _peerFutures.putIfAbsent(peerId, () => _createPeer(peerId));

  Future<PeerConnectionManager> _createPeer(String peerId) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    remoteRenderers[peerId] = renderer;
    final manager = PeerConnectionManager(
      signaling: _signaling!,
      remoteUserId: peerId,
      localStream: _localStream!,
      iceConfiguration: _iceConfiguration,
    );
    manager.onLinkState = (link) {
      final changed = link == PeerLinkState.failed
          ? _failedPeers.add(peerId)
          : link == PeerLinkState.connected && _failedPeers.remove(peerId);
      if (changed) {
        _set(_state.copyWith(failedPeerIds: _failedPeers.toList()));
      }
    };
    manager.onRemoteStream = (stream) {
      // Set again for every track, so a later audio track is played too.
      renderer.srcObject = stream;
      _set(_state.copyWith(remotePeerIds: remoteRenderers.keys.toList()));
    };
    manager.onRemoteScreen = (stream) => _guard(() async {
      var screenRenderer = remoteScreenRenderers[peerId];
      if (screenRenderer == null) {
        screenRenderer = RTCVideoRenderer();
        await screenRenderer.initialize();
        remoteScreenRenderers[peerId] = screenRenderer;
      }
      screenRenderer.srcObject = stream;
      _set(_state.copyWith(remotePeerIds: remoteRenderers.keys.toList()));
    });
    await manager.init();
    // Joined while we share: the first offer / answer includes the screen.
    final screen = _screenStream;
    if (screen != null) await manager.startScreen(screen, negotiate: false);
    _set(_state.copyWith(remotePeerIds: remoteRenderers.keys.toList()));
    return manager;
  }

  Future<void> _removePeer(String peerId) async {
    final pending = _peerFutures.remove(peerId);
    final renderer = remoteRenderers.remove(peerId);
    final screenRenderer = remoteScreenRenderers.remove(peerId);
    try {
      await (await pending)?.dispose();
    } on Object catch (e) {
      ErrorHandler.log(e);
    }
    renderer?.srcObject = null;
    await renderer?.dispose();
    screenRenderer?.srcObject = null;
    await screenRenderer?.dispose();
    _failedPeers.remove(peerId);
    _set(
      _state.copyWith(
        remotePeerIds: remoteRenderers.keys.toList(),
        failedPeerIds: _failedPeers.toList(),
      ),
    );
  }

  MediaStreamTrack? get _screenVideoTrack {
    final tracks = _screenStream?.getVideoTracks() ?? const [];
    return tracks.isEmpty ? null : tracks.first;
  }

  Future<void> _forEachPeer(
    Future<void> Function(PeerConnectionManager peer) action,
  ) async {
    for (final future in _peerFutures.values.toList()) {
      await _guard(() async => action(await future));
    }
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
      if (ScreenCaptureService.isRequired) {
        // Android: the user must consent first, then a foreground service of
        // type "mediaProjection" must be running before capture starts.
        final granted = await Helper.requestCapturePermission();
        if (!granted) {
          _set(
            _state.copyWith(
              errorMessage: 'Screen sharing needs your permission to start.',
            ),
          );
          return;
        }
        await ScreenCaptureService.start();
      }
      final screen = await navigator.mediaDevices.getDisplayMedia(
        kIsWeb
            ? {
                // Browser: suggest the entire screen (so switching windows is
                // shared too), include the sound of a playing video, and let
                // the lecturer switch the shared tab / window later.
                'video': {
                  'displaySurface': 'monitor',
                  'frameRate': {'ideal': 24, 'max': 30},
                },
                'audio': true,
                'systemAudio': 'include',
                'surfaceSwitching': 'include',
                'selfBrowserSurface': 'exclude',
              }
            : {'video': true},
      );
      _screenStream = screen;
      final track = _screenVideoTrack;
      if (track == null) throw StateError('No screen video track');
      // Sharing can also be stopped from the system UI / browser bar.
      track.onEnded = () => _guard(stopScreenShare);
      await _forEachPeer((peer) => peer.startScreen(screen));
      if (_rendererReady) localRenderer.srcObject = screen;
      _set(_state.copyWith(screenSharing: true));
    } on Object catch (e) {
      ErrorHandler.log(e);
      await _releaseScreen();
      _set(
        _state.copyWith(
          errorMessage: kIsWeb
              ? 'Screen sharing was cancelled or is blocked by the browser.'
              : 'Screen sharing is not available on this device.',
        ),
      );
    }
  }

  @override
  Future<void> stopScreenShare() async {
    if (_screenStream == null) return;
    await _forEachPeer((peer) => peer.stopScreen());
    if (_rendererReady) localRenderer.srcObject = _localStream;
    await _releaseScreen();
    _set(_state.copyWith(screenSharing: false));
  }

  Future<void> _releaseScreen() async {
    final screen = _screenStream;
    _screenStream = null;
    for (final t in screen?.getTracks() ?? const <MediaStreamTrack>[]) {
      await t.stop();
    }
    await screen?.dispose();
    if (ScreenCaptureService.isRequired) await ScreenCaptureService.stop();
  }

  @override
  Future<void> leaveRoom() async {
    for (final id in _peerFutures.keys.toList()) {
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
    await _board.close();
  }
}
