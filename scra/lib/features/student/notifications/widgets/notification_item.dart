import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/models.dart';
import '../../../../widgets/cards/notification_card.dart';
import '../../../../widgets/common/app_card.dart';

class StudentNotificationItem extends StatelessWidget {
  const StudentNotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onAction,
  });

  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = notificationVisuals(notification.type);
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      color: notification.isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: Icon(icon, color: fg),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.type.label,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        Text(Formatters.timeAgo(notification.createdAt)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceXs),
                    Text(
                      notification.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppDimensions.spaceXs),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notification.actionLabel != null ||
              notification.referenceId != null) ...[
            const Divider(height: AppDimensions.spaceLg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onAction,
                child: Text(notification.actionLabel ?? 'View Details'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
