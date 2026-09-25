import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockReportRepository extends MockRepositoryBase
    implements ReportRepository {
  MockReportRepository(this._store, {super.latency});

  final MockDataStore _store;

  double _courseRate(String courseId) {
    final records = _store.attendance.values.where((r) =>
        r.courseId == courseId &&
        _store.sessions[r.sessionId]?.status == SessionStatus.completed);
    if (records.isEmpty) return 0;
    final attended = records.where((r) => r.status.countsAsAttended).length;
    final counted =
        records.where((r) => r.status != AttendanceStatus.excused).length;
    return counted == 0 ? 0 : attended / counted * 100;
  }

  int _atRisk(Iterable<String> courseIds) {
    final threshold = _store.systemSettings.minimumAttendance;
    final flagged = <String>{};
    for (final courseId in courseIds) {
      for (final studentId in _store.enrollments[courseId] ?? const <String>[]) {
        final records = _store.attendance.values
            .where((r) => r.courseId == courseId && r.studentId == studentId)
            .toList();
        final s = AttendanceModel.fromRecords(studentId, records);
        if (s.totalSessions > 0 && s.percentage < threshold) {
          flagged.add(studentId);
        }
      }
    }
    return flagged.length;
  }

  List<ReportDataPoint> _weeklyTrend(Iterable<String> courseIds,
      {int weeks = 6}) {
    final ids = courseIds.toSet();
    final now = _store.now;
    return List.generate(weeks, (i) {
      final end = now.subtract(Duration(days: 7 * (weeks - 1 - i)));
      final start = end.subtract(const Duration(days: 7));
      final records = _store.attendance.values.where((r) =>
          ids.contains(r.courseId) &&
          r.sessionStart.isAfter(start) &&
          !r.sessionStart.isAfter(end));
      final total = records.length;
      final attended = records.where((r) => r.status.countsAsAttended).length;
      return ReportDataPoint(
        label: 'W${i + 1}',
        value: total == 0 ? 0 : attended / total * 100,
        extra: attended.toDouble(),
      );
    });
  }

  @override
  Future<ReportModel> getAdminDashboard() => delay(() {
        final students = _store.users.values
            .where((u) => u.role == UserRole.student)
            .length;
        final lecturers = _store.users.values
            .where((u) => u.role == UserRole.lecturer)
            .length;
        final live = _store.sessions.values
            .where((s) => s.status == SessionStatus.live)
            .length;
        return ReportModel(
          id: 'rpt-admin-dashboard',
          title: 'Campus Overview',
          type: ReportType.institution,
          generatedAt: DateTime.now(),
          periodStart: _store.terms[MockDataStore.activeTermId]!.startDate,
          periodEnd: _store.terms[MockDataStore.activeTermId]!.endDate,
          metrics: {
            // Institution-wide numbers mirror the design; the demo data set
            // only contains a sample of the campus population.
            'total_students': 1240,
            'new_students': 38,
            'registered_rate': 98,
            'active_classes': live.toDouble() + 7,
            'total_staff': 65,
            'on_campus_staff': 42,
            'remote_staff': 23,
            'avg_attendance': 89.5,
            'attendance_change': 2.1,
            'attendance_target': 85,
            'term_week': _store.terms[MockDataStore.activeTermId]!
                .weekAt(_store.now)
                .toDouble(),
            'demo_students': students.toDouble(),
            'demo_lecturers': lecturers.toDouble(),
          },
          trend: _weeklyTrend(_store.courses.keys),
        );
      });

  @override
  Future<ReportModel> getLecturerReport(String lecturerId,
          {String? courseId}) =>
      delay(() {
        final courses = _store.courses.values
            .where((c) =>
                c.lecturerId == lecturerId &&
                (courseId == null || c.id == courseId))
            .toList();
        if (courses.isEmpty) {
          throw const NotFoundException('No courses found for this report.');
        }
        final ids = courses.map((c) => c.id).toList();
        final sessions = _store.sessions.values.where((s) =>
            ids.contains(s.courseId) && s.status == SessionStatus.completed);
        final rates = courses.map((c) => _courseRate(c.id)).toList();
        final avg = rates.isEmpty
            ? 0.0
            : rates.reduce((a, b) => a + b) / rates.length;
        return ReportModel(
          id: 'rpt-lec-$lecturerId-${courseId ?? 'all'}',
          title: courseId == null
              ? 'Attendance Reports'
              : '${courses.first.code} Attendance',
          type: ReportType.attendance,
          scopeId: courseId ?? lecturerId,
          generatedAt: DateTime.now(),
          periodStart: _store.terms[MockDataStore.activeTermId]!.startDate,
          periodEnd: _store.now,
          metrics: {
            'average_rate': avg,
            'sessions': sessions.length.toDouble(),
            'students': courses
                .fold<int>(0, (s, c) => s + c.enrolledCount)
                .toDouble(),
            'at_risk': _atRisk(ids).toDouble(),
            'participation_rate': 78,
          },
          trend: _weeklyTrend(ids),
          breakdown: [
            for (final c in courses)
              ReportBreakdown(
                id: c.id,
                label: c.code,
                subtitle: c.title,
                value: _courseRate(c.id),
                meta: {
                  'students': '${c.enrolledCount}',
                  'sessions': '${c.sessionsHeld} / ${c.totalSessions}',
                },
              ),
          ],
        );
      });

  @override
  Future<ReportModel> getInstitutionReport({
    String? departmentId,
    String? termId,
  }) =>
      delay(() {
        final courses = _store.courses.values
            .where((c) =>
                c.status == CourseStatus.active &&
                (departmentId == null || c.departmentId == departmentId))
            .toList();
        final faculties = _store.faculties.values.toList();
        return ReportModel(
          id: 'rpt-inst-${departmentId ?? 'all'}-${termId ?? 'current'}',
          title: 'Institutional Analytics',
          type: ReportType.institution,
          scopeId: departmentId,
          generatedAt: DateTime.now(),
          periodStart: _store.terms[termId ?? MockDataStore.activeTermId]!
              .startDate,
          periodEnd: _store.now,
          metrics: const {
            'overall_rate': 89.4,
            'rate_change': 2.3,
            'sessions': 1420,
            'sync_rate': 98.1,
            'at_risk': 48,
            'target': 85,
          },
          trend: const [
            ReportDataPoint(label: 'W1', value: 86.2, extra: 1180),
            ReportDataPoint(label: 'W2', value: 87.9, extra: 1214),
            ReportDataPoint(label: 'W3', value: 88.4, extra: 1236),
            ReportDataPoint(label: 'W4', value: 87.1, extra: 1205),
            ReportDataPoint(label: 'W5', value: 90.3, extra: 1288),
            ReportDataPoint(label: 'W6', value: 91.2, extra: 1310),
            ReportDataPoint(label: 'W7', value: 90.6, extra: 1296),
            ReportDataPoint(label: 'W8', value: 89.4, extra: 1275),
          ],
          previousTrend: const [
            ReportDataPoint(label: 'W1', value: 84.0),
            ReportDataPoint(label: 'W2', value: 85.3),
            ReportDataPoint(label: 'W3', value: 86.1),
            ReportDataPoint(label: 'W4', value: 85.4),
            ReportDataPoint(label: 'W5', value: 87.0),
            ReportDataPoint(label: 'W6', value: 88.2),
            ReportDataPoint(label: 'W7', value: 87.5),
            ReportDataPoint(label: 'W8', value: 87.1),
          ],
          breakdown: [
            for (final f in faculties.take(4))
              ReportBreakdown(
                id: f.id,
                label: f.name,
                value: _store.departments.values
                        .where((d) => d.facultyId == f.id)
                        .map((d) => d.averageAttendance)
                        .fold<double>(0, (a, b) => a > b ? a : b),
                subtitle: 'faculty',
              ),
            for (final c in courses.take(6))
              ReportBreakdown(
                id: c.id,
                label: c.code,
                subtitle: c.title,
                value: _courseRate(c.id) == 0 ? 87.8 : _courseRate(c.id),
                meta: {
                  'type': 'course',
                  'lecturer': c.lecturerName ?? 'Unassigned',
                  'students': '${c.enrolledCount}',
                  'sessions': '${c.sessionsHeld} / ${c.totalSessions}',
                },
              ),
          ],
        );
      });

  @override
  Future<String> exportReport(
    String reportId, {
    required ReportFormat format,
    bool includeMatricule = true,
    bool includeGeolocation = false,
  }) =>
      delay(() => '${reportId}_${DateTime.now().millisecondsSinceEpoch}.${format.value}');
}
