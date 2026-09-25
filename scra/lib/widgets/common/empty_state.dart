import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../buttons/secondary_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
            compact ? AppDimensions.spaceMd : AppDimensions.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: compact ? 28 : 36,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spaceXs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              SecondaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
