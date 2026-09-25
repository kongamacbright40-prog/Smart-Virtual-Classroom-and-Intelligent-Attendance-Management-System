import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/features/authentication/providers/auth_provider.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/providers/settings_provider.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/common/user_avatar.dart';
import 'package:smart_class/widgets/dialogs/logout_dialog.dart';

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      color: scheme.errorContainer,
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.logout, color: scheme.error),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Text(
              'Sign Out of Administrator Session',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id ?? '';
    return AppScaffold(
      appBar: const AdminScreenHeader(
        title: 'Admin Settings',
        subtitle: 'Smart Class',
        showBack: true,
      ),
      body: AsyncView<_AdminProfileData>(
        load: () async {
          final userRepository = context.read<UserRepository>();
          final adminRepository = context.read<AdminRepository>();
          return _AdminProfileData(
            await userRepository.getAdminProfile(userId),
            await adminRepository.getSystemSettings(),
          );
        },
        builder: (context, data, reload) {
          final admin = data.admin;
          final settings = data.settings;
          return ListView(
            children: [
              AppCard(
                child: Column(
                  children: [
                    UserAvatar(
                      name: admin.user.fullName,
                      imageUrl: admin.user.avatarUrl,
                      size: 86,
                      showOnline: true,
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    Text(
                      admin.user.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: StatusChip(
                        label: admin.accessLevel.label,
                        tone: StatusTone.primary,
                        icon: Icons.shield_outlined,
                      ),
                    ),
                    Text(admin.user.email),
                    Text('Admin ID: ${admin.adminId}'),
                    Text(
                      admin.lastLoginAt == null
                          ? 'Last session authenticated: Not available'
                          : 'Last session authenticated: ${Formatters.relativeDay(admin.lastLoginAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _LogoutCard(onTap: () => _logout(context)),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle(
                      title: 'Credentials & Identity',
                      trailing: Text('Profile'),
                    ),
                    const SizedBox(height: AppDimensions.spaceMd),
                    _kv(context, 'Root Identifier', admin.user.id),
                    _kv(context, 'Access Scope', admin.accessLevel.label),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  children: [
                    AdminSectionTitle(
                      title: 'Security Enforcement',
                      trailing: StatusChip(
                        label: settings.enforceSso
                            ? 'SSO enforced'
                            : 'SSO optional',
                        tone: StatusTone.neutral,
                        dense: true,
                      ),
                    ),
                    AdminInfoRow(
                      icon: Icons.token_outlined,
                      title: 'Two-Factor Authentication',
                      subtitle: admin.twoFactorEnabled
                          ? 'Enabled'
                          : 'Not enabled',
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    AdminInfoRow(
                      icon: Icons.timer_outlined,
                      title: 'Idle Session Timeout',
                      subtitle: '${settings.sessionTimeoutMinutes} minutes',
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle(title: 'Preferences'),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, _) => Wrap(
                        spacing: AppDimensions.spaceSm,
                        children: [
                          for (final mode in ThemeMode.values)
                            ChoiceChip(
                              label: Text(
                                mode.name[0].toUpperCase() +
                                    mode.name.substring(1),
                              ),
                              selected: settings.themeMode == mode,
                              onSelected: (_) => settings.setThemeMode(mode),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _LogoutCard(
                key: const Key('admin_logout'),
                onTap: () => _logout(context),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                'Signing out will invalidate this device session token and require multi-factor re-authentication.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(BuildContext context, String key, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
    child: Row(
      children: [
        Expanded(
          child: Text(key, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    ),
  );

  Future<void> _logout(BuildContext context) =>
      confirmAndLogout(context, loginRoute: RouteNames.adminLogin);
}

class _AdminProfileData {
  const _AdminProfileData(this.admin, this.settings);
  final AdminModel admin;
  final SystemSettingsModel settings;
}
