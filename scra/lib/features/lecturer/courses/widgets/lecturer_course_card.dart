import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/secondary_button.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/status_chip.dart';
import '../../lecturer_shared.dart';

class LecturerCourseCard extends StatelessWidget {
  const LecturerCourseCard({
    super.key,
    required this.course,
    required this.averageAttendance,
    this.nextSession,
  });

  final CourseModel course;

  /// `null` until the course has held a class.
  final double? averageAttendance;
  final ClassSessionModel? nextSession;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () =>
          Navigator.of(context)
              .pushNamed(RouteNames.courseRoster, arguments: course.id),
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CodeTag(course.code),
              if (course.credits != null) ...[
                const SizedBox(width: AppDimensions.spaceSm),
                StatusChip(label: '${course.credits} CR', dense: true),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'schedule', child: Text('Schedule')),
                  PopupMenuItem(value: 'roster', child: Text('Roster')),
                  PopupMenuItem(value: 'attendance', child: Text('Attendance')),
                  PopupMenuItem(
                    value: 'settings',
                    child: Text('Course Settings'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'schedule') {
                    Navigator.of(
                      context,
                    ).pushNamed(RouteNames.scheduleClass, arguments: course.id);
                  } else if (value == 'roster') {
                    Navigator.of(
                      context,
                    ).pushNamed(RouteNames.courseRoster, arguments: course.id);
                  } else if (value == 'attendance') {
                    Navigator.of(context).pushNamed(
                      RouteNames.attendanceReports,
                      arguments: course.id,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            '${course.enrolledCount} Students enrolled • ${course.room ?? 'Room pending'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceSm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined, size: 20),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Text(
                    nextSession == null
                        ? course.scheduleSummary ?? 'Schedule pending'
                        : '${Formatters.shortDate(nextSession!.startTime)}, ${Formatters.time(nextSession!.startTime)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Avg Attendance'),
                    Text(
                      averageAttendance == null
                          ? '—'
                          : attendancePercent(averageAttendance!),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: averageAttendance == null
                            ? null
                            : colorForAttendance(context, averageAttendance!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Schedule',
                  icon: Icons.calendar_month_outlined,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.scheduleClass, arguments: course.id),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: SecondaryButton(
                  label: 'Roster',
                  icon: Icons.checklist_outlined,
                  onPressed: () => Navigator.of(context)
                      .pushNamed(RouteNames.courseRoster, arguments: course.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
