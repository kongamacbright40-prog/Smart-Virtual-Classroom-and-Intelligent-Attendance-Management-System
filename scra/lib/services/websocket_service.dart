import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/error_handler.dart';

enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed;

  bool get isConnected => this == RealtimeConnectionState.connected;
}

/// A typed message on the classroom WebSocket.
///
/// Wire format: `{"type": "<event>", "payload": {...}}`.
/// Expected event types: `participant.joined`, `participant.left`,
/// `participant.updated`, `chat.message`, `question.launched`,
/// `question.updated`, `question.closed`, `attendance.updated`,
/// `session.started`, `session.ended`, `notification.created`.
class RealtimeEvent {
  const RealtimeEvent(this.type, [this.payload = const {}]);

  final String type;
  final Map<String, dynamic> payload;

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) => RealtimeEvent(
    json['type'] as String? ?? 'unknown',
    json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : const {},
  );

  Map<String, dynamic> toJson() => {'type': type, 'payload': payload};
}

/// Abstraction over a real-time channel so repositories can switch from
/// polling to server push without UI changes.
abstract interface class WebSocketService {
  RealtimeConnectionState get state;
  Stream<RealtimeConnectionState> get stateChanges;
  Stream<RealtimeEvent> get events;

  /// Connects to `AppConfig.wsBaseUrl + path`, e.g. `/ws/classroom/{id}`.
  Future<void> connect(String path, {Map<String, String>? query});
  void send(RealtimeEvent event);
  Future<void> disconnect();
  Future<void> dispose();
}

/// Socket used when the backend has no classroom event stream: it never
/// connects and never emits, so repositories fall back to polling.
class DisabledWebSocketService implements WebSocketService {
  final _states = StreamController<RealtimeConnectionState>.broadcast();

  @override
  RealtimeConnectionState get state => RealtimeConnectionState.disconnected;

  @override
  Stream<RealtimeConnectionState> get stateChanges => _states.stream;

  @override
  Stream<RealtimeEvent> get events => const Stream.empty();

  @override
  Future<void> connect(String path, {Map<String, String>? query}) async {}

  @override
  void send(RealtimeEvent event) {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() => _states.close();
}

/// `web_socket_channel` implementation with exponential-backoff reconnects.
class ChannelWebSocketService implements WebSocketService {
  ChannelWebSocketService({
    String? baseUrl,
    this.maxReconnectAttempts = 5,
    this.tokenProvider,
  }) : _baseUrl = baseUrl ?? AppConfig.wsBaseUrl;

  final String _baseUrl;
  final int maxReconnectAttempts;

  /// Optional bearer token appended as `?token=` (browsers cannot set
  /// headers on WebSocket upgrades).
  final Future<String?> Function()? tokenProvider;

  final _events = StreamController<RealtimeEvent>.broadcast();
  final _states = StreamController<RealtimeConnectionState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;
  String? _path;
  Map<String, String>? _query;
  int _attempts = 0;
  bool _manualClose = false;
  Timer? _reconnectTimer;

  @override
  RealtimeConnectionState get state => _state;

  @override
  Stream<RealtimeConnectionState> get stateChanges => _states.stream;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  void _setState(RealtimeConnectionState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  @override
  Future<void> connect(String path, {Map<String, String>? query}) async {
    _path = path;
    _query = query;
    _manualClose = false;
    _setState(
      _attempts == 0
          ? RealtimeConnectionState.connecting
          : RealtimeConnectionState.reconnecting,
    );
    final token = await tokenProvider?.call();
    final params = {...?query, 'token': ?token};
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: params.isEmpty ? null : params);
    try {
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _attempts = 0;
      _setState(RealtimeConnectionState.connected);
      _subscription = channel.stream.listen(
        _onData,
        onError: (Object e) => _onClosed(e),
        onDone: () => _onClosed(null),
      );
    } on Object catch (e) {
      _onClosed(e);
    }
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      _events.add(RealtimeEvent.fromJson(json));
    } on Object catch (e) {
      ErrorHandler.log(e);
    }
  }

  void _onClosed(Object? error) {
    if (error != null) ErrorHandler.log(error);
    _subscription?.cancel();
    _channel = null;
    if (_manualClose || _path == null) {
      _setState(RealtimeConnectionState.disconnected);
      return;
    }
    if (_attempts >= maxReconnectAttempts) {
      _setState(RealtimeConnectionState.failed);
      return;
    }
    _attempts++;
    _setState(RealtimeConnectionState.reconnecting);
    final delay = Duration(milliseconds: 500 * (1 << (_attempts - 1)));
    _reconnectTimer = Timer(delay, () => connect(_path!, query: _query));
  }

  @override
  void send(RealtimeEvent event) {
    final channel = _channel;
    if (channel == null || !_state.isConnected) return;
    channel.sink.add(jsonEncode(event.toJson()));
  }

  @override
  Future<void> disconnect() async {
    _manualClose = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(RealtimeConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _events.close();
    await _states.close();
  }
}
