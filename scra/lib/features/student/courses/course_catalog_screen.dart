import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/inputs/search_field.dart';
import '../../authentication/providers/auth_provider.dart';

/// Every open course, with Enroll / Drop actions for the student.
///
/// Courses of the student's own department are included automatically and
/// can't be dropped; other courses can be joined and left freely.
class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  String _query = '';
  final Set<String> _busy = {};

  Future<_CatalogData> _load() async {
    final user = context.read<AuthProvider>().user!;
    final repo = context.read<CourseRepository>();
    final all = await repo.getAllCourses();
    final mine = await repo.getStudentCourses(user.id);
    return _CatalogData(
      courses: all.where((c) => c.status != CourseStatus.archived).toList()
        ..sort((a, b) => a.code.compareTo(b.code)),
      enrolledIds: {for (final c in mine) c.id},
      departmentId: user.departmentId,
    );
  }

  Future<void> _toggle(
    CourseModel course, {
    required bool enroll,
    required Future<void> Function() reload,
  }) async {
    final repo = context.read<CourseRepository>();
    setState(() => _busy.add(course.id));
    try {
      if (enroll) {
        await repo.enrollInCourse(course.id);
      } else {
        await repo.dropCourse(course.id);
      }
      if (mounted) {
        Helpers.showSnackBar(
          context,
          enroll ? 'Enrolled in ${course.code}.' : 'You left ${course.code}.',
        );
      }
      await reload();
    } on Object catch (e) {
      if (mounted) Helpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(course.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<_CatalogData>(
      load: _load,
      builder: (context, data, reload) {
        final courses = data.search(_query);
        return AppScaffold(
          appBar: const SmartAppBar(
            title: 'Enroll in Courses',
            subtitle: 'Join courses outside your department',
            showBack: true,
          ),
          scrollable: true,
          onRefresh: reload,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(
                hint: 'Search by code, title or lecturer',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              if (data.departmentId == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
                  child: Text(
                    'You have no department yet, so pick your courses here. '
                    'An administrator can also set your department.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (courses.isEmpty)
                const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No courses found',
                  message: 'Courses created by the administrator appear here.',
                  compact: true,
                )
              else
                for (final course in courses) ...[
                  _CatalogTile(
                    course: course,
                    viaDepartment: data.viaDepartment(course),
                    enrolled: data.enrolledIds.contains(course.id),
                    busy: _busy.contains(course.id),
                    onEnroll: () =>
                        _toggle(course, enroll: true, reload: reload),
                    onDrop: () =>
                        _toggle(course, enroll: false, reload: reload),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                ],
              const SizedBox(height: AppDimensions.spaceLg),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.course,
    required this.viaDepartment,
    required this.enrolled,
    required this.busy,
    required this.onEnroll,
    required this.onDrop,
  });

  final CourseModel course;
  final bool viaDepartment;
  final bool enrolled;
  final bool busy;
  final VoidCallback onEnroll;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      course.departmentName,
      course.lecturerName ?? 'Lecturer to be assigned',
    ].whereType<String>().join(' • ');
    final Widget action;
    if (busy) {
      action = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else if (viaDepartment) {
      action = const StatusChip(
        label: 'Your department',
        tone: StatusTone.info,
      );
    } else if (enrolled) {
      action = OutlinedButton(
        key: Key('drop_${course.id}'),
        onPressed: onDrop,
        child: const Text('Drop'),
      );
    } else {
      action = FilledButton(
        key: Key('enroll_${course.id}'),
        onPressed: onEnroll,
        child: const Text('Enroll'),
      );
    }
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        course.code,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (enrolled && !viaDepartment) ...[
                      const SizedBox(width: AppDimensions.spaceSm),
                      const StatusChip(
                        label: 'Enrolled',
                        tone: StatusTone.success,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  course.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          action,
        ],
      ),
    );
  }
}

class _CatalogData {
  const _CatalogData({
    required this.courses,
    required this.enrolledIds,
    required this.departmentId,
  });

  final List<CourseModel> courses;
  final Set<String> enrolledIds;
  final String? departmentId;

  bool viaDepartment(CourseModel course) =>
      course.enrollment == CourseEnrollment.department ||
      (departmentId != null &&
          departmentId!.isNotEmpty &&
          course.departmentId == departmentId);

  List<CourseModel> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return courses;
    return courses
        .where(
          (c) =>
              c.code.toLowerCase().contains(q) ||
              c.title.toLowerCase().contains(q) ||
              (c.lecturerName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
}
