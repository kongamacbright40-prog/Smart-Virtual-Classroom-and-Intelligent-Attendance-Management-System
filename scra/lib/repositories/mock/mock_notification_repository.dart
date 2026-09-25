import '../../models/models.dart';
import '../repositories.dart';
import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockNotificationRepository extends MockRepositoryBase
    implements NotificationRepository {
  MockNotificationRepository(this._store, {super.latency});

  final MockDataStore _store;

  @override
  Future<List<NotificationModel>> getNotifications(String userId) =>
      delay(() => _store.notifications.values
          .where((n) => n.userId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Future<void> markAsRead(String notificationId) => delay(() {
        final n = _store.notifications[notificationId];
        if (n != null) {
          _store.notifications[notificationId] = n.copyWith(isRead: true);
        }
      });

  @override
  Future<void> markAllAsRead(String userId) => delay(() {
        for (final entry in _store.notifications.entries.toList()) {
          if (entry.value.userId == userId) {
            _store.notifications[entry.key] =
                entry.value.copyWith(isRead: true);
          }
        }
      });

  /// Pushes a new notification (used by the mock notification service).
  void push(NotificationModel notification) {
    _store.notifications[notification.id] = notification;
    _store.notificationChannel(notification.userId).add(notification);
  }

  @override
  Stream<NotificationModel> watchNotifications(String userId) =>
      _store.notificationChannel(userId).stream;
}
