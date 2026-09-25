import 'class_session_model.dart';
import 'json_utils.dart';

/// A lecturer's request to schedule a class (Schedule Class screen) and the
/// resulting room configuration returned by the backend.
class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.topic,
    required this.startTime,
    required this.durationMinutes,
    this.lateThresholdMinutes = 10,
    this.enableQuestions = true,
    this.room,
    this.mode = SessionMode.hybrid,
    this.roomCode,
    this.expectedStudents = 0,
    this.sessionId,
    this.createdAt,
  });

  final String id;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final String topic;
  final DateTime startTime;
  final int durationMinutes;

  /// Students joining after this many minutes are marked late.
  final int lateThresholdMinutes;
  final bool enableQuestions;
  final String? room;
  final SessionMode mode;

  /// Code students can use to join, e.g. `#SC-CS301-B`.
  final String? roomCode;
  final int expectedStudents;

  /// Id of the [ClassSessionModel] created for this schedule.
  final String? sessionId;
  final DateTime? createdAt;

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  factory ScheduleModel.fromJson(Json json) => ScheduleModel(
        id: json['id'].toString(),
        courseId: json['course_id'].toString(),
        courseCode: json['course_code'] as String,
        courseTitle: json['course_title'] as String,
        topic: json['topic'] as String,
        startTime: JsonX.date(json['start_time']),
        durationMinutes: JsonX.toInt(json['duration_minutes'], 60),
        lateThresholdMinutes: JsonX.toInt(json['late_threshold_minutes'], 10),
        enableQuestions: json['enable_questions'] as bool? ?? true,
        room: json['room'] as String?,
        mode: SessionMode.fromJson(json['mode']),
        roomCode: json['room_code'] as String?,
        expectedStudents: JsonX.toInt(json['expected_students']),
        sessionId: json['session_id'] as String?,
        createdAt: JsonX.dateOrNull(json['created_at']),
      );

  Json toJson() => {
        'id': id,
        'course_id': courseId,
        'course_code': courseCode,
        'course_title': courseTitle,
        'topic': topic,
        'start_time': startTime.toIso8601String(),
        'duration_minutes': durationMinutes,
        'late_threshold_minutes': lateThresholdMinutes,
        'enable_questions': enableQuestions,
        'room': room,
        'mode': mode.value,
        'room_code': roomCode,
        'expected_students': expectedStudents,
        'session_id': sessionId,
        'created_at': JsonX.isoOrNull(createdAt),
      };
}
