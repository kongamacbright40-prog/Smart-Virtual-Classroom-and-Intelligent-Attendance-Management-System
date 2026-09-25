import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../webrtc/signaling_service.dart';
import '../webrtc/peer_connection_manager.dart';

class LiveClassScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String serverUrl;
  // Note: remoteUserId is GONE — we no longer know in advance who else
  // will be in the room. Peers are discovered dynamically as they join.

  const LiveClassScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.serverUrl,
  });

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  late SignalingService _signaling;

  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  // One PeerConnectionManager + one renderer PER remote person in the room,
  // keyed by their userId. This replaces the old single _peerManager /
  // _remoteRenderer pair.
  final Map<String, PeerConnectionManager> _peers = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _localRenderer.initialize();

    try {
      // Get the camera/mic ONCE — shared across every peer connection we create.
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': true,
      });
      _localRenderer.srcObject = _localStream;

      _signaling = SignalingService(
        roomId: widget.roomId,
        userId: widget.userId,
        serverUrl: widget.serverUrl,
      );

      // A new peer joined the room — create a connection just for them,
      // and WE make the offer (since we were already here, they're the newcomer).
      _signaling.onUserJoined = (data) async {
        final newPeerId = data['from'] as String;
        final manager = await _createPeerFor(newPeerId);
        await manager.createOffer();
      };

      // Someone sent us an offer — find or create their connection, then answer.
      _signaling.onOffer = (data) async {
        final fromId = data['from'] as String;
        final manager = _peers[fromId] ?? await _createPeerFor(fromId);
        await manager.handleOffer(data['payload']);
      };

      // Someone answered OUR offer — route it to the right peer.
      _signaling.onAnswer = (data) async {
        final fromId = data['from'] as String;
        await _peers[fromId]?.handleAnswer(data['payload']);
      };

      // An ICE candidate arrived — route it to the right peer.
      _signaling.onCandidate = (data) async {
        final fromId = data['from'] as String;
        await _peers[fromId]?.handleCandidate(data['payload']);
      };

      // Someone left — clean up just their connection and renderer.
      _signaling.onUserLeft = (data) async {
        final leftId = data['from'] as String;
        await _peers[leftId]?.dispose();
        _peers.remove(leftId);
        await _remoteRenderers[leftId]?.dispose();
        setState(() {
          _remoteRenderers.remove(leftId);
        });
      };

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

  // Creates a PeerConnectionManager + a matching video renderer for one
  // specific remote person, and wires up its remote-stream callback.
  Future<PeerConnectionManager> _createPeerFor(String peerId) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _remoteRenderers[peerId] = renderer;

    final manager = PeerConnectionManager(
      signaling: _signaling,
      remoteUserId: peerId,
      localStream: _localStream!,
    );

    manager.onRemoteStream = (stream) {
      renderer.srcObject = stream;
      if (mounted) setState(() {});
    };

    await manager.init();
    _peers[peerId] = manager;
    return manager;
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    for (final manager in _peers.values) {
      manager.dispose();
    }
    for (final renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
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
                // Remote video feeds laid out in a simple grid — grows
                // automatically as more people join.
                Positioned.fill(
                  child: _remoteRenderers.isEmpty
                      ? const Center(
                          child: Text(
                            'Waiting for others to join...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : GridView.count(
                          crossAxisCount: _remoteRenderers.length > 1 ? 2 : 1,
                          children: _remoteRenderers.values
                              .map((renderer) => RTCVideoView(renderer))
                              .toList(),
                        ),
                ),
                // Your own camera stays as a small overlay, same as before.
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
