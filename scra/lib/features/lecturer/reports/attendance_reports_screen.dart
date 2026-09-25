import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/cards/statistic_card.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/async_view.dart';
import '../lecturer_shared.dart';
import 'widgets/attendance_chart.dart';
import 'widgets/report_card.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key, this.courseId});

  final String? courseId;

  @override
  State<AttendanceReportsScreen> createState() =>
      _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
  }

  Future<_ReportsData> _load(BuildContext context) async {
    final lecturerId = lecturerIdOf(context);
    final courseRepository = context.read<CourseRepository>();
    final reportRepository = context.read<ReportRepository>();
    final courses = await courseRepository.getLecturerCourses(lecturerId);
    final report = await reportRepository.getLecturerReport(
      lecturerId,
      courseId: _selectedCourseId,
    );
    return _ReportsData(courses: courses, report: report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Attendance Reports',
        subtitle: 'Verified cohort attendance analytics',
        showBack: widget.courseId == null ? false : null,
      ),
      body: AsyncView<_ReportsData>(
        load: () => _load(context),
        builder: (context, data, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.pageMargin),
            children: [
              Text(
                'Export verified cohort attendance, session timelines, and student participation metrics across accredited sessions.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        right: AppDimensions.spaceSm,
                      ),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCourseId == null,
                        onSelected: (_) =>
                            setState(() => _selectedCourseId = null),
                      ),
                    ),
                    for (final course in data.courses)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppDimensions.spaceSm,
                        ),
                        child: ChoiceChip(
                          label: Text(course.code),
                          selected: _selectedCourseId == course.id,
                          onSelected: (_) =>
                              setState(() => _selectedCourseId = course.id),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDimensions.spaceSm,
                crossAxisSpacing: AppDimensions.spaceSm,
                children: [
                  StatisticCard(
                    value: attendancePercent(
                      data.report.metric('average_rate'),
                    ),
                    label: 'Average Rate',
                    icon: Icons.pie_chart,
                    valueColor: colorForAttendance(
                      context,
                      data.report.metric('average_rate'),
                    ),
                    alignment: CrossAxisAlignment.start,
                  ),
                  StatisticCard(
                    value: data.report.metric('sessions').round().toString(),
                    label: 'Sessions',
                    icon: Icons.event_available,
                    alignment: CrossAxisAlignment.start,
                  ),
                  StatisticCard(
                    value: data.report.metric('students').round().toString(),
                    label: 'Students',
                    icon: Icons.groups,
                    alignment: CrossAxisAlignment.start,
                  ),
                  StatisticCard(
                    value: data.report.metric('at_risk').round().toString(),
                    label: 'At Risk',
                    icon: Icons.warning_amber,
                    valueColor: Theme.of(context).colorScheme.error,
                    alignment: CrossAxisAlignment.start,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Trend',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    AttendanceChart(points: data.report.trend),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              PrimaryButton(
                label: 'Generate Certified Report',
                icon: Icons.assessment_outlined,
                onPressed: () => _showExportSheet(context, data.report.id),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              Text(
                'Per-Course Breakdown',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              for (final item in data.report.breakdown)
                ReportCard(
                  breakdown: item,
                  onTap: () => Navigator.of(context)
                      .pushNamed(RouteNames.courseRoster, arguments: item.id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExportSheet(BuildContext context, String reportId) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.pageMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            for (final format in ReportFormat.values)
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(format.label),
                onTap: () {
                  Navigator.of(context).pop();
                  exportAndNotify(context, reportId, format: format);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportsData {
  const _ReportsData({required this.courses, required this.report});
  final List<CourseModel> courses;
  final ReportModel report;
}
