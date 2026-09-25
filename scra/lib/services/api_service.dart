import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/error_handler.dart';

/// Supplies the bearer token for authenticated requests.
typedef TokenProvider = Future<String?> Function();

/// Centralized REST client for the FastAPI backend.
///
/// * Builds every URL from [AppConfig] (never hard-code hosts elsewhere).
/// * Adds JSON + `Authorization: Bearer <token>` headers.
/// * Applies a request timeout.
/// * Decodes JSON and maps failures to [AppException] subtypes.
class ApiService {
  ApiService({
    http.Client? client,
    this.tokenProvider,
    String? baseUrl,
    Duration? timeout,
    this.onUnauthorized,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}',
       _timeout = timeout ?? AppConfig.requestTimeout;

  final http.Client _client;
  final TokenProvider? tokenProvider;
  final String _baseUrl;
  final Duration _timeout;

  /// Invoked on HTTP 401 so the app can clear the session.
  void Function()? onUnauthorized;

  String get baseUrl => _baseUrl;

  Uri buildUri(String path, [Map<String, Object?>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final params = <String, String>{
      for (final e in (query ?? const <String, Object?>{}).entries)
        if (e.value != null) e.key: e.value.toString(),
    };
    return Uri.parse('$_baseUrl$normalized')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<Map<String, String>> _headers({bool authenticated = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated && tokenProvider != null) {
      final token = await tokenProvider!();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    bool authenticated = true,
  }) => _send('GET', path, query: query, authenticated: authenticated);

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    bool authenticated = true,
  }) => _send(
    'POST',
    path,
    body: body,
    query: query,
    authenticated: authenticated,
  );

  Future<Object?> put(String path, {Object? body, bool authenticated = true}) =>
      _send('PUT', path, body: body, authenticated: authenticated);

  Future<Object?> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('PATCH', path, body: body, authenticated: authenticated);

  Future<Object?> delete(String path, {bool authenticated = true}) =>
      _send('DELETE', path, authenticated: authenticated);

  /// Convenience: GET and expect a JSON object.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final data = await get(path, query: query);
    if (data is Map<String, dynamic>) return data;
    throw const ParsingException();
  }

  /// Convenience: GET and expect a JSON array of objects.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final data = await get(path, query: query);
    final list = data is Map<String, dynamic> ? data['items'] : data;
    if (list is List) {
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw const ParsingException();
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    bool authenticated = true,
  }) async {
    final request = http.Request(method, buildUri(path, query))
      ..headers.addAll(await _headers(authenticated: authenticated));
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(_timeout);
      return _handle(response);
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const TimeoutAppException();
    } on Object catch (e) {
      throw ErrorHandler.normalize(e);
    }
  }

  Object? _handle(http.Response response) {
    final status = response.statusCode;
    final decoded = _decode(response.body);

    if (status >= 200 && status < 300) return decoded;

    final message = _extractMessage(decoded);
    switch (status) {
      case 400:
      case 409:
      case 422:
        throw ValidationException(
          message ?? 'Some fields are invalid.',
          fieldErrors: _extractFieldErrors(decoded),
        );
      case 401:
        onUnauthorized?.call();
        throw AuthException(message ?? 'Your session has expired.');
      case 403:
        throw ForbiddenException(
          message ?? 'You do not have permission to do this.',
        );
      case 404:
        throw NotFoundException(message ?? 'Not found.');
      default:
        if (status >= 500) {
          throw ServerException(
            message ?? 'The server encountered an error.',
            status,
          );
        }
        throw UnknownException(message ?? 'Unexpected response ($status).');
    }
  }

  Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  /// FastAPI returns `{"detail": "..."}` or `{"detail": [{"loc":..,"msg":..}]}`.
  String? _extractMessage(Object? decoded) {
    if (decoded is Map) {
      final detail = decoded['detail'] ?? decoded['message'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty && detail.first is Map) {
        return (detail.first as Map)['msg']?.toString();
      }
    }
    if (decoded is String && decoded.isNotEmpty && decoded.length < 200) {
      return decoded;
    }
    return null;
  }

  Map<String, String> _extractFieldErrors(Object? decoded) {
    if (decoded is! Map || decoded['detail'] is! List) return const {};
    final result = <String, String>{};
    for (final item in decoded['detail'] as List) {
      if (item is Map &&
          item['loc'] is List &&
          (item['loc'] as List).isNotEmpty) {
        result[(item['loc'] as List).last.toString()] =
            item['msg']?.toString() ?? 'Invalid value';
      }
    }
    return result;
  }

  void dispose() => _client.close();
}
