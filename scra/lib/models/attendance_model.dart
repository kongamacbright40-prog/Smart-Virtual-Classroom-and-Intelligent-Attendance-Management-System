import 'attendance_record_model.dart';
import 'json_utils.dart';

/// Aggregated attendance for a student (optionally scoped to one course).
class AttendanceModel {
  const AttendanceModel({
    required this.studentId,
    required this.totalSessions,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    this.excusedCount = 0,
    this.courseId,
    this.courseCode,
    this.courseTitle,
    this.participationRate,
    this.requiredPercentage = 75,
  });

  final String studentId;
  final String? courseId;
  final String? courseCode;
  final String? courseTitle;
  final int totalSessions;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int excusedCount;

  /// Live quiz / poll participation percentage.
  final double? participationRate;

  /// Minimum attendance percentage required by the institution.
  final double requiredPercentage;

  int get attendedCount => presentCount + lateCount;

  /// Attendance percentage. Excused sessions are removed from the total.
  double get percentage {
    final counted = totalSessions - excusedCount;
    if (counted <= 0) return 0;
    return attendedCount / counted * 100;
  }

  bool get meetsRequirement => percentage >= requiredPercentage;

  /// Builds a summary from individual records.
  factory AttendanceModel.fromRecords(
    String studentId,
    List<AttendanceRecordModel> records, {
    String? courseId,
    String? courseCode,
    String? courseTitle,
    double? participationRate,
    double requiredPercentage = 75,
  }) {
    int count(AttendanceStatus s) => records.where((r) => r.status == s).length;
    return AttendanceModel(
      studentId: studentId,
      courseId: courseId,
      courseCode: courseCode,
      courseTitle: courseTitle,
      totalSessions: records.length,
      presentCount: count(AttendanceStatus.present),
      lateCount: count(AttendanceStatus.late),
      absentCount: count(AttendanceStatus.absent),
      excusedCount: count(AttendanceStatus.excused),
      participationRate: participationRate,
      requiredPercentage: requiredPercentage,
    );
  }

  factory AttendanceModel.fromJson(Json json) => AttendanceModel(
    studentId: json['student_id'].toString(),
    courseId: json['course_id'] as String?,
    courseCode: json['course_code'] as String?,
    courseTitle: json['course_title'] as String?,
    totalSessions: JsonX.toInt(json['total_sessions']),
    presentCount: JsonX.toInt(json['present_count']),
    lateCount: JsonX.toInt(json['late_count']),
    absentCount: JsonX.toInt(json['absent_count']),
    excusedCount: JsonX.toInt(json['excused_count']),
    participationRate: json['participation_rate'] == null
        ? null
        : JsonX.toDouble(json['participation_rate']),
    requiredPercentage: JsonX.toDouble(json['required_percentage'], 75),
  );

  Json toJson() => {
    'student_id': studentId,
    'course_id': courseId,
    'course_code': courseCode,
    'course_title': courseTitle,
    'total_sessions': totalSessions,
    'present_count': presentCount,
    'late_count': lateCount,
    'absent_count': absentCount,
    'excused_count': excusedCount,
    'participation_rate': participationRate,
    'required_percentage': requiredPercentage,
  };
}
