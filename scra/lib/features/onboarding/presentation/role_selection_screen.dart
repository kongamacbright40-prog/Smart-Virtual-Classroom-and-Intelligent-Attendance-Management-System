import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../models/user_model.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/app_logo.dart';
import '../../../widgets/common/status_chip.dart';
import '../../authentication/providers/auth_provider.dart';

/// Stitch screen 05 — Select Your Portal.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selected = UserRole.student;

  static const _portals = [
    _Portal(
      role: UserRole.student,
      icon: Icons.school_outlined,
      title: 'Student Portal',
      tag: 'Learner',
      description:
          'Join live lectures, submit coursework & track daily attendance.',
      features: ['Live Polling', 'Auto-Attendance', 'Class Timetable'],
    ),
    _Portal(
      role: UserRole.lecturer,
      icon: Icons.cast_for_education_outlined,
      title: 'Lecturer Portal',
      tag: 'Faculty',
      description:
          'Stream interactive classes, moderate Q&A, and assess participation.',
      features: ['Session Broadcast', 'Live Telemetry', 'Grading Hub'],
    ),
    _Portal(
      role: UserRole.admin,
      icon: Icons.shield_outlined,
      title: 'Admin Portal',
      tag: 'Staff',
      description:
          'Manage user roster, audit logs, and institutional infrastructure.',
      features: ['Campus Directory', 'Audit Logs', 'SIS Sync'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = context.read<AuthProvider>().selectedRole ?? UserRole.student;
  }

  Future<void> _continue() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    await auth.completeOnboarding();
    await auth.selectRole(_selected);
    if (_selected == UserRole.admin) {
      navigator.pushNamed(RouteNames.adminLogin);
    } else {
      navigator.pushNamed(RouteNames.login, arguments: _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                tooltip: AppStrings.back,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        centerTitle: true,
        toolbarHeight: 72,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 40),
            const SizedBox(width: AppDimensions.spaceSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.appName, style: theme.textTheme.titleLarge),
                Text(
                  AppStrings.suiteName.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Which portal should I choose?'),
                content: const Text(
                  'Pick the role assigned to you by your institution. '
                  'You can switch portals later from the login screen.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.close),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.pageMargin),
                    children: [
                      const SizedBox(height: AppDimensions.spaceSm),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: StatusChip(
                          label: 'Identity Gateway • Step 1 of 3',
                          icon: Icons.verified_user_outlined,
                          tone: StatusTone.primary,
                          uppercase: true,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),
                      Text('Select Your Portal',
                          style: theme.textTheme.headlineLarge),
                      const SizedBox(height: AppDimensions.spaceSm),
                      Text(
                        'Choose your institutional role to calibrate your workspace.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppDimensions.spaceLg),
                      for (final portal in _portals) ...[
                        _PortalCard(
                          portal: portal,
                          selected: _selected == portal.role,
                          onTap: () => setState(() => _selected = portal.role),
                        ),
                        const SizedBox(height: AppDimensions.spaceMd),
                      ],
                    ],
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
                      PrimaryButton(
                        key: const Key('role_continue'),
                        label: 'Continue to Setup',
                        trailingIcon: Icons.arrow_forward,
                        onPressed: _continue,
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: AppDimensions.spaceSm),
                          Flexible(
                            child: Text(
                              'Protected via SAML 2.0 & Institutional Credentials',
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

class _Portal {
  const _Portal({
    required this.role,
    required this.icon,
    required this.title,
    required this.tag,
    required this.description,
    required this.features,
  });

  final UserRole role;
  final IconData icon;
  final String title;
  final String tag;
  final String description;
  final List<String> features;
}

class _PortalCard extends StatelessWidget {
  const _PortalCard({
    required this.portal,
    required this.selected,
    required this.onTap,
  });

  final _Portal portal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: portal.title,
      child: Material(
        key: Key('portal_${portal.role.value}'),
        color: selected
            ? AppColors.primaryFixed.withValues(alpha: 0.45)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? scheme.primaryContainer : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryFixed
                            : scheme.surfaceContainerHigh,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Icon(
                        portal.icon,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppDimensions.spaceSm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(portal.title,
                                  style: theme.textTheme.titleLarge),
                              StatusChip(
                                label: portal.tag,
                                tone: selected
                                    ? StatusTone.info
                                    : StatusTone.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(portal.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHigh,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                Wrap(
                  spacing: AppDimensions.spaceSm,
                  runSpacing: AppDimensions.spaceSm,
                  children: [
                    for (final f in portal.features)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : scheme.surfaceContainerHigh,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(f, style: theme.textTheme.labelMedium),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
