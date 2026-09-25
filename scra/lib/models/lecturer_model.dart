import 'json_utils.dart';
import 'user_model.dart';

class LecturerModel {
  const LecturerModel({
    required this.user,
    required this.staffId,
    required this.title,
    this.specialization,
    this.officeLocation,
    this.officeHours,
    this.courseIds = const [],
    this.totalStudents = 0,
    this.averageAttendance = 0,
    this.rating,
  });

  final UserModel user;

  /// Institutional staff ID, e.g. `FAC-2024-8192`.
  final String staffId;

  /// Academic title such as `Dr.` or `Prof.`
  final String title;
  final String? specialization;
  final String? officeLocation;
  final String? officeHours;
  final List<String> courseIds;
  final int totalStudents;
  final double averageAttendance;
  final double? rating;

  String get id => user.id;

  factory LecturerModel.fromJson(Json json) => LecturerModel(
    user: UserModel.fromJson(JsonX.map(json['user'])),
    staffId: json['staff_id'] as String,
    title: json['title'] as String? ?? '',
    specialization: json['specialization'] as String?,
    officeLocation: json['office_location'] as String?,
    officeHours: json['office_hours'] as String?,
    courseIds: JsonX.stringList(json['course_ids']),
    totalStudents: JsonX.toInt(json['total_students']),
    averageAttendance: JsonX.toDouble(json['average_attendance']),
    rating: json['rating'] == null ? null : JsonX.toDouble(json['rating']),
  );

  Json toJson() => {
    'user': user.toJson(),
    'staff_id': staffId,
    'title': title,
    'specialization': specialization,
    'office_location': officeLocation,
    'office_hours': officeHours,
    'course_ids': courseIds,
    'total_students': totalStudents,
    'average_attendance': averageAttendance,
    'rating': rating,
  };

  LecturerModel copyWith({
    UserModel? user,
    String? specialization,
    String? officeLocation,
    String? officeHours,
  }) => LecturerModel(
    user: user ?? this.user,
    staffId: staffId,
    title: title,
    specialization: specialization ?? this.specialization,
    officeLocation: officeLocation ?? this.officeLocation,
    officeHours: officeHours ?? this.officeHours,
    courseIds: courseIds,
    totalStudents: totalStudents,
    averageAttendance: averageAttendance,
    rating: rating,
  );
}
