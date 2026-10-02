import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/models.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../authentication/providers/auth_provider.dart';

class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final user = auth.user!;
    return AppScaffold(
      appBar: SmartAppBar(
        title: 'Settings',
        subtitle: 'Manage your student preferences',
      ),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StudentTile(user: user),
          const SizedBox(height: AppDimensions.spaceLg),
          _SectionLabel(
            icon: Icons.notifications_active_outlined,
            label: 'NOTIFICATIONS',
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchRow(
                  title: 'Push Notifications',
                  subtitle: 'Instant alerts for class starts, room changes & attendance reminders',
                  value: settings.pushNotifications,
                  onChanged: (v) =>
                      _update(context, (s) => s.copyWith(pushNotifications: v)),
                ),
                _SwitchRow(
                  title: 'Email Class Alerts',
                  subtitle: 'Daily digest of syllabi changes, quiz results & dean announcements',
                  value: settings.emailClassAlerts,
                  onChanged: (v) =>
                      _update(context, (s) => s.copyWith(emailClassAlerts: v)),
                ),
                _SwitchRow(
                  title: 'Attendance Warning Guard',
                  subtitle:
                      'Alert when subject drops below ${settings.attendanceWarningThreshold.round()}%',
                  value: settings.attendanceWarningGuard,
                  onChanged: (v) => _update(
                    context,
                    (s) => s.copyWith(attendanceWarningGuard: v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          _SectionLabel(icon: Icons.videocam_outlined, label: 'VIDEO & AUDIO'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchRow(
                  title: 'Join With Microphone Off',
                  subtitle: 'Microphone stays muted by default upon entering a live class session',
                  value: settings.joinWithMicOff,
                  onChanged: (v) =>
                      _update(context, (s) => s.copyWith(joinWithMicOff: v)),
                ),
                _SwitchRow(
                  title: 'Join With Camera Off',
                  subtitle:
                      'Camera remains disabled until manually turned on by you',
                  value: settings.joinWithCameraOff,
                  onChanged: (v) =>
                      _update(context, (s) => s.copyWith(joinWithCameraOff: v)),
                ),
                ListTile(
                  leading: const Icon(Icons.noise_aware_outlined),
                  title: const Text('Audio Noise Cancellation'),
                  subtitle: Text(settings.noiseCancellation),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          _SectionLabel(icon: Icons.palette_outlined, label: 'APPEARANCE'),
          _ThemeSelector(current: settings.themeMode),
          const SizedBox(height: AppDimensions.spaceLg),
          _SectionLabel(icon: Icons.security_outlined, label: 'ACCOUNT'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _changePassword(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              foregroundColor: AppColors.onErrorContainer,
              minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
            ),
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Text(
            '${AppConstants.appName} v${AppConstants.appVersion}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static Future<void> _update(
    BuildContext context,
    AppSettingsModel Function(AppSettingsModel) change,
  ) => context.read<SettingsProvider>().update(change);

  static Future<void> _changePassword(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  static Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
        title: const Text(AppStrings.logoutTitle),
        content: const Text(AppStrings.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              unawaited(auth.logout());
              navigator.pushNamedAndRemoveUntil(RouteNames.login, (_) => false);
            },
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          UserAvatar(name: user.fullName, size: 64, showOnline: true),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Institutional ID: ${user.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spaceXs),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        value ? Icons.check_circle : Icons.cancel,
        color: value ? AppColors.primary : Colors.grey,
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current});

  final ThemeMode current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemeOption(
            mode: ThemeMode.light,
            current: current,
            icon: Icons.light_mode,
            title: 'Light',
            subtitle: 'Campus Day',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: _ThemeOption(
            mode: ThemeMode.dark,
            current: current,
            icon: Icons.dark_mode,
            title: 'Dark',
            subtitle: 'Study Night',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: _ThemeOption(
            mode: ThemeMode.system,
            current: current,
            icon: Icons.settings_brightness,
            title: 'System',
            subtitle: 'Auto Match',
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.current,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ThemeMode mode;
  final ThemeMode current;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final selected = mode == current;
    return AppCard(
      onTap: () => context.read<SettingsProvider>().setThemeMode(mode),
      color: selected ? AppColors.primaryFixed : null,
      child: Column(
        children: [
          Icon(icon, color: selected ? AppColors.primary : null),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Icon(
            selected ? Icons.check_circle : Icons.circle,
            size: 18,
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.spaceLg,
        right: AppDimensions.spaceLg,
        top: AppDimensions.spaceLg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spaceLg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _current,
              label: 'Current Password',
              obscure: true,
              validator: Validators.password,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _password,
              label: 'New Password',
              obscure: true,
              validator: Validators.newPassword,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _confirm,
              label: 'Confirm Password',
              obscure: true,
              validator: (v) => Validators.confirmPassword(v, _password.text),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final ok = await context.read<AuthProvider>().changePassword(
        currentPassword: _current.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        Helpers.showSnackBar(context, 'Password changed');
      } else {
        Helpers.showError(
          context,
          context.read<AuthProvider>().errorMessage ??
              'Unable to change password',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
