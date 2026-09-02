class IceConfig {
  static Map<String, dynamic> get configuration => {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
      // TODO: add your TURN server here once you have one, e.g.:
      // {
      //   'urls': 'turn:your.turn.server:3478',
      //   'username': 'user',
      //   'credential': 'pass',
      // },
    ],
  };
}
