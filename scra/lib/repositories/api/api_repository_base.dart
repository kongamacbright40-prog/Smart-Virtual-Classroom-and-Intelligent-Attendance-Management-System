import 'dart:async';

import '../../core/errors/app_exception.dart';
import '../../models/json_utils.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';

/// Helpers shared by the REST-backed repositories.
abstract class ApiRepositoryBase {
  ApiRepositoryBase(this.api);

  final ApiService api;

  Future<T> getOne<T>(
    String path,
    T Function(Json) fromJson, {
    Map<String, Object?>? query,
  }) async =>
      fromJson(await api.getJson(path, query: query));

  Future<List<T>> getMany<T>(
    String path,
    T Function(Json) fromJson, {
    Map<String, Object?>? query,
  }) async =>
      (await api.getList(path, query: query)).map(fromJson).toList();

  Json asJson(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ParsingException();
  }

  Future<T> postOne<T>(String path, Object? body, T Function(Json) fromJson) async =>
      fromJson(asJson(await api.post(path, body: body)));

  Future<T> putOne<T>(String path, Object? body, T Function(Json) fromJson) async =>
      fromJson(asJson(await api.put(path, body: body)));

  Future<T> patchOne<T>(String path, Object? body, T Function(Json) fromJson) async =>
      fromJson(asJson(await api.patch(path, body: body)));

  /// Emits [load] once, then again every time a WebSocket event whose type
  /// starts with [eventPrefix] arrives. The socket connection itself is owned
  /// by the classroom controller / app shell.
  Stream<T> refetchOnEvents<T>(
    WebSocketService socket,
    String eventPrefix,
    Future<T> Function() load,
  ) async* {
    yield await load();
    await for (final event in socket.events) {
      if (event.type.startsWith(eventPrefix)) yield await load();
    }
  }
}
