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
          final userRepo = context.read<UserRepository>();
          final (course, sessions, summaries, roster) = await (
            courseRepo.getCourse(courseId),
            scheduleRepo.getCourseSessions(courseId),
            attendanceRepo.getCourseSummaries(courseId),
            userRepo.getCourseRoster(courseId),
          ).wait;
          return _CourseDetailsData(course, sessions, summaries, roster);
        },
        builder: (context, data, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            children: [
              AdminHeroCard(
                title: data.course.title,
                subtitle:
                    '${data.course.code} • ${data.course.departmentName ?? 'Department'}',
                icon: Icons.menu_book_outlined,
                trailing: StatusChip(
                  label: data.course.status.label,
                  tone: data.course.status == CourseStatus.archived
                      ? StatusTone.neutral
                      : StatusTone.success,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle(title: 'Course Information'),
                    const SizedBox(height: AppDimensions.spaceMd),
                    Wrap(
                      spacing: AppDimensions.spaceSm,
                      runSpacing: AppDimensions.spaceSm,
                      children: [
                        CodeTag(data.course.code),
                        if (data.course.credits != null)
                          StatusChip(
                            label: '${data.course.credits} Credits',
                            tone: StatusTone.info,
                          ),
                        if (data.course.category != null)
                          StatusChip(
                            label: data.course.category!,
                            tone: StatusTone.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    Text(
                      data.course.description.isEmpty
                          ? 'No catalogue description yet.'
                          : data.course.description,
                    ),
                    const Divider(height: AppDimensions.spaceLg),
                    AdminInfoRow(
                      icon: data.course.hasLecturer
                          ? Icons.person_outline
                          : Icons.person_off_outlined,
                      title: data.course.hasLecturer
                          ? data.course.lecturerName!
                          : 'Unassigned',
                      subtitle: 'Lecturer',
                      trailing: TextButton(
                        onPressed: () => _assign(context, data.course, reload),
                        child: Text(
                          data.course.hasLecturer ? 'Reassign' : 'Assign',
                        ),
                      ),
                    ),
                    AdminInfoRow(
                      icon: Icons.groups_outlined,
                      title: '${data.course.enrolledCount} Students',
                      subtitle: 'Enrollment count',
                    ),
                    AdminInfoRow(
                      icon: Icons.schedule_outlined,
                      title: data.course.scheduleSummary ?? 'Schedule pending',
                      subtitle: data.course.room ?? 'Room pending',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _EnrollmentCard(
                course: data.course,
                roster: data.roster,
                onAdd: () => _addStudent(context, data, reload),
                onRemove: (student) =>
                    _removeStudent(context, data.course, student, reload),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle(title: 'Attendance Summary'),
                    const SizedBox(height: AppDimensions.spaceSm),
                    Text(
                      '${data.averageAttendance.toStringAsFixed(1)}% course average • ${data.summaries.length} student summaries',
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    LinearProgressIndicator(
                      value: data.averageAttendance / 100,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminSectionTitle(
                      title: 'Sessions',
                      trailing: Text('${data.sessions.length} total'),
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    for (final session in data.sessions.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_note_outlined),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${Formatters.relativeDay(session.startTime)} • ${session.status.label}',
                        ),
                        trailing: Text(
                          '${session.participantCount}/${session.expectedCount}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: data.course.hasLecturer
                          ? 'Reassign Lecturer'
                          : 'Assign Lecturer',
                      icon: Icons.person_add_alt_1,
                      onPressed: () => _assign(context, data.course, reload),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Archive',
                      icon: Icons.archive_outlined,
                      foregroundColor: Theme.of(context).colorScheme.error,
                      onPressed: () => _archive(context, data.course, reload),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assign(
    BuildContext context,
    CourseModel course,
    Future<void> Function() reload,
  ) async {
    final lecturers = await context.read<AdminRepository>().getUsers(
      role: UserRole.lecturer,
    );
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
                    await context.read<CourseRepository>().assignLecturer(
                      courseId: course.id,
                      lecturerId: lecturer.id,
                    );
                    if (context.mounted) {
                      Helpers.showSnackBar(context, 'Lecturer assigned.');
                    }
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

  Future<void> _addStudent(
    BuildContext context,
    _CourseDetailsData data,
    Future<void> Function() reload,
  ) async {
    final List<UserModel> students;
    try {
      students = await context.read<AdminRepository>().getUsers(
        role: UserRole.student,
      );
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
      return;
    }
    if (!context.mounted) return;
    final enrolled = {for (final s in data.roster) s.id};
    final candidates = students.where((s) => !enrolled.contains(s.id)).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final picked = await showModalBottomSheet<UserModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _StudentPicker(course: data.course, students: candidates),
    );
    if (picked == null || !context.mounted) return;
    try {
      await context.read<CourseRepository>().addStudentToCourse(
        courseId: data.course.id,
        studentId: picked.id,
      );
      if (context.mounted) {
        Helpers.showSnackBar(
          context,
          '${picked.fullName} added to ${data.course.code}.',
        );
      }
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _removeStudent(
    BuildContext context,
    CourseModel course,
    StudentModel student,
    Future<void> Function() reload,
  ) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Remove from course?',
      message: '${student.user.fullName} will no longer take ${course.code}.',
      confirmLabel: 'Remove',
      destructive: true,
      icon: Icons.person_remove_outlined,
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<CourseRepository>().removeStudentFromCourse(
        courseId: course.id,
        studentId: student.id,
      );
      if (context.mounted) Helpers.showSnackBar(context, 'Student removed.');
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _archive(
    BuildContext context,
    CourseModel course,
    Future<void> Function() reload,
  ) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Archive course?',
      message: course.title,
      confirmLabel: 'Archive',
      destructive: true,
      icon: Icons.archive_outlined,
    );
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
  const _CourseDetailsData(
    this.course,
    this.sessions,
    this.summaries,
    this.roster,
  );
  final CourseModel course;
  final List<ClassSessionModel> sessions;
  final List<AttendanceModel> summaries;
  final List<StudentModel> roster;
  double get averageAttendance => summaries.isEmpty
      ? 0
      : summaries.map((s) => s.percentage).reduce((a, b) => a + b) /
            summaries.length;
}

/// Students taking the course, with Add / Remove for individual enrollments.
class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({
    required this.course,
    required this.roster,
    required this.onAdd,
    required this.onRemove,
  });

  final CourseModel course;
  final List<StudentModel> roster;
  final VoidCallback onAdd;
  final void Function(StudentModel student) onRemove;

  bool _viaDepartment(StudentModel s) =>
      s.user.departmentId != null && s.user.departmentId == course.departmentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionTitle(
            title: 'Enrolled Students',
            subtitle:
                'Students of ${course.departmentName ?? 'the department'} '
                'are included automatically.',
            trailing: TextButton.icon(
              key: const Key('course_add_student'),
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Add'),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          if (roster.isEmpty)
            Text('No students yet.', style: theme.textTheme.bodyMedium)
          else
            for (final s in roster)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(
                  s.user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (s.matricule.isNotEmpty) s.matricule,
                    _viaDepartment(s) ? 'Department' : 'Added individually',
                  ].join(' • '),
                ),
                trailing: _viaDepartment(s)
                    ? null
                    : IconButton(
                        tooltip: 'Remove from course',
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () => onRemove(s),
                      ),
              ),
        ],
      ),
    );
  }
}

/// Searchable list of students to add to [course]; pops the chosen one.
class _StudentPicker extends StatefulWidget {
  const _StudentPicker({required this.course, required this.students});

  final CourseModel course;
  final List<UserModel> students;

  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final matches = widget.students
        .where(
          (s) =>
              q.isEmpty ||
              s.fullName.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q),
        )
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTitle(
                title: 'Add Student',
                subtitle: widget.course.code,
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search name or email',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Expanded(
                child: matches.isEmpty
                    ? const Center(child: Text('No other students to add.'))
                    : ListView(
                        children: [
                          for (final s in matches)
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(s.fullName),
                              subtitle: Text(s.departmentName ?? s.email),
                              onTap: () => Navigator.of(context).pop(s),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
