import 'json_utils.dart';

enum NotificationType {
  classReminder('class_reminder', 'Class Reminder'),
  newCourse('new_course', 'New Course'),
  attendanceUpdate('attendance_update', 'Attendance'),
  liveQuestion('live_question', 'Live Question'),
  announcement('announcement', 'Announcement');

  const NotificationType(this.value, this.label);

  final String value;
  final String label;

  static NotificationType fromJson(Object? value) =>
      NotificationType.values.firstWhere(
        (e) => e.value == value,
        orElse: () => NotificationType.announcement,
      );
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.referenceId,
    this.actionLabel,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  /// Id of the related entity (session, course, question...).
  final String? referenceId;

  /// Optional call-to-action label, e.g. `Join Now`.
  final String? actionLabel;

  factory NotificationModel.fromJson(Json json) => NotificationModel(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.fromJson(json['type']),
        createdAt: JsonX.date(json['created_at']),
        isRead: json['is_read'] as bool? ?? false,
        referenceId: json['reference_id'] as String?,
        actionLabel: json['action_label'] as String?,
      );

  Json toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
        'reference_id': referenceId,
        'action_label': actionLabel,
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        referenceId: referenceId,
        actionLabel: actionLabel,
      );
}
