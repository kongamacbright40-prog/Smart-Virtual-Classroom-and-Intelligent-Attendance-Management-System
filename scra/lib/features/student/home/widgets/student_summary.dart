import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common/app_card.dart';

class StudentSummary extends StatelessWidget {
  const StudentSummary({super.key, required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            value: Formatters.percent(student.overallAttendance),
            label: 'Overall Attend.',
            emphasize: true,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: _SummaryTile(
            value: '${student.activeCredits}',
            label: 'Active Credits',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: _SummaryTile(
            value: student.campusPassValid ? 'Valid' : 'Hold',
            label: 'Campus Pass',
            icon: Icons.verified,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.value,
    required this.label,
    this.icon,
    this.emphasize = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceSm,
        vertical: AppDimensions.spaceMd,
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppDimensions.spaceXs),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: emphasize ? theme.colorScheme.primary : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
