import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/routing/route_names.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/core/utils/validators.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/features/admin/courses/widgets/admin_course_item.dart';
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

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  String _query = '';
  CourseStatus? _status;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AdminScreenHeader(title: 'Courses'),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_course'),
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
        onPressed: () => _showCourseForm(context, () async => setState(() {})),
      ),
      body: AsyncView<_CoursesData>(
        key: ValueKey('courses-$_query-${_status?.name}'),
        load: () async {
          final courseRepo = context.read<CourseRepository>();
          final adminRepo = context.read<AdminRepository>();
          return _CoursesData(
            await courseRepo.getAllCourses(status: _status, query: _query),
            await courseRepo.getAllCourses(),
            await adminRepo.getDepartments(),
            await adminRepo.getFaculties(),
          );
        },
        builder: (context, data, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withValues(alpha: 0.16),
                      child: Text(
                        '${data.all.length} Total Courses • ${data.faculties.where((f) => f.isActive).length} Faculties Active',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  PrimaryButton(
                    label: 'New Course',
                    icon: Icons.add,
                    expanded: false,
                    onPressed: () => _showCourseForm(context, reload),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              SearchField(
                hint: 'Search courses by code, title, lecturer...',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Wrap(
                spacing: AppDimensions.spaceSm,
                children: [
                  ChoiceChip(
                    label: Text('All (${data.all.length})'),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  ChoiceChip(
                    label: Text(
                      'Active (${data.all.where((c) => c.status == CourseStatus.active).length})',
                    ),
                    selected: _status == CourseStatus.active,
                    onSelected: (_) =>
                        setState(() => _status = CourseStatus.active),
                  ),
                  ChoiceChip(
                    label: Text(
                      'Archived (${data.all.where((c) => c.status == CourseStatus.archived).length})',
                    ),
                    selected: _status == CourseStatus.archived,
                    onSelected: (_) =>
                        setState(() => _status = CourseStatus.archived),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              if (data.courses.isEmpty)
                const EmptyState(
                  title: 'No matching courses',
                  message: 'Try another query or status tab.',
                )
              else
                for (final course in data.courses)
                  AdminCourseItem(
                    course: course,
                    onAssign: () => _assignLecturer(context, course, reload),
                    onDetails: () => Navigator.of(context)
                        .pushNamed(
                          RouteNames.adminCourseDetails,
                          arguments: course.id,
                        )
                        .then((_) => setState(() {})),
                    onRoster: () => Navigator.of(context).pushNamed(
                      RouteNames.adminCourseDetails,
                      arguments: course.id,
                    ),
                    onArchive: () => _archive(context, course, reload),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignLecturer(
    BuildContext context,
    CourseModel course,
    Future<void> Function() reload,
  ) async {
    final lecturers = await context.read<AdminRepository>().getUsers(
      role: UserRole.lecturer,
    );
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          children: [
            AdminSectionTitle(title: 'Assign Lecturer', subtitle: course.code),
            const SizedBox(height: AppDimensions.spaceMd),
            for (final lecturer in lecturers)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(lecturer.fullName),
                subtitle: Text(lecturer.departmentName ?? lecturer.email),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await context.read<CourseRepository>().assignLecturer(
                      courseId: course.id,
                      lecturerId: lecturer.id,
                    );
                    if (context.mounted) {
                      Helpers.showSnackBar(
                        context,
                        '${lecturer.fullName} assigned to ${course.code}.',
                      );
                    }
                    await reload();
                  } on Object catch (e) {
                    if (context.mounted) Helpers.showError(context, e);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _archive(
    BuildContext context,
    CourseModel course,
    Future<void> Function() reload,
  ) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Archive course?',
      message: course.code,
      confirmLabel: 'Archive',
      destructive: true,
      icon: Icons.archive_outlined,
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<CourseRepository>().archiveCourse(course.id);
      if (context.mounted) Helpers.showSnackBar(context, 'Course archived.');
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _showCourseForm(
    BuildContext context,
    Future<void> Function() reload,
  ) async {
    final departments = await context.read<AdminRepository>().getDepartments();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CourseForm(departments: departments, onSaved: reload),
    );
  }
}

class _CoursesData {
  const _CoursesData(this.courses, this.all, this.departments, this.faculties);
  final List<CourseModel> courses;
  final List<CourseModel> all;
  final List<DepartmentModel> departments;
  final List<FacultyModel> faculties;
}

class _CourseForm extends StatefulWidget {
  const _CourseForm({required this.departments, required this.onSaved});
  final List<DepartmentModel> departments;
  final Future<void> Function() onSaved;

  @override
  State<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<_CourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _credits = TextEditingController();
  final _category = TextEditingController();
  late String? _departmentId = widget.departments.isEmpty
      ? null
      : widget.departments.first.id;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _credits.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDepartment =
        widget.departments.where((d) => d.id == _departmentId).isEmpty
        ? null
        : widget.departments.firstWhere((d) => d.id == _departmentId);
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
                const AdminSectionTitle(title: 'New Course'),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  fieldKey: const Key('course_code'),
                  controller: _code,
                  label: 'Course code',
                  isRequired: true,
                  validator: Validators.courseCode,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  fieldKey: const Key('course_title'),
                  controller: _title,
                  label: 'Title',
                  isRequired: true,
                  validator: Validators.courseTitle,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  fieldKey: const Key('course_credits'),
                  controller: _credits,
                  label: 'Credits',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  validator: Validators.credits,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppDropdown<DepartmentModel>(
                  label: 'Department',
                  value: selectedDepartment,
                  items: widget.departments,
                  onChanged: (d) => setState(() => _departmentId = d?.id),
                  itemLabel: (d) => d.name,
                  validator: (d) => d == null ? 'Department is required' : null,
                ),
                const SizedBox(height: AppDimensions.spaceMd),
                AppTextField(
                  fieldKey: const Key('course_category'),
                  controller: _category,
                  label: 'Category',
                  validator: (v) => Validators.required(v, field: 'Category'),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                PrimaryButton(
                  label: 'Create Course',
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
    final dept = widget.departments.firstWhere((d) => d.id == _departmentId);
    final course = CourseModel(
      id: '',
      code: _code.text.trim(),
      title: _title.text.trim(),
      credits: int.parse(_credits.text.trim()),
      departmentId: dept.id,
      departmentName: dept.name,
      category: _category.text.trim(),
    );
    try {
      await context.read<CourseRepository>().createCourse(course);
      await widget.onSaved();
      if (mounted) {
        Helpers.showSnackBar(context, 'Course created.');
        Navigator.pop(context);
      }
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
