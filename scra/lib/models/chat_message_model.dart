import 'json_utils.dart';
import 'user_model.dart';

enum MessageStatus {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  const MessageStatus(this.value);

  final String value;

  static MessageStatus fromJson(Object? value) => MessageStatus.values
      .firstWhere((e) => e.value == value, orElse: () => MessageStatus.sent);
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.classroomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isQuestion = false,
    this.isPinned = false,
  });

  final String id;
  final String classroomId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String message;
  final DateTime timestamp;
  final MessageStatus status;

  /// Flagged by the sender as a question for the lecturer.
  final bool isQuestion;
  final bool isPinned;

  factory ChatMessageModel.fromJson(Json json) => ChatMessageModel(
    id: json['id'].toString(),
    classroomId: json['classroom_id'].toString(),
    senderId: json['sender_id'].toString(),
    senderName: json['sender_name'] as String,
    senderRole: UserRole.fromJson(json['sender_role']),
    message: json['message'] as String,
    timestamp: JsonX.date(json['timestamp']),
    status: MessageStatus.fromJson(json['status']),
    isQuestion: json['is_question'] as bool? ?? false,
    isPinned: json['is_pinned'] as bool? ?? false,
  );

  Json toJson() => {
    'id': id,
    'classroom_id': classroomId,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_role': senderRole.value,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'status': status.value,
    'is_question': isQuestion,
    'is_pinned': isPinned,
  };

  ChatMessageModel copyWith({
    String? id,
    MessageStatus? status,
    bool? isPinned,
  }) => ChatMessageModel(
    id: id ?? this.id,
    classroomId: classroomId,
    senderId: senderId,
    senderName: senderName,
    senderRole: senderRole,
    message: message,
    timestamp: timestamp,
    status: status ?? this.status,
    isQuestion: isQuestion,
    isPinned: isPinned ?? this.isPinned,
  );
}
