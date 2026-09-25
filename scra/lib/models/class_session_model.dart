import 'json_utils.dart';

enum SessionStatus {
  scheduled('scheduled', 'Scheduled'),
  live('live', 'Live'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const SessionStatus(this.value, this.label);

  final String value;
  final String label;

  static SessionStatus fromJson(Object? value) =>
      SessionStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => SessionStatus.scheduled,
      );
}

enum SessionMode {
  inPerson('in_person', 'In Person'),
  virtual('virtual', 'Virtual'),
  hybrid('hybrid', 'Hybrid');

  const SessionMode(this.value, this.label);

  final String value;
  final String label;

  static SessionMode fromJson(Object? value) => SessionMode.values.firstWhere(
        (e) => e.value == value,
        orElse: () => SessionMode.hybrid,
      );
}

/// A single occurrence of a class (lecture, lab, seminar).
class ClassSessionModel {
  const ClassSessionModel({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.lecturerId,
    this.lecturerName,
    this.room,
    this.mode = SessionMode.hybrid,
    this.status = SessionStatus.scheduled,
    this.sessionNumber,
    this.participantCount = 0,
    this.expectedCount = 0,
    this.attendanceActive = false,
    this.materials = const [],
  });

  final String id;
  final String courseId;
  final String courseCode;
  final String courseTitle;

  /// e.g. `Lecture 13: Graph Traversal & BFS`
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? lecturerId;
  final String? lecturerName;
  final String? room;
  final SessionMode mode;
  final SessionStatus status;
  final int? sessionNumber;
  final int participantCount;
  final int expectedCount;

  /// Whether smart attendance is currently being captured.
  final bool attendanceActive;
  final List<String> materials;

  /// Room identifier used for WebSocket / WebRTC channels.
  String get roomId => id;

  Duration get duration => endTime.difference(startTime);

  bool get isLive => status == SessionStatus.live;

  /// Fraction of the class that has elapsed at [now], clamped to 0..1.
  double progressAt(DateTime now) {
    final total = duration.inSeconds;
    if (total <= 0) return 0;
    return (now.difference(startTime).inSeconds / total).clamp(0, 1);
  }

  factory ClassSessionModel.fromJson(Json json) => ClassSessionModel(
        id: json['id'].toString(),
        courseId: json['course_id'].toString(),
        courseCode: json['course_code'] as String,
        courseTitle: json['course_title'] as String,
        title: json['title'] as String,
        startTime: JsonX.date(json['start_time']),
        endTime: JsonX.date(json['end_time']),
        lecturerId: json['lecturer_id'] as String?,
        lecturerName: json['lecturer_name'] as String?,
        room: json['room'] as String?,
        mode: SessionMode.fromJson(json['mode']),
        status: SessionStatus.fromJson(json['status']),
        sessionNumber: json['session_number'] == null
            ? null
            : JsonX.toInt(json['session_number']),
        participantCount: JsonX.toInt(json['participant_count']),
        expectedCount: JsonX.toInt(json['expected_count']),
        attendanceActive: json['attendance_active'] as bool? ?? false,
        materials: JsonX.stringList(json['materials']),
      );

  Json toJson() => {
        'id': id,
        'course_id': courseId,
        'course_code': courseCode,
        'course_title': courseTitle,
        'title': title,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'lecturer_id': lecturerId,
        'lecturer_name': lecturerName,
        'room': room,
        'mode': mode.value,
        'status': status.value,
        'session_number': sessionNumber,
        'participant_count': participantCount,
        'expected_count': expectedCount,
        'attendance_active': attendanceActive,
        'materials': materials,
      };

  ClassSessionModel copyWith({
    SessionStatus? status,
    int? participantCount,
    bool? attendanceActive,
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      ClassSessionModel(
        id: id,
        courseId: courseId,
        courseCode: courseCode,
        courseTitle: courseTitle,
        title: title,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        room: room,
        mode: mode,
        status: status ?? this.status,
        sessionNumber: sessionNumber,
        participantCount: participantCount ?? this.participantCount,
        expectedCount: expectedCount,
        attendanceActive: attendanceActive ?? this.attendanceActive,
        materials: materials,
      );
}
