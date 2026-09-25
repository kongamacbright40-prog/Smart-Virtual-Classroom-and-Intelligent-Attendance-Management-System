import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Rounded linear progress bar used for attendance / session progress.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 6,
  });

  /// 0..1
  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        color: color ?? scheme.primary,
        backgroundColor: backgroundColor ?? scheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Row of equal segments, e.g. step indicator or password strength meter.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.total,
    required this.filled,
    this.color,
    this.height = 6,
    this.spacing = 6,
  });

  final int total;
  final int filled;
  final Color? color;
  final double height;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: height,
              decoration: BoxDecoration(
                color: i < filled
                    ? (color ?? scheme.secondary)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
