import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Compact metric tile (`94% Overall Attend.`, `18 Active Credits`).
class StatisticCard extends StatelessWidget {
  const StatisticCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.valueColor,
    this.caption,
    this.captionColor,
    this.onTap,
    this.alignment = CrossAxisAlignment.center,
    this.backgroundColor,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? valueColor;

  /// Small line under the label (e.g. `+2.1% w/w`).
  final String? caption;
  final Color? captionColor;
  final VoidCallback? onTap;
  final CrossAxisAlignment alignment;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = valueColor ?? theme.colorScheme.onSurface;
    final textAlign = alignment == CrossAxisAlignment.center
        ? TextAlign.center
        : TextAlign.start;
    return Material(
      color: backgroundColor ?? theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceSm,
            vertical: AppDimensions.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: alignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: textAlign,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  textAlign: textAlign,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: captionColor ?? theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
