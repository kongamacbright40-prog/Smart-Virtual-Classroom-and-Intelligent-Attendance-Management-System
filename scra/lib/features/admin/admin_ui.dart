import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_colors.dart';
import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/features/authentication/providers/auth_provider.dart';
import 'package:smart_class/widgets/common/app_bar.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/common/user_avatar.dart';
import 'package:smart_class/widgets/navigation/role_shell.dart';

const adminGap = SizedBox(height: AppDimensions.spaceMd);
const adminSmallGap = SizedBox(height: AppDimensions.spaceSm);

class AdminScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const AdminScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> actions;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null ? kToolbarHeight : 68);

  @override
  Widget build(BuildContext context) {
    return SmartAppBar(
      title: title,
      subtitle: subtitle,
      showBack: showBack,
      leading: showBack
          ? null
          : IconButton(
              key: const Key('admin_menu'),
              tooltip: 'Menu',
              icon: const Icon(Icons.menu),
              onPressed: () => ShellScope.openDrawer(context),
            ),
      actions: [
        ...actions,
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(Icons.account_circle),
          onPressed: () =>
              Navigator.of(context).pushNamed(RouteNames.adminProfile),
        ),
      ],
    );
  }
}

class AdminHeroCard extends StatelessWidget {
  const AdminHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.icon = Icons.school_outlined,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppDimensions.spaceXs),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppDimensions.spaceSm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null)
                Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Flexible(child: trailing!),
        ],
      ],
    );
  }
}

class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryFixed,
          foregroundColor: theme.colorScheme.primary,
          child: Icon(icon, size: 20),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing,
      ),
    );
  }
}

String adminRoleLabel(dynamic role) {
  final text = role.toString().split('.').last;
  return text[0].toUpperCase() + text.substring(1);
}

StatusTone adminStatusTone(bool active) =>
    active ? StatusTone.success : StatusTone.neutral;

String adminDate(DateTime? value) =>
    value == null ? '—' : Formatters.date(value);

UserAvatar adminCurrentAvatar(BuildContext context, {double size = 36}) {
  final user = context.watch<AuthProvider>().user;
  return UserAvatar(
    name: user?.fullName ?? 'Admin',
    imageUrl: user?.avatarUrl,
    size: size,
  );
}

/// Two-column grid whose rows size to their content (no fixed aspect ratio),
/// so cards never overflow with larger text or on small phones.
class AdminGrid extends StatelessWidget {
  const AdminGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.spacing = AppDimensions.spaceSm,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) cells.add(SizedBox(width: spacing));
        final index = i + c;
        cells.add(
          Expanded(
            child: index < children.length ? children[index] : const SizedBox(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
