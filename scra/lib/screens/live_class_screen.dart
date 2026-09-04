import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../webrtc/signaling_service.dart';
import '../webrtc/peer_connection_manager.dart';

class LiveClassScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String remoteUserId;
  final String serverUrl;

  const LiveClassScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.remoteUserId,
    required this.serverUrl,
  });

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  late SignalingService _signaling;
  late PeerConnectionManager _peerManager;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _signaling = SignalingService(
      roomId: widget.roomId,
      userId: widget.userId,
      serverUrl: widget.serverUrl,
    );

    _peerManager = PeerConnectionManager(
      signaling: _signaling,
      remoteUserId: widget.remoteUserId,
    );

    _peerManager.onLocalStream = (stream) {
      _localRenderer.srcObject = stream;
      setState(() {});
    };

    _peerManager.onRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    };

    try {
      await _peerManager.init();

      _signaling.onOffer = (data) => _peerManager.handleOffer(data['payload']);
      _signaling.onAnswer = (data) =>
          _peerManager.handleAnswer(data['payload']);
      _signaling.onCandidate = (data) =>
          _peerManager.handleCandidate(data['payload']);

      await _signaling.connect();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Setup failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerManager.dispose();
    _signaling.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Room: ${widget.roomId}')),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : Stack(
              children: [
                Positioned.fill(child: RTCVideoView(_remoteRenderer)),
                Positioned(
                  right: 16,
                  bottom: 16,
                  width: 100,
                  height: 140,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RTCVideoView(_localRenderer, mirror: true),
                  ),
                ),
              ],
            ),
    );
  }
}
