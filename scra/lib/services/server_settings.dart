import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import 'storage_service.dart';

/// The backend address used by the app, changeable on the device (sign-in
/// screen → "Server") so a new Wi-Fi address doesn't need a new app build.
abstract final class ServerSettings {
  /// `10.0.0.5:8000` → `http://10.0.0.5:8000`; trims spaces and trailing
  /// slashes. Returns null when [input] is not a usable http(s) address.
  static String? normalize(String? input) {
    var value = (input ?? '').trim();
    if (value.isEmpty || value.contains(RegExp(r'\s'))) return null;
    if (!value.contains('://')) value = 'http://$value';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty ||
        uri.host.contains(' ') ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery) {
      return null;
    }
    return uri.replace(path: '').toString().replaceAll(RegExp(r'/+$'), '');
  }

  /// Whether a Smart Class backend answers at [baseUrl] (`GET /health`).
  static Future<bool> isReachable(String baseUrl, {http.Client? client}) async {
    final owned = client == null;
    final c = client ?? http.Client();
    try {
      final response = await c
          .get(Uri.parse('$baseUrl${AppConfig.apiPrefix}/health'))
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200 && response.body.contains('ok');
    } on Object {
      return false;
    } finally {
      if (owned) c.close();
    }
  }

  /// Uses and remembers [url]; `null` goes back to the built-in address.
  static Future<void> apply(StorageService storage, String? url) async {
    await storage.setServerUrl(url);
    AppConfig.useServer(url);
  }
}
