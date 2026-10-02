import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/empty_state.dart';
import 'package:smart_class/widgets/common/status_chip.dart';

class FacultiesScreen extends StatefulWidget {
  const FacultiesScreen({super.key});

  @override
  State<FacultiesScreen> createState() => _FacultiesScreenState();
}

class _FacultiesScreenState extends State<FacultiesScreen> {
  int _version = 0;

  Future<void> _addFaculty() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _FacultyNameDialog(),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      await context.read<AdminRepository>().createFaculty(name);
      if (mounted) {
        Helpers.showSnackBar(context, 'Faculty "${name.trim()}" created.');
        setState(() => _version++);
      }
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AdminScreenHeader(title: 'Faculties', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_faculty'),
        icon: const Icon(Icons.add),
        label: const Text('Add Faculty'),
        onPressed: _addFaculty,
      ),
      body: AsyncView<List<FacultyModel>>(
        key: ValueKey('faculties-$_version'),
        load: () => context.read<AdminRepository>().getFaculties(),
        builder: (context, faculties, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              const AdminHeroCard(
                title: 'Faculty Directory',
                subtitle:
                    'Create faculties first, then add departments to them.',
                icon: Icons.account_balance_outlined,
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              if (faculties.isEmpty)
                EmptyState(
                  icon: Icons.account_balance_outlined,
                  title: 'No faculties yet',
                  message: 'Add your first faculty, e.g. "Faculty of ICT".',
                  actionLabel: 'Add Faculty',
                  onAction: _addFaculty,
                  compact: true,
                )
              else
                for (final faculty in faculties) _FacultyCard(faculty: faculty),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacultyNameDialog extends StatefulWidget {
  const _FacultyNameDialog();

  @override
  State<_FacultyNameDialog> createState() => _FacultyNameDialogState();
}

class _FacultyNameDialogState extends State<_FacultyNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().length < 2) return;
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Faculty'),
      content: TextField(
        key: const Key('faculty_name'),
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Faculty name',
          hintText: 'e.g. Faculty of ICT',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('faculty_save'),
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _FacultyCard extends StatelessWidget {
  const _FacultyCard({required this.faculty});
  final FacultyModel faculty;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CodeTag(faculty.code),
              const SizedBox(width: AppDimensions.spaceSm),
              StatusChip(
                label: faculty.isActive ? 'Active' : 'Archived',
                tone: faculty.isActive
                    ? StatusTone.success
                    : StatusTone.neutral,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            faculty.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('Dean: ${faculty.deanName ?? 'Unassigned'}'),
          const SizedBox(height: AppDimensions.spaceMd),
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              if (faculty.category != null && faculty.category!.isNotEmpty)
                _pill(context, faculty.category!),
              _pill(context, '${faculty.departmentCount} Departments'),
              _pill(context, '${faculty.courseCount} Courses'),
              _pill(
                context,
                '${Formatters.compactNumber(faculty.studentCount)} Students',
              ),
              _pill(context, '${faculty.staffCount} Staff'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
    ),
    child: Text(label),
  );
}
