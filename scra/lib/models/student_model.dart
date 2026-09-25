import 'json_utils.dart';
import 'user_model.dart';

class StudentModel {
  const StudentModel({
    required this.user,
    required this.matricule,
    required this.programme,
    required this.level,
    required this.semester,
    this.facultyName,
    this.enrolledCourseIds = const [],
    this.overallAttendance = 0,
    this.activeCredits = 0,
    this.gpa,
    this.campusPassValid = true,
  });

  final UserModel user;

  /// Institutional student ID, e.g. `MAT-2024-9148`.
  final String matricule;
  final String programme;
  final int level;
  final int semester;
  final String? facultyName;
  final List<String> enrolledCourseIds;
  final double overallAttendance;
  final int activeCredits;
  final double? gpa;
  final bool campusPassValid;

  String get id => user.id;

  factory StudentModel.fromJson(Json json) => StudentModel(
    user: UserModel.fromJson(JsonX.map(json['user'])),
    matricule: json['matricule'] as String,
    programme: json['programme'] as String? ?? '',
    level: JsonX.toInt(json['level'], 100),
    semester: JsonX.toInt(json['semester'], 1),
    facultyName: json['faculty_name'] as String?,
    enrolledCourseIds: JsonX.stringList(json['enrolled_course_ids']),
    overallAttendance: JsonX.toDouble(json['overall_attendance']),
    activeCredits: JsonX.toInt(json['active_credits']),
    gpa: json['gpa'] == null ? null : JsonX.toDouble(json['gpa']),
    campusPassValid: json['campus_pass_valid'] as bool? ?? true,
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

  StudentModel copyWith({UserModel? user, String? programme}) => StudentModel(
    user: user ?? this.user,
    matricule: matricule,
    programme: programme ?? this.programme,
    level: level,
    semester: semester,
    facultyName: facultyName,
    enrolledCourseIds: enrolledCourseIds,
    overallAttendance: overallAttendance,
    activeCredits: activeCredits,
    gpa: gpa,
    campusPassValid: campusPassValid,
  );
}
