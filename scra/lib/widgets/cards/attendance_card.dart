import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../models/attendance_record_model.dart';
import '../common/status_chip.dart';

/// Maps an attendance status to a chip tone (shared by all roles).
StatusTone attendanceTone(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => StatusTone.success,
  AttendanceStatus.late => StatusTone.warning,
  AttendanceStatus.absent => StatusTone.error,
  AttendanceStatus.excused => StatusTone.info,
};

/// Attendance log entry: date block, course, time, status chip and details.
class AttendanceCard extends StatelessWidget {
  const AttendanceCard({
    super.key,
    required this.record,
    this.onTap,
    this.action,
  });

  final AttendanceRecordModel record;
  final VoidCallback? onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = record.sessionStart;
    return Material(
      color: theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Column(
                  children: [
                    Text(
                      AppDateUtils.monthsShort[d.month - 1].toUpperCase(),
                      style: theme.textTheme.labelSmall,
                    ),
                    Text('${d.day}', style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${record.courseCode}: ${record.courseTitle}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceSm),
                        StatusChip(
                          label: record.status.label,
                          tone: attendanceTone(record.status),
                          uppercase: true,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${Formatters.time(d)} • '
                            '${record.sessionMinutes} min session',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (record.status.countsAsAttended) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.status == AttendanceStatus.late
                            ? 'Entered: ${Formatters.time(record.checkedInAt!)} '
                                  '(${record.minutesLate} min delay)'
                            : '${record.minutesLogged} / ${record.sessionMinutes} '
                                  'mins logged (${record.durationPercent.round()}%)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (record.verificationMethod != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.verificationMethod!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                    if (action != null) ...[
                      const SizedBox(height: AppDimensions.spaceSm),
                      action!,
                    ],
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
