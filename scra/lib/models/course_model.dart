import 'json_utils.dart';

enum CourseStatus {
  active('active', 'Active'),
  pendingLecturer('pending_lecturer', 'Pending Lecturer'),
  draft('draft', 'Draft'),
  archived('archived', 'Archived');

  const CourseStatus(this.value, this.label);

  final String value;
  final String label;

  static CourseStatus fromJson(Object? value) => CourseStatus.values.firstWhere(
    (e) => e.value == value,
    orElse: () => CourseStatus.active,
  );
}

class CourseModel {
  const CourseModel({
    required this.id,
    required this.code,
    required this.title,
    required this.credits,
    required this.departmentId,
    this.description = '',
    this.category = 'Core Major',
    this.creditNote,
    this.lecturerId,
    this.lecturerName,
    this.lecturerRole,
    this.departmentName,
    this.facultyName,
    this.termId,
    this.status = CourseStatus.active,
    this.enrolledCount = 0,
    this.capacity,
    this.totalSessions = 0,
    this.sessionsHeld = 0,
    this.scheduleSummary,
    this.room,
    this.virtualRoomUrl,
    this.topics = const [],
  });

  final String id;

  /// Catalogue code, e.g. `CS-301`.
  final String code;
  final String title;
  final String description;

  /// `Core Major`, `Faculty Elective`, `Required`, ...
  final String category;
  final int credits;

  /// Extra descriptor shown with credits, e.g. `Theory + Lab`.
  final String? creditNote;
  final String? lecturerId;
  final String? lecturerName;
  final String? lecturerRole;
  final String departmentId;
  final String? departmentName;
  final String? facultyName;
  final String? termId;
  final CourseStatus status;
  final int enrolledCount;
  final int? capacity;
  final int totalSessions;
  final int sessionsHeld;

  /// Human readable meeting pattern, e.g. `Mon & Wed • 10:00 — 11:30 AM`.
  final String? scheduleSummary;
  final String? room;
  final String? virtualRoomUrl;
  final List<String> topics;

  bool get hasLecturer => lecturerId != null && lecturerId!.isNotEmpty;

  double get progress =>
      totalSessions == 0 ? 0 : (sessionsHeld / totalSessions).clamp(0, 1);

  factory CourseModel.fromJson(Json json) => CourseModel(
    id: json['id'].toString(),
    code: json['code'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? 'Core Major',
    credits: JsonX.toInt(json['credits']),
    creditNote: json['credit_note'] as String?,
    lecturerId: json['lecturer_id'] as String?,
    lecturerName: json['lecturer_name'] as String?,
    lecturerRole: json['lecturer_role'] as String?,
    departmentId: json['department_id'] as String,
    departmentName: json['department_name'] as String?,
    facultyName: json['faculty_name'] as String?,
    termId: json['term_id'] as String?,
    status: CourseStatus.fromJson(json['status']),
    enrolledCount: JsonX.toInt(json['enrolled_count']),
    capacity: json['capacity'] == null ? null : JsonX.toInt(json['capacity']),
    totalSessions: JsonX.toInt(json['total_sessions']),
    sessionsHeld: JsonX.toInt(json['sessions_held']),
    scheduleSummary: json['schedule_summary'] as String?,
    room: json['room'] as String?,
    virtualRoomUrl: json['virtual_room_url'] as String?,
    topics: JsonX.stringList(json['topics']),
  );

  Json toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'description': description,
    'category': category,
    'credits': credits,
    'credit_note': creditNote,
    'lecturer_id': lecturerId,
    'lecturer_name': lecturerName,
    'lecturer_role': lecturerRole,
    'department_id': departmentId,
    'department_name': departmentName,
    'faculty_name': facultyName,
    'term_id': termId,
    'status': status.value,
    'enrolled_count': enrolledCount,
    'capacity': capacity,
    'total_sessions': totalSessions,
    'sessions_held': sessionsHeld,
    'schedule_summary': scheduleSummary,
    'room': room,
    'virtual_room_url': virtualRoomUrl,
    'topics': topics,
  };

  CourseModel copyWith({
    String? code,
    String? title,
    String? description,
    String? category,
    int? credits,
    String? lecturerId,
    String? lecturerName,
    String? departmentId,
    String? departmentName,
    String? termId,
    CourseStatus? status,
    int? enrolledCount,
    int? sessionsHeld,
  }) => CourseModel(
    id: id,
    code: code ?? this.code,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    credits: credits ?? this.credits,
    creditNote: creditNote,
    lecturerId: lecturerId ?? this.lecturerId,
    lecturerName: lecturerName ?? this.lecturerName,
    lecturerRole: lecturerRole,
    departmentId: departmentId ?? this.departmentId,
    departmentName: departmentName ?? this.departmentName,
    facultyName: facultyName,
    termId: termId ?? this.termId,
    status: status ?? this.status,
    enrolledCount: enrolledCount ?? this.enrolledCount,
    capacity: capacity,
    totalSessions: totalSessions,
    sessionsHeld: sessionsHeld ?? this.sessionsHeld,
    scheduleSummary: scheduleSummary,
    room: room,
    virtualRoomUrl: virtualRoomUrl,
    topics: topics,
  );
}
