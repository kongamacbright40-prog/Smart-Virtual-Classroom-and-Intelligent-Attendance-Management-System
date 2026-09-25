import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/icon_button.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/cards/attendance_card.dart';
import '../../../widgets/cards/schedule_card.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/progress_bar.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../authentication/providers/auth_provider.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final studentId = context.watch<AuthProvider>().user!.id;
    return AsyncView<_CourseDetailsData>(
      load: () => _CourseDetailsData.load(context, studentId, widget.courseId),
      builder: (context, data, reload) => AppScaffold(
        appBar: SmartAppBar(
          overline: data.course.departmentName ?? 'Computer Science',
          title: 'Course Details',
          actions: [
            AppIconButton(
              icon: Icons.bookmark_border,
              tooltip: 'Bookmark',
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.more_vert,
              tooltip: 'More',
              onPressed: () {},
            ),
          ],
        ),
        scrollable: true,
        onRefresh: reload,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CourseHero(course: data.course),
            const SizedBox(height: AppDimensions.spaceMd),
            if (data.liveSession != null) ...[
              _LiveCourseBanner(session: data.liveSession!),
              const SizedBox(height: AppDimensions.spaceMd),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Overview'),
                    icon: Icon(Icons.info_outline),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Sessions'),
                    icon: Icon(Icons.view_timeline_outlined),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Attendance'),
                    icon: Icon(Icons.fact_check_outlined),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            if (_tab == 0) _OverviewTab(data: data),
            if (_tab == 1) _SessionsTab(data: data),
            if (_tab == 2) _AttendanceTab(data: data),
          ],
        ),
      ),
    );
  }
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      borderColor: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceXs,
            children: [
              CodeTag(course.code),
              Text('• ${course.credits} Credits • ${course.category}'),
              const StatusChip(
                label: 'Active Term',
                tone: StatusTone.success,
                showDot: true,
                uppercase: true,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(course.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceSm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                UserAvatar(name: course.lecturerName ?? 'Lecturer', size: 48),
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.lecturerName ?? 'Course Lecturer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${course.lecturerRole ?? 'Lecturer'} • ${course.departmentName ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chat_bubble_outline,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCourseBanner extends StatelessWidget {
  const _LiveCourseBanner({required this.session});

  final ClassSessionModel session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      gradient: const LinearGradient(
        colors: [AppColors.primaryContainer, AppColors.secondary],
      ),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimensions.spaceSm,
            children: const [
              StatusChip(
                label: 'LIVE NOW',
                tone: StatusTone.live,
                showDot: true,
              ),
              StatusChip(
                label: 'Smart Attendance Active',
                tone: StatusTone.primary,
                icon: Icons.sensors,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            session.title,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          Text(
            '${session.room ?? 'Virtual Room'} • ${Formatters.timeRange(session.startTime, session.endTime)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  key: const Key('join_live_session'),
                  label: 'Join Live Session',
                  icon: Icons.videocam,
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () => Navigator.of(context).pushNamed(
                    RouteNames.studentLiveClassroom,
                    arguments: session.id,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              AppIconButton(
                icon: Icons.qr_code_scanner,
                tooltip: 'Attendance code',
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data});

  final _CourseDetailsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Text(
                      'Course Description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Text(data.course.description),
              const SizedBox(height: AppDimensions.spaceMd),
              Wrap(
                spacing: AppDimensions.spaceSm,
                runSpacing: AppDimensions.spaceSm,
                children: [
                  for (final topic in data.course.topics)
                    Chip(label: Text(topic)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Text(
                      'Attendance Standing',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  StatusChip(
                    label: Helpers.attendanceLabel(data.summary.percentage),
                    tone: data.summary.meetsRequirement
                        ? StatusTone.success
                        : StatusTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              Row(
                children: [
                  SizedBox.square(
                    dimension: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: data.summary.percentage / 100,
                          strokeWidth: 8,
                        ),
                        Text(
                          Formatters.percent(data.summary.percentage),
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data.summary.attendedCount} of ${data.summary.totalSessions}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const Text('Sessions'),
                        const SizedBox(height: AppDimensions.spaceSm),
                        AppProgressBar(value: data.summary.percentage / 100),
                        const SizedBox(height: AppDimensions.spaceXs),
                        Text(
                          'Minimum ${data.summary.requiredPercentage.round()}% required for finals',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Text(
                      'Schedule & Venue',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Sync Calendar'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Wrap(
                spacing: AppDimensions.spaceSm,
                runSpacing: AppDimensions.spaceSm,
                children: [
                  _InfoPill(
                    label: 'Days',
                    value: data.course.scheduleSummary ?? 'See timetable',
                  ),
                  _InfoPill(
                    label: 'Physical Hall',
                    value: data.course.room ?? 'Virtual room',
                  ),
                  if (data.course.virtualRoomUrl != null)
                    _InfoPill(
                      label: 'Virtual Room',
                      value: data.course.virtualRoomUrl!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.data});

  final _CourseDetailsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final session in data.sessions) ...[
          ScheduleCard(
            session: session,
            action: session.isLive
                ? PrimaryButton(
                    label: 'Join Now',
                    icon: Icons.videocam,
                    onPressed: () => Navigator.of(context).pushNamed(
                      RouteNames.studentLiveClassroom,
                      arguments: session.id,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
        ],
      ],
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.data});

  final _CourseDetailsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final record in data.records) ...[
          AttendanceCard(record: record),
          const SizedBox(height: AppDimensions.spaceMd),
        ],
      ],
    );
  }
}

class _CourseDetailsData {
  const _CourseDetailsData({
    required this.course,
    required this.sessions,
    required this.summary,
    required this.records,
  });

  final CourseModel course;
  final List<ClassSessionModel> sessions;
  final AttendanceModel summary;
  final List<AttendanceRecordModel> records;

  ClassSessionModel? get liveSession {
    for (final session in sessions) {
      if (session.status == SessionStatus.live) return session;
    }
    return null;
  }

  static Future<_CourseDetailsData> load(
    BuildContext context,
    String studentId,
    String courseId,
  ) async {
    final results = await Future.wait<Object>([
      context.read<CourseRepository>().getCourse(courseId),
      context.read<ScheduleRepository>().getCourseSessions(courseId),
      context.read<AttendanceRepository>().getStudentSummary(
        studentId,
        courseId: courseId,
      ),
      context.read<AttendanceRepository>().getStudentRecords(
        studentId,
        courseId: courseId,
      ),
    ]);
    return _CourseDetailsData(
      course: results[0] as CourseModel,
      sessions: results[1] as List<ClassSessionModel>,
      summary: results[2] as AttendanceModel,
      records: results[3] as List<AttendanceRecordModel>,
    );
  }
}
