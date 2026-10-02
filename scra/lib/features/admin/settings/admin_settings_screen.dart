import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/buttons/primary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/navigation/role_shell.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AdminScreenHeader(title: 'System Settings'),
      body: AsyncView<_SettingsData>(
        load: () async {
          final repo = context.read<AdminRepository>();
          final (terms, settings, faculties, departments) = await (
            repo.getAcademicTerms(),
            repo.getSystemSettings(),
            repo.getFaculties(),
            repo.getDepartments(),
          ).wait;
          return _SettingsData(
            settings,
            faculties,
            departments,
            terms.where((t) => t.status == TermStatus.active).firstOrNull,
          );
        },
        builder: (context, data, reload) {
          final settings = data.settings;
          final activeTerm = data.activeTerm;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              children: [
                AdminHeroCard(
                  title: 'Institutional Governance',
                  subtitle: activeTerm == null
                      ? 'Global configurations'
                      : 'Global configurations for ${activeTerm.name}',
                  icon: Icons.cloud_done_outlined,
                  trailing: StatusChip(
                    label: settings.lastSyncedAt == null
                        ? 'Settings'
                        : 'Synced ${Formatters.timeAgo(settings.lastSyncedAt!)}',
                    tone: StatusTone.live,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                _Section(
                  title: 'Academic Configuration',
                  trailing: '${data.faculties.length} faculties',
                  children: [
                    AdminInfoRow(
                      icon: Icons.domain_outlined,
                      title: 'Manage Departments & Faculties',
                      subtitle:
                          '${data.faculties.where((f) => f.isActive).length} faculties, ${data.departments.where((d) => d.isActive).length} departments active',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context)
                              .pushNamed(RouteNames.departments),
                    ),
                    AdminInfoRow(
                      icon: Icons.calendar_month_outlined,
                      title: 'Academic Terms & Semesters',
                      subtitle: activeTerm == null
                          ? 'No active academic term'
                          : '${activeTerm.name} • Enrollment ${activeTerm.enrollmentOpen ? 'open' : 'closed'}',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context)
                              .pushNamed(RouteNames.academicTerms),
                    ),
                    AdminInfoRow(
                      icon: Icons.pie_chart_outline,
                      title: 'Course Allocation & Faculty Quota',
                      subtitle: 'Automatic capacity & assignment limits',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          ShellScope.maybeOf(context)
                              ?.selectTab(AdminTabs.courses),
                    ),
                  ],
                ),
                _Section(
                  title: 'Attendance Policies & Algorithms',
                  trailing:
                      '${Formatters.percent(settings.minimumAttendance, decimals: 0)} minimum',
                  children: [
                    AdminInfoRow(
                      icon: Icons.timelapse_outlined,
                      title: 'Late Arrival Threshold',
                      subtitle:
                          'Mark late after ${settings.lateThresholdMinutes} minutes of class start',
                      trailing: StatusChip(
                        label: '${settings.lateThresholdMinutes} mins',
                        tone: StatusTone.primary,
                        icon: Icons.tune,
                        dense: true,
                      ),
                      onTap: () => _threshold(context, settings, reload),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.sensors_outlined),
                      title: const Text('Automatic Join / Leave Recording'),
                      subtitle: const Text(
                        'Mark students present when they join a live class. '
                        'Off: lecturers mark attendance by hand.',
                      ),
                      value: settings.autoJoinLeaveRecording,
                      onChanged: (v) => _save(
                        context,
                        settings.copyWith(autoJoinLeaveRecording: v),
                        reload,
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: 'Security & Access Control',
                  children: [
                    AdminInfoRow(
                      icon: Icons.badge_outlined,
                      title: 'Roles',
                      subtitle: UserRole.values.map((r) => r.label).join(', '),
                    ),
                    AdminInfoRow(
                      key: const Key('open_activity_log'),
                      icon: Icons.receipt_long_outlined,
                      title: 'Activity Log',
                      subtitle: 'Who changed what, and when',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context)
                              .pushNamed(RouteNames.adminActivity),
                    ),
                  ],
                ),
                _Section(
                  title: 'System Metadata',
                  trailing: settings.lastSyncedAt == null
                      ? null
                      : Formatters.timeAgo(settings.lastSyncedAt!),
                  children: [
                    AdminInfoRow(
                      icon: Icons.memory_outlined,
                      title: 'Cluster Version',
                      subtitle: settings.clusterVersion,
                    ),
                    AdminInfoRow(
                      icon: Icons.sync,
                      title: 'Last Settings Sync',
                      subtitle: settings.lastSyncedAt == null
                          ? 'Not available'
                          : Formatters.date(settings.lastSyncedAt!),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    SystemSettingsModel settings,
    Future<void> Function() reload,
  ) async {
    try {
      await context.read<AdminRepository>().updateSystemSettings(settings);
      if (context.mounted) Helpers.showSnackBar(context, 'Settings saved.');
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _threshold(
    BuildContext context,
    SystemSettingsModel settings,
    Future<void> Function() reload,
  ) async {
    var selected = settings.lateThresholdMinutes;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionTitle(
                  title: 'Late Arrival Threshold',
                  subtitle: 'Students joining after this grace period receive a LATE mark.',
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                Wrap(
                  spacing: AppDimensions.spaceSm,
                  children: [
                    for (final m in const [5, 10, 15, 20, 30])
                      ChoiceChip(
                        label: Text('${m}m'),
                        selected: selected == m,
                        onSelected: (_) => setSheetState(() => selected = m),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                Text('Selected Policy: $selected Minutes Grace Period'),
                const SizedBox(height: AppDimensions.spaceMd),
                PrimaryButton(
                  key: const Key('save_threshold'),
                  label: 'Save Threshold',
                  icon: Icons.check,
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _save(
                      context,
                      settings.copyWith(lateThresholdMinutes: selected),
                      reload,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsData {
  const _SettingsData(
    this.settings,
    this.faculties,
    this.departments,
    this.activeTerm,
  );
  final SystemSettingsModel settings;
  final List<FacultyModel> faculties;
  final List<DepartmentModel> departments;
  final AcademicTermModel? activeTerm;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});
  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionTitle(
            title: title,
            trailing: trailing == null ? null : Text(trailing!),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          AppCard(child: Column(children: children)),
        ],
      ),
    );
  }
}
