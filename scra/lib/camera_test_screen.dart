import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CameraTestScreen extends StatefulWidget {
  const CameraTestScreen({super.key});

  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFrontCamera = true;
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  void initState() {
    super.initState();
    initRenderer();
  }

  Future<void> initRenderer() async {
    try {
      await _localRenderer.initialize();
      await _getUserMedia();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _getUserMedia() async {
    try {
      final mediaConstraints = {
        'audio': true,
        'video': {
          'facingMode': _isFrontCamera ? 'user' : 'environment',
          'optional': [],
        },
      };

      final stream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );

      if (!mounted) {
        stream.getTracks().forEach((track) => track.stop());
        await stream.dispose();
        return;
      }

      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();

      _localRenderer.srcObject = stream;
      _localStream = stream;

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error accessing camera/microphone: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_localStream == null) return;
    try {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to switch camera: $e')));
    }
  }

  void _toggleMute() {
    if (_localStream == null) return;
    final audioTrack = _localStream!.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      final newMuteState = !_isMuted;
      audioTrack.enabled = !newMuteState;
      setState(() {
        _isMuted = newMuteState;
      });
    }
  }

  void _toggleVideo() {
    if (_localStream == null) return;
    final videoTrack = _localStream!.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      final newVideoOffState = !_isVideoOff;
      videoTrack.enabled = !newVideoOffState;
      setState(() {
        _isVideoOff = newVideoOffState;
      });
    }
  }

  @override
  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localRenderer.srcObject = null;
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
        actions: [
          if (_localStream != null)
            IconButton(
              icon: Icon(
                _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
              ),
              tooltip: 'Switch Camera',
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _localStream != null
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Colors.white,
                    ),
                    tooltip: _isMuted ? 'Unmute' : 'Mute',
                    onPressed: _toggleMute,
                  ),
                  IconButton(
                    icon: Icon(
                      _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      color: _isVideoOff ? Colors.red : Colors.white,
                    ),
                    tooltip: _isVideoOff ? 'Turn Video On' : 'Turn Video Off',
                    onPressed: _toggleVideo,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.flip_camera_android,
                      color: Colors.white,
                    ),
                    tooltip: 'Flip Camera',
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _getUserMedia();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        RTCVideoView(
          _localRenderer,
          mirror: _isFrontCamera,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
        if (_isVideoOff)
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Camera is turned off',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }
}
