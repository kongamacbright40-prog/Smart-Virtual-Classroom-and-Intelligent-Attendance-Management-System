import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/utils/helpers.dart';
import '../../models/course_model.dart';
import '../common/progress_bar.dart';
import '../common/status_chip.dart';

/// Course summary card (Student Home "MY COURSES" style): code + category,
/// title, lecturer, attendance bar and next session line.
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.attendancePercent,
    this.nextSessionLabel,
    this.onTap,
    this.trailing,
  });

  final CourseModel course;
  final double? attendancePercent;
  final String? nextSessionLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = attendancePercent;
    return Material(
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppDimensions.spaceSm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            CodeTag(course.code),
                            Text(
                              '• ${course.category}',
                              style: theme.textTheme.labelMedium,
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
                            course.lecturerName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.arrow_forward,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                ],
              ),
            ),
            if (percent != null || nextSessionLabel != null)
              Container(
                color: theme.colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (percent != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Attendance: ${percent.round()}%',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          Text(
                            Helpers.attendanceLabel(percent),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color:
                                  Helpers.attendanceColor(percent) ==
                                      Helpers.attendanceColor(100)
                                  ? theme.colorScheme.primary
                                  : Helpers.attendanceColor(percent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceSm),
                      AppProgressBar(
                        value: percent / 100,
                        color: percent >= 93
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                    ],
                    if (nextSessionLabel != null) ...[
                      const SizedBox(height: AppDimensions.spaceSm),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppDimensions.spaceSm),
                          Expanded(
                            child: Text(
                              'Next: $nextSessionLabel',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
