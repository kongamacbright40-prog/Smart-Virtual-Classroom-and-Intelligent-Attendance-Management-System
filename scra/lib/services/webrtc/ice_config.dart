import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/errors/error_handler.dart';

/// ICE servers the peer connections may use to find a network path.
///
/// STUN (public Google servers) is enough on the same Wi-Fi/LAN. Across
/// different networks (mobile data, other Wi-Fi, strict routers) audio and
/// video only flow through a TURN relay. The relay is configured on the
/// backend (`GET /signaling/ice-servers`), so it can change without rebuilding
/// the app. One can also be built in:
/// `--dart-define=TURN_URL=turn:host:3478 --dart-define=TURN_USERNAME=u
///  --dart-define=TURN_CREDENTIAL=p`.
class IceConfig {
  static const String _turnUrl = String.fromEnvironment('TURN_URL');
  static const String _turnUsername = String.fromEnvironment('TURN_USERNAME');
  static const String _turnCredential = String.fromEnvironment(
    'TURN_CREDENTIAL',
  );

  static const List<String> _defaultStun = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
  ];

  static Map<String, dynamic>? get _builtInTurn => _turnUrl.isEmpty
      ? null
      : {
          'urls': _turnUrl,
          'username': _turnUsername,
          'credential': _turnCredential,
        };

  /// Whether this build carries its own TURN relay.
  static bool get hasBuiltInTurn => _turnUrl.isNotEmpty;

  /// Peer-connection configuration. [serverIceServers] (from the backend)
  /// replaces the default STUN list when given.
  static Map<String, dynamic> configuration([
    List<Map<String, dynamic>>? serverIceServers,
  ]) => {
    'iceServers': [
      if (serverIceServers != null && serverIceServers.isNotEmpty)
        ...serverIceServers
      else
        {'urls': _defaultStun},
      if (hasBuiltInTurn) _builtInTurn!,
    ],
  };

  /// Fetches the STUN/TURN servers configured on the backend. Returns null
  /// when unavailable (older backend, network error); callers then fall back
  /// to the default STUN servers.
  static Future<IceServersInfo?> fetch({
    required String? token,
    http.Client? client,
    String? baseUrl,
  }) async {
    final owned = client == null;
    final c = client ?? http.Client();
    try {
      final uri = Uri.parse(
        '${baseUrl ?? AppConfig.apiBaseUrl}${AppConfig.apiPrefix}'
        '/signaling/ice-servers',
      );
      final response = await c
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map) return null;
      final servers = (body['ice_servers'] as List? ?? const [])
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .where((s) => s['urls'] != null)
          .toList();
      return IceServersInfo(
        servers: servers,
        turnConfigured: body['turn_configured'] == true,
      );
    } on Object catch (e) {
      ErrorHandler.log(e);
      return null;
    } finally {
      if (owned) c.close();
    }
  }
}

class IceServersInfo {
  const IceServersInfo({required this.servers, required this.turnConfigured});

  final List<Map<String, dynamic>> servers;
  final bool turnConfigured;
}
