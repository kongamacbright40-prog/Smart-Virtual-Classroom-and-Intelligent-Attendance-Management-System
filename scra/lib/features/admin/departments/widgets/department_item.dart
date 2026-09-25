import 'package:flutter/material.dart';

import 'package:smart_class/core/constants/app_colors.dart';
import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/widgets/buttons/secondary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/status_chip.dart';

class DepartmentItem extends StatelessWidget {
  const DepartmentItem({
    super.key,
    required this.department,
    required this.onOptions,
    required this.onEdit,
  });

  final DepartmentModel department;
  final VoidCallback onOptions;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceSm),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(
                  Icons.domain_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppDimensions.spaceSm,
                      children: [
                        CodeTag(department.code),
                        StatusChip(
                          label: department.isActive ? 'Active' : 'Archived',
                          tone: department.isActive
                              ? StatusTone.success
                              : StatusTone.neutral,
                          showDot: true,
                          dense: true,
                        ),
                      ],
                    ),
                    Text(
                      department.facultyName ?? 'Faculty',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      department.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOptions,
                icon: const Icon(Icons.more_vert),
                tooltip: 'Department options',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              'Head of Department\n${department.headName ?? 'Unassigned'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              _chip(
                context,
                Icons.menu_book_outlined,
                '${department.courseCount} Courses',
              ),
              _chip(
                context,
                Icons.school_outlined,
                '${Formatters.compactNumber(department.studentCount)} Students',
              ),
              _chip(
                context,
                Icons.badge_outlined,
                '${department.staffCount} Faculty',
              ),
              _chip(
                context,
                Icons.sensors_outlined,
                '${department.liveSessions} Live Sessions Now',
              ),
              _chip(
                context,
                Icons.show_chart,
                '${Formatters.percent(department.averageAttendance, decimals: 1)} Avg Attendance',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          SecondaryButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: onEdit,
            expanded: true,
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
