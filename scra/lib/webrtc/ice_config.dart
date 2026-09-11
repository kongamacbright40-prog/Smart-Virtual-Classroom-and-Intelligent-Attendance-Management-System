class IceConfig {
  // here ice config simply tells us what server the peer coonection is allowed to use
  static Map<String, dynamic> get configuration => {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
  };
}
/*The STURN server, wchich gives public address when asked by the device
which is been written in flutter webrtc format for peer connection
*/
