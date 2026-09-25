import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';

/// Page indicator: the active page is a wide pill, others are dots.
class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index
                    ? scheme.primary
                    : i < index
                    ? scheme.primary
                    : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
        ],
      ),
    );
  }
}
