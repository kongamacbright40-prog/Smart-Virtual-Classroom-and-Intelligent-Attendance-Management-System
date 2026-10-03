import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'ice_config.dart';
import 'signaling_service.dart';

/// Whether audio/video with one remote participant is flowing.
enum PeerLinkState { connecting, connected, failed }

/// One WebRTC connection to one remote participant.
///
/// Media sent to the peer: the shared local stream (camera + microphone) and,
/// while sharing, the shared screen as a *separate* stream (video + its sound),
/// added with a renegotiation. Media received from the peer is reported the
/// same way: [onRemoteStream] for its main stream, [onRemoteScreen] for a
/// second stream (its shared screen).
class PeerConnectionManager {
  final SignalingService signaling;
  final String remoteUserId;
  final MediaStream localStream; // shared camera stream, owned by the caller

  /// STUN/TURN configuration (see [IceConfig.configuration]).
  final Map<String, dynamic> iceConfiguration;

  /// Whether we made the first offer to this peer. Only that side restarts
  /// ICE after a failure, so both sides don't send offers at the same time.
  bool initiator = false;
  int _iceRestarts = 0;
  static const _maxIceRestarts = 3;

  RTCPeerConnection? _peerConnection;
  MediaStream? remoteStream;
  MediaStream? remoteScreenStream;

  /// ICE candidates that arrive before the remote description is set would be
  /// rejected by `addCandidate`, so they are held until then.
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteDescriptionSet = false;

  void Function(MediaStream stream)? onRemoteStream;
  void Function(MediaStream stream)? onRemoteScreen;
  void Function(PeerLinkState state)? onLinkState;

  /// Sender of our camera video. It exists even without a camera.
  RTCRtpSender? _videoSender;
  MediaStream? _fallbackRemoteStream;
  String? _mainRemoteStreamId;

  /// Senders of the shared screen (video, and audio when shared), kept after a
  /// share ends so the next share reuses them without renegotiating.
  final Map<String, RTCRtpSender> _screenSenders = {};

  /// Screen tracks were added while we were answering; offer them afterwards.
  bool _needsOffer = false;

  PeerConnectionManager({
    required this.signaling,
    required this.remoteUserId,
    required this.localStream,
    Map<String, dynamic>? iceConfiguration,
  }) : iceConfiguration = iceConfiguration ?? IceConfig.configuration();

  Future<void> init() async {
    _peerConnection = await createPeerConnection(iceConfiguration);

    // The SHARED local tracks (one camera stream, many peers).
    for (final track in localStream.getTracks()) {
      final sender = await _peerConnection!.addTrack(track, localStream);
      if (track.kind == 'video') _videoSender = sender;
    }
    // No camera / microphone: still open the channels, so we receive the
    // other side's media.
    if (_videoSender == null) {
      final transceiver = await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.SendRecv,
          streams: [localStream],
        ),
      );
      _videoSender = transceiver.sender;
    }
    if (localStream.getAudioTracks().isEmpty) {
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.SendRecv,
          streams: [localStream],
        ),
      );
    }

    // The first stream a peer sends is its camera/microphone; any other
    // stream is its shared screen.
    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      MediaStream stream;
      if (event.streams.isNotEmpty) {
        stream = event.streams[0];
      } else {
        stream = _fallbackRemoteStream ??= await createLocalMediaStream(
          'remote-$remoteUserId',
        );
        await stream.addTrack(event.track);
      }
      _mainRemoteStreamId ??= stream.id;
      if (stream.id == _mainRemoteStreamId) {
        remoteStream = stream;
        onRemoteStream?.call(stream);
      } else {
        remoteScreenStream = stream;
        onRemoteScreen?.call(stream);
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      signaling.sendCandidate(remoteUserId, candidate.toMap());
    };

    _peerConnection!.onIceConnectionState = _onIceState;
  }

  void _onIceState(RTCIceConnectionState state) {
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        _iceRestarts = 0;
        onLinkState?.call(PeerLinkState.connected);
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        onLinkState?.call(PeerLinkState.failed);
        unawaited(_restartIce());
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        onLinkState?.call(PeerLinkState.connecting);
      default:
        break;
    }
  }

  /// No network path was found (or it broke): look for a new one, e.g. after
  /// switching from Wi-Fi to mobile data.
  Future<void> _restartIce() async {
    if (!initiator || _iceRestarts >= _maxIceRestarts) return;
    _iceRestarts++;
    try {
      if (await _isStable()) await createOffer(iceRestart: true);
    } on Object catch (e) {
      debugPrint('ICE restart failed: $e');
    }
  }

  // Called by whoever initiates the call with this specific peer, and to
  // renegotiate (e.g. when a screen share is added).
  Future<void> createOffer({bool iceRestart = false}) async {
    _needsOffer = false;
    final offer = await _peerConnection!.createOffer({
      if (iceRestart) 'iceRestart': true,
    });
    await _peerConnection!.setLocalDescription(offer);
    signaling.sendOffer(remoteUserId, offer.toMap());
  }

  // Called when we receive an offer from this peer
  Future<void> handleOffer(Map<String, dynamic> offerData) async {
    final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
    await _peerConnection!.setRemoteDescription(offer);
    await _flushPendingCandidates();
    try {
      await _adoptOfferedVideoChannel();
    } on Object {
      // Best effort: only matters for peers without a camera.
    }

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    signaling.sendAnswer(remoteUserId, answer.toMap());
    if (_needsOffer) await createOffer();
  }

  // Called when we receive an answer to our offer from this peer
  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    final answer = RTCSessionDescription(answerData['sdp'], answerData['type']);
    await _peerConnection!.setRemoteDescription(answer);
    await _flushPendingCandidates();
  }

  // Called when a remote ICE candidate arrives from this peer
  Future<void> handleCandidate(Map<String, dynamic> candidateData) async {
    final value = candidateData['candidate'];
    if (value is! String || value.isEmpty) return; // end-of-candidates
    final candidate = RTCIceCandidate(
      value,
      candidateData['sdpMid'],
      candidateData['sdpMLineIndex'],
    );
    if (!_remoteDescriptionSet) {
      _pendingCandidates.add(candidate);
      return;
    }
    await _peerConnection!.addCandidate(candidate);
  }

  Future<void> _flushPendingCandidates() async {
    _remoteDescriptionSet = true;
    final pending = List.of(_pendingCandidates);
    _pendingCandidates.clear();
    for (final c in pending) {
      await _peerConnection!.addCandidate(c);
    }
  }

  /// Starts sending [screen] (its video and, if shared, its sound).
  ///
  /// [negotiate]: send a new offer now. Pass false while the connection is
  /// being set up (the first offer / answer then includes the screen).
  Future<void> startScreen(MediaStream screen, {bool negotiate = true}) async {
    final pc = _peerConnection!;
    var added = false;
    for (final track in screen.getTracks()) {
      final kind = track.kind ?? 'video';
      final existing = _screenSenders[kind];
      if (existing != null) {
        await existing.replaceTrack(track);
      } else {
        _screenSenders[kind] = await pc.addTrack(track, screen);
        added = true;
      }
      if (kind == 'video') await _tuneScreenVideo(_screenSenders[kind]!);
    }
    // A sound sender left over from a previous share with sound.
    if (screen.getAudioTracks().isEmpty) {
      await _screenSenders['audio']?.replaceTrack(null);
    }
    if (!added) return;
    if (negotiate && await _isStable()) {
      await createOffer();
    } else {
      _needsOffer = true;
    }
  }

  /// Stops sending the shared screen (keeps the channel for the next share).
  Future<void> stopScreen() async {
    for (final sender in _screenSenders.values) {
      await sender.replaceTrack(null);
    }
  }

  /// Offer the screen tracks added during set-up, if not done yet.
  Future<void> offerIfNeeded() async {
    if (_needsOffer && await _isStable()) await createOffer();
  }

  Future<bool> _isStable() async =>
      await _peerConnection!.getSignalingState() ==
      RTCSignalingState.RTCSignalingStateStable;

  /// Keeps a shared screen moving smoothly (e.g. a video being played):
  /// limits frame rate and bitrate and prefers frame rate over sharpness when
  /// bandwidth is short. Phone screens (very high resolution) are halved.
  Future<void> _tuneScreenVideo(RTCRtpSender sender) async {
    try {
      final params = sender.parameters;
      final encodings = params.encodings;
      if (encodings == null || encodings.isEmpty) {
        params.encodings = [RTCRtpEncoding()];
      }
      for (final e in params.encodings!) {
        e.maxFramerate = 24;
        e.maxBitrate = 2500000;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          e.scaleResolutionDownBy = 2.0;
        }
      }
      params.degradationPreference =
          RTCDegradationPreference.MAINTAIN_FRAMERATE;
      await sender.setParameters(params);
    } on Object {
      // Not supported on this platform: the defaults still work.
    }
  }

  /// As the answering side, a video channel we created ourselves (no camera)
  /// is not part of the other side's offer. Send through the offer's video
  /// channel instead.
  Future<void> _adoptOfferedVideoChannel() async {
    final pc = _peerConnection!;
    final transceivers = await pc.getTransceivers();
    final ours = transceivers
        .where((t) => t.sender.senderId == _videoSender?.senderId)
        .firstOrNull;
    if (ours != null && ours.mid.isNotEmpty) return;
    final screenSenderIds = {for (final s in _screenSenders.values) s.senderId};
    for (final t in transceivers) {
      if (t.mid.isEmpty) continue;
      if (t.receiver.track?.kind != 'video') continue;
      if (screenSenderIds.contains(t.sender.senderId)) continue;
      await t.setDirection(TransceiverDirection.SendRecv);
      _videoSender = t.sender;
      return;
    }
  }

  // Dispose only THIS peer's connection, not the shared local stream, since
  // other peer connections may still be using it.
  Future<void> dispose() async {
    await remoteStream?.dispose();
    await remoteScreenStream?.dispose();
    await _peerConnection?.close();
  }
}
