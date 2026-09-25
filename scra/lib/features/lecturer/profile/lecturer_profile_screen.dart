import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../models/models.dart';
import '../../../providers/settings_provider.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/cards/statistic_card.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../../widgets/dialogs/logout_dialog.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../authentication/providers/auth_provider.dart';
import '../lecturer_shared.dart';

class LecturerProfileScreen extends StatelessWidget {
  const LecturerProfileScreen({super.key});

  Future<_ProfileData> _load(BuildContext context) async {
    final lecturerId = lecturerIdOf(context);
    final userRepository = context.read<UserRepository>();
    final courseRepository = context.read<CourseRepository>();
    final profile = await userRepository.getLecturerProfile(lecturerId);
    final courses = await courseRepository.getLecturerCourses(lecturerId);
    return _ProfileData(profile: profile, courses: courses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartAppBar(title: 'Faculty Profile'),
      body: AsyncView<_ProfileData>(
        load: () => _load(context),
        builder: (context, data, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.pageMargin),
            children: [
              _Header(data: data),
              const SizedBox(height: AppDimensions.spaceLg),
              _InfoCard(
                profile: data.profile,
                onEdit: () => _editProfile(context, data.profile, reload),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _CoursesCard(courses: data.courses),
              const SizedBox(height: AppDimensions.spaceMd),
              const _PreferencesCard(),
              const SizedBox(height: AppDimensions.spaceMd),
              _SecurityCard(onLogout: () => _logout(context)),
              const SizedBox(height: AppDimensions.spaceMd),
              Text(
                'Compliance & Governance Verified\nSmart Class v2.4.1',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    LecturerModel lecturer,
    Future<void> Function() reload,
  ) async {
    final name = TextEditingController(text: lecturer.user.fullName);
    final phone = TextEditingController(text: lecturer.user.phone ?? '');
    final office = TextEditingController(text: lecturer.officeLocation ?? '');
    final key = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.pageMargin,
          AppDimensions.pageMargin,
          AppDimensions.pageMargin,
          MediaQuery.viewInsetsOf(context).bottom + AppDimensions.pageMargin,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: name,
                label: 'Full Name',
                validator: (v) => Validators.required(v, field: 'Full name'),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppTextField(
                controller: phone,
                label: 'Phone',
                validator: (v) => Validators.phone(v, isRequired: false),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              AppTextField(
                controller: office,
                label: 'Office',
                validator: (v) => Validators.required(v, field: 'Office'),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              FilledButton(
                onPressed: () {
                  if (key.currentState!.validate()) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      try {
        final updated = lecturer.user.copyWith(
          fullName: name.text.trim(),
          phone: phone.text.trim(),
        );
        final savedUser = await context.read<UserRepository>().updateProfile(
          updated,
        );
        if (!context.mounted) return;
        await context.read<AuthProvider>().updateUser(savedUser);
        await reload();
        if (context.mounted) Helpers.showSnackBar(context, 'Profile updated.');
      } on Object catch (e) {
        if (context.mounted) Helpers.showError(context, e);
      }
    }
    name.dispose();
    phone.dispose();
    office.dispose();
  }

  Future<void> _logout(BuildContext context) =>
      confirmAndLogout(context, loginRoute: RouteNames.login);
}

class _Header extends StatelessWidget {
  const _Header({required this.data});
  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    final lecturer = data.profile;
    return Column(
      children: [
        UserAvatar(
          name: lecturer.user.fullName,
          size: 96,
          imageUrl: lecturer.user.avatarUrl,
          showOnline: true,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Text(
          lecturer.user.fullName,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        Text(
          '${lecturer.title} ? ${lecturer.specialization ?? 'Faculty'}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        Text(
          lecturer.user.departmentName ?? 'Department of Computer Science',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        Wrap(
          spacing: AppDimensions.spaceSm,
          alignment: WrapAlignment.center,
          children: [
            StatusChip(label: 'Staff ID: ${lecturer.staffId}'),
            const StatusChip(
              label: 'Active Faculty • On Campus',
              showDot: true,
              tone: StatusTone.success,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppDimensions.spaceSm,
          children: [
            StatisticCard(
              value: '${data.courses.length}',
              label: 'Active Courses',
            ),
            StatisticCard(
              value: '${lecturer.totalStudents}',
              label: 'Mentored',
            ),
            StatisticCard(
              value: '${lecturer.averageAttendance.toStringAsFixed(1)}%',
              label: 'Avg Attendance',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.profile, required this.onEdit});
  final LecturerModel profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Faculty Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
            ],
          ),
          LecturerInfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: profile.user.fullName,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          LecturerInfoRow(
            icon: Icons.mail_outline,
            label: 'Institutional Email',
            value: profile.user.email,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          LecturerInfoRow(
            icon: Icons.meeting_room_outlined,
            label: 'Office Location',
            value: profile.officeLocation ?? 'Office pending',
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          LecturerInfoRow(
            icon: Icons.science_outlined,
            label: 'Research Facility',
            value: profile.specialization ?? 'Academic research',
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          LecturerInfoRow(
            icon: Icons.call_outlined,
            label: 'Phone & Extension',
            value: profile.user.phone ?? 'Not provided',
          ),
        ],
      ),
    );
  }
}

class _CoursesCard extends StatelessWidget {
  const _CoursesCard({required this.courses});
  final List<CourseModel> courses;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Assigned Courses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(label: '${courses.length} Courses'),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          for (final course in courses.take(4))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${course.code} ? ${course.scheduleSummary ?? course.room ?? 'Schedule pending'}',
              ),
              trailing: Text('${course.enrolledCount} Students'),
              onTap: () =>
                  Navigator.of(context)
                      .pushNamed(RouteNames.courseRoster, arguments: course.id),
            ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Preferences',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SwitchListTile.adaptive(
            title: const Text('Real-Time Attendance Alerts'),
            subtitle: const Text(
              'Alert when course attendance drops below threshold',
            ),
            value: settings.attendanceWarningGuard,
            onChanged: (v) =>
                provider.update((s) => s.copyWith(attendanceWarningGuard: v)),
          ),
          SwitchListTile.adaptive(
            title: const Text('Student Hand Raise & Question Pings'),
            subtitle: const Text('Live lecture queue notifications'),
            value: settings.liveQuestionAlerts,
            onChanged: (v) =>
                provider.update((s) => s.copyWith(liveQuestionAlerts: v)),
          ),
          SwitchListTile.adaptive(
            title: const Text('Automated Weekly Digest Reports'),
            subtitle: const Text('Attendance summaries every Friday'),
            value: settings.emailClassAlerts,
            onChanged: (v) =>
                provider.update((s) => s.copyWith(emailClassAlerts: v)),
          ),
          SwitchListTile.adaptive(
            title: const Text('Institutional Registrar Broadcasts'),
            subtitle: const Text('Critical academic deadlines'),
            value: settings.announcementAlerts,
            onChanged: (v) =>
                provider.update((s) => s.copyWith(announcementAlerts: v)),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Security & Auth',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          const LecturerInfoRow(
            icon: Icons.vpn_key_outlined,
            label: 'SSO Identity',
            value: 'Academic SSO (SAML 2.0 Connected)',
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          const LecturerInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Two-Factor Authentication',
            value: '2FA Enabled',
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          SecondaryButton(
            label: 'Sign Out of Lecturer Portal',
            icon: Icons.logout,
            foregroundColor: Theme.of(context).colorScheme.error,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({required this.profile, required this.courses});
  final LecturerModel profile;
  final List<CourseModel> courses;
}
