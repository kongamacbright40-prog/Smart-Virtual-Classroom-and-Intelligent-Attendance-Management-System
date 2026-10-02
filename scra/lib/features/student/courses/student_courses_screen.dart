import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/inputs/search_field.dart';
import '../../authentication/providers/auth_provider.dart';
import 'widgets/course_card.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  String _query = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final studentId = context.watch<AuthProvider>().user!.id;
    return AsyncView<_CoursesData>(
      load: () => _CoursesData.load(context, studentId),
      builder: (context, data, reload) {
        final filtered = data.filter(_query, _filter);
        return AppScaffold(
          appBar: SmartAppBar(
            title: 'My Courses',
            subtitle: data.activeTerm?.name ?? data.activeTerm?.academicYear,
          ),
          scrollable: true,
          onRefresh: reload,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(
                hint: 'Search courses, codes, or professor',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              OutlinedButton.icon(
                key: const Key('open_course_catalog'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Enroll in a course'),
                onPressed: () async {
                  await Navigator.of(context)
                      .pushNamed(RouteNames.courseCatalog);
                  await reload();
                },
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final chip in data.filters) ...[
                      ChoiceChip(
                        label: Text(chip),
                        selected: _filter == chip,
                        onSelected: (_) => setState(() => _filter = chip),
                      ),
                      const SizedBox(width: AppDimensions.spaceSm),
                    ],
                  ],
                ),
              ),
              SectionHeader(
                title: 'Enrolled Courses',
                subtitle: '${filtered.length} Total',
              ),
              if (data.courses.isEmpty)
                EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No courses yet',
                  message:
                      'You get every course of your department automatically. '
                      'You can also enroll in other courses.',
                  actionLabel: 'Browse courses',
                  onAction: () async {
                    await Navigator.of(context)
                        .pushNamed(RouteNames.courseCatalog);
                    await reload();
                  },
                  compact: true,
                )
              else if (filtered.isEmpty)
                const EmptyState(
                  icon: Icons.search_off,
                  title: 'No matching courses',
                  message: 'Try changing your search or filter.',
                  compact: true,
                )
              else
                for (final course in filtered) ...[
                  StudentCourseCard(
                    course: course,
                    attendancePercent: data.attendance[course.id],
                    nextSessionLabel: data.nextLabels[course.id],
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(RouteNames.courseDetails, arguments: course.id),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _CoursesData {
  const _CoursesData({
    required this.courses,
    required this.attendance,
    required this.nextLabels,
    this.activeTerm,
  });

  final List<CourseModel> courses;
  final Map<String, double> attendance;
  final Map<String, String> nextLabels;
  final AcademicTermModel? activeTerm;

  List<String> get filters {
    final values = <String>['All'];
    if (courses.any((course) => course.status == CourseStatus.active)) {
      values.add('Active');
    }
    for (final course in courses) {
      final department = course.departmentName?.trim();
      if (department != null && department.isNotEmpty) values.add(department);
    }
    for (final course in courses) {
      final category = course.category?.trim() ?? '';
      if (category.isNotEmpty) values.add(category);
    }
    return values.toSet().toList();
  }

  List<CourseModel> filter(String query, String filter) {
    final q = query.trim().toLowerCase();
    return courses.where((course) {
      final matchesQuery =
          q.isEmpty ||
          course.code.toLowerCase().contains(q) ||
          course.title.toLowerCase().contains(q) ||
          (course.lecturerName?.toLowerCase().contains(q) ?? false);
      if (!matchesQuery) return false;
      if (filter == 'Active') return course.status == CourseStatus.active;
      if (filter == 'All') return true;
      return course.departmentName == filter || course.category == filter;
    }).toList();
  }

  static Future<_CoursesData> load(
    BuildContext context,
    String studentId,
  ) async {
    final courseRepo = context.read<CourseRepository>();
    final attendanceRepo = context.read<AttendanceRepository>();
    final scheduleRepo = context.read<ScheduleRepository>();
    final adminRepo = context.read<AdminRepository>();
    final now = DateTime.now();
    // The term label is optional; students may not have access to the
    // academic-terms endpoint.
    final (courses, terms, sessions) = await (
      courseRepo.getStudentCourses(studentId),
      adminRepo.getAcademicTerms().catchError(
        (Object _) => <AcademicTermModel>[],
      ),
      scheduleRepo.getStudentSessions(
        studentId,
        from: now,
        to: now.add(const Duration(days: 14)),
      ),
    ).wait;
    final activeTerm = terms
        .where((term) => term.status == TermStatus.active)
        .cast<AcademicTermModel?>()
        .firstOrNull;
    final summaries = await Future.wait(
      courses.map(
        (c) => attendanceRepo.getStudentSummary(studentId, courseId: c.id),
      ),
    );
    return _CoursesData(
      courses: courses,
      attendance: {
        for (final summary in summaries)
          if (summary.courseId != null && summary.totalSessions > 0)
            summary.courseId!: summary.percentage,
      },
      nextLabels: {
        for (final course in courses)
          course.id: _nextLabel(course.id, sessions, now),
      },
      activeTerm: activeTerm,
    );
  }

  static String _nextLabel(
    String courseId,
    List<ClassSessionModel> sessions,
    DateTime now,
  ) {
    final upcoming = sessions
        .where((s) => s.courseId == courseId && s.startTime.isAfter(now))
        .toList();
    if (upcoming.isEmpty) return 'No upcoming session';
    final s = upcoming.first;
    final room = s.room == null ? '' : ' • ${s.room}';
    return '${Formatters.relativeDay(s.startTime, now: now)}$room';
  }
}
