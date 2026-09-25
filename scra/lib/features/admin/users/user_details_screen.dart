
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/features/admin/users/widgets/user_form.dart';
import 'package:smart_class/features/authentication/providers/auth_provider.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/buttons/secondary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/dialogs/confirmation_dialog.dart';

class UserDetailsScreen extends StatelessWidget {
  const UserDetailsScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    final isCreate = userId == null;
    return AppScaffold(
      appBar: AdminScreenHeader(title: isCreate ? 'Create User' : 'User Details', showBack: true),
      scrollable: true,
      body: AsyncView<_UserDetailsData>(
        load: () async {
          final admin = context.read<AdminRepository>();
          final depts = await admin.getDepartments();
          final user = isCreate ? null : await admin.getUser(userId!);
          return _UserDetailsData(user, depts);
        },
        builder: (context, data, reload) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminHeroCard(
              title: isCreate ? 'New account' : data.user!.fullName,
              subtitle: isCreate ? 'Create a student, lecturer, or administrator profile.' : '${data.user!.role.label} ? ${data.user!.email}',
              icon: isCreate ? Icons.person_add_alt_1 : Icons.manage_accounts_outlined,
              trailing: isCreate ? null : StatusChip(label: data.user!.isActive ? 'Active' : 'Suspended', tone: adminStatusTone(data.user!.isActive)),
            ),
            adminGap,
            AppCard(
              child: UserForm(
                initialUser: data.user,
                departments: data.departments,
                submitLabel: isCreate ? 'Create User' : 'Save Changes',
                onSubmit: (user) async {
                  try {
                    final repo = context.read<AdminRepository>();
                    final auth = context.read<AuthProvider>();
                    final saved = isCreate ? await repo.createUser(user) : await repo.updateUser(user);
                    if (auth.user?.id == saved.id) await auth.updateUser(saved);
                    if (context.mounted) {
                      Helpers.showSnackBar(context, isCreate ? 'User created.' : 'User saved.');
                      Navigator.of(context).pop();
                    }
                  } on Object catch (e) {
                    if (context.mounted) Helpers.showError(context, e);
                  }
                },
              ),
            ),
            if (!isCreate) ...[
              adminGap,
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle(title: 'Account actions'),
                    const SizedBox(height: AppDimensions.spaceMd),
                    SecondaryButton(
                      label: data.user!.isActive ? 'Deactivate User' : 'Activate User',
                      icon: data.user!.isActive ? Icons.person_off_outlined : Icons.check_circle_outline,
                      foregroundColor: data.user!.isActive ? Theme.of(context).colorScheme.error : null,
                      onPressed: () => _toggle(context, data.user!, reload),
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    SecondaryButton(
                      label: 'Delete User',
                      icon: Icons.delete_outline,
                      foregroundColor: Theme.of(context).colorScheme.error,
                      onPressed: () => _delete(context, data.user!),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, UserModel user, Future<void> Function() reload) async {
    final ok = await ConfirmationDialog.show(context, title: user.isActive ? 'Deactivate account?' : 'Activate account?', message: user.fullName, confirmLabel: user.isActive ? 'Deactivate' : 'Activate', destructive: user.isActive, icon: Icons.person_off_outlined);
    if (!ok || !context.mounted) return;
    try {
      await context.read<AdminRepository>().setUserActive(user.id, !user.isActive);
      if (context.mounted) Helpers.showSnackBar(context, 'Account updated.');
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _delete(BuildContext context, UserModel user) async {
    final navigator = Navigator.of(context);
    final ok = await ConfirmationDialog.show(context, title: 'Delete account?', message: 'Delete ${user.fullName}?', confirmLabel: 'Delete', destructive: true, icon: Icons.delete_outline);
    if (!ok || !context.mounted) return;
    try {
      await context.read<AdminRepository>().deleteUser(user.id);
      if (context.mounted) Helpers.showSnackBar(context, 'Account deleted.');
      navigator.pop();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }
}

class _UserDetailsData {
  const _UserDetailsData(this.user, this.departments);
  final UserModel? user;
  final List<DepartmentModel> departments;
}


