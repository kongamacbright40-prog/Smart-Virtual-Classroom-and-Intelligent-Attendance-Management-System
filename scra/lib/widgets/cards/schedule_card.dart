import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/class_session_model.dart';
import '../common/status_chip.dart';

/// Timetable entry card (Student Schedule style).
class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.session,
    this.onTap,
    this.action,
    this.footer,
    this.now,
  });

  final ClassSessionModel session;
  final VoidCallback? onTap;

  /// Primary action (e.g. `Join Now`).
  final Widget? action;

  /// Extra line under the card content (e.g. `Attended • 75m logged`).
  final Widget? footer;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = session.status == SessionStatus.live;
    final (label, tone) = switch (session.status) {
      SessionStatus.live => ('Live', StatusTone.live),
      SessionStatus.completed => ('Completed', StatusTone.success),
      SessionStatus.cancelled => ('Cancelled', StatusTone.error),
      SessionStatus.scheduled => ('Scheduled', StatusTone.neutral),
    };

    return Material(
      color: isLive ? AppColors.inverseSurface : theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: isLive
              ? Colors.transparent
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isLive ? Icons.timer_outlined : Icons.schedule,
                      size: 18,
                      color: isLive
                          ? AppColors.sky400
                          : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Text(
                      Formatters.timeRange(session.startTime, session.endTime),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isLive ? Colors.white : null,
                      ),
                    ),
                  ),
                  StatusChip(label: label, tone: tone, showDot: isLive),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                '${session.courseCode} ${session.courseTitle}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isLive ? Colors.white : null,
                ),
              ),
              if (session.lecturerName != null)
                Text(
                  session.lecturerName!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLive
                        ? AppColors.slate300
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (session.room != null) ...[
                const SizedBox(height: AppDimensions.spaceXs),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16,
                        color: isLive
                            ? AppColors.slate300
                            : theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.room!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isLive ? AppColors.slate300 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: AppDimensions.spaceSm),
                footer!,
              ],
              if (action != null) ...[
                const SizedBox(height: AppDimensions.spaceMd),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
