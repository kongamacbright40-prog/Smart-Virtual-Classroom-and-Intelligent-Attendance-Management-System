
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/core/utils/validators.dart';
import 'package:smart_class/features/admin/academic_terms/widgets/academic_term_item.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/buttons/primary_button.dart';
import 'package:smart_class/widgets/buttons/secondary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/progress_bar.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/inputs/app_text_field.dart';

class AcademicTermsScreen extends StatelessWidget {
  const AcademicTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AdminScreenHeader(
        title: 'Academic Terms',
        showBack: true,
        actions: [IconButton(tooltip: 'New Term', icon: const Icon(Icons.add), onPressed: () => _showTermForm(context, null, () async {}))],
      ),
      body: AsyncView<List<AcademicTermModel>>(
        load: () => context.read<AdminRepository>().getAcademicTerms(),
        builder: (context, terms, reload) {
          final active = terms.where((t) => t.status == TermStatus.active).isEmpty ? terms.first : terms.firstWhere((t) => t.status == TermStatus.active);
          final archived = terms.where((t) => t.status == TermStatus.archived).toList();
          final planned = terms.where((t) => t.status == TermStatus.planned).toList();
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              children: [
                AppCard(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: const Row(children: [Icon(Icons.sync), SizedBox(width: AppDimensions.spaceSm), Expanded(child: Text('2025/2026 Academic Year • Registrar Sync Active'))]),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                _CurrentTermCard(term: active),
                const SizedBox(height: AppDimensions.spaceMd),
                _Snapshot(terms: terms),
                const SizedBox(height: AppDimensions.spaceMd),
                AdminSectionTitle(title: 'Previous Terms', trailing: Text('Archive (${archived.length})')),
                const SizedBox(height: AppDimensions.spaceSm),
                for (final term in archived) AcademicTermItem(term: term),
                const SizedBox(height: AppDimensions.spaceMd),
                const AdminSectionTitle(title: 'Upcoming Terms', trailing: Text('Planning Phase')),
                const SizedBox(height: AppDimensions.spaceSm),
                for (final term in planned) AcademicTermItem(term: term, onEdit: () => _showTermForm(context, term, reload)),
                PrimaryButton(key: const Key('new_term'), label: 'New Term', icon: Icons.add, onPressed: () => _showTermForm(context, null, reload)),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<void> _showTermForm(BuildContext context, AcademicTermModel? term, Future<void> Function() reload) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TermForm(term: term, onSaved: reload),
    );
  }
}

class _CurrentTermCard extends StatelessWidget {
  const _CurrentTermCard({required this.term});
  final AcademicTermModel term;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final elapsed = term.elapsedAt(now);
    return AppCard(
      borderColor: Theme.of(context).colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Expanded(child: Text('CURRENT SEMESTER')), StatusChip(label: 'Active', tone: StatusTone.live, showDot: true, dense: true)]),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(term.name, style: Theme.of(context).textTheme.headlineSmall),
          Wrap(spacing: AppDimensions.spaceSm, children: [CodeTag(term.code), Text('${term.totalWeeks} Weeks (${term.teachingDays ?? 0} Teaching Days)')]),
          const SizedBox(height: AppDimensions.spaceMd),
          AppCard(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Row(children: [Expanded(child: Text('Start Date\n${Formatters.date(term.startDate)}')), Expanded(child: Text('End Date\n${Formatters.date(term.endDate)}'))]),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(children: [Expanded(child: Text('Week ${term.weekAt(now)} of ${term.totalWeeks}')), Text('${(elapsed * 100).round()}% Elapsed', style: TextStyle(color: Theme.of(context).colorScheme.primary))]),
          const SizedBox(height: AppDimensions.spaceSm),
          AppProgressBar(value: elapsed),
          const SizedBox(height: AppDimensions.spaceMd),
          StatusChip(label: 'Enrollment: ${term.enrollmentOpen ? 'OPEN' : 'CLOSED'}', tone: term.enrollmentOpen ? StatusTone.live : StatusTone.neutral, icon: Icons.check_circle_outline),
          Text('Add/Drop closes ${adminDate(term.addDropDeadline)} ? ${term.enrolledStudents} Enrolled'),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(children: [Expanded(child: SecondaryButton(label: 'Configure', icon: Icons.tune, onPressed: () {})), const SizedBox(width: AppDimensions.spaceSm), Expanded(child: SecondaryButton(label: 'Deadlines', icon: Icons.event_note_outlined, onPressed: () {}))]),
        ],
      ),
    );
  }
}

class _Snapshot extends StatelessWidget {
  const _Snapshot({required this.terms});
  final List<AcademicTermModel> terms;

  @override
  Widget build(BuildContext context) {
    final active = terms.where((t) => t.status == TermStatus.active).isEmpty ? terms.first : terms.firstWhere((t) => t.status == TermStatus.active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle(title: 'Semester Snapshot', trailing: Text('Real-time Telemetry')),
        const SizedBox(height: AppDimensions.spaceSm),
        AdminGrid(children: [
            _tile(context, Icons.menu_book_outlined, active.courseCount.toString(), 'Active Courses'),
            _tile(context, Icons.account_balance_outlined, '4 Faculties', '18 Departments'),
            _tile(context, Icons.groups_outlined, Formatters.compactNumber(active.enrolledStudents), 'Registered Students'),
            _tile(context, Icons.cloud_done_outlined, '98.1%', 'Session Sync'),
          ],
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String value, String label) => AppCard(
        padding: const EdgeInsets.all(AppDimensions.spaceSm),
        child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: AppDimensions.spaceSm), Expanded(child: Text('$value\n$label', maxLines: 2, overflow: TextOverflow.ellipsis))]),
      );
}

class _TermForm extends StatefulWidget {
  const _TermForm({this.term, required this.onSaved});
  final AcademicTermModel? term;
  final Future<void> Function() onSaved;

  @override
  State<_TermForm> createState() => _TermFormState();
}

class _TermFormState extends State<_TermForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.term?.name ?? '');
  late final _code = TextEditingController(text: widget.term?.code ?? '');
  late final _year = TextEditingController(text: widget.term?.academicYear ?? '2026/2027');
  late DateTime _start = widget.term?.startDate ?? DateTime.now().add(const Duration(days: 30));
  late DateTime _end = widget.term?.endDate ?? DateTime.now().add(const Duration(days: 130));
  bool _saving = false;

  @override
  void dispose() { _name.dispose(); _code.dispose(); _year.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: AppDimensions.spaceMd, right: AppDimensions.spaceMd, bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spaceMd),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminSectionTitle(title: widget.term == null ? 'New Term' : 'Edit Planning'),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(controller: _name, label: 'Name', isRequired: true, validator: (v) => Validators.required(v, field: 'Name')),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(controller: _code, label: 'Code', isRequired: true, validator: (v) => Validators.required(v, field: 'Code')),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(controller: _year, label: 'Academic year', isRequired: true, validator: (v) => Validators.required(v, field: 'Academic year')),
                const SizedBox(height: AppDimensions.spaceMd),
                Row(children: [Expanded(child: SecondaryButton(label: 'Start: ${Formatters.date(_start)}', onPressed: () => _pick(true))), const SizedBox(width: AppDimensions.spaceSm), Expanded(child: SecondaryButton(label: 'End: ${Formatters.date(_end)}', onPressed: () => _pick(false)))]),
                if (!_end.isAfter(_start)) Padding(padding: const EdgeInsets.only(top: AppDimensions.spaceSm), child: Text('End date must be after start date', style: TextStyle(color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: AppDimensions.spaceLg),
                PrimaryButton(label: 'Save Academic Term', isLoading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDate: start ? _start : _end);
    if (picked != null) setState(() { if (start) { _start = picked; } else { _end = picked; } });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || !_end.isAfter(_start)) return;
    setState(() => _saving = true);
    final base = widget.term;
    final term = AcademicTermModel(id: base?.id ?? '', name: _name.text.trim(), code: _code.text.trim(), academicYear: _year.text.trim(), startDate: _start, endDate: _end, status: base?.status ?? TermStatus.planned, notes: base?.notes);
    try {
      await context.read<AdminRepository>().saveAcademicTerm(term);
      await widget.onSaved();
      if (mounted) { Helpers.showSnackBar(context, 'Academic term saved.'); Navigator.pop(context); }
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

