
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/buttons/primary_button.dart';
import 'package:smart_class/widgets/buttons/secondary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/dialogs/confirmation_dialog.dart';

class AdminCourseDetailsScreen extends StatelessWidget {
  const AdminCourseDetailsScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AdminScreenHeader(title: 'Course Details', showBack: true),
      body: AsyncView<_CourseDetailsData>(
        load: () async {
          final courseRepo = context.read<CourseRepository>();
          final scheduleRepo = context.read<ScheduleRepository>();
          final attendanceRepo = context.read<AttendanceRepository>();
          return _CourseDetailsData(
            await courseRepo.getCourse(courseId),
            await scheduleRepo.getCourseSessions(courseId),
            await attendanceRepo.getCourseSummaries(courseId),
          );
        },
        builder: (context, data, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            children: [
              AdminHeroCard(
                title: data.course.title,
                subtitle: '${data.course.code} ? ${data.course.departmentName ?? 'Department'}',
                icon: Icons.menu_book_outlined,
                trailing: StatusChip(label: data.course.status.label, tone: data.course.status == CourseStatus.archived ? StatusTone.neutral : StatusTone.success),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle(title: 'Course Information'),
                    const SizedBox(height: AppDimensions.spaceMd),
                    Wrap(spacing: AppDimensions.spaceSm, runSpacing: AppDimensions.spaceSm, children: [
                      CodeTag(data.course.code),
                      StatusChip(label: '${data.course.credits} Credits', tone: StatusTone.info),
                      StatusChip(label: data.course.category, tone: StatusTone.primary),
                    ]),
                    const SizedBox(height: AppDimensions.spaceMd),
                    Text(data.course.description.isEmpty ? 'No catalogue description yet.' : data.course.description),
                    const Divider(height: AppDimensions.spaceLg),
                    AdminInfoRow(icon: data.course.hasLecturer ? Icons.person_outline : Icons.person_off_outlined, title: data.course.hasLecturer ? data.course.lecturerName! : 'Unassigned', subtitle: 'Lecturer', trailing: TextButton(onPressed: () => _assign(context, data.course, reload), child: Text(data.course.hasLecturer ? 'Reassign' : 'Assign'))),
                    AdminInfoRow(icon: Icons.groups_outlined, title: '${data.course.enrolledCount} Students', subtitle: 'Enrollment count'),
                    AdminInfoRow(icon: Icons.schedule_outlined, title: data.course.scheduleSummary ?? 'Schedule pending', subtitle: data.course.room ?? 'Room pending'),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle(title: 'Attendance Summary'),
                    const SizedBox(height: AppDimensions.spaceSm),
                    Text('${data.averageAttendance.toStringAsFixed(1)}% course average ? ${data.summaries.length} student summaries'),
                    const SizedBox(height: AppDimensions.spaceSm),
                    LinearProgressIndicator(value: data.averageAttendance / 100),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminSectionTitle(title: 'Sessions', trailing: Text('${data.sessions.length} total')),
                    const SizedBox(height: AppDimensions.spaceSm),
                    for (final session in data.sessions.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_note_outlined),
                        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${Formatters.relativeDay(session.startTime)} ? ${session.status.label}'),
                        trailing: Text('${session.participantCount}/${session.expectedCount}'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Row(children: [
                Expanded(child: PrimaryButton(label: data.course.hasLecturer ? 'Reassign Lecturer' : 'Assign Lecturer', icon: Icons.person_add_alt_1, onPressed: () => _assign(context, data.course, reload))),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(child: SecondaryButton(label: 'Archive', icon: Icons.archive_outlined, foregroundColor: Theme.of(context).colorScheme.error, onPressed: () => _archive(context, data.course, reload))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assign(BuildContext context, CourseModel course, Future<void> Function() reload) async {
    final lecturers = await context.read<AdminRepository>().getUsers(role: UserRole.lecturer);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          children: [
            AdminSectionTitle(title: 'Assign Lecturer', subtitle: course.code),
            for (final lecturer in lecturers)
              ListTile(
                title: Text(lecturer.fullName),
                subtitle: Text(lecturer.departmentName ?? lecturer.email),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await context.read<CourseRepository>().assignLecturer(courseId: course.id, lecturerId: lecturer.id);
                    if (context.mounted) Helpers.showSnackBar(context, 'Lecturer assigned.');
                    await reload();
                  } on Object catch (e) {
                    if (context.mounted) Helpers.showError(context, e);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _archive(BuildContext context, CourseModel course, Future<void> Function() reload) async {
    final ok = await ConfirmationDialog.show(context, title: 'Archive course?', message: course.title, confirmLabel: 'Archive', destructive: true, icon: Icons.archive_outlined);
    if (!ok || !context.mounted) return;
    try {
      await context.read<CourseRepository>().archiveCourse(course.id);
      if (context.mounted) Helpers.showSnackBar(context, 'Course archived.');
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }
}

class _CourseDetailsData {
  const _CourseDetailsData(this.course, this.sessions, this.summaries);
  final CourseModel course;
  final List<ClassSessionModel> sessions;
  final List<AttendanceModel> summaries;
  double get averageAttendance => summaries.isEmpty ? 0 : summaries.map((s) => s.percentage).reduce((a, b) => a + b) / summaries.length;
}

