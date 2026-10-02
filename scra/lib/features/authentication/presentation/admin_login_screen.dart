import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common/app_logo.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form.dart';

/// Stitch screen 09 — Institutional Administration login.
class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  Future<void> _login(
    BuildContext context,
    String id,
    String password,
    bool remember,
  ) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final ok = await auth.login(
      role: UserRole.admin,
      identifier: id,
      password: password,
      rememberMe: remember,
    );
    if (ok) {
      navigator.pushNamedAndRemoveUntil(
        AppRouter.homeFor(UserRole.admin),
        (_) => false,
      );
    }
  }

  void _returnToPortal(BuildContext context) {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    auth.selectRole(UserRole.student);
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.login,
      (_) => false,
      arguments: UserRole.student,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.maxContentWidth,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _AdminHero(),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceLg,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceLg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXl,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LoginForm(
                            showRequired: true,
                            identifierLabel: 'Administrator email',
                            identifierHint: 'Your registered email address',
                            identifierValidator: (v) => (v ?? '').contains('@')
                                ? Validators.email(v)
                                : Validators.adminId(v),
                            fieldFill: theme.colorScheme.surfaceContainerLow,
                            rememberLabel: 'Remember credentials',
                            onLink: () =>
                                Navigator.of(context)
                                    .pushNamed(RouteNames.forgotPassword),
                            submitLabel: 'Secure Login',
                            submitIcon: Icons.vpn_key_outlined,
                            onSubmit: (id, pw, remember) =>
                                _login(context, id, pw, remember),
                          ),
                          const SizedBox(height: AppDimensions.spaceMd),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'New administrator? ',
                                style: theme.textTheme.bodyMedium,
                              ),
                              TextButton(
                                key: const Key('admin_register'),
                                onPressed: () => Navigator.of(context)
                                    .pushNamed(RouteNames.adminRegistration),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: const Text('Register as admin'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceLg,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXl,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                              ),
                              child: const Icon(
                                Icons.gavel,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OFFICIAL COMPLIANCE NOTICE',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.onPrimaryFixed,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Authorized administrative access only. Administrative actions are logged.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceMd),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceMd,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'AES-256 Encrypted',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                Center(
                  child: TextButton.icon(
                    key: const Key('admin_return_portal'),
                    onPressed: () => _returnToPortal(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return to Student / Lecturer Portal'),
                  ),
                ),
                SizedBox(
                  height:
                      MediaQuery.paddingOf(context).bottom +
                      AppDimensions.spaceMd,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusXl + 8),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spaceLg,
        MediaQuery.paddingOf(context).top + AppDimensions.spaceMd,
        AppDimensions.spaceLg,
        AppDimensions.spaceXl + 24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (canPop)
                Material(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Back',
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              const Spacer(),
              Flexible(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.live,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  blurRadius: 30,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Smart Class • Institutional Gateway',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.slate300,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            'Institutional Administration',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Secure administrative access.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.slate300,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: AppColors.slate300,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Root & Faculty Administration System',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.slate300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
