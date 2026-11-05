import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_endpoints.dart';

typedef SignalCallback = void Function(Map<String, dynamic> data);
typedef SocketConnector = WebSocketChannel Function(Uri uri);

/// WebRTC mesh signaling over the backend socket
/// `/ws/signal/{class_id}?token=<access token>`.
///
/// Backend wire format:
/// * sent: `{type: offer|answer|ice_candidate, target_peer_id: <int>, payload}`
///   and `{type: ping}` heartbeats
/// * received: the same message plus `from_peer_id`, and `room_state`,
///   `peer_joined` / `peer_left` (`peer_id`), `session_ended`, `pong`, `error`.
///
/// Callbacks receive a normalized `{type, from: <peer id>, payload}` map.
/// Connecting also marks the user present in the class (server side).
///
/// The socket is kept alive with heartbeats and reopened automatically when
/// the network drops it (mobile data, Wi-Fi switch, proxy idle timeout);
/// otherwise later participants could never negotiate audio/video with us.
class SignalingService {
  SignalingService({
    required this.roomId,
    required this.userId,
    required this.serverUrl,
    this.token,
    this.tokenProvider,
    this.heartbeatInterval = const Duration(seconds: 20),
    this.maxReconnectAttempts = 6,
    this.reconnectBaseDelay = const Duration(seconds: 1),
    SocketConnector? connector,
  }) : _connector = connector ?? WebSocketChannel.connect;

  final String roomId;
  final String userId;
  final String serverUrl;
  final String? token;

  /// Supplies a fresh access token for reconnections (the first one may have
  /// expired during a long class). Falls back to [token].
  final Future<String?> Function()? tokenProvider;
  final Duration heartbeatInterval;
  final int maxReconnectAttempts;

  /// First reconnect delay; it doubles on each failed attempt (max 15×).
  final Duration reconnectBaseDelay;
  final SocketConnector _connector;

  /// Close codes after which reconnecting is pointless: 1000 (the server
  /// closed it on purpose, e.g. the same account joined from another device)
  /// and 1008 (not allowed: class ended, token rejected).
  static const _finalCloseCodes = {1000, 1008};

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  Timer? _retry;
  bool _isConnected = false;
  bool _closedByUser = false;
  bool _sessionEnded = false;
  bool _serverAnswersPings = false;
  int _attempt = 0;
  DateTime _lastMessageAt = DateTime.now();

  SignalCallback? onOffer;
  SignalCallback? onAnswer;
  SignalCallback? onCandidate;
  SignalCallback? onUserJoined;
  SignalCallback? onUserLeft;
  void Function(List<String> peerIds)? onRoomState;

  /// Whiteboard messages (`board` / `board_state`) from the lecturer.
  SignalCallback? onBoard;
  void Function()? onSessionEnded;

  /// The socket dropped and a new one is being opened.
  void Function()? onReconnecting;

  /// A dropped socket was reopened: the other participants are told we
  /// (re)joined and will send fresh offers.
  void Function()? onReconnected;

  /// The socket is gone for good (closed by the server, or reconnecting
  /// failed [maxReconnectAttempts] times).
  void Function()? onDisconnected;

  bool get isConnected => _isConnected;

  Uri get uri => _uriWith(token);

  Uri _uriWith(String? accessToken) =>
      Uri.parse('$serverUrl${ApiEndpoints.signaling(roomId)}')
          .replace(queryParameters: {'token': ?accessToken});

  Future<void> connect() async {
    _closedByUser = false;
    _sessionEnded = false;
    await _open(token);
  }

  Future<void> _open(String? accessToken, {bool reconnect = false}) async {
    final channel = _connector(_uriWith(accessToken));
    await channel.ready;
    if (_closedByUser) {
      await channel.sink.close();
      return;
    }
    _channel = channel;
    _isConnected = true;
    _lastMessageAt = DateTime.now();
    if (reconnect) {
      _attempt = 0;
      // Before listening, so stale connections are dropped before any new
      // offer is handled.
      onReconnected?.call();
    }
    _subscription = channel.stream.listen(
      (raw) {
        _lastMessageAt = DateTime.now();
        handleMessage(raw);
      },
      onDone: () => _onDropped(channel),
      onError: (Object _) => _onDropped(channel),
      cancelOnError: true,
    );
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(heartbeatInterval, (_) {
      final channel = _channel;
      if (channel == null) return;
      // Only servers that answer pings can be judged silent.
      final silentFor = DateTime.now().difference(_lastMessageAt);
      if (_serverAnswersPings && silentFor > heartbeatInterval * 2.5) {
        debugPrint('Signaling: no reply for $silentFor, reconnecting');
        unawaited(channel.sink.close());
        _onDropped(channel);
        return;
      }
      try {
        channel.sink.add(jsonEncode({'type': 'ping'}));
      } on Object catch (e) {
        debugPrint('Signaling: heartbeat failed: $e');
      }
    });
  }

  void _onDropped(WebSocketChannel channel) {
    if (!identical(channel, _channel)) return;
    _channel = null;
    _isConnected = false;
    _heartbeat?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (_closedByUser || _sessionEnded) return;
    if (_finalCloseCodes.contains(channel.closeCode)) {
      onDisconnected?.call();
      return;
    }
    onReconnecting?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closedByUser) return;
    if (_attempt >= maxReconnectAttempts) {
      _attempt = 0;
      onDisconnected?.call();
      return;
    }
    // 1 s, 2 s, 4 s, 8 s, then every 15 s (with the default base delay).
    final delay = reconnectBaseDelay * (_attempt < 4 ? 1 << _attempt : 15);
    _attempt++;
    _retry?.cancel();
    _retry = Timer(delay, () async {
      if (_closedByUser) return;
      try {
        final fresh = await tokenProvider?.call() ?? token;
        await _open(fresh, reconnect: true);
      } on Object catch (e) {
        debugPrint('Signaling: reconnect failed: $e');
        _scheduleReconnect();
      }
    });
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
          _sessionEnded = true;
          onSessionEnded?.call();
        case 'board':
        case 'board_state':
          onBoard?.call(data);
        case 'pong':
          _serverAnswersPings = true;
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
    _closedByUser = true;
    _retry?.cancel();
    _heartbeat?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }
}
