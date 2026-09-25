import 'json_utils.dart';

enum AttendanceStatus {
  present('present', 'Present'),
  late('late', 'Late'),
  absent('absent', 'Absent'),
  excused('excused', 'Excused');

  const AttendanceStatus(this.value, this.label);

  final String value;
  final String label;

  /// Present and late both count toward attendance.
  bool get countsAsAttended =>
      this == AttendanceStatus.present || this == AttendanceStatus.late;

  static AttendanceStatus fromJson(Object? value) =>
      AttendanceStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => AttendanceStatus.absent,
      );
}

/// A single student's attendance for a single class session.
class AttendanceRecordModel {
  const AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.status,
    required this.sessionStart,
    this.checkedInAt,
    this.leftAt,
    this.minutesLogged = 0,
    this.sessionMinutes = 0,
    this.verificationMethod,
    this.lecturerName,
    this.room,
    this.note,
    this.matricule,
  });

  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final AttendanceStatus status;
  final DateTime sessionStart;
  final DateTime? checkedInAt;
  final DateTime? leftAt;
  final int minutesLogged;
  final int sessionMinutes;

  /// e.g. `Smart Geofence & Biometric check-in`
  final String? verificationMethod;
  final String? lecturerName;
  final String? room;
  final String? note;
  final String? matricule;

  /// Minutes the student was late relative to the session start.
  int get minutesLate => checkedInAt == null
      ? 0
      : checkedInAt!.difference(sessionStart).inMinutes.clamp(0, 1 << 20);

  double get durationPercent => sessionMinutes == 0
      ? 0
      : (minutesLogged / sessionMinutes * 100).clamp(0, 100);

  factory AttendanceRecordModel.fromJson(Json json) => AttendanceRecordModel(
    id: json['id'].toString(),
    sessionId: json['session_id'].toString(),
    studentId: json['student_id'].toString(),
    studentName: json['student_name'] as String,
    courseId: json['course_id'].toString(),
    courseCode: json['course_code'] as String,
    courseTitle: json['course_title'] as String,
    status: AttendanceStatus.fromJson(json['status']),
    sessionStart: JsonX.date(json['session_start']),
    checkedInAt: JsonX.dateOrNull(json['checked_in_at']),
    leftAt: JsonX.dateOrNull(json['left_at']),
    minutesLogged: JsonX.toInt(json['minutes_logged']),
    sessionMinutes: JsonX.toInt(json['session_minutes']),
    verificationMethod: json['verification_method'] as String?,
    lecturerName: json['lecturer_name'] as String?,
    room: json['room'] as String?,
    note: json['note'] as String?,
    matricule: json['matricule'] as String?,
  );

  Json toJson() => {
    'id': id,
    'session_id': sessionId,
    'student_id': studentId,
    'student_name': studentName,
    'course_id': courseId,
    'course_code': courseCode,
    'course_title': courseTitle,
    'status': status.value,
    'session_start': sessionStart.toIso8601String(),
    'checked_in_at': JsonX.isoOrNull(checkedInAt),
    'left_at': JsonX.isoOrNull(leftAt),
    'minutes_logged': minutesLogged,
    'session_minutes': sessionMinutes,
    'verification_method': verificationMethod,
    'lecturer_name': lecturerName,
    'room': room,
    'note': note,
    'matricule': matricule,
  };

  AttendanceRecordModel copyWith({
    AttendanceStatus? status,
    DateTime? checkedInAt,
    DateTime? leftAt,
    int? minutesLogged,
    String? note,
  }) => AttendanceRecordModel(
    id: id,
    sessionId: sessionId,
    studentId: studentId,
    studentName: studentName,
    courseId: courseId,
    courseCode: courseCode,
    courseTitle: courseTitle,
    status: status ?? this.status,
    sessionStart: sessionStart,
    checkedInAt: checkedInAt ?? this.checkedInAt,
    leftAt: leftAt ?? this.leftAt,
    minutesLogged: minutesLogged ?? this.minutesLogged,
    sessionMinutes: sessionMinutes,
    verificationMethod: verificationMethod,
    lecturerName: lecturerName,
    room: room,
    note: note ?? this.note,
    matricule: matricule,
  );
}
