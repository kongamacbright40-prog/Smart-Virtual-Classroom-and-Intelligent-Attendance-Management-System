import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/core/utils/validators.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/features/admin/departments/widgets/department_item.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/buttons/primary_button.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/empty_state.dart';
import 'package:smart_class/widgets/dialogs/confirmation_dialog.dart';
import 'package:smart_class/widgets/inputs/app_dropdown.dart';
import 'package:smart_class/widgets/inputs/app_text_field.dart';
import 'package:smart_class/widgets/inputs/search_field.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AdminScreenHeader(
        title: 'Departments & Faculties',
        subtitle: 'Smart Class System',
        actions: [
          IconButton(
            tooltip: 'Faculties',
            icon: const Icon(Icons.account_balance_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.faculties),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_department'),
        icon: const Icon(Icons.add),
        label: const Text('Create Dept'),
        onPressed: () =>
            _showDepartmentForm(context, null, () async => setState(() {})),
      ),
      body: AsyncView<_DepartmentsData>(
        key: ValueKey('dept-$_query-$_category'),
        load: () async {
          final repo = context.read<AdminRepository>();
          return _DepartmentsData(
            await repo.getDepartments(),
            await repo.getFaculties(),
          );
        },
        builder: (context, data, reload) {
          final facultyById = {for (final f in data.faculties) f.id: f};
          final filtered = data.departments.where((d) {
            final q = _query.trim().toLowerCase();
            final categoryOk =
                _category == 'All' ||
                facultyById[d.facultyId]?.category == _category;
            final queryOk =
                q.isEmpty ||
                d.name.toLowerCase().contains(q) ||
                d.code.toLowerCase().contains(q) ||
                (d.facultyName?.toLowerCase().contains(q) ?? false);
            return categoryOk && queryOk;
          }).toList();
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                SearchField(
                  hint: 'Search departments or faculties...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in const [
                        'All',
                        'Science & Tech',
                        'Engineering',
                        'Business',
                        'Humanities',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              c == 'All'
                                  ? 'All (${data.departments.length})'
                                  : c,
                            ),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle(
                        title: 'Campus Structure Overview',
                        trailing: Text('Term 2 • 2025'),
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),
                      Wrap(
                        spacing: AppDimensions.spaceSm,
                        runSpacing: AppDimensions.spaceSm,
                        children: [
                          _stat(
                            context,
                            data.faculties.length.toString(),
                            'Faculties',
                          ),
                          _stat(
                            context,
                            data.departments.length.toString(),
                            'Depts',
                          ),
                          _stat(
                            context,
                            data.departments
                                .fold<int>(0, (s, d) => s + d.courseCount)
                                .toString(),
                            'Courses',
                          ),
                          _stat(
                            context,
                            Formatters.compactNumber(
                              data.departments.fold<int>(
                                0,
                                (s, d) => s + d.studentCount,
                              ),
                            ),
                            'Students',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                if (filtered.isEmpty)
                  EmptyState(
                    title: 'No matching departments',
                    message: 'Try modifying your search or filter criteria.',
                    actionLabel: 'Reset Filters',
                    onAction: () => setState(() {
                      _query = '';
                      _category = 'All';
                    }),
                  )
                else
                  for (final department in filtered)
                    DepartmentItem(
                      department: department,
                      onOptions: () =>
                          _showOptions(context, department, reload),
                      onEdit: () =>
                          _showDepartmentForm(context, department, reload),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Container(
    width: 74,
    padding: const EdgeInsets.all(AppDimensions.spaceSm),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        Text(label),
      ],
    ),
  );

  Future<void> _showOptions(
    BuildContext context,
    DepartmentModel department,
    Future<void> Function() reload,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AdminSectionTitle(title: 'Faculty Options'),
              AdminInfoRow(
                icon: Icons.groups_outlined,
                title: 'View Student Rosters',
                subtitle: department.name,
                onTap: () => Navigator.pop(sheetContext),
              ),
              AdminInfoRow(
                icon: Icons.person_add_alt_1,
                title: 'Assign Head of Department',
                subtitle: 'Update leadership',
                onTap: () => Navigator.pop(sheetContext),
              ),
              AdminInfoRow(
                icon: Icons.download_outlined,
                title: 'Export Attendance Report',
                subtitle: 'Prepare CSV/PDF',
                onTap: () {
                  Navigator.pop(sheetContext);
                  Helpers.showSnackBar(context, 'Attendance export queued.');
                },
              ),
              AdminInfoRow(
                icon: Icons.archive_outlined,
                title: 'Archive Department',
                subtitle: 'Deactivate ${department.code}',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _archive(context, department, reload);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _archive(
    BuildContext context,
    DepartmentModel department,
    Future<void> Function() reload,
  ) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Archive department?',
      message: department.name,
      confirmLabel: 'Archive',
      destructive: true,
      icon: Icons.archive_outlined,
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<AdminRepository>().archiveDepartment(department.id);
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Department archived.');
      }
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _showDepartmentForm(
    BuildContext context,
    DepartmentModel? department,
    Future<void> Function() reload,
  ) async {
    final faculties = await context.read<AdminRepository>().getFaculties();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DepartmentForm(
        department: department,
        faculties: faculties,
        onSaved: reload,
      ),
    );
  }
}

class _DepartmentsData {
  const _DepartmentsData(this.departments, this.faculties);
  final List<DepartmentModel> departments;
  final List<FacultyModel> faculties;
}

class _DepartmentForm extends StatefulWidget {
  const _DepartmentForm({
    required this.faculties,
    required this.onSaved,
    this.department,
  });
  final List<FacultyModel> faculties;
  final DepartmentModel? department;
  final Future<void> Function() onSaved;

  @override
  State<_DepartmentForm> createState() => _DepartmentFormState();
}

class _DepartmentFormState extends State<_DepartmentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.department?.name ?? '');
  late final _code = TextEditingController(text: widget.department?.code ?? '');
  late final _head = TextEditingController(
    text: widget.department?.headName ?? '',
  );
  late String? _facultyId =
      widget.department?.facultyId ??
      (widget.faculties.isEmpty ? null : widget.faculties.first.id);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _head.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedFaculty =
        widget.faculties.where((f) => f.id == _facultyId).isEmpty
        ? null
        : widget.faculties.firstWhere((f) => f.id == _facultyId);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.spaceMd,
          right: AppDimensions.spaceMd,
          bottom:
              MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spaceMd,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminSectionTitle(
                  title: widget.department == null
                      ? 'Create Department'
                      : 'Edit Department',
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  controller: _name,
                  label: 'Name',
                  isRequired: true,
                  validator: (v) =>
                      Validators.required(v, field: 'Department name'),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  controller: _code,
                  label: 'Code',
                  isRequired: true,
                  validator: (v) => Validators.required(v, field: 'Code'),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppDropdown<FacultyModel>(
                  label: 'Faculty',
                  value: selectedFaculty,
                  items: widget.faculties,
                  onChanged: (f) => setState(() => _facultyId = f?.id),
                  itemLabel: (f) => f.name,
                  validator: (f) => f == null ? 'Faculty is required' : null,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  controller: _head,
                  label: 'HOD',
                  validator: (v) => null,
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                PrimaryButton(
                  label: 'Save Department',
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final base = widget.department;
    final department = DepartmentModel(
      id: base?.id ?? '',
      name: _name.text.trim(),
      code: _code.text.trim(),
      facultyId: _facultyId!,
      headName: _head.text.trim().isEmpty ? null : _head.text.trim(),
      courseCount: base?.courseCount ?? 0,
      studentCount: base?.studentCount ?? 0,
      staffCount: base?.staffCount ?? 0,
      liveSessions: base?.liveSessions ?? 0,
      averageAttendance: base?.averageAttendance ?? 0,
      isActive: base?.isActive ?? true,
    );
    try {
      await context.read<AdminRepository>().saveDepartment(department);
      await widget.onSaved();
      if (mounted) {
        Helpers.showSnackBar(context, 'Department saved.');
        Navigator.pop(context);
      }
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
