import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/async_view.dart';
import '../lecturer_shared.dart';
import 'widgets/class_form.dart';

class ScheduleClassScreen extends StatefulWidget {
  const ScheduleClassScreen({super.key, this.courseId});

  final String? courseId;

  @override
  State<ScheduleClassScreen> createState() => _ScheduleClassScreenState();
}

class _ScheduleClassScreenState extends State<ScheduleClassScreen> {
  ScheduleModel? _created;

  Future<List<CourseModel>> _load(BuildContext context) => context
      .read<CourseRepository>()
      .getLecturerCourses(lecturerIdOf(context));

  Future<void> _submit(ScheduleModel request) async {
    try {
      final created = await context.read<ScheduleRepository>().scheduleClass(
        request,
      );
      if (!mounted) return;
      setState(() => _created = created);
      Helpers.showSnackBar(context, 'Class scheduled successfully.');
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    return Scaffold(
      appBar: SmartAppBar(
        title: created == null ? 'Schedule Class' : 'Class Scheduled',
      ),
      body: AsyncView<List<CourseModel>>(
        load: () => _load(context),
        isEmpty: (courses) => courses.isEmpty,
        builder: (context, courses, reload) => ListView(
          padding: const EdgeInsets.all(AppDimensions.pageMargin),
          children: [
            // After scheduling, the confirmation replaces the form so the
            // lecturer sees exactly what was saved.
            if (created != null)
              _SuccessPanel(
                schedule: created,
                onScheduleAnother: () => setState(() => _created = null),
              )
            else
              ClassForm(
                courses: courses,
                initialCourseId: widget.courseId,
                onSubmit: _submit,
              ),
          ],
        ),
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({
    required this.schedule,
    required this.onScheduleAnother,
  });

  final ScheduleModel schedule;
  final VoidCallback onScheduleAnother;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.18),
            child: Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            'Class Scheduled!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            schedule.sessionId == null ? 'Class details saved' : 'Room ready',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            'Your session "${schedule.topic}" for ${schedule.courseCode} is set for ${Formatters.shortDate(schedule.startTime)} at ${Formatters.time(schedule.startTime)}.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Column(
              children: [
                LecturerInfoRow(
                  icon: Icons.menu_book_outlined,
                  label: 'Course',
                  value: '${schedule.courseCode} • ${schedule.courseTitle}',
                ),
                const Divider(),
                LecturerInfoRow(
                  icon: Icons.event_outlined,
                  label: 'Date',
                  value: Formatters.shortDate(schedule.startTime),
                ),
                const Divider(),
                LecturerInfoRow(
                  icon: Icons.schedule,
                  label: 'Time',
                  value:
                      '${Formatters.time(schedule.startTime)} – '
                      '${Formatters.time(schedule.startTime.add(Duration(minutes: schedule.durationMinutes)))}',
                ),
                const Divider(),
                if (schedule.roomCode != null) ...[
                  LecturerInfoRow(
                    icon: Icons.key,
                    label: 'Room Code',
                    value: schedule.roomCode!,
                  ),
                  const Divider(),
                ],
                LecturerInfoRow(
                  icon: Icons.groups,
                  label: 'Expected Students',
                  value: '${schedule.expectedStudents} Students',
                ),
                if (schedule.room != null) ...[
                  const Divider(),
                  LecturerInfoRow(
                    icon: Icons.meeting_room_outlined,
                    label: 'Room',
                    value: schedule.room!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          PrimaryButton(
            label: 'View Class',
            icon: Icons.visibility_outlined,
            onPressed: schedule.sessionId == null
                ? null
                : () => Navigator.of(context).pushNamed(
                    RouteNames.lecturerLiveClassroom,
                    arguments: schedule.sessionId,
                  ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          SecondaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).maybePop(true),
          ),
          TextButton.icon(
            onPressed: onScheduleAnother,
            icon: const Icon(Icons.add),
            label: const Text('Schedule another class'),
          ),
        ],
      ),
    );
  }
}
