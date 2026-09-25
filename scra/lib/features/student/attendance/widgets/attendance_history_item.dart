import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/secondary_button.dart';
import '../../../../widgets/cards/attendance_card.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/status_chip.dart';

class AttendanceHistoryItem extends StatelessWidget {
  const AttendanceHistoryItem({super.key, required this.record, this.onAppeal});

  final AttendanceRecordModel record;
  final VoidCallback? onAppeal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = attendanceTone(record.status);
    final borderColor = StatusChip.colorsFor(context, tone).$2;
    return AppCard(
      borderColor: borderColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spaceMd,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  AppDateUtils.monthsShort[record.sessionStart.month - 1]
                      .toUpperCase(),
                ),
                Text(
                  '${record.sessionStart.day}',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${record.courseCode}: ${record.courseTitle}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    StatusChip(
                      label: record.status.label,
                      tone: tone,
                      uppercase: true,
                      showDot: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  '${Formatters.time(record.sessionStart)} • ${record.room ?? '${record.sessionMinutes} min session'}',
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  decoration: BoxDecoration(
                    color: record.status == AttendanceStatus.absent
                        ? AppColors.errorContainer.withValues(alpha: 0.5)
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (record.status == AttendanceStatus.late)
                        Text(
                          'Entered: ${Formatters.time(record.checkedInAt ?? record.sessionStart)} (${record.minutesLate} min delay)',
                        )
                      else if (record.status.countsAsAttended)
                        Text(
                          '${record.minutesLogged} / ${record.sessionMinutes} mins logged (${record.durationPercent.round()}%)',
                        )
                      else
                        Text(_absenceDetail(record)),
                      if (record.verificationMethod != null) ...[
                        const SizedBox(height: AppDimensions.spaceXs),
                        Text(
                          record.verificationMethod!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: borderColor,
                          ),
                        ),
                      ],
                      if (onAppeal != null) ...[
                        const SizedBox(height: AppDimensions.spaceMd),
                        SecondaryButton(
                          label: 'Submit Medical Slip / Appeal',
                          icon: Icons.attachment,
                          onPressed: onAppeal,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _absenceDetail(AttendanceRecordModel record) {
    if (record.sessionMinutes > 0) {
      return '${record.minutesLogged} / ${record.sessionMinutes} mins logged';
    }
    return 'No attendance recorded';
  }
}
