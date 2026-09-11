import 'dart:convert'; //this help json and dart to communicate together

import 'package:web_socket_channel/web_socket_channel.dart'; // this contains the websocket channel thatbpemits live connection on a server

typedef SignalCallback = void Function(Map<String, dynamic> data);// any valid signalcallback muss accept one map

class SignalingService {
  final String roomId;
  final String userId;
  final String serverUrl;
  //the adress needed here for information to be transfered

  WebSocketChannel? _channel;// underscore in dart means the code belongs only to this file
  bool _isConnected = false; // here a signalling service is been creatded but no connecion is been opened yet

  SignalCallback? onOffer;
  SignalCallback? onAnswer;
  SignalCallback? onCandidate;
  SignalCallback? onUserJoined;
  SignalCallback? onUserLeft;
  void Function()? onDisconnected;
  // here are the 

  SignalingService({
    required this.roomId,
    required this.userId,
    required this.serverUrl,
    //must be listed for for signalling to take place, if not it fails
  });

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    final uri = Uri.parse('$serverUrl/ws/$roomId/$userId');
    _channel = WebSocketChannel.connect(uri);
    _isConnected = true;

    _channel!.stream.listen(
      (raw) => _handleMessage(raw),
      onDone: () {
        _isConnected = false;
        onDisconnected?.call();
      },
      onError: (error) {
        _isConnected = false;
        onDisconnected?.call();
      },
    );
  }

  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (data['type']) {
        case 'offer':
          onOffer?.call(data);
          break;
        case 'answer':
          onAnswer?.call(data);
          break;
        case 'candidate':
          onCandidate?.call(data);
          break;
        case 'user_joined':
          onUserJoined?.call(data);
          break;
        case 'user_left':
          onUserLeft?.call(data);
          break;
        default:
          break;
      }
    } catch (e) {
      print("Signaling: failed to parse message: $e");
    }
  }

  void _send(Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  void sendOffer(String targetId, Map<String, dynamic> sdp) {
    _send({'type': 'offer', 'target': targetId, 'payload': sdp});
  }

  void sendAnswer(String targetId, Map<String, dynamic> sdp) {
    _send({'type': 'answer', 'target': targetId, 'payload': sdp});
  }

  void sendCandidate(String targetId, Map<String, dynamic> candidate) {
    _send({'type': 'candidate', 'target': targetId, 'payload': candidate});
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}
