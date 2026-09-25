import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'ice_config.dart';
import 'signaling_service.dart';

class PeerConnectionManager {
  final SignalingService signaling;
  final String remoteUserId;
  final MediaStream localStream; // now passed in, not created here

  RTCPeerConnection? _peerConnection;
  MediaStream? remoteStream;

  void Function(MediaStream stream)? onRemoteStream;

  PeerConnectionManager({
    required this.signaling,
    required this.remoteUserId,
    required this.localStream, // caller now supplies the shared camera stream
  });

  Future<void> init() async {
    // Create the peer connection with STUN/TURN config
    _peerConnection = await createPeerConnection(IceConfig.configuration);

    //  Add the SHARED local tracks so the other side receives them
    //    (no getUserMedia call here anymore — one camera stream, many peers)
    for (var track in localStream.getTracks()) {
      await _peerConnection!.addTrack(track, localStream);
    }

    //  When a remote track arrives, expose it via callback
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onRemoteStream?.call(remoteStream!);
      }
    };

    //  When we discover an ICE candidate, send it to this specific peer
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      signaling.sendCandidate(remoteUserId, candidate.toMap());
    };
  }

  // Called by whoever initiates the call with this specific peer
  Future<void> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    signaling.sendOffer(remoteUserId, offer.toMap());
  }

  // Called when we receive an offer from this peer
  Future<void> handleOffer(Map<String, dynamic> offerData) async {
    final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    signaling.sendAnswer(remoteUserId, answer.toMap());
  }

  // Called when we receive an answer to our offer from this peer
  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    final answer = RTCSessionDescription(answerData['sdp'], answerData['type']);
    await _peerConnection!.setRemoteDescription(answer);
  }

  // Called when a remote ICE candidate arrives from this peer
  Future<void> handleCandidate(Map<String, dynamic> candidateData) async {
    final candidate = RTCIceCandidate(
      candidateData['candidate'],
      candidateData['sdpMid'],
      candidateData['sdpMLineIndex'],
    );
    await _peerConnection!.addCandidate(candidate);
  }

  // Dispose only THIS peer's connection — NOT the shared local stream,
  // since other peer connections may still be using it.
  Future<void> dispose() async {
    await remoteStream?.dispose();
    await _peerConnection?.close();
  }
}
