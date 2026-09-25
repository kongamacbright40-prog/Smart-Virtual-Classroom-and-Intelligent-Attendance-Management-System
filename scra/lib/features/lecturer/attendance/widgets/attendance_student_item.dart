import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/status_chip.dart';
import '../../../../widgets/common/user_avatar.dart';
import '../../lecturer_shared.dart';

class AttendanceStudentItem extends StatelessWidget {
  const AttendanceStudentItem({
    super.key,
    required this.record,
    required this.onStatus,
  });

  final AttendanceRecordModel record;
  final ValueChanged<AttendanceStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final statusTone = toneForStatus(record.status);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                name: record.studentName,
                size: 48,
                statusColor: StatusChip.colorsFor(context, statusTone).$2,
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${record.matricule ?? record.studentId} • ${record.courseCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'present':
                      onStatus(AttendanceStatus.present);
                    case 'late':
                      onStatus(AttendanceStatus.late);
                    case 'absent':
                      onStatus(AttendanceStatus.absent);
                    case 'excused':
                      onStatus(AttendanceStatus.excused);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'present',
                    child: Text('Manual Check-in'),
                  ),
                  PopupMenuItem(value: 'late', child: Text('Waive as On-Time')),
                  PopupMenuItem(value: 'absent', child: Text('Mark Absent')),
                  PopupMenuItem(value: 'excused', child: Text('Excused')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceXs,
            children: [
              StatusChip(
                label: record.status.label,
                tone: statusTone,
                showDot: true,
              ),
              if (record.checkedInAt != null)
                StatusChip(
                  label: 'Joined ${Formatters.time(record.checkedInAt!)}',
                  icon: Icons.login,
                ),
              if (record.verificationMethod != null)
                StatusChip(
                  label: record.verificationMethod!,
                  icon: Icons.verified_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
