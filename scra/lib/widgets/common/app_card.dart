import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// White rounded container used for most Stitch cards.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spaceMd),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppDimensions.radiusLg,
    this.margin,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color:
            borderColor ??
            theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: gradient == null
            ? (color ?? theme.cardTheme.color)
            : Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: gradient == null
              ? null
              : BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(radius),
                ),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
