import 'json_utils.dart';

class FacultyModel {
  const FacultyModel({
    required this.id,
    required this.name,
    required this.code,
    this.deanName,
    this.category,
    this.departmentCount = 0,
    this.courseCount = 0,
    this.studentCount = 0,
    this.staffCount = 0,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// Short code, e.g. `FCS-ENG`.
  final String code;
  final String? deanName;

  /// Filter group shown in the Departments screen, e.g. `Science & Tech`.
  final String? category;
  final int departmentCount;
  final int courseCount;
  final int studentCount;
  final int staffCount;
  final bool isActive;

  factory FacultyModel.fromJson(Json json) => FacultyModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        code: json['code'] as String,
        deanName: json['dean_name'] as String?,
        category: json['category'] as String?,
        departmentCount: JsonX.toInt(json['department_count']),
        courseCount: JsonX.toInt(json['course_count']),
        studentCount: JsonX.toInt(json['student_count']),
        staffCount: JsonX.toInt(json['staff_count']),
        isActive: json['is_active'] as bool? ?? true,
      );

  Json toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'dean_name': deanName,
        'category': category,
        'department_count': departmentCount,
        'course_count': courseCount,
        'student_count': studentCount,
        'staff_count': staffCount,
        'is_active': isActive,
      };
}
