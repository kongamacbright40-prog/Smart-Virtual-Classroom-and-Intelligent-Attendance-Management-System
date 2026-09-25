import 'json_utils.dart';

enum TermStatus {
  planned('planned', 'Draft / Planned'),
  active('active', 'Active'),
  archived('archived', 'Archived');

  const TermStatus(this.value, this.label);

  final String value;
  final String label;

  static TermStatus fromJson(Object? value) => TermStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => TermStatus.planned,
      );
}

class AcademicTermModel {
  const AcademicTermModel({
    required this.id,
    required this.name,
    required this.code,
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    this.status = TermStatus.planned,
    this.termType = 'Regular',
    this.teachingDays,
    this.enrollmentOpen = false,
    this.addDropDeadline,
    this.enrolledStudents = 0,
    this.courseCount = 0,
    this.averageAttendance,
    this.notes,
  });

  final String id;

  /// e.g. `Fall Semester 2026`
  final String name;

  /// e.g. `FA26-REGULAR`
  final String code;

  /// e.g. `2025/2026`
  final String academicYear;
  final DateTime startDate;
  final DateTime endDate;
  final TermStatus status;

  /// `Regular`, `Intensive`, ...
  final String termType;
  final int? teachingDays;
  final bool enrollmentOpen;
  final DateTime? addDropDeadline;
  final int enrolledStudents;
  final int courseCount;
  final double? averageAttendance;
  final String? notes;

  int get totalWeeks => (endDate.difference(startDate).inDays / 7).ceil();

  /// 1-based current week at [now], clamped to the term.
  int weekAt(DateTime now) {
    if (now.isBefore(startDate)) return 0;
    final w = now.difference(startDate).inDays ~/ 7 + 1;
    return w.clamp(1, totalWeeks);
  }

  double elapsedAt(DateTime now) {
    final total = endDate.difference(startDate).inSeconds;
    if (total <= 0) return 0;
    return (now.difference(startDate).inSeconds / total).clamp(0, 1);
  }

  factory AcademicTermModel.fromJson(Json json) => AcademicTermModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        code: json['code'] as String,
        academicYear: json['academic_year'] as String,
        startDate: JsonX.date(json['start_date']),
        endDate: JsonX.date(json['end_date']),
        status: TermStatus.fromJson(json['status']),
        termType: json['term_type'] as String? ?? 'Regular',
        teachingDays: json['teaching_days'] == null
            ? null
            : JsonX.toInt(json['teaching_days']),
        enrollmentOpen: json['enrollment_open'] as bool? ?? false,
        addDropDeadline: JsonX.dateOrNull(json['add_drop_deadline']),
        enrolledStudents: JsonX.toInt(json['enrolled_students']),
        courseCount: JsonX.toInt(json['course_count']),
        averageAttendance: json['average_attendance'] == null
            ? null
            : JsonX.toDouble(json['average_attendance']),
        notes: json['notes'] as String?,
      );

  Json toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'academic_year': academicYear,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': status.value,
        'term_type': termType,
        'teaching_days': teachingDays,
        'enrollment_open': enrollmentOpen,
        'add_drop_deadline': JsonX.isoOrNull(addDropDeadline),
        'enrolled_students': enrolledStudents,
        'course_count': courseCount,
        'average_attendance': averageAttendance,
        'notes': notes,
      };

  AcademicTermModel copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    TermStatus? status,
    bool? enrollmentOpen,
    String? notes,
  }) =>
      AcademicTermModel(
        id: id,
        name: name ?? this.name,
        code: code,
        academicYear: academicYear,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        termType: termType,
        teachingDays: teachingDays,
        enrollmentOpen: enrollmentOpen ?? this.enrollmentOpen,
        addDropDeadline: addDropDeadline,
        enrolledStudents: enrolledStudents,
        courseCount: courseCount,
        averageAttendance: averageAttendance,
        notes: notes ?? this.notes,
      );
}
