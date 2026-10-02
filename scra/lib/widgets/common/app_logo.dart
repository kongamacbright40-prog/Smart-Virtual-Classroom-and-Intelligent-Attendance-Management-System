import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';

/// Smart Class brand mark (graduation cap + live signal app icon).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: SizedBox.square(
        dimension: size,
        // The source icon has a transparent margin; scaling crops it.
        child: Transform.scale(
          scale: 1.08,
          child: Image.asset(
            AppAssets.appIcon,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.onPrimary,
                size: size * 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo + "Smart Class" title with a subtitle line (e.g. the user's name).
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.subtitle,
    this.logoSize = 44,
    this.trailing,
    this.badge,
  });

  final String subtitle;
  final double logoSize;
  final Widget? trailing;

  /// Optional pill after the title (e.g. `MVP`).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AppLogo(size: logoSize),
        const SizedBox(width: AppDimensions.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      AppStrings.appName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: AppDimensions.spaceSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryFixed,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryFixedVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
