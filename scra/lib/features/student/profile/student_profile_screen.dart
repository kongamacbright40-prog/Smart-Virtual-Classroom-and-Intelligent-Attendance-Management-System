import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/icon_button.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../authentication/providers/auth_provider.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return AsyncView<_ProfileData>(
      load: () => _ProfileData.load(context, user.id),
      builder: (context, data, reload) => AppScaffold(
        appBar: SmartAppBar(
          title: 'Student Profile',
          showBack: false,
          actions: [
            AppIconButton(
              icon: Icons.notifications_outlined,
              tooltip: 'Notifications',
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.notifications),
            ),
            AppIconButton(
              icon: Icons.qr_code_2,
              tooltip: 'Student badge',
              onPressed: () => _showId(context, data.student),
            ),
          ],
        ),
        scrollable: true,
        onRefresh: reload,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(
              student: data.student,
              onEdit: () => _editProfile(context, data.student, reload),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            _AcademicInfo(student: data.student),
            const SizedBox(height: AppDimensions.spaceMd),
            _ContactInfo(student: data.student),
            const SizedBox(height: AppDimensions.spaceMd),
            _CoursesSummary(courses: data.courses, attendance: data.attendance),
            const SizedBox(height: AppDimensions.spaceMd),
            _AccountLinks(student: data.student),
            const SizedBox(height: AppDimensions.spaceMd),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorContainer,
                foregroundColor: AppColors.onErrorContainer,
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            Text(
              'Smart Class Android MVP\nv2.4.1 (Build 2025) • Powered by Academic Nexus Identity System',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  static void _showId(BuildContext context, StudentModel student) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge, size: 56, color: AppColors.primary),
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              student.user.fullName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('${student.matricule} • ${student.programme}'),
            const SizedBox(height: AppDimensions.spaceLg),
            const Text('SCAN AT LECTURE HALL TERMINALS'),
            const SizedBox(height: AppDimensions.spaceLg),
            PrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _editProfile(
    BuildContext context,
    StudentModel student,
    Future<void> Function() reload,
  ) async {
    final updated = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(user: student.user),
    );
    if (updated == null || !context.mounted) return;
    await context.read<AuthProvider>().updateUser(updated);
    await reload();
    if (context.mounted) Helpers.showSnackBar(context, 'Profile updated');
  }

  static Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
        title: const Text(AppStrings.logoutTitle),
        content: const Text(AppStrings.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              unawaited(auth.logout());
              AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                RouteNames.login,
                (_) => false,
              );
            },
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student, required this.onEdit});

  final StudentModel student;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        UserAvatar(
          name: student.user.fullName,
          imageUrl: student.user.avatarUrl,
          size: 96,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(student.user.fullName, style: theme.textTheme.headlineSmall),
        Wrap(
          spacing: AppDimensions.spaceSm,
          runSpacing: AppDimensions.spaceXs,
          alignment: WrapAlignment.center,
          children: [
            Chip(label: Text('Matric: ${student.matricule}')),
            Chip(
              label: Text(
                '${student.user.departmentName ?? 'Computer Science'} • Level ${student.level}',
              ),
            ),
            const Chip(label: Text('Status: Active / Enrolled')),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Edit Profile',
                icon: Icons.edit,
                onPressed: onEdit,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.badge),
                label: const Text('Digital Student ID'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AcademicInfo extends StatelessWidget {
  const _AcademicInfo({required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.school,
            title: 'Academic Information',
            trailing: const StatusChip(
              label: 'Honors Track',
              tone: StatusTone.primary,
            ),
          ),
          _InfoRow(
            'Department',
            student.user.departmentName ?? 'Department of Computer Science',
          ),
          _InfoRow('Program', student.programme),
          _InfoRow(
            'Level',
            'Level ${student.level} (Year ${(student.level / 100).round()})',
          ),
          _InfoRow(
            'Current Term',
            '${DateTime.now().year}/${DateTime.now().year + 1} Semester ${student.semester}',
          ),
          _InfoRow(
            'Enrolled Courses',
            '${student.enrolledCourseIds.length} Courses (${student.activeCredits} Credits)',
            action: () =>
                Navigator.of(context).pushNamed(RouteNames.studentCourses),
          ),
        ],
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  const _ContactInfo({required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.contact_mail_outlined,
            title: 'Contact Information',
          ),
          _InfoRow(
            'Institutional Email',
            student.user.email,
            badge: 'Verified',
          ),
          _InfoRow(
            'Phone',
            student.user.phone ?? 'Not set',
            badge: student.user.phone == null ? null : 'Verified',
          ),
          const _InfoRow('Campus Residence', 'Hall 4, West Campus'),
        ],
      ),
    );
  }
}

class _CoursesSummary extends StatelessWidget {
  const _CoursesSummary({required this.courses, required this.attendance});

  final List<CourseModel> courses;
  final Map<String, double> attendance;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.auto_stories,
            title: 'Enrolled Courses Summary',
            trailing: const StatusChip(
              label: '92% Aggregate',
              tone: StatusTone.info,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppDimensions.spaceSm,
            mainAxisSpacing: AppDimensions.spaceSm,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.0,
            children: [
              for (final course in courses.take(4))
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.code,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Text('Att:'),
                          const Spacer(),
                          Text(
                            '${(attendance[course.id] ?? 0).round()}%',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountLinks extends StatelessWidget {
  const _AccountLinks({required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const _SectionTitle(icon: Icons.lock, title: 'Account Security'),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Multi-Factor Authentication'),
            subtitle: Text('SMS & Authenticator App'),
            trailing: StatusChip(label: 'Active', tone: StatusTone.success),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.vpn_key),
            title: const Text('Settings / Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.studentSettings),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.notifications),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.badge, this.action});

  final String label;
  final String value;
  final String? badge;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (badge != null)
                  StatusChip(label: badge!, tone: StatusTone.info, dense: true),
                if (action != null)
                  TextButton(
                    onPressed: action,
                    child: const Text('View Courses >'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final UserModel user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(text: widget.user.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
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
            Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _name,
              label: 'Full Name',
              validator: (v) => Validators.required(v, field: 'Full name'),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            AppTextField(
              controller: _phone,
              label: 'Phone',
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.phone(v, isRequired: false),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            PrimaryButton(
              label: 'Save Changes',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await context.read<UserRepository>().updateProfile(
        widget.user.copyWith(
          fullName: _name.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        ),
      );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) Helpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProfileData {
  const _ProfileData({
    required this.student,
    required this.courses,
    required this.attendance,
  });

  final StudentModel student;
  final List<CourseModel> courses;
  final Map<String, double> attendance;

  static Future<_ProfileData> load(
    BuildContext context,
    String studentId,
  ) async {
    final userRepo = context.read<UserRepository>();
    final courseRepo = context.read<CourseRepository>();
    final attendanceRepo = context.read<AttendanceRepository>();
    final student = await userRepo.getStudentProfile(studentId);
    final courses = await courseRepo.getStudentCourses(studentId);
    final summaries = await Future.wait(
      courses.map(
        (c) => attendanceRepo.getStudentSummary(studentId, courseId: c.id),
      ),
    );
    return _ProfileData(
      student: student,
      courses: courses,
      attendance: {
        for (final s in summaries)
          if (s.courseId != null) s.courseId!: s.percentage,
      },
    );
  }
}
