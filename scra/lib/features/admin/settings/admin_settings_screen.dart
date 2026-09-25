
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
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
      body: AsyncView<SystemSettingsModel>(
        load: () => context.read<AdminRepository>().getSystemSettings(),
        builder: (context, settings, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            children: [
              AdminHeroCard(title: 'Institutional Governance', subtitle: 'Global configurations for Fall Semester 2026', icon: Icons.cloud_done_outlined, trailing: StatusChip(label: 'Synced', tone: StatusTone.live)),
              const SizedBox(height: AppDimensions.spaceMd),
              _Section(
                title: 'Academic Configuration',
                trailing: '3 Modules',
                children: [
                  AdminInfoRow(icon: Icons.domain_outlined, title: 'Manage Departments & Faculties', subtitle: '4 faculties, 18 departments active', trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).pushNamed(RouteNames.departments)),
                  AdminInfoRow(icon: Icons.calendar_month_outlined, title: 'Academic Terms & Semesters', subtitle: 'Fall Semester 2026 active • Enrollment open', trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.of(context).pushNamed(RouteNames.academicTerms)),
                  AdminInfoRow(icon: Icons.pie_chart_outline, title: 'Course Allocation & Faculty Quota', subtitle: 'Automatic capacity & assignment limits', trailing: const Icon(Icons.chevron_right), onTap: () => ShellScope.maybeOf(context)?.selectTab(AdminTabs.courses)),
                ],
              ),
              _Section(
                title: 'Attendance Policies & Algorithms',
                trailing: '4 Rules',
                children: [
                  AdminInfoRow(icon: Icons.timelapse_outlined, title: 'Late Arrival Threshold', subtitle: 'Mark late after ${settings.lateThresholdMinutes} minutes of class start', trailing: StatusChip(label: '${settings.lateThresholdMinutes} mins', tone: StatusTone.primary, icon: Icons.tune, dense: true), onTap: () => _threshold(context, settings, reload)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.sensors_outlined),
                    title: const Text('Automatic Join / Leave Recording'),
                    subtitle: const Text('Automate logs with WebRTC telemetry'),
                    value: settings.autoJoinLeaveRecording,
                    onChanged: (v) => _save(context, settings.copyWith(autoJoinLeaveRecording: v), reload),
                  ),
                  AdminInfoRow(icon: Icons.forum_outlined, title: 'Participation Weighting', subtitle: 'Live Q&A and chat: ${settings.participationWeight}% score weight', trailing: StatusChip(label: '${settings.participationWeight}% Weight', tone: StatusTone.neutral, icon: Icons.edit_outlined, dense: true), onTap: () => _participation(context, settings, reload)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.location_on_outlined),
                    title: const Text('Enforce Strict Geofencing'),
                    subtitle: const Text('Verify student location on campus'),
                    value: settings.strictGeofencing,
                    onChanged: (v) => _save(context, settings.copyWith(strictGeofencing: v), reload),
                  ),
                ],
              ),
              _Section(
                title: 'Security & Access Control',
                trailing: 'SSO Active',
                children: [
                  const AdminInfoRow(icon: Icons.badge_outlined, title: 'Role Permissions & Access Matrix', subtitle: 'Super Admin, Faculty Dean, Lecturer, Student', trailing: Icon(Icons.chevron_right)),
                  const AdminInfoRow(icon: Icons.receipt_long_outlined, title: 'Audit Logs & Compliance', subtitle: 'Immutable tamper-proof activity ledger', trailing: Icon(Icons.chevron_right)),
                  AdminInfoRow(icon: Icons.timer_off_outlined, title: 'Session Inactivity Timeout', subtitle: 'Force re-authentication after idle duration', trailing: StatusChip(label: '${settings.sessionTimeoutMinutes} mins', tone: StatusTone.neutral, dense: true)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.vpn_key_outlined),
                    title: const Text('Enforce Institutional SSO (SAML 2.0)'),
                    subtitle: const Text('Mandate university single sign-on'),
                    value: settings.enforceSso,
                    onChanged: (v) => _save(context, settings.copyWith(enforceSso: v), reload),
                  ),
                ],
              ),
              _Section(
                title: 'Integrations & Infrastructure',
                trailing: 'All Systems Nominal',
                children: const [
                  AdminInfoRow(icon: Icons.podcasts_outlined, title: 'WebRTC Media Server Cluster', subtitle: 'eu-central-webrtc-01 • 12ms latency', trailing: Text('Healthy')),
                  AdminInfoRow(icon: Icons.sync, title: 'PostgreSQL & SIS Registrar Sync', subtitle: 'Automated 6-hour bidirectional sync', trailing: Text('Synced 18m ago')),
                  AdminInfoRow(icon: Icons.cloud_queue_outlined, title: 'Cloud Storage & Archives', subtitle: 'AWS S3: 842 GB used of 2 TB allocation', trailing: Icon(Icons.chevron_right)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, SystemSettingsModel settings, Future<void> Function() reload) async {
    try {
      await context.read<AdminRepository>().updateSystemSettings(settings);
      if (context.mounted) Helpers.showSnackBar(context, 'Settings saved.');
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _threshold(BuildContext context, SystemSettingsModel settings, Future<void> Function() reload) async {
    var selected = settings.lateThresholdMinutes;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminSectionTitle(title: 'Late Arrival Threshold', subtitle: 'Students joining after this grace period receive a LATE mark.'),
              const SizedBox(height: AppDimensions.spaceMd),
              Wrap(spacing: AppDimensions.spaceSm, children: [for (final m in const [5, 10, 15, 20, 30]) ChoiceChip(label: Text('${m}m'), selected: selected == m, onSelected: (_) => setSheetState(() => selected = m))]),
              const SizedBox(height: AppDimensions.spaceMd),
              Text('Selected Policy: $selected Minutes Grace Period'),
              const SizedBox(height: AppDimensions.spaceMd),
              PrimaryButton(key: const Key('save_threshold'), label: 'Save Threshold', icon: Icons.check, onPressed: () async { Navigator.pop(sheetContext); await _save(context, settings.copyWith(lateThresholdMinutes: selected), reload); }),
            ],
          ),
        ),
      )),
    );
  }

  Future<void> _participation(BuildContext context, SystemSettingsModel settings, Future<void> Function() reload) async {
    final controller = TextEditingController(text: settings.participationWeight.toString());
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Participation Weight'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: (value) {
            final number = int.tryParse(value ?? '');
            if (number == null || number < 0 || number > 100) return 'Enter 0–100';
            return null;
          },
          decoration: const InputDecoration(labelText: 'Weight (%)'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(onPressed: () async { if (!formKey.currentState!.validate()) return; Navigator.pop(dialogContext); await _save(context, settings.copyWith(participationWeight: int.parse(controller.text)), reload); }, child: const Text('Save')),
      ],
    ));
    controller.dispose();
  }
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
          AdminSectionTitle(title: title, trailing: trailing == null ? null : Text(trailing!)),
          const SizedBox(height: AppDimensions.spaceSm),
          AppCard(child: Column(children: children)),
        ],
      ),
    );
  }
}
