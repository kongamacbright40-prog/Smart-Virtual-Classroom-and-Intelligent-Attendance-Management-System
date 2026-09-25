import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/inputs/app_dropdown.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../authentication/providers/auth_provider.dart';
import 'widgets/attendance_history_item.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  AttendanceStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final studentId = context.watch<AuthProvider>().user!.id;
    return AsyncView<_AttendanceData>(
      load: () => _AttendanceData.load(context, studentId),
      builder: (context, data, reload) {
        final records = data.records
            .where((r) => _filter == null || r.status == _filter)
            .toList();
        return AppScaffold(
          appBar: SmartAppBar(
            title: 'My Attendance',
            subtitle: _studentSubtitle(data.student),
            showBack: false,
          ),
          scrollable: true,
          onRefresh: reload,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryCard(summary: data.summary),
              const SizedBox(height: AppDimensions.spaceMd),
              _CountsRow(summary: data.summary),
              const SizedBox(height: AppDimensions.spaceMd),
              if (data.summary.participationRate != null) ...[
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spaceMd),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: const Icon(Icons.bolt, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppDimensions.spaceMd),
                      Expanded(
                        child: Text(
                          'Live Quiz & Poll Presence',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        Formatters.percent(data.summary.participationRate!),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
              ] else
                const SizedBox(height: AppDimensions.spaceLg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Logs',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Chip(label: Text('${data.records.length} total')),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Wrap(
                spacing: AppDimensions.spaceSm,
                runSpacing: AppDimensions.spaceSm,
                children: [
                  ChoiceChip(
                    label: Text('All Logs (${data.records.length})'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  for (final status in [
                    AttendanceStatus.present,
                    AttendanceStatus.late,
                    AttendanceStatus.absent,
                  ])
                    ChoiceChip(
                      label: Text(
                        '${status.label} (${data.records.where((r) => r.status == status).length})',
                      ),
                      selected: _filter == status,
                      onSelected: (_) => setState(() => _filter = status),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              if (records.isEmpty)
                const EmptyState(title: 'No attendance logs', compact: true)
              else
                for (final record in records) ...[
                  AttendanceHistoryItem(
                    record: record,
                    onAppeal: record.status == AttendanceStatus.absent
                        ? () => _showAppealSheet(context, record, reload)
                        : null,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAppealSheet(
    BuildContext context,
    AttendanceRecordModel record,
    Future<void> Function() reload,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AppealSheet(record: record),
    );
    if (result == true && context.mounted) {
      Helpers.showSnackBar(context, 'Review request submitted');
      await reload();
    }
  }

  String? _studentSubtitle(StudentModel student) {
    final parts = [
      if (student.programme.trim().isNotEmpty) student.programme.trim(),
      'Level ${student.level}',
    ];
    return parts.join(' • ');
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final AttendanceModel summary;

  @override
  Widget build(BuildContext context) {
    final percent = summary.percentage;
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 10,
                    color: Helpers.attendanceColor(percent),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.percent(percent),
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text('Aggregate', style: theme.textTheme.labelMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(
                  label: summary.meetsRequirement ? 'GOOD STANDING' : 'AT RISK',
                  tone: summary.meetsRequirement
                      ? StatusTone.success
                      : StatusTone.error,
                  icon: Icons.verified,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  summary.meetsRequirement
                      ? 'Exceeds Requirement'
                      : 'Below Requirement',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'Minimum ${summary.requiredPercentage.round()}% needed for exam sitting eligibility.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDimensions.spaceSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountsRow extends StatelessWidget {
  const _CountsRow({required this.summary});

  final AttendanceModel summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CountTile(
            label: 'PRESENT',
            value: '${summary.presentCount}',
            detail: 'lectures',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: _CountTile(
            label: 'LATE',
            value: '${summary.lateCount}',
            detail: 'sessions',
            color: AppColors.live,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: _CountTile(
            label: 'ABSENT',
            value: '${summary.absentCount}',
            detail: 'missed',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.labelSmall)),
              Icon(Icons.circle, size: 10, color: color),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(value, style: theme.textTheme.headlineSmall),
          Text(detail, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AppealSheet extends StatefulWidget {
  const _AppealSheet({required this.record});

  final AttendanceRecordModel record;

  @override
  State<_AppealSheet> createState() => _AppealSheetState();
}

class _AppealSheetState extends State<_AppealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _document = TextEditingController();
  String? _reason = 'Medical Condition';
  bool _submitting = false;

  @override
  void dispose() {
    _document.dispose();
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Attendance Review',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              '${widget.record.courseCode} • ${Formatters.date(widget.record.sessionStart)}',
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppDropdown<String>(
              label: 'Reason for Absence',
              items: const [
                'Medical Condition',
                'Official University Duty',
                'Other',
              ],
              value: _reason,
              onChanged: (value) => setState(() => _reason = value),
              itemLabel: (value) => value,
              validator: (value) => Validators.required(value, field: 'Reason'),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _document,
              label: 'Supporting Document',
              hint: 'Doctor note or approval file name',
              prefixIcon: Icons.cloud_upload_outlined,
              validator: (value) =>
                  Validators.required(value, field: 'Document name'),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Submit for Faculty Approval'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await context.read<AttendanceRepository>().submitAppeal(
        recordId: widget.record.id,
        reason: _reason!,
        documentName: _document.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) Helpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _AttendanceData {
  const _AttendanceData({
    required this.student,
    required this.summary,
    required this.records,
  });

  final StudentModel student;
  final AttendanceModel summary;
  final List<AttendanceRecordModel> records;

  static Future<_AttendanceData> load(
    BuildContext context,
    String studentId,
  ) async {
    final repo = context.read<AttendanceRepository>();
    final results = await Future.wait<Object>([
      context.read<UserRepository>().getStudentProfile(studentId),
      repo.getStudentSummary(studentId),
      repo.getStudentRecords(studentId),
    ]);
    return _AttendanceData(
      student: results[0] as StudentModel,
      summary: results[1] as AttendanceModel,
      records: results[2] as List<AttendanceRecordModel>,
    );
  }
}
