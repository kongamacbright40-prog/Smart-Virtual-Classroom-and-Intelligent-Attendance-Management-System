import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_endpoints.dart';

typedef SignalCallback = void Function(Map<String, dynamic> data);

/// WebRTC mesh signaling over the backend socket
/// `/ws/signal/{class_id}?token=<access token>`.
///
/// Backend wire format:
/// * sent: `{type: offer|answer|ice_candidate, target_peer_id: <int>, payload}`
/// * received: the same message plus `from_peer_id`, and `room_state`,
///   `peer_joined` / `peer_left` (`peer_id`), `session_ended`, `error`.
///
/// Callbacks receive a normalized `{type, from: <peer id>, payload}` map.
/// Connecting also marks the user present in the class (server side).
class SignalingService {
  SignalingService({
    required this.roomId,
    required this.userId,
    required this.serverUrl,
    this.token,
  });

  final String roomId;
  final String userId;
  final String serverUrl;
  final String? token;

  WebSocketChannel? _channel;
  bool _isConnected = false;

  SignalCallback? onOffer;
  SignalCallback? onAnswer;
  SignalCallback? onCandidate;
  SignalCallback? onUserJoined;
  SignalCallback? onUserLeft;
  void Function(List<String> peerIds)? onRoomState;

  /// Whiteboard messages (`board` / `board_state`) from the lecturer.
  SignalCallback? onBoard;
  void Function()? onSessionEnded;
  void Function()? onDisconnected;

  bool get isConnected => _isConnected;

  Uri get uri =>
      Uri.parse('$serverUrl${ApiEndpoints.signaling(roomId)}')
          .replace(queryParameters: {'token': ?token});

  Future<void> connect() async {
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    _channel = channel;
    _isConnected = true;

    channel.stream.listen(
      (raw) => handleMessage(raw),
      onDone: () {
        _isConnected = false;
        onDisconnected?.call();
      },
      onError: (Object error) {
        _isConnected = false;
        onDisconnected?.call();
      },
    );
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> data) => {
    'type': data['type'],
    'from': (data['from_peer_id'] ?? data['peer_id'])?.toString(),
    'payload': data['payload'] is Map
        ? Map<String, dynamic>.from(data['payload'] as Map)
        : <String, dynamic>{},
    if (data['full_name'] != null) 'full_name': data['full_name'],
    if (data['role'] != null) 'role': data['role'],
  };

  @visibleForTesting
  void handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (data['type']) {
        case 'offer':
          onOffer?.call(_normalize(data));
        case 'answer':
          onAnswer?.call(_normalize(data));
        case 'ice_candidate':
          onCandidate?.call(_normalize(data));
        case 'peer_joined':
          onUserJoined?.call(_normalize(data));
        case 'peer_left':
          onUserLeft?.call(_normalize(data));
        case 'room_state':
          final peers = data['peers'] is List
              ? data['peers'] as List
              : const [];
          onRoomState?.call(peers.map((p) => p.toString()).toList());
        case 'session_ended':
          onSessionEnded?.call();
        case 'board':
        case 'board_state':
          onBoard?.call(data);
        case 'error':
          debugPrint('Signaling: server error: ${data['detail']}');
        default:
          break;
      }
    } catch (e) {
      debugPrint('Signaling: failed to parse message: $e');
    }
  }

  void _send(String type, String targetId, Map<String, dynamic> payload) {
    final target = int.tryParse(targetId);
    if (!_isConnected || _channel == null || target == null) return;
    _channel!.sink.add(
      jsonEncode({'type': type, 'target_peer_id': target, 'payload': payload}),
    );
  }

  void sendOffer(String targetId, Map<String, dynamic> sdp) =>
      _send('offer', targetId, sdp);

  void sendAnswer(String targetId, Map<String, dynamic> sdp) =>
      _send('answer', targetId, sdp);

  void sendCandidate(String targetId, Map<String, dynamic> candidate) =>
      _send('ice_candidate', targetId, candidate);

  /// Lecturer only: a whiteboard operation broadcast to the class.
  void sendBoard(Map<String, dynamic> operation) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({...operation, 'type': 'board'}));
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}
