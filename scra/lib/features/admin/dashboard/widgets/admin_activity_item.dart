import 'package:flutter/material.dart';

import 'package:smart_class/core/constants/app_colors.dart';
import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/models/models.dart';

class AdminActivityItem extends StatelessWidget {
  const AdminActivityItem({super.key, required this.activity});

  final ActivityLogModel activity;

  @override
  Widget build(BuildContext context) {
    final color = switch (activity.severity) {
      ActivitySeverity.success => AppColors.success,
      ActivitySeverity.warning => AppColors.warning,
      ActivitySeverity.critical => Theme.of(context).colorScheme.error,
      ActivitySeverity.info => Theme.of(context).colorScheme.primary,
    };
    final icon = switch (activity.category) {
      'users' => Icons.group_outlined,
      'courses' => Icons.menu_book_outlined,
      'security' => Icons.security_outlined,
      'attendance' => Icons.fact_check_outlined,
      _ => Icons.history_outlined,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  activity.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${activity.actorName ?? 'System'} ? ${Formatters.timeAgo(activity.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
