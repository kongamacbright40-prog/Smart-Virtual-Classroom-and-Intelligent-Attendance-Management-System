import 'dart:async';

import '../../core/constants/api_endpoints.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'backend_mappers.dart';

/// Largest page the backend accepts (`PageParams.page_size <= 100`).
const int backendPageSize = 100;

/// How often live data is re-fetched: the backend has no classroom event
/// stream, so repositories poll instead.
const Duration backendPollInterval = Duration(seconds: 3);

/// State shared by the REST repositories: the signed-in user and the local
/// attendance-capture flag of classes (the backend records attendance
/// automatically while participants are connected).
class ApiContext {
  ApiContext({UserModel? Function()? currentUser})
    : _currentUser = currentUser ?? (() => null);

  final UserModel? Function() _currentUser;

  UserModel? get currentUser => _currentUser();
  UserRole? get role => currentUser?.role;

  /// Class id → whether the lecturer paused attendance capture in the app.
  final Map<String, bool> attendanceCapture = {};

  /// Last known classes, used to enrich attendance records.
  final Map<String, ClassSessionModel> sessions = {};
}

/// Helpers shared by the REST-backed repositories.
abstract class ApiRepositoryBase {
  ApiRepositoryBase(this.api, this.context);

  final ApiService api;
  final ApiContext context;

  Future<T> getOne<T>(
    String path,
    T Function(Json) fromJson, {
    Map<String, Object?>? query,
  }) async => fromJson(await api.getJson(path, query: query));

  /// GET a backend `Page` (or bare list) and map every item.
  Future<List<T>> getMany<T>(
    String path,
    T Function(Json) fromJson, {
    Map<String, Object?>? query,
  }) async => (await api.getList(
    path,
    query: {'page_size': backendPageSize, ...?query},
  )).map(fromJson).toList();

  /// GET a bare JSON array (no pagination parameters).
  Future<List<T>> getArray<T>(
    String path,
    T Function(Json) fromJson, {
    Map<String, Object?>? query,
  }) async => (await api.getList(path, query: query)).map(fromJson).toList();

  Json asJson(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ParsingException();
  }

  Future<T> postOne<T>(
    String path,
    Object? body,
    T Function(Json) fromJson,
  ) async => fromJson(asJson(await api.post(path, body: body)));

  Future<T> putOne<T>(
    String path,
    Object? body,
    T Function(Json) fromJson,
  ) async => fromJson(asJson(await api.put(path, body: body)));

  Future<T> patchOne<T>(
    String path,
    Object? body,
    T Function(Json) fromJson,
  ) async => fromJson(asJson(await api.patch(path, body: body)));

  Never unsupported(String feature) => throw UnsupportedFeatureException(
    '$feature is not available on the server yet.',
  );

  /// Emits [load] now and then every [interval]. Failed polls are logged and
  /// skipped; identical consecutive results are not re-emitted when
  /// [equals] is given.
  Stream<T> poll<T>(
    Future<T> Function() load, {
    Duration interval = backendPollInterval,
    bool Function(T previous, T next)? equals,
  }) {
    late StreamController<T> controller;
    Timer? timer;
    var busy = false;
    var hasValue = false;
    late T last;

    Future<void> tick() async {
      if (busy || controller.isClosed) return;
      busy = true;
      try {
        final value = await load();
        if (controller.isClosed) return;
        if (hasValue && equals != null && equals(last, value)) return;
        last = value;
        hasValue = true;
        controller.add(value);
      } on Object catch (e) {
        ErrorHandler.log(e);
      } finally {
        busy = false;
      }
    }

    controller = StreamController<T>(
      onListen: () {
        tick();
        timer = Timer.periodic(interval, (_) => tick());
      },
      onCancel: () {
        timer?.cancel();
        return controller.close();
      },
    );
    return controller.stream;
  }

  /// Maps a `ClassSessionOut`, applying the local attendance-capture flag,
  /// and remembers it.
  ClassSessionModel mapSession(Json json) {
    final id = json['id'].toString();
    final session = BackendMappers.session(
      json,
      attendanceActive: context.attendanceCapture[id],
    );
    context.sessions[id] = session;
    return session;
  }

  Future<ClassSessionModel> fetchSession(String sessionId) async =>
      mapSession(asJson(await api.get(ApiEndpoints.classDetail(sessionId))));

  /// Classes visible to the caller (the backend filters by role).
  Future<List<ClassSessionModel>> fetchSessions({
    String? courseId,
    DateTime? from,
    DateTime? to,
  }) => getMany(
    ApiEndpoints.classes,
    mapSession,
    query: {
      'course_id': courseId,
      'from': from == null ? null : BackendMappers.iso(from),
      'to': to == null ? null : BackendMappers.iso(to),
    },
  );
}
