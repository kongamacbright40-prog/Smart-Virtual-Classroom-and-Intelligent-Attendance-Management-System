import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'ice_config.dart';
import 'signaling_service.dart';

class PeerConnectionManager {
  final SignalingService signaling;
  final String remoteUserId;

  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  void Function(MediaStream stream)? onRemoteStream;
  void Function(MediaStream stream)? onLocalStream;

  PeerConnectionManager({required this.signaling, required this.remoteUserId});

  Future<void> init() async {
    // 1. Get local camera/mic
    localStream = await navigator.mediaDevices.getUserMedia({
      'video': {'facingMode': 'user'},
      'audio': true,
    });
    onLocalStream?.call(localStream!);

    // 2. Create the peer connection with STUN/TURN config
    _peerConnection = await createPeerConnection(IceConfig.configuration);

    // 3. Add our local tracks so the other side receives them
    for (var track in localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, localStream!);
    }

    // 4. When a remote track arrives, expose it via callback
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onRemoteStream?.call(remoteStream!);
      }
    };

    // 5. When we discover an ICE candidate, send it to the other peer
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      signaling.sendCandidate(remoteUserId, candidate.toMap());
    };
  }

  // Called by whoever initiates the call
  Future<void> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    signaling.sendOffer(remoteUserId, offer.toMap());
  }

  // Called when we receive an offer from the other peer
  Future<void> handleOffer(Map<String, dynamic> offerData) async {
    final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    signaling.sendAnswer(remoteUserId, answer.toMap());
  }

  // Called when we receive an answer to our offer
  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    final answer = RTCSessionDescription(answerData['sdp'], answerData['type']);
    await _peerConnection!.setRemoteDescription(answer);
  }

  // Called when a remote ICE candidate arrives
  Future<void> handleCandidate(Map<String, dynamic> candidateData) async {
    final candidate = RTCIceCandidate(
      candidateData['candidate'],
      candidateData['sdpMid'],
      candidateData['sdpMLineIndex'],
    ); // this should be the best coding
    await _peerConnection!.addCandidate(candidate);
  }

  Future<void> dispose() async {
    await localStream?.dispose();
    await remoteStream?.dispose();
    await _peerConnection?.close();
  }
}
