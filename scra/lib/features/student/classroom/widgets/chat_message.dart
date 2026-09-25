import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common/user_avatar.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.onRetry,
  });

  final ChatMessageModel message;
  final bool isOwn;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lecturer = message.senderRole == UserRole.lecturer;
    final bg = isOwn
        ? theme.colorScheme.primary
        : lecturer
        ? AppColors.primaryFixed
        : theme.colorScheme.surfaceContainerLow;
    final fg = isOwn
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isOwn) ...[
            UserAvatar(name: message.senderName, size: 36),
            const SizedBox(width: AppDimensions.spaceSm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isOwn
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppDimensions.spaceSm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isOwn
                          ? '${message.senderName} (You)'
                          : message.senderName,
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      Formatters.time(message.timestamp),
                      style: theme.textTheme.labelSmall,
                    ),
                    if (lecturer)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          message.isPinned ? 'Lecturer Pinned' : 'Lecturer',
                        ),
                        avatar: const Icon(Icons.star, size: 14),
                      ),
                    if (message.isQuestion)
                      const Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('Question'),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Text(
                    message.message,
                    style: theme.textTheme.bodyLarge?.copyWith(color: fg),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXs),
                _StatusIcon(status: message.status, onRetry: onRetry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, this.onRetry});

  final MessageStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      MessageStatus.sending => (Icons.access_time, 'Sending', Colors.grey),
      MessageStatus.sent ||
      MessageStatus.delivered ||
      MessageStatus.read => (Icons.done, 'Sent', AppColors.success),
      MessageStatus.failed => (
        Icons.error_outline,
        'Failed — tap to retry',
        AppColors.error,
      ),
    };
    return InkWell(
      onTap: onRetry,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
