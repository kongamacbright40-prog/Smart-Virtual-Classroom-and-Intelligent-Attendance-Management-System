import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/icon_button.dart';
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
            subtitle:
                'Academic Session ${DateTime.now().year}–${DateTime.now().year + 1}',
            actions: [
              AppIconButton(
                icon: Icons.calendar_month_outlined,
                tooltip: 'Fall Term ${DateTime.now().year}',
                onPressed: () {},
              ),
            ],
          ),
          scrollable: true,
          onRefresh: reload,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(
                hint: 'Search courses, codes, or professor',
                onChanged: (value) => setState(() => _query = value),
                onFilter: () {},
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final chip in const [
                      'All',
                      'Current Term',
                      'Computer Science',
                      'Mathematics',
                      'Faculty Electives',
                    ]) ...[
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
                trailing: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Sort by Schedule'),
                ),
              ),
              if (filtered.isEmpty)
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
  });

  final List<CourseModel> courses;
  final Map<String, double> attendance;
  final Map<String, String> nextLabels;

  List<CourseModel> filter(String query, String filter) {
    final q = query.trim().toLowerCase();
    return courses.where((course) {
      final matchesQuery =
          q.isEmpty ||
          course.code.toLowerCase().contains(q) ||
          course.title.toLowerCase().contains(q) ||
          (course.lecturerName?.toLowerCase().contains(q) ?? false);
      if (!matchesQuery) return false;
      return switch (filter) {
        'Current Term' => course.status == CourseStatus.active,
        'Computer Science' =>
          (course.departmentName ?? '').toLowerCase().contains('computer') ||
              course.code.startsWith('CS'),
        'Mathematics' =>
          (course.departmentName ?? '').toLowerCase().contains('math') ||
              course.code.startsWith('MTH'),
        'Faculty Electives' => course.category.toLowerCase().contains(
          'elective',
        ),
        _ => true,
      };
    }).toList();
  }

  static Future<_CoursesData> load(
    BuildContext context,
    String studentId,
  ) async {
    final courseRepo = context.read<CourseRepository>();
    final attendanceRepo = context.read<AttendanceRepository>();
    final scheduleRepo = context.read<ScheduleRepository>();
    final now = DateTime.now();
    final courses = await courseRepo.getStudentCourses(studentId);
    final summaries = await Future.wait(
      courses.map(
        (c) => attendanceRepo.getStudentSummary(studentId, courseId: c.id),
      ),
    );
    final sessions = await scheduleRepo.getStudentSessions(
      studentId,
      from: now,
      to: now.add(const Duration(days: 14)),
    );
    return _CoursesData(
      courses: courses,
      attendance: {
        for (final summary in summaries)
          if (summary.courseId != null) summary.courseId!: summary.percentage,
      },
      nextLabels: {
        for (final course in courses)
          course.id: _nextLabel(course.id, sessions, now),
      },
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
