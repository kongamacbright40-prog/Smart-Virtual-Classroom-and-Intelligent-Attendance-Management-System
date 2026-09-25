import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/route_names.dart';
import '../../features/admin/courses/course_management_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/settings/admin_settings_screen.dart';
import '../../features/admin/users/user_management_screen.dart';
import '../../features/authentication/providers/auth_provider.dart';
import '../common/app_logo.dart';
import '../dialogs/logout_dialog.dart';
import 'role_shell.dart';

/// Admin bottom navigation: Dashboard • Users • Courses • Settings, plus a
/// navigation drawer (the `menu` icon in the Stitch admin headers) for the
/// remaining administrative sections.
class AdminNavigation extends StatelessWidget {
  const AdminNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      initialIndex: initialIndex,
      drawer: const AdminDrawer(),
      destinations: [
        ShellDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          builder: (_) => const AdminDashboardScreen(),
        ),
        ShellDestination(
          label: 'Users',
          icon: Icons.group_outlined,
          selectedIcon: Icons.group,
          builder: (_) => const UserManagementScreen(),
        ),
        ShellDestination(
          label: 'Courses',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          builder: (_) => const CourseManagementScreen(),
        ),
        ShellDestination(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          builder: (_) => const AdminSettingsScreen(),
        ),
      ],
    );
  }
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final shell = ShellScope.maybeOf(context);

    void tab(int index) {
      Navigator.of(context).pop();
      shell?.selectTab(index);
    }

    void push(String route) {
      Navigator.of(context)
        ..pop()
        ..pushNamed(route);
    }

    return NavigationDrawer(
      selectedIndex: null,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceLg,
            AppDimensions.spaceLg,
            AppDimensions.spaceMd,
            AppDimensions.spaceMd,
          ),
          child: BrandHeader(subtitle: user?.fullName ?? 'Administration'),
        ),
        const Divider(),
        _item(context, Icons.dashboard_outlined, 'Dashboard',
            () => tab(AdminTabs.dashboard)),
        _item(context, Icons.group_outlined, 'User Management',
            () => tab(AdminTabs.users)),
        _item(context, Icons.domain_outlined, 'Departments & Faculties',
            () => push(RouteNames.departments)),
        _item(context, Icons.calendar_month_outlined, 'Academic Terms',
            () => push(RouteNames.academicTerms)),
        _item(context, Icons.menu_book_outlined, 'Course Management',
            () => tab(AdminTabs.courses)),
        _item(context, Icons.analytics_outlined, 'Reports & Analytics',
            () => push(RouteNames.adminReports)),
        _item(context, Icons.settings_outlined, 'System Settings',
            () => tab(AdminTabs.settings)),
        _item(context, Icons.admin_panel_settings_outlined, 'Admin Profile',
            () => push(RouteNames.adminProfile)),
        const Divider(),
        _item(context, Icons.logout, AppStrings.logout, () {
          final navigatorContext = Navigator.of(context).context;
          Navigator.of(context).pop();
          confirmAndLogout(navigatorContext, loginRoute: RouteNames.adminLogin);
        }, color: theme.colorScheme.error),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: color == null ? null : TextStyle(color: color)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLg),
      onTap: onTap,
    );
  }
}
