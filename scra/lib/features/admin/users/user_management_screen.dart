
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/features/admin/users/widgets/user_list_item.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/buttons/primary_button.dart';
import 'package:smart_class/widgets/buttons/secondary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/empty_state.dart';
import 'package:smart_class/widgets/dialogs/confirmation_dialog.dart';
import 'package:smart_class/widgets/inputs/search_field.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _query = '';
  UserRole? _role;
  bool _activeOnly = false;

  Future<_UsersData> _load(BuildContext context) async {
    final repo = context.read<AdminRepository>();
    final all = await repo.getUsers();
    final users = await repo.getUsers(role: _role, query: _query);
    return _UsersData(all, users);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AdminScreenHeader(
        title: 'User Management',
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => Helpers.showSnackBar(context, 'User export queued.'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_user'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add User'),
        onPressed: () => Navigator.of(context).pushNamed(RouteNames.userDetails).then((_) => setState(() {})),
      ),
      body: AsyncView<_UsersData>(
        key: ValueKey('users-$_query-${_role?.name}-$_activeOnly'),
        load: () => _load(context),
        builder: (context, data, reload) {
          final users = data.users.where((u) => !_activeOnly || u.isActive).toList();
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _Summary(all: data.all),
                const SizedBox(height: AppDimensions.spaceMd),
                SearchField(
                  hint: 'Search by name, ID, or email...',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _roleChip('All (${data.all.length})', null),
                      _roleChip('Students (${data.count(UserRole.student)})', UserRole.student),
                      _roleChip('Lecturers (${data.count(UserRole.lecturer)})', UserRole.lecturer),
                      _roleChip('Admins (${data.count(UserRole.admin)})', UserRole.admin),
                      const SizedBox(width: AppDimensions.spaceSm),
                      FilterChip(
                        key: const Key('active_only_filter'),
                        label: const Text('Active Only'),
                        selected: _activeOnly,
                        onSelected: (v) => setState(() => _activeOnly = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                if (users.isEmpty)
                  EmptyState(
                    title: 'No matching users',
                    message: 'Try another search or filter.',
                    actionLabel: 'Reset Filters',
                    onAction: () => setState(() { _query = ''; _role = null; _activeOnly = false; }),
                  )
                else
                  for (final user in users)
                    UserListItem(
                      user: user,
                      identifier: _identifier(user),
                      onEdit: () => Navigator.of(context).pushNamed(RouteNames.userDetails, arguments: user.id).then((_) => setState(() {})),
                      onResetPassword: () => Helpers.showSnackBar(context, 'Password reset link sent to ${user.email}.'),
                      onToggleActive: () => _toggleUser(user, reload),
                      onDelete: () => _deleteUser(user, reload),
                    ),
                Center(child: Text('Showing ${users.length} of ${data.all.length} verified accounts')),
                const SizedBox(height: AppDimensions.spaceMd),
                SecondaryButton(label: 'Load More Users', icon: Icons.sync, onPressed: () => Helpers.showSnackBar(context, 'All demo users loaded.')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _roleChip(String label, UserRole? role) => Padding(
        padding: const EdgeInsets.only(right: AppDimensions.spaceSm),
        child: ChoiceChip(label: Text(label), selected: _role == role, onSelected: (_) => setState(() => _role = role)),
      );

  String _identifier(UserModel user) {
    return switch (user.role) {
      UserRole.student => user.id.toUpperCase().replaceFirst('STU-', 'ICT'),
      UserRole.lecturer => user.id.toUpperCase().replaceFirst('LEC-', 'FAC-'),
      UserRole.admin => user.id.toUpperCase().replaceFirst('ADM-', 'ADM-'),
    };
  }

  Future<void> _toggleUser(UserModel user, Future<void> Function() reload) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: user.isActive ? 'Deactivate user?' : 'Activate user?',
      message: '${user.fullName} will be ${user.isActive ? 'deactivated' : 'activated'}.',
      confirmLabel: user.isActive ? 'Deactivate' : 'Activate',
      destructive: user.isActive,
      icon: user.isActive ? Icons.person_off_outlined : Icons.check_circle_outline,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<AdminRepository>().setUserActive(user.id, !user.isActive);
      if (mounted) Helpers.showSnackBar(context, 'User updated.');
      await reload();
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _deleteUser(UserModel user, Future<void> Function() reload) async {
    final ok = await ConfirmationDialog.show(context, title: 'Delete user?', message: 'Delete ${user.fullName}?', confirmLabel: 'Delete', destructive: true, icon: Icons.delete_outline);
    if (!ok || !mounted) return;
    try {
      await context.read<AdminRepository>().deleteUser(user.id);
      if (mounted) Helpers.showSnackBar(context, 'User deleted.');
      await reload();
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    }
  }
}

class _UsersData {
  const _UsersData(this.all, this.users);
  final List<UserModel> all;
  final List<UserModel> users;
  int count(UserRole role) => all.where((u) => u.role == role).length;
}

class _Summary extends StatelessWidget {
  const _Summary({required this.all});
  final List<UserModel> all;

  @override
  Widget build(BuildContext context) {
    final active = all.where((u) => u.isActive).length;
    final percent = all.isEmpty ? 0 : active / all.length * 100;
    return AppCard(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          const Icon(Icons.circle, size: 10),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(child: Text('${all.length} Accounts ? ${percent.toStringAsFixed(1)}% Active')),
          PrimaryButton(label: 'Export', icon: Icons.file_download_outlined, expanded: false, onPressed: () => Helpers.showSnackBar(context, 'Export queued.')),
        ],
      ),
    );
  }
}
