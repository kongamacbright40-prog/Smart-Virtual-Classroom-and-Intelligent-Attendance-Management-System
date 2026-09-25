import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/common/app_logo.dart';
import '../../authentication/providers/auth_provider.dart';
import 'onboarding_indicator.dart';

/// Shared layout of the three onboarding pages (Stitch screens 02–04):
/// brand header with Skip, hero card, badge, title, body, page indicator,
/// Back/Next buttons and a trust footer.
class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.pageIndex,
    required this.hero,
    required this.title,
    required this.body,
    required this.footerIcon,
    required this.footerText,
    required this.onNext,
    this.badge,
    this.headerBadge,
    this.headerSubtitle = AppStrings.suiteName,
    this.nextLabel = AppStrings.next,
    this.onBack,
  });

  final int pageIndex;
  final Widget hero;
  final Widget? badge;
  final String title;
  final String body;
  final IconData footerIcon;
  final String footerText;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String nextLabel;
  final String? headerBadge;
  final String headerSubtitle;

  static const int pageCount = 3;

  static Future<void> skip(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().completeOnboarding();
    navigator.pushNamedAndRemoveUntil(RouteNames.roleSelection, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pageMargin,
                    AppDimensions.spaceSm,
                    AppDimensions.spaceSm,
                    AppDimensions.spaceSm,
                  ),
                  child: BrandHeader(
                    badge: headerBadge,
                    subtitle: headerSubtitle,
                    trailing: TextButton(
                      key: const Key('onboarding_skip'),
                      onPressed: () => skip(context),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        backgroundColor: theme.colorScheme.surfaceContainerLow,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text(AppStrings.skip),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pageMargin,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppDimensions.spaceSm),
                        hero,
                        const SizedBox(height: AppDimensions.spaceLg),
                        if (badge != null) ...[
                          badge!,
                          const SizedBox(height: AppDimensions.spaceMd),
                        ],
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceLg),
                        OnboardingIndicator(
                          count: pageCount,
                          index: pageIndex,
                        ),
                        const SizedBox(height: AppDimensions.spaceLg),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pageMargin,
                    AppDimensions.spaceSm,
                    AppDimensions.pageMargin,
                    AppDimensions.spaceMd,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (onBack != null) ...[
                            Expanded(
                              flex: 2,
                              child: SecondaryButton(
                                label: AppStrings.back,
                                icon: Icons.arrow_back,
                                onPressed: onBack,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceMd),
                          ],
                          Expanded(
                            flex: 4,
                            child: PrimaryButton(
                              key: const Key('onboarding_next'),
                              label: nextLabel,
                              trailingIcon: Icons.arrow_forward,
                              onPressed: onNext,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(footerIcon,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: AppDimensions.spaceSm),
                          Flexible(
                            child: Text(
                              footerText,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Illustrated hero card. Stitch uses generated artwork; this recreates the
/// composition with a soft gradient scene and Material icons.
class OnboardingHero extends StatelessWidget {
  const OnboardingHero({
    super.key,
    required this.icons,
    this.topLeft,
    this.topRight,
    this.bottomRight,
    this.height = 220,
    this.bottom,
  });

  final List<IconData> icons;
  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomRight;
  final double height;

  /// Content rendered under the illustration inside the same card.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE0ECFF),
                          Color(0xFFF1F6FF),
                          Color(0xFFD9F0FF),
                        ],
                      ),
                    ),
                    child: _HeroIcons(icons: icons),
                  ),
                ),
                if (topLeft != null)
                  Positioned(top: 12, left: 12, child: topLeft!),
                if (topRight != null)
                  Positioned(top: 12, right: 12, child: topRight!),
                if (bottomRight != null)
                  Positioned(bottom: 12, right: 12, child: bottomRight!),
              ],
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}

class _HeroIcons extends StatelessWidget {
  const _HeroIcons({required this.icons});

  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    final main = icons.first;
    final satellites = icons.skip(1).toList();
    const positions = [
      Alignment(-0.75, -0.2),
      Alignment(0.75, -0.3),
      Alignment(-0.55, 0.65),
      Alignment(0.6, 0.6),
    ];
    return Stack(
      children: [
        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.sky400, AppColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(main, size: 56, color: Colors.white),
          ),
        ),
        for (var i = 0; i < satellites.length && i < positions.length; i++)
          Align(
            alignment: positions[i],
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 12),
                ],
              ),
              child: Icon(satellites[i],
                  size: 24, color: AppColors.primaryContainer),
            ),
          ),
      ],
    );
  }
}

/// White pill overlay used on the hero illustration.
class HeroPill extends StatelessWidget {
  const HeroPill({
    super.key,
    required this.label,
    this.icon,
    this.dotColor,
    this.dark = false,
  });

  final String label;
  final IconData? icon;
  final Color? dotColor;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = dark ? Colors.white : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.inverseSurface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          if (icon != null) ...[
            Icon(icon, size: 16, color: dark ? Colors.white : theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tonal badge above onboarding titles (`⚡ SMART PRESENCE`).
class OnboardingBadge extends StatelessWidget {
  const OnboardingBadge({
    super.key,
    required this.label,
    this.icon = Icons.bolt,
    this.color,
    this.foreground,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foreground ?? AppColors.onPrimaryFixedVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
