import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/status_chip.dart';
import '../../../../widgets/common/user_avatar.dart';
import '../../lecturer_shared.dart';

class StudentRosterItem extends StatelessWidget {
  const StudentRosterItem({
    super.key,
    required this.student,
    required this.summary,
    this.latestRecord,
    required this.onAdjust,
    required this.onHistory,
    required this.onNotice,
  });

  final StudentModel student;
  final AttendanceModel summary;
  final AttendanceRecordModel? latestRecord;
  final VoidCallback onAdjust;
  final VoidCallback onHistory;
  final VoidCallback onNotice;

  @override
  Widget build(BuildContext context) {
    final percent = summary.percentage;
    final atRisk = percent < 75;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  name: student.user.fullName,
                  size: 48,
                  statusColor: latestRecord == null
                      ? null
                      : colorForAttendance(context, percent),
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
                              student.user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          StatusChip(
                            label: attendancePercent(percent),
                            tone: toneForAttendance(percent),
                            dense: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),
                      Text(
                        '${student.matricule} ? ${student.programme} ? Year ${student.level ~/ 100}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),
                      Wrap(
                        spacing: AppDimensions.spaceSm,
                        runSpacing: AppDimensions.spaceXs,
                        children: [
                          Text(attendanceFraction(summary)),
                          if (atRisk)
                            const StatusChip(
                              label: 'At Risk',
                              icon: Icons.warning_amber,
                              tone: StatusTone.warning,
                              dense: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'adjust') onAdjust();
                    if (value == 'history') onHistory();
                    if (value == 'notice') onNotice();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'adjust',
                      child: Text('Adjust Attendance'),
                    ),
                    PopupMenuItem(
                      value: 'history',
                      child: Text('View History'),
                    ),
                    PopupMenuItem(
                      value: 'notice',
                      child: Text('Send Direct Notice'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMd,
              vertical: AppDimensions.spaceSm,
            ),
            decoration: BoxDecoration(
              color: latestRecord == null
                  ? Theme.of(context).colorScheme.surfaceContainerLow
                  : StatusChip.colorsFor(
                      context,
                      toneForStatus(latestRecord!.status),
                    ).$1,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: Text(
              latestRecord == null
                  ? 'No recent attendance record'
                  : '${latestRecord!.status.label.toUpperCase()} ? ${latestRecord!.verificationMethod ?? 'Validated'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
