import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/common/progress_bar.dart';

/// Header block of the gateway screens (activation, registration, recovery):
/// a step card, an emblem with a verified badge, a title and a description.
class RoleHeader extends StatelessWidget {
  const RoleHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.badgeIcon = Icons.verified,
    this.step,
  });

  final IconData icon;
  final IconData badgeIcon;
  final String title;
  final String description;
  final StepInfo? step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (step != null) ...[
          StepCard(info: step!),
          const SizedBox(height: AppDimensions.spaceLg),
        ],
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixed.withValues(alpha: 0.5),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryFixed,
                ),
                child: Icon(icon, size: 38, color: theme.colorScheme.primary),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 3,
                  ),
                ),
                child: Icon(badgeIcon, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class StepInfo {
  const StepInfo({
    required this.overline,
    required this.title,
    required this.current,
    required this.total,
  });

  final String overline;
  final String title;
  final int current;
  final int total;
}

/// `IDENTITY VERIFICATION • Step 2 of 2` progress card.
class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.info});

  final StepInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${info.current}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.overline.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(info.title, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Text(
                'Step ${info.current} of ${info.total}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          SegmentedProgress(
            total: info.total,
            filled: info.current,
            color: theme.colorScheme.primaryContainer,
            height: 5,
          ),
        ],
      ),
    );
  }
}

/// Centered footer line with an icon (`🔒 256-Bit TLS · ...`).
class SecurityFooter extends StatelessWidget {
  const SecurityFooter({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline,
    this.pill = false,
  });

  final String text;
  final IconData icon;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppDimensions.spaceSm),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
          ),
        ),
      ],
    );
    if (!pill) return row;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: row,
    );
  }
}

/// Gateway app bar: back, centered brand title with overline, help action.
class GatewayAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GatewayAppBar({
    super.key,
    required this.title,
    required this.overline,
    this.titleIcon,
    this.overlineBelow = false,
  });

  final String title;
  final String overline;
  final IconData? titleIcon;

  /// Student gateway shows the subtitle below the title.
  final bool overlineBelow;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = Text(
      overlineBelow ? overline : overline.toUpperCase(),
      style: overlineBelow
          ? theme.textTheme.labelMedium
          : theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
    );
    final main = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (titleIcon != null) ...[
          Icon(titleIcon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
        ),
      ],
    );
    return AppBar(
      toolbarHeight: 68,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: overlineBelow ? [main, over] : [over, main],
      ),
      actions: [
        IconButton(
          tooltip: 'Help',
          icon: const Icon(Icons.contact_support_outlined),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.support_agent),
              title: const Text('Need help?'),
              content: const Text(
                'Contact your institution administrator or the campus IT '
                'Helpdesk for account assistance.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
