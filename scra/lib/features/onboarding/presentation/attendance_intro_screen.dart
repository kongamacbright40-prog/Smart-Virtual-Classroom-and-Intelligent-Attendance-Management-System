import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../widgets/common/status_chip.dart';
import '../widgets/onboarding_layout.dart';

/// Stitch screen 03 — Automatic Attendance introduction.
class AttendanceIntroScreen extends StatelessWidget {
  const AttendanceIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      pageIndex: 1,
      hero: const OnboardingHero(
        height: 200,
        icons: [
          Icons.laptop_chromebook,
          Icons.fingerprint,
          Icons.schedule,
          Icons.fact_check_outlined,
        ],
        topLeft: HeroPill(label: 'TELEMETRY ACTIVE', dotColor: AppColors.live),
        bottomRight: HeroPill(
          label: 'Auto-Logged',
          icon: Icons.verified_outlined,
          dark: true,
        ),
        bottom: _SessionTrackingCard(),
      ),
      badge: const OnboardingBadge(label: 'Smart Presence'),
      title: 'Automatic Attendance',
      body:
          'Your join time, leave time and active session duration are recorded automatically.',
      footerIcon: Icons.pin_drop_outlined,
      footerText: 'Biometric & Geo-timestamped • Zero manual roll call',
      onBack: () => Navigator.of(context).maybePop(),
      onNext: () =>
          Navigator.of(context).pushNamed(RouteNames.participationIntro),
    );
  }
}

class _SessionTrackingCard extends StatelessWidget {
  const _SessionTrackingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.laptop_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text('Session Tracking',
                    style: theme.textTheme.titleMedium),
              ),
              const StatusChip(
                label: 'Auto Verified',
                tone: StatusTone.success,
                showDot: true,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: _TimePoint(
                    icon: Icons.login,
                    time: '10:02 AM',
                    label: 'Joined lecture',
                    highlight: true,
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 56,
                      height: 3,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 6),
                    const StatusChip(
                      label: '58 MIN',
                      icon: Icons.schedule,
                      dense: true,
                    ),
                  ],
                ),
                const Expanded(
                  child: _TimePoint(
                    icon: Icons.logout,
                    time: '10:58 AM',
                    label: 'Session ended',
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              Icon(Icons.security_update_good_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text('Biometric sync & digital footprint',
                    style: theme.textTheme.bodyMedium),
              ),
              Text(
                '100% Valid',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePoint extends StatelessWidget {
  const _TimePoint({
    required this.icon,
    required this.time,
    required this.label,
    this.highlight = false,
    this.alignEnd = false,
  });

  final IconData icon;
  final String time;
  final String label;
  final bool highlight;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBox = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Icon(icon,
          size: 14,
          color: highlight
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant),
    );
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: alignEnd
              ? [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(time, style: theme.textTheme.titleSmall),
                    ),
                  ),
                  const SizedBox(width: 4),
                  iconBox,
                ]
              : [
                  iconBox,
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(time, style: theme.textTheme.titleSmall),
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
