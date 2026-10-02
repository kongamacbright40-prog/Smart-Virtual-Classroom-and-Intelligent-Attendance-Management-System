/// ICE servers the peer connections may use to find a network path.
///
/// STUN (public Google servers) is enough on the same Wi-Fi/LAN. Across
/// strict NATs or mobile data a TURN relay is needed; supply one at build time:
/// `--dart-define=TURN_URL=turn:host:3478 --dart-define=TURN_USERNAME=u
///  --dart-define=TURN_CREDENTIAL=p`.
class IceConfig {
  static const String _turnUrl = String.fromEnvironment('TURN_URL');
  static const String _turnUsername = String.fromEnvironment('TURN_USERNAME');
  static const String _turnCredential = String.fromEnvironment(
    'TURN_CREDENTIAL',
  );

  static Map<String, dynamic> get configuration => {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
      if (_turnUrl.isNotEmpty)
        {
          'urls': _turnUrl,
          'username': _turnUsername,
          'credential': _turnCredential,
        },
    ],
  };
}
