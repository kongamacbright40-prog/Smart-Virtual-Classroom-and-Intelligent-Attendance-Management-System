import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../widgets/common/progress_bar.dart';

class CourseProgress extends StatelessWidget {
  const CourseProgress({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    this.progress,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final double? progress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: AppDimensions.spaceXs),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        if (progress != null) ...[
          const SizedBox(height: AppDimensions.spaceXs),
          AppProgressBar(value: progress!, color: color, height: 4),
        ],
        const SizedBox(height: AppDimensions.spaceXs),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
