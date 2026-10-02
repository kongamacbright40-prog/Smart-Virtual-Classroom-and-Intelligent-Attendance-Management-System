import 'json_utils.dart';
import 'user_model.dart';

class StudentModel {
  const StudentModel({
    required this.user,
    required this.matricule,
    required this.programme,
    this.level,
    this.semester,
    this.facultyName,
    this.enrolledCourseIds = const [],
    this.overallAttendance,
    this.activeCredits,
    this.gpa,
    this.campusPassValid,
  });

  final UserModel user;

  /// Institutional student ID, e.g. `MAT-2024-9148`.
  final String matricule;
  final String programme;
  final int? level;
  final int? semester;
  final String? facultyName;
  final List<String> enrolledCourseIds;

  /// `null` until at least one class has been held.
  final double? overallAttendance;
  final int? activeCredits;
  final double? gpa;
  final bool? campusPassValid;

  String get id => user.id;

  factory StudentModel.fromJson(Json json) => StudentModel(
    user: UserModel.fromJson(JsonX.map(json['user'])),
    matricule: json['matricule'] as String,
    programme: json['programme'] as String? ?? '',
    level: json['level'] == null ? null : JsonX.toInt(json['level']),
    semester: json['semester'] == null ? null : JsonX.toInt(json['semester']),
    facultyName: json['faculty_name'] as String?,
    enrolledCourseIds: JsonX.stringList(json['enrolled_course_ids']),
    overallAttendance: json['overall_attendance'] == null
        ? null
        : JsonX.toDouble(json['overall_attendance']),
    activeCredits: json['active_credits'] == null
        ? null
        : JsonX.toInt(json['active_credits']),
    gpa: json['gpa'] == null ? null : JsonX.toDouble(json['gpa']),
    campusPassValid: json['campus_pass_valid'] as bool?,
  );

  Json toJson() => {
    'user': user.toJson(),
    'matricule': matricule,
    'programme': programme,
    'level': level,
    'semester': semester,
    'faculty_name': facultyName,
    'enrolled_course_ids': enrolledCourseIds,
    'overall_attendance': overallAttendance,
    'active_credits': activeCredits,
    'gpa': gpa,
    'campus_pass_valid': campusPassValid,
  };

  StudentModel copyWith({
    UserModel? user,
    String? programme,
    List<String>? enrolledCourseIds,
  }) => StudentModel(
    user: user ?? this.user,
    matricule: matricule,
    programme: programme ?? this.programme,
    level: level,
    semester: semester,
    facultyName: facultyName,
    enrolledCourseIds: enrolledCourseIds ?? this.enrolledCourseIds,
    overallAttendance: overallAttendance,
    activeCredits: activeCredits,
    gpa: gpa,
    campusPassValid: campusPassValid,
  );
}
