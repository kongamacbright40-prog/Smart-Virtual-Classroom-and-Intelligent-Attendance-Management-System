import 'package:flutter/material.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/widgets/buttons/secondary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/status_chip.dart';

class AcademicTermItem extends StatelessWidget {
  const AcademicTermItem({super.key, required this.term, this.onEdit});

  final AcademicTermModel term;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final tone = switch (term.status) {
      TermStatus.active => StatusTone.live,
      TermStatus.archived => StatusTone.neutral,
      TermStatus.planned => StatusTone.primary,
    };
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  term.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(label: term.status.label, tone: tone, dense: true),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            '${Formatters.date(term.startDate)} • ${Formatters.date(term.endDate)} • ${term.totalWeeks} Weeks',
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spaceSm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppDimensions.spaceMd,
              runSpacing: AppDimensions.spaceSm,
              children: [
                Text(
                  'Enrollment\n${term.enrolledStudents} Students • ${term.courseCount} Courses',
                ),
                Text(
                  '${term.averageAttendance == null ? 'Planning' : 'Attendance'}\n${term.averageAttendance == null ? term.code : Formatters.percent(term.averageAttendance!, decimals: 1)}',
                ),
              ],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            Align(
              alignment: Alignment.centerRight,
              child: SecondaryButton(
                label: 'Edit Planning',
                icon: Icons.edit_calendar_outlined,
                expanded: false,
                onPressed: onEdit,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
