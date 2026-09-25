import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum StatusTone { primary, live, success, warning, error, neutral, info }

/// Rounded pill used for statuses (`LIVE NOW`, `Present`, `Active`...).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.showDot = false,
    this.uppercase = false,
    this.dense = false,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool showDot;
  final bool uppercase;
  final bool dense;

  static (Color bg, Color fg) colorsFor(BuildContext context, StatusTone tone) {
    final scheme = Theme.of(context).colorScheme;
    return switch (tone) {
      StatusTone.primary => (
        AppColors.primaryFixed,
        AppColors.onPrimaryFixedVariant,
      ),
      StatusTone.live => (const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
      StatusTone.success => (
        AppColors.successContainer,
        AppColors.onSuccessContainer,
      ),
      StatusTone.warning => (
        AppColors.warningContainer,
        AppColors.onWarningContainer,
      ),
      StatusTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      StatusTone.info => (
        AppColors.secondaryFixed,
        AppColors.onSecondaryFixedVariant,
      ),
      StatusTone.neutral => (
        scheme.surfaceContainerHigh,
        scheme.onSurfaceVariant,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = colorsFor(context, tone);
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: fg, letterSpacing: uppercase ? 0.8 : 0.3);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small code tag, e.g. `CS-301`.
class CodeTag extends StatelessWidget {
  const CodeTag(this.code, {super.key, this.onDark = false});

  final String code;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        code,
        style: theme.textTheme.labelMedium?.copyWith(
          color: onDark ? Colors.white : AppColors.onPrimaryFixed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
