import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../widgets/onboarding_layout.dart';

/// Stitch screen 02 — Welcome / Onboarding.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      pageIndex: 0,
      hero: const OnboardingHero(
        height: 260,
        icons: [
          Icons.cast_for_education,
          Icons.video_camera_front_outlined,
          Icons.bar_chart_rounded,
          Icons.groups_2_outlined,
          Icons.forum_outlined,
        ],
        topLeft: HeroPill(
          label: 'INTERACTIVE LIVE',
          dotColor: AppColors.success,
        ),
        bottomRight: HeroPill(
          label: 'Smart Attendance',
          icon: Icons.verified_outlined,
        ),
      ),
      title: 'Welcome to Smart Class',
      body:
          'Attend classes virtually, participate in real time and automatically track your attendance.',
      footerIcon: Icons.lock_outline,
      footerText: 'Secured by University Single Sign-On',
      onNext: () =>
          Navigator.of(context).pushNamed(RouteNames.attendanceIntro),
      badge: const _FeatureChips(),
    );
  }
}

class _FeatureChips extends StatelessWidget {
  const _FeatureChips();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.videocam_outlined, 'HD Video'),
      (Icons.how_to_reg_outlined, 'Auto-Log'),
      (Icons.forum_outlined, 'Realtime Q&A'),
    ];
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceSm,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i].$1, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      items[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
