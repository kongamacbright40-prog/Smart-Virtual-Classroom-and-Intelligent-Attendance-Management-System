import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/inputs/search_field.dart';
import '../lecturer_shared.dart';
import 'widgets/lecturer_course_card.dart';

class LecturerCoursesScreen extends StatefulWidget {
  const LecturerCoursesScreen({super.key});

  @override
  State<LecturerCoursesScreen> createState() => _LecturerCoursesScreenState();
}

class _LecturerCoursesScreenState extends State<LecturerCoursesScreen> {
  String _query = '';
  String _filter = 'All';

  Future<_CoursesData> _load(BuildContext context) async {
    final lecturerId = lecturerIdOf(context);
    final courseRepository = context.read<CourseRepository>();
    final reportRepository = context.read<ReportRepository>();
    final scheduleRepository = context.read<ScheduleRepository>();
    final courses = await courseRepository.getLecturerCourses(lecturerId);
    final report = await reportRepository.getLecturerReport(lecturerId);
    final sessions = await scheduleRepository.getLecturerSessions(
      lecturerId,
      from: DateTime.now().subtract(const Duration(days: 1)),
      to: DateTime.now().add(const Duration(days: 14)),
    );
    return _CoursesData(courses: courses, report: report, sessions: sessions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Assigned Courses',
        subtitle: 'AY 2024/2025 • First Semester',
        showBack: false,
        actions: [
          IconButton(
            tooltip: 'Schedule class',
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.scheduleClass),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AsyncView<_CoursesData>(
        load: () => _load(context),
        builder: (context, data, reload) {
          final q = _query.toLowerCase();
          final courses = data.courses.where((course) {
            final matchesQuery =
                q.isEmpty ||
                course.code.toLowerCase().contains(q) ||
                course.title.toLowerCase().contains(q) ||
                (course.room ?? '').toLowerCase().contains(q);
            final matchesFilter =
                _filter == 'All' ||
                (_filter == 'Current Semester' &&
                    course.status == CourseStatus.active) ||
                (_filter == 'Archived' &&
                    course.status == CourseStatus.archived);
            return matchesQuery && matchesFilter;
          }).toList();
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.pageMargin),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.auto_stories_outlined,
                        label: 'Active Cohorts',
                        value: '${data.courses.length} Courses',
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.groups_outlined,
                        label: 'Lectured Pool',
                        value:
                            '${data.courses.fold<int>(0, (s, c) => s + c.enrolledCount)} Enrolled',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                SearchField(
                  hint: 'Search courses, modules, or halls...',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in [
                        'All',
                        'Current Semester',
                        'Archived',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(
                            right: AppDimensions.spaceSm,
                          ),
                          child: ChoiceChip(
                            label: Text(
                              filter == 'All'
                                  ? 'All ${data.courses.length}'
                                  : filter,
                            ),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                for (final course in courses)
                  LecturerCourseCard(
                    course: course,
                    averageAttendance: data.report.breakdown
                        .firstWhere(
                          (b) => b.id == course.id,
                          orElse: () => ReportBreakdown(
                            id: course.id,
                            label: course.code,
                            value: data.report.metric('average_rate'),
                          ),
                        )
                        .value,
                    nextSession:
                        (data.sessions
                                .where(
                                  (s) =>
                                      s.courseId == course.id &&
                                      s.status != SessionStatus.completed,
                                )
                                .toList()
                              ..sort(
                                (a, b) => a.startTime.compareTo(b.startTime),
                              ))
                            .firstOrNull,
                  ),
                const SizedBox(height: AppDimensions.spaceLg),
                const Center(
                  child: Text('All semester allocations up to date'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoursesData {
  const _CoursesData({
    required this.courses,
    required this.report,
    required this.sessions,
  });
  final List<CourseModel> courses;
  final ReportModel report;
  final List<ClassSessionModel> sessions;
}
