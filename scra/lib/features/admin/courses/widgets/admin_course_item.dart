import 'package:flutter/material.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/widgets/buttons/primary_button.dart';
import 'package:smart_class/widgets/buttons/secondary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/status_chip.dart';

class AdminCourseItem extends StatelessWidget {
  const AdminCourseItem({
    super.key,
    required this.course,
    required this.onAssign,
    required this.onDetails,
    required this.onRoster,
    required this.onArchive,
  });

  final CourseModel course;
  final VoidCallback onAssign;
  final VoidCallback onDetails;
  final VoidCallback onRoster;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsLecturer = !course.hasLecturer;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      borderColor: needsLecturer ? theme.colorScheme.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CodeTag(course.code),
              const SizedBox(width: AppDimensions.spaceSm),
              Flexible(
                child: StatusChip(
                  label: course.status.label,
                  tone: needsLecturer
                      ? StatusTone.live
                      : (course.status == CourseStatus.archived
                            ? StatusTone.neutral
                            : StatusTone.success),
                  showDot: true,
                  dense: true,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'assign':
                      onAssign();
                    case 'enroll':
                      onRoster();
                    case 'archive':
                      onArchive();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'assign',
                    child: Text('Assign Lecturer'),
                  ),
                  PopupMenuItem(
                    value: 'enroll',
                    child: Text('View Enrollment'),
                  ),
                  PopupMenuItem(value: 'archive', child: Text('Archive')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
          Text(
            [
              course.departmentName,
              course.facultyName,
            ].whereType<String>().join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  needsLecturer ? 'Instructor Status' : 'Instructor',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  needsLecturer
                      ? 'Unassigned • Assign Faculty'
                      : course.lecturerName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: needsLecturer ? theme.colorScheme.primary : null,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Wrap(
                  spacing: AppDimensions.spaceMd,
                  runSpacing: AppDimensions.spaceXs,
                  children: [
                    Text('${course.enrolledCount} Enrolled'),
                    Text(course.scheduleSummary ?? 'Schedule pending'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          if (needsLecturer)
            PrimaryButton(
              label: 'Assign Lecturer Now',
              icon: Icons.person_add_alt_1,
              onPressed: onAssign,
            )
          else
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Manage Roster',
                    onPressed: onRoster,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: SecondaryButton(
                    label: 'View Details',
                    onPressed: onDetails,
                    style: SecondaryButtonStyle.outlined,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
