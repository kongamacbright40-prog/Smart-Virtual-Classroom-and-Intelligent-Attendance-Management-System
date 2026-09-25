import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/common/status_chip.dart';
import '../widgets/onboarding_layout.dart';

/// Stitch screen 04 — Interactive Participation introduction.
class ParticipationIntroScreen extends StatelessWidget {
  const ParticipationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      pageIndex: 2,
      headerBadge: 'MVP',
      headerSubtitle: 'EduVerse Academic Nexus',
      hero: const OnboardingHero(
        height: 170,
        icons: [
          Icons.co_present_outlined,
          Icons.poll_outlined,
          Icons.front_hand_outlined,
          Icons.quiz_outlined,
        ],
        topLeft: HeroPill(
          label: 'ACTIVE SESSION',
          dotColor: AppColors.live,
          dark: true,
        ),
        topRight: HeroPill(label: '38 Present', icon: Icons.how_to_reg_outlined),
        bottom: _PollPreview(),
      ),
      badge: const OnboardingBadge(
        label: 'Real-Time Engagement',
        color: AppColors.secondaryFixed,
        foreground: AppColors.onSecondaryFixedVariant,
      ),
      title: 'Interactive Participation',
      body:
          'Answer live questions and participate in classroom activities while your engagement is tracked separately from technical attendance.',
      footerIcon: Icons.verified_outlined,
      footerText: 'Attendance & Participation sync with Campus LMS',
      nextLabel: 'Get Started',
      onBack: () => Navigator.of(context).maybePop(),
      onNext: () => OnboardingLayout.skip(context),
    );
  }
}

class _PollPreview extends StatelessWidget {
  const _PollPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = [
      ('A', 'Proof of Stake', 0.68, true),
      ('B', 'Byzantine Fault Tolerance', 0.24, false),
      ('C', 'Proof of Authority', 0.08, false),
    ];
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: StatusChip(
                  label: 'Live polling active',
                  tone: StatusTone.live,
                  showDot: true,
                  uppercase: true,
                ),
              ),
              Icon(Icons.timer_outlined,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('00:42s', style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'Q2: Which consensus algorithm optimizes low-latency verification?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
              child: _PollBar(
                letter: o.$1,
                label: o.$2,
                fraction: o.$3,
                selected: o.$4,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceSm, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text('98',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.secondary)),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Score: 98%', style: theme.textTheme.labelLarge),
                      Text('Live Tracked',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ),
                ),
                const StatusChip(
                  label: '14 Raised',
                  icon: Icons.pan_tool_outlined,
                  tone: StatusTone.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PollBar extends StatelessWidget {
  const _PollBar({
    required this.letter,
    required this.label,
    required this.fraction,
    required this.selected,
  });

  final String letter;
  final String label;
  final double fraction;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: theme.colorScheme.surfaceContainerLow),
          ),
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: ColoredBox(
                color: selected
                    ? AppColors.primaryFixedDim.withValues(alpha: 0.6)
                    : theme.colorScheme.surfaceContainerHigh,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceSm, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    letter,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? Colors.white : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium),
                ),
                Text(
                  '${(fraction * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle_outline,
                      size: 18, color: theme.colorScheme.primary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
