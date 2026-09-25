import 'json_utils.dart';

class DepartmentModel {
  const DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.facultyId,
    this.facultyName,
    this.description,
    this.headName,
    this.courseCount = 0,
    this.studentCount = 0,
    this.staffCount = 0,
    this.liveSessions = 0,
    this.averageAttendance = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final String facultyId;
  final String? facultyName;

  /// Sub-heading, e.g. `Applied Modeling & Data Sciences`.
  final String? description;
  final String? headName;
  final int courseCount;
  final int studentCount;
  final int staffCount;
  final int liveSessions;
  final double averageAttendance;
  final bool isActive;

  factory DepartmentModel.fromJson(Json json) => DepartmentModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        code: json['code'] as String,
        facultyId: json['faculty_id'].toString(),
        facultyName: json['faculty_name'] as String?,
        description: json['description'] as String?,
        headName: json['head_name'] as String?,
        courseCount: JsonX.toInt(json['course_count']),
        studentCount: JsonX.toInt(json['student_count']),
        staffCount: JsonX.toInt(json['staff_count']),
        liveSessions: JsonX.toInt(json['live_sessions']),
        averageAttendance: JsonX.toDouble(json['average_attendance']),
        isActive: json['is_active'] as bool? ?? true,
      );

  Json toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'faculty_id': facultyId,
        'faculty_name': facultyName,
        'description': description,
        'head_name': headName,
        'course_count': courseCount,
        'student_count': studentCount,
        'staff_count': staffCount,
        'live_sessions': liveSessions,
        'average_attendance': averageAttendance,
        'is_active': isActive,
      };

  DepartmentModel copyWith({
    String? name,
    String? code,
    String? headName,
    String? description,
    bool? isActive,
  }) =>
      DepartmentModel(
        id: id,
        name: name ?? this.name,
        code: code ?? this.code,
        facultyId: facultyId,
        facultyName: facultyName,
        description: description ?? this.description,
        headName: headName ?? this.headName,
        courseCount: courseCount,
        studentCount: studentCount,
        staffCount: staffCount,
        liveSessions: liveSessions,
        averageAttendance: averageAttendance,
        isActive: isActive ?? this.isActive,
      );
}
