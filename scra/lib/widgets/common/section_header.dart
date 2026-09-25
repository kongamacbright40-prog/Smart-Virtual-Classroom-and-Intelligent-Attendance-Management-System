import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Section title row (e.g. `MY COURSES ........ View All (4) >`).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.uppercase = false,
    this.padding = const EdgeInsets.only(
      top: AppDimensions.spaceLg,
      bottom: AppDimensions.spaceSm,
    ),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final bool uppercase;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uppercase ? title.toUpperCase() : title,
                  style: theme.textTheme.titleLarge,
                ),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          ?trailing,
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
