import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/status_chip.dart';

class UpcomingClassCard extends StatelessWidget {
  const UpcomingClassCard({super.key, required this.session, this.onTap});

  final ClassSessionModel session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
            label: 'NEXT CLASS',
            tone: StatusTone.info,
            icon: Icons.event,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(session.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            '${session.courseCode} • ${Formatters.relativeDay(session.startTime)}',
            style: theme.textTheme.bodyMedium,
          ),
          if (session.room != null) ...[
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              session.room!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppDimensions.spaceMd),
          PrimaryButton(
            label: 'View Schedule',
            icon: Icons.calendar_today_outlined,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
