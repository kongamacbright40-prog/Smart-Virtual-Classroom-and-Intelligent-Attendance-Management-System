import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/features/admin/reports/widgets/analytics_card.dart';
import 'package:smart_class/features/admin/reports/widgets/analytics_chart.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/buttons/primary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/inputs/app_dropdown.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String? _departmentId;
  bool _weekly = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AdminScreenHeader(
        title: 'Institution Reports',
        showBack: true,
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _export(context, null),
          ),
        ],
      ),
      body: AsyncView<_ReportsData>(
        key: ValueKey('reports-$_departmentId'),
        load: () async {
          final adminRepo = context.read<AdminRepository>();
          final reportRepo = context.read<ReportRepository>();
          final terms = await adminRepo.getAcademicTerms();
          return _ReportsData(
            await reportRepo.getInstitutionReport(departmentId: _departmentId),
            await adminRepo.getDepartments(),
            terms.where((t) => t.status == TermStatus.active).firstOrNull,
            await adminRepo.getSystemSettings(),
          );
        },
        builder: (context, data, reload) {
          final facultyRows = data.report.breakdown
              .where((b) => b.meta['type'] != 'course')
              .toList();
          final courseRows = data.report.breakdown
              .where((b) => b.meta['type'] == 'course')
              .toList();
          final selectedDept =
              data.departments.where((d) => d.id == _departmentId).isEmpty
              ? null
              : data.departments.firstWhere((d) => d.id == _departmentId);
          final target = data.report.metric(
            'target',
            data.settings.minimumAttendance,
          );
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              children: [
                AdminHeroCard(
                  title: 'Institutional Analytics',
                  subtitle:
                      data.activeTerm?.name ??
                      '${Formatters.date(data.report.periodStart)} • ${Formatters.date(data.report.periodEnd)}',
                  icon: Icons.domain_verification_outlined,
                  trailing: StatusChip(label: 'Updated', tone: StatusTone.live),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                PrimaryButton(
                  key: const Key('export_report'),
                  label: 'Export Report',
                  icon: Icons.download_outlined,
                  onPressed: () => _export(context, data.report),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                Wrap(
                  spacing: AppDimensions.spaceSm,
                  runSpacing: AppDimensions.spaceSm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('This Term'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    ChoiceChip(
                      label: const Text('Custom Range'),
                      selected: false,
                      onSelected: null,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppDropdown<DepartmentModel>(
                  label: 'Department',
                  hint: 'All',
                  value: selectedDept,
                  items: data.departments,
                  onChanged: (d) => setState(() => _departmentId = d?.id),
                  itemLabel: (d) => d.name,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AdminGrid(
                  children: [
                    AnalyticsCard(
                      title: 'Overall Rate',
                      value: Formatters.percent(
                        data.report.metric('overall_rate'),
                        decimals: 1,
                      ),
                      icon: Icons.school_outlined,
                      badge:
                          '+${data.report.metric('rate_change').toStringAsFixed(1)}%',
                      tone: StatusTone.success,
                    ),
                    AnalyticsCard(
                      title: 'Sessions',
                      value: Formatters.compactNumber(
                        data.report.metric('sessions'),
                      ),
                      icon: Icons.verified_outlined,
                      badge:
                          '${data.report.metric('sync_rate').toStringAsFixed(1)}%',
                      tone: StatusTone.live,
                    ),
                    AnalyticsCard(
                      title:
                          'At-Risk (<${Formatters.percent(target, decimals: 0)})',
                      value: data.report.metric('at_risk').round().toString(),
                      icon: Icons.warning_amber_outlined,
                      badge: 'Action',
                      tone: StatusTone.warning,
                    ),
                    AnalyticsCard(
                      title: 'Sync',
                      value:
                          '${data.report.metric('sync_rate').toStringAsFixed(1)}%',
                      icon: Icons.cloud_done_outlined,
                      tone: StatusTone.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminSectionTitle(
                        title: 'Attendance Trend',
                        subtitle: 'Weekly percentage progression',
                        trailing: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Weekly')),
                            ButtonSegment(value: false, label: Text('Monthly')),
                          ],
                          selected: {_weekly},
                          onSelectionChanged: (s) =>
                              setState(() => _weekly = s.first),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),
                      const Wrap(
                        spacing: AppDimensions.spaceMd,
                        children: [
                          Text('● Current term'),
                          Text('— Previous term'),
                        ],
                      ),
                      AnalyticsChart(
                        current: data.report.trend,
                        previous: data.report.previousTrend,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminSectionTitle(
                        title: 'Attendance by Faculty',
                        subtitle:
                            'Benchmark threshold: ${Formatters.percent(target, decimals: 0)} requirement',
                        trailing: Text(
                          '${Formatters.percent(target, decimals: 0)} Goal',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),
                      for (final row in facultyRows)
                        _FacultyBar(row: row, target: target),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AdminSectionTitle(
                  title: 'Course Attendance',
                  subtitle: '(${courseRows.length} Courses)',
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                for (final row in courseRows.take(6))
                  _CourseReportRow(row: row, target: target),
                const SizedBox(height: AppDimensions.spaceMd),
                PrimaryButton(
                  label: 'Export Report',
                  icon: Icons.download_outlined,
                  onPressed: () => _export(context, data.report),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _export(BuildContext context, ReportModel? report) async {
    final actualReport =
        report ??
        await context.read<ReportRepository>().getInstitutionReport(
          departmentId: _departmentId,
        );
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ExportSheet(report: actualReport),
    );
  }
}

class _ReportsData {
  const _ReportsData(
    this.report,
    this.departments,
    this.activeTerm,
    this.settings,
  );
  final ReportModel report;
  final List<DepartmentModel> departments;
  final AcademicTermModel? activeTerm;
  final SystemSettingsModel settings;
}

class _FacultyBar extends StatelessWidget {
  const _FacultyBar({required this.row, required this.target});
  final ReportBreakdown row;
  final double target;

  @override
  Widget build(BuildContext context) {
    final below = row.value < target;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${row.value.toStringAsFixed(1)}%${below ? ' • Below target' : ''}',
                style: TextStyle(
                  color: below
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          LinearProgressIndicator(
            value: row.value / 100,
            color: below
                ? Colors.orange
                : Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _CourseReportRow extends StatelessWidget {
  const _CourseReportRow({required this.row, required this.target});
  final ReportBreakdown row;
  final double target;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CodeTag(row.label),
              const Spacer(),
              StatusChip(
                label: '${row.value.toStringAsFixed(1)}%',
                tone: row.value < target
                    ? StatusTone.warning
                    : StatusTone.success,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            row.subtitle ?? row.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(row.meta['lecturer'] ?? 'Unassigned'),
          const SizedBox(height: AppDimensions.spaceSm),
          Wrap(
            spacing: AppDimensions.spaceMd,
            children: [
              if (row.meta['students'] != null)
                Text('${row.meta['students']} Students Enrolled'),
              if (row.meta['sessions'] != null)
                Text('${row.meta['sessions']} Sessions'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.report});
  final ReportModel report;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  ReportFormat _format = ReportFormat.pdf;
  bool _matricule = true;
  bool _geo = true;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.spaceMd,
          right: AppDimensions.spaceMd,
          bottom:
              MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spaceMd,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionTitle(
                title: 'Export Institution Report',
                subtitle:
                    'Select your preferred format & options for ${widget.report.title}',
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              for (final format in ReportFormat.values)
                ListTile(
                  onTap: () => setState(() => _format = format),
                  leading: Icon(
                    _format == format
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(format.label),
                ),
              CheckboxListTile(
                value: _matricule,
                onChanged: (v) => setState(() => _matricule = v ?? _matricule),
                title: const Text('Include Student Matricule IDs'),
              ),
              CheckboxListTile(
                value: _geo,
                onChanged: (v) => setState(() => _geo = v ?? _geo),
                title: const Text('Include Lecturer Geolocation & Timestamps'),
              ),
              PrimaryButton(
                label: 'Export File',
                icon: Icons.file_download_outlined,
                isLoading: _exporting,
                onPressed: _doExport,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doExport() async {
    setState(() => _exporting = true);
    try {
      final file = await context.read<ReportRepository>().exportReport(
        widget.report.id,
        format: _format,
        includeMatricule: _matricule,
        includeGeolocation: _geo,
      );
      if (mounted) {
        Helpers.showSnackBar(context, 'Export ready: $file');
        Navigator.pop(context);
      }
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
