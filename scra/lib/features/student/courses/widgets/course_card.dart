import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/status_chip.dart';
import 'course_progress.dart';

class StudentCourseCard extends StatelessWidget {
  const StudentCourseCard({
    super.key,
    required this.course,
    this.attendancePercent,
    this.nextSessionLabel,
    this.onTap,
  });

  final CourseModel course;
  final double? attendancePercent;
  final String? nextSessionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = attendancePercent;
    final color = percent == null ? null : Helpers.attendanceColor(percent);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppDimensions.spaceSm,
                      runSpacing: AppDimensions.spaceXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CodeTag(course.code),
                        if (course.category != null)
                          StatusChip(
                            label: course.category!,
                            tone: StatusTone.info,
                            dense: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (course.lecturerName != null)
                      Text(
                        '${course.lecturerName} • ${course.lecturerRole ?? 'Course Lecturer'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CourseProgress(
                    icon: Icons.verified_outlined,
                    label: 'Attendance',
                    value: percent == null ? '—' : '${percent.round()}%',
                    detail: percent == null
                        ? 'No attendance summary'
                        : Helpers.attendanceLabel(percent),
                    color: color,
                    progress: percent == null ? null : percent / 100,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: CourseProgress(
                    icon: Icons.school_outlined,
                    label: 'Weight',
                    value: course.credits == null
                        ? '—'
                        : '${course.credits} Credits',
                    detail: course.creditNote ?? course.category ?? '',
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: CourseProgress(
                    icon: Icons.event_repeat,
                    label: 'Held',
                    value: '${course.sessionsHeld} Sessions',
                    detail: 'of ${course.totalSessions} Term',
                  ),
                ),
              ],
            ),
          ),
          if (nextSessionLabel != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMd,
                vertical: AppDimensions.spaceSm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: theme.colorScheme.primary),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Text(
                      'Next: $nextSessionLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceMd),
          PrimaryButton(
            label: 'View Course',
            trailingIcon: Icons.arrow_forward,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
