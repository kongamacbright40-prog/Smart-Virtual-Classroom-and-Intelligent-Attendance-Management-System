import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../widgets/cards/statistic_card.dart';
import '../../lecturer_shared.dart';

class LecturerSummary extends StatelessWidget {
  const LecturerSummary({
    super.key,
    required this.assignedCourses,
    required this.averageAttendance,
    required this.pendingAppeals,
  });

  final int assignedCourses;
  final double averageAttendance;
  final int pendingAppeals;

  @override
  Widget build(BuildContext context) {
    return LecturerStatGrid(
      cards: [
        StatisticCard(
          value: '$assignedCourses',
          label: 'Assigned',
          caption: 'Active',
          icon: Icons.auto_stories_outlined,
          alignment: CrossAxisAlignment.start,
        ),
        StatisticCard(
          value: Formatters.percent(averageAttendance),
          label: 'Avg Attend',
          icon: Icons.trending_up,
          valueColor: colorForAttendance(context, averageAttendance),
          alignment: CrossAxisAlignment.start,
        ),
        StatisticCard(
          value: '$pendingAppeals',
          label: 'Appeals',
          caption: pendingAppeals == 0 ? 'Clear' : 'Review',
          icon: Icons.pending_actions_outlined,
          valueColor: Theme.of(context).colorScheme.error,
          alignment: CrossAxisAlignment.start,
        ),
      ],
    );
  }
}
