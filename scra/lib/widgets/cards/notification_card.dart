import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/notification_model.dart';

(IconData, Color, Color) notificationVisuals(NotificationType type) =>
    switch (type) {
      NotificationType.classReminder => (
          Icons.videocam_outlined,
          AppColors.primaryFixed,
          AppColors.primary
        ),
      NotificationType.newCourse => (
          Icons.menu_book_outlined,
          AppColors.secondaryFixed,
          AppColors.secondary
        ),
      NotificationType.attendanceUpdate => (
          Icons.how_to_reg_outlined,
          AppColors.successContainer,
          AppColors.success
        ),
      NotificationType.liveQuestion => (
          Icons.bolt_outlined,
          AppColors.warningContainer,
          AppColors.warning
        ),
      NotificationType.announcement => (
          Icons.campaign_outlined,
          AppColors.tertiaryFixed,
          AppColors.tertiary
        ),
    };

class NotificationCard extends StatelessWidget {
  const NotificationCard({
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
    final theme = Theme.of(context);
    final (icon, bg, fg) = notificationVisuals(notification.type);
    final unread = !notification.isRead;
    return Material(
      color: unread
          ? AppColors.primaryFixed.withValues(alpha: 0.35)
          : theme.cardTheme.color,
      shape: theme.cardTheme.shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: fg, size: 20),
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
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          Formatters.timeAgo(notification.createdAt),
                          style: theme.textTheme.labelSmall,
                        ),
                        if (unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(notification.body, style: theme.textTheme.bodyMedium),
                    if (notification.actionLabel != null && onAction != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(notification.actionLabel!),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
