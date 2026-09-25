import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/features/admin/dashboard/widgets/admin_activity_item.dart';
import 'package:smart_class/features/admin/dashboard/widgets/admin_statistic_card.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/buttons/secondary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/navigation/role_shell.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AdminScreenHeader(
        title: 'Dashboard',
        subtitle: 'Administration',
        actions: [
          IconButton(
            key: const Key('dashboard_settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                ShellScope.maybeOf(context)?.selectTab(AdminTabs.settings),
          ),
        ],
      ),
      scrollable: true,
      body: AsyncView<_DashboardData>(
        load: () async {
          final reports = context.read<ReportRepository>();
          final admin = context.read<AdminRepository>();
          return _DashboardData(
            await reports.getAdminDashboard(),
            await admin.getRecentActivity(limit: 5),
          );
        },
        builder: (context, data, reload) => RefreshIndicator(
          onRefresh: reload,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 10),
                    const SizedBox(width: AppDimensions.spaceSm),
                    const Expanded(
                      child: Text(
                        'Telemetry & Campus Cloud Active\nAcademic Year 2026/2027 • Semester 2',
                      ),
                    ),
                    StatusChip(
                      label: 'Synced',
                      tone: StatusTone.live,
                      icon: Icons.cloud_done_outlined,
                    ),
                  ],
                ),
              ),
              adminGap,
              AdminHeroCard(
                title: 'Academic Nexus Cockpit',
                subtitle:
                    '${Formatters.compactNumber(data.report.metric('total_staff'))} Faculty Members currently deployed across active lecture modules.',
                trailing: StatusChip(
                  label: 'Term Wk ${data.report.metric('term_week').round()}',
                  tone: StatusTone.primary,
                ),
              ),
              adminGap,
              AdminGrid(
                children: [
                  AdminStatisticCard(
                    icon: Icons.school_outlined,
                    value: Formatters.compactNumber(
                      data.report.metric('total_students'),
                    ),
                    label: 'Total Students',
                    helper:
                        '${data.report.metric('registered_rate').round()}% registered',
                    badge: '+${data.report.metric('new_students').round()} new',
                  ),
                  AdminStatisticCard(
                    icon: Icons.sensors_outlined,
                    value: data.report
                        .metric('active_classes')
                        .round()
                        .toString(),
                    label: 'Active Classes',
                    helper: 'Halls A, B & Labs',
                    badge: 'Live',
                    tone: StatusTone.live,
                  ),
                  AdminStatisticCard(
                    icon: Icons.badge_outlined,
                    value: data.report
                        .metric('on_campus_staff')
                        .round()
                        .toString(),
                    label: 'On-Campus Staff',
                    helper:
                        '${data.report.metric('remote_staff').round()} virtual/remote',
                    badge: '${data.report.metric('total_staff').round()} Staff',
                  ),
                  AdminStatisticCard(
                    icon: Icons.fact_check_outlined,
                    value: Formatters.percent(
                      data.report.metric('avg_attendance'),
                      decimals: 1,
                    ),
                    label: 'Avg Attendance',
                    helper:
                        'Target: >=${Formatters.percent(data.report.metric('attendance_target'), decimals: 1)}',
                    badge:
                        '+${data.report.metric('attendance_change').toStringAsFixed(1)}% w/w',
                  ),
                ],
              ),
              adminGap,
              const AdminSectionTitle(
                title: 'Administrative Actions',
                trailing: Text('FAST ACCESS'),
              ),
              adminSmallGap,
              AdminGrid(
                children: [
                  _ActionCard(
                    icon: Icons.person_add_alt_1,
                    title: 'Add User',
                    subtitle: 'Enroll student or faculty',
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteNames.userDetails),
                  ),
                  _ActionCard(
                    icon: Icons.create_new_folder_outlined,
                    title: 'Create Course',
                    subtitle: 'New syllabus & credit',
                    onTap: () =>
                        ShellScope.maybeOf(context)
                            ?.selectTab(AdminTabs.courses),
                  ),
                  _ActionCard(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Assign Lecturer',
                    subtitle: 'Course-faculty mapping',
                    onTap: () =>
                        ShellScope.maybeOf(context)
                            ?.selectTab(AdminTabs.courses),
                  ),
                  _ActionCard(
                    icon: Icons.domain_outlined,
                    title: 'Departments',
                    subtitle: 'Campus structure',
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteNames.departments),
                  ),
                  _ActionCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Academic Terms',
                    subtitle: 'Semester control',
                    onTap: () =>
                        Navigator.of(context)
                            .pushNamed(RouteNames.academicTerms),
                  ),
                  _ActionCard(
                    icon: Icons.query_stats_outlined,
                    title: 'Reports',
                    subtitle: 'Compliance & exports',
                    onTap: () =>
                        Navigator.of(context)
                            .pushNamed(RouteNames.adminReports),
                  ),
                ],
              ),
              adminGap,
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle(
                      title: 'Recent Activity',
                      subtitle: 'Administrative audit feed',
                    ),
                    for (final activity in data.activity)
                      AdminActivityItem(activity: activity),
                  ],
                ),
              ),
              adminGap,
              AppCard(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth_connected_outlined),
                    const SizedBox(width: AppDimensions.spaceMd),
                    const Expanded(
                      child: Text(
                        'Infrastructure Verified\n12/12 BLE Gateways Online • Audit Log Active',
                      ),
                    ),
                    SecondaryButton(
                      label: 'View',
                      expanded: false,
                      onPressed: () =>
                          Navigator.of(context)
                              .pushNamed(RouteNames.adminReports),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData(this.report, this.activity);
  final ReportModel report;
  final List<ActivityLogModel> activity;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
