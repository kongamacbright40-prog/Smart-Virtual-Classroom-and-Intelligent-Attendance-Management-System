import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/services/webrtc/signaling_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// In-memory WebSocket: the test plays the server.
class _FakeSocket implements WebSocketChannel {
  _FakeSocket(this.uri);

  final Uri uri;
  final _incoming = StreamController<dynamic>();
  final List<Map<String, dynamic>> sent = [];
  int? _closeCode;
  bool closedByClient = false;
  late final _FakeSink _sink = _FakeSink(this);

  void serverSends(Map<String, dynamic> message) =>
      _incoming.add(jsonEncode(message));

  /// The connection drops (network loss = no close code).
  void drop([int? code]) {
    _closeCode = code;
    _incoming.close();
  }

  @override
  Future<void> get ready => Future.value();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this.socket);

  final _FakeSocket socket;
  final _done = Completer<void>();

  @override
  void add(dynamic data) => socket.sent.add(
    Map<String, dynamic>.from(jsonDecode(data as String) as Map),
  );

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    socket.closedByClient = true;
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<void> get done => _done.future;

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}
}

void main() {
  late List<_FakeSocket> sockets;
  late int tokenCalls;

  SignalingService create({
    Duration heartbeat = const Duration(seconds: 20),
    int maxAttempts = 3,
  }) {
    sockets = [];
    tokenCalls = 0;
    return SignalingService(
      roomId: '11',
      userId: '7',
      serverUrl: 'ws://server',
      token: 'first',
      tokenProvider: () async => 'fresh${++tokenCalls}',
      heartbeatInterval: heartbeat,
      maxReconnectAttempts: maxAttempts,
      reconnectBaseDelay: const Duration(milliseconds: 5),
      connector: (uri) {
        final socket = _FakeSocket(uri);
        sockets.add(socket);
        return socket;
      },
    );
  }

  Future<void> settle([int ms = 40]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  /// Waits (up to 3 s) until [condition] holds; timers run slower when many
  /// test files run in parallel.
  Future<void> until(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!condition() && DateTime.now().isBefore(deadline)) {
      await settle(5);
    }
  }

  test('reconnects with a fresh token after the network drops', () async {
    final signaling = create();
    var reconnecting = 0;
    var reconnected = 0;
    var disconnected = 0;
    signaling.onReconnecting = () => reconnecting++;
    signaling.onReconnected = () => reconnected++;
    signaling.onDisconnected = () => disconnected++;

    await signaling.connect();
    expect(sockets.single.uri.queryParameters['token'], 'first');

    sockets.single.drop(); // abnormal close, e.g. mobile data switch
    await until(() => reconnected == 1);
    expect(reconnecting, 1);
    expect(reconnected, 1);
    expect(disconnected, 0);
    expect(sockets, hasLength(2));
    expect(sockets.last.uri.queryParameters['token'], 'fresh1');
    expect(signaling.isConnected, isTrue);

    // Messages on the new socket are handled.
    Map<String, dynamic>? offer;
    signaling.onOffer = (d) => offer = d;
    sockets.last.serverSends({
      'type': 'offer',
      'from_peer_id': 3,
      'payload': {'sdp': 'x', 'type': 'offer'},
    });
    await settle(5);
    expect(offer?['from'], '3');
    signaling.disconnect();
  });

  test('does not reconnect when the server ends the connection', () async {
    for (final code in [1000, 1008]) {
      final signaling = create();
      var disconnected = 0;
      signaling.onDisconnected = () => disconnected++;
      await signaling.connect();
      sockets.single.drop(code);
      await settle();
      expect(sockets, hasLength(1), reason: 'code $code');
      expect(disconnected, 1);
    }
  });

  test('does not reconnect after the class ended or a manual leave', () async {
    final signaling = create();
    var ended = 0;
    signaling.onSessionEnded = () => ended++;
    await signaling.connect();
    sockets.single.serverSends({'type': 'session_ended'});
    await settle(5);
    sockets.single.drop();
    await settle();
    expect(ended, 1);
    expect(sockets, hasLength(1));

    final other = create();
    await other.connect();
    other.disconnect();
    expect(sockets.single.closedByClient, isTrue);
    await settle();
    expect(sockets, hasLength(1));
  });

  test('gives up after the maximum number of attempts', () async {
    sockets = [];
    var attempts = 0;
    var disconnected = 0;
    final signaling = SignalingService(
      roomId: '11',
      userId: '7',
      serverUrl: 'ws://server',
      maxReconnectAttempts: 2,
      reconnectBaseDelay: const Duration(milliseconds: 2),
      connector: (uri) {
        attempts++;
        if (attempts > 1) throw StateError('server down');
        final socket = _FakeSocket(uri);
        sockets.add(socket);
        return socket;
      },
    );
    signaling.onDisconnected = () => disconnected++;
    await signaling.connect();
    sockets.single.drop();
    await until(() => disconnected == 1);
    await settle();
    expect(attempts, 3); // first connection + 2 retries
    expect(disconnected, 1);
    expect(signaling.isConnected, isFalse);
  });

  test('sends heartbeats and reconnects when pongs stop', () async {
    final signaling = create(heartbeat: const Duration(milliseconds: 10));
    var reconnected = 0;
    signaling.onReconnected = () => reconnected++;
    await signaling.connect();
    final first = sockets.single;
    await until(() => first.sent.isNotEmpty);
    expect(first.sent.where((m) => m['type'] == 'ping'), isNotEmpty);

    // A server that answers pings, then goes silent (dead connection).
    first.serverSends({'type': 'pong'});
    await until(() => reconnected >= 1);
    expect(first.closedByClient, isTrue);
    expect(reconnected, greaterThanOrEqualTo(1));
    expect(sockets.length, greaterThanOrEqualTo(2));
    signaling.disconnect();
  });

  test('servers that never answer pings are not treated as dead', () async {
    final signaling = create(heartbeat: const Duration(milliseconds: 10));
    await signaling.connect();
    await settle(80);
    expect(sockets, hasLength(1));
    expect(sockets.single.closedByClient, isFalse);
    signaling.disconnect();
  });
}
