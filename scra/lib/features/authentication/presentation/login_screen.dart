import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../models/user_model.dart';
import '../../../widgets/common/app_logo.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form.dart';

/// Stitch screen 06 — Login (Student / Lecturer; Admin opens the dedicated
/// institutional gateway).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialRole});

  final UserRole? initialRole;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late UserRole _role = widget.initialRole == UserRole.lecturer
      ? UserRole.lecturer
      : UserRole.student;

  Future<void> _login(String id, String password, bool remember) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final ok = await auth.login(
      role: _role,
      identifier: id,
      password: password,
      rememberMe: remember,
    );
    if (ok && auth.role != null) {
      navigator.pushNamedAndRemoveUntil(
        AppRouter.homeFor(auth.role!),
        (_) => false,
      );
    }
  }

  void _selectRole(UserRole role) {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    if (role == UserRole.admin) {
      Navigator.of(context).pushNamed(RouteNames.adminLogin);
      return;
    }
    setState(() => _role = role);
    auth.selectRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageMargin,
                vertical: AppDimensions.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (canPop)
                        IconButton(
                          tooltip: AppStrings.back,
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                  const Center(child: AppLogo(size: 88)),
                  const SizedBox(height: AppDimensions.spaceMd),
                  Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppDimensions.spaceXs),
                  Text(
                    'Sign in with your institutional credentials.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  _RoleToggle(selected: _role, onSelected: _selectRole),
                  const SizedBox(height: AppDimensions.spaceLg),
                  LoginForm(
                    key: ValueKey(_role),
                    onSubmit: _login,
                    identifierHint: 'Your registered email address',
                    onLink: () =>
                        Navigator.of(context)
                            .pushNamed(RouteNames.forgotPassword),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                  _FirstTimeLink(role: _role),
                  const SizedBox(height: AppDimensions.spaceSm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Need help? ', style: theme.textTheme.bodyMedium),
                      Text(
                        'Contact your institution administrator.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.selected, required this.onSelected});

  final UserRole selected;
  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        children: [
          for (final role in UserRole.values)
            Expanded(
              child: Semantics(
                selected: role == selected,
                button: true,
                child: InkWell(
                  key: Key('login_role_${role.value}'),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  onTap: () => onSelected(role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: role == selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (role == selected) ...[
                          const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            role.label,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: role == selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Entry point to first-time account setup for the selected role.
class _FirstTimeLink extends StatelessWidget {
  const _FirstTimeLink({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStudent = role == UserRole.student;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isStudent ? 'First time here? ' : 'New faculty member? ',
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          key: const Key('login_first_time'),
          onPressed: () => Navigator.of(context).pushNamed(
            isStudent
                ? RouteNames.studentActivation
                : RouteNames.lecturerRegistration,
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 36),
          ),
          child: Text(
            isStudent ? 'Activate your account' : 'Register as lecturer',
          ),
        ),
      ],
    );
  }
}
