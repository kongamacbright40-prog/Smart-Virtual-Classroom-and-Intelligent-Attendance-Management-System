import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/status_chip.dart';
import '../../lecturer_shared.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.breakdown, required this.onTap});

  final ReportBreakdown breakdown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final students = breakdown.meta['students'];
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CodeTag(breakdown.label),
                    const SizedBox(width: AppDimensions.spaceSm),
                    if (students != null)
                      StatusChip(label: '$students Students', dense: true),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  breakdown.subtitle ?? 'Attendance report',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (breakdown.meta['sessions'] != null)
                  Text('${breakdown.meta['sessions']} sessions'),
              ],
            ),
          ),
          Text(
            attendancePercent(breakdown.value),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorForAttendance(context, breakdown.value),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
