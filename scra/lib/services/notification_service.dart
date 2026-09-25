import 'dart:async';

import '../models/notification_model.dart';
import '../repositories/repositories.dart';

/// Delivers notifications to the running app.
///
/// The in-app implementation listens to the [NotificationRepository] stream.
/// A push implementation (e.g. Firebase Cloud Messaging) can later implement
/// the same interface and register [getPushToken] with the backend.
abstract interface class NotificationService {
  Stream<NotificationModel> get onNotification;

  /// Starts listening for notifications addressed to [userId].
  Future<void> startListening(String userId);
  Future<void> stopListening();

  /// Shows a notification inside the app (and as a system notification once
  /// push support is added).
  Future<void> show(NotificationModel notification);

  /// Device token for push delivery; `null` while push is not configured.
  Future<String?> getPushToken();

  Future<void> dispose();
}

class InAppNotificationService implements NotificationService {
  InAppNotificationService(this._repository);

  final NotificationRepository _repository;
  final _controller = StreamController<NotificationModel>.broadcast();
  StreamSubscription<NotificationModel>? _subscription;

  @override
  Stream<NotificationModel> get onNotification => _controller.stream;

  @override
  Future<void> startListening(String userId) async {
    await _subscription?.cancel();
    _subscription = _repository.watchNotifications(userId).listen(show);
  }

  @override
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> show(NotificationModel notification) async {
    if (!_controller.isClosed) _controller.add(notification);
  }

  @override
  Future<String?> getPushToken() async => null;

  @override
  Future<void> dispose() async {
    await stopListening();
    await _controller.close();
  }
}
