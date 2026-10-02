import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/cards/statistic_card.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/inputs/search_field.dart';
import '../lecturer_shared.dart';
import 'widgets/student_roster_item.dart';

class CourseRosterScreen extends StatefulWidget {
  const CourseRosterScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseRosterScreen> createState() => _CourseRosterScreenState();
}

class _CourseRosterScreenState extends State<CourseRosterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );
  String _query = '';
  String _filter = 'All';

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_RosterData> _load(BuildContext context) async {
    final courseRepository = context.read<CourseRepository>();
    final userRepository = context.read<UserRepository>();
    final attendanceRepository = context.read<AttendanceRepository>();
    final scheduleRepository = context.read<ScheduleRepository>();
    final (course, roster, summaries, sessions) = await (
      courseRepository.getCourse(widget.courseId),
      userRepository.getCourseRoster(widget.courseId),
      attendanceRepository.getCourseSummaries(widget.courseId),
      scheduleRepository.getCourseSessions(widget.courseId),
    ).wait;
    final latest =
        sessions
            .where(
              (s) =>
                  s.status == SessionStatus.live ||
                  s.status == SessionStatus.completed,
            )
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final records = latest.isEmpty
        ? <AttendanceRecordModel>[]
        : await attendanceRepository.getSessionAttendance(latest.first.id);
    return _RosterData(
      course: course,
      roster: roster,
      summaries: summaries,
      sessions: sessions,
      latestSession: latest.firstOrNull,
      latestRecords: records,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(title: 'Course Management'),
      body: AsyncView<_RosterData>(
        load: () => _load(context),
        builder: (context, data, reload) {
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.pageMargin),
              children: [
                _CourseHeader(data: data),
                const SizedBox(height: AppDimensions.spaceMd),
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Roster ${data.roster.length}'),
                    Tab(text: 'Sessions ${data.sessions.length}'),
                    const Tab(text: 'Settings'),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.72,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _RosterTab(
                        data: data,
                        query: _query,
                        filter: _filter,
                        onQuery: (v) => setState(() => _query = v),
                        onFilter: (v) => setState(() => _filter = v),
                        onReload: reload,
                      ),
                      _SessionsTab(sessions: data.sessions),
                      _SettingsTab(course: data.course),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.data});
  final _RosterData data;

  @override
  Widget build(BuildContext context) {
    final avg = data.summaries.isEmpty
        ? 0.0
        : data.summaries.map((s) => s.percentage).reduce((a, b) => a + b) /
              data.summaries.length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimensions.spaceSm,
            children: [
              CodeTag(data.course.code),
              if (data.course.credits != null)
                StatusChip(label: '${data.course.credits} Credits'),
              if (data.course.termId != null)
                StatusChip(label: data.course.termId!, showDot: true),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            data.course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (data.course.lecturerName != null) Text(data.course.lecturerName!),
          const SizedBox(height: AppDimensions.spaceMd),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.45,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppDimensions.spaceSm,
            crossAxisSpacing: AppDimensions.spaceSm,
            children: [
              StatisticCard(
                value: '${data.roster.length}',
                label: 'Students',
                icon: Icons.groups_outlined,
                alignment: CrossAxisAlignment.start,
              ),
              StatisticCard(
                value: attendancePercent(avg),
                label: 'Cohort Attendance',
                icon: Icons.show_chart,
                valueColor: colorForAttendance(context, avg),
                alignment: CrossAxisAlignment.start,
              ),
              StatisticCard(
                value:
                    '${data.sessions.where((s) => s.status == SessionStatus.completed).length}',
                label: 'Sessions',
                icon: Icons.event_repeat,
                alignment: CrossAxisAlignment.start,
              ),
              StatisticCard(
                value: data.course.room ?? 'Not assigned',
                label: 'Room',
                icon: Icons.meeting_room_outlined,
                alignment: CrossAxisAlignment.start,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RosterTab extends StatelessWidget {
  const _RosterTab({
    required this.data,
    required this.query,
    required this.filter,
    required this.onQuery,
    required this.onFilter,
    required this.onReload,
  });

  final _RosterData data;
  final String query;
  final String filter;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onFilter;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final summaryByStudent = {for (final s in data.summaries) s.studentId: s};
    final recordByStudent = {
      for (final r in data.latestRecords) r.studentId: r,
    };
    final q = query.toLowerCase();
    final students = data.roster.where((student) {
      final summary =
          summaryByStudent[student.id] ??
          AttendanceModel(
            studentId: student.id,
            totalSessions: 0,
            presentCount: 0,
            lateCount: 0,
            absentCount: 0,
          );
      final record = recordByStudent[student.id];
      final matchesQuery =
          q.isEmpty ||
          student.user.fullName.toLowerCase().contains(q) ||
          student.matricule.toLowerCase().contains(q);
      final matchesFilter = switch (filter) {
        'Present' => record?.status.countsAsAttended ?? false,
        'Absent' => record?.status == AttendanceStatus.absent,
        'At Risk' =>
          summary.percentage < AppConstants.attendanceWarningThreshold,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.spaceMd),
      children: [
        SearchField(
          hint: 'Search student by name or matricule...',
          onChanged: onQuery,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in ['All', 'Present', 'Absent', 'At Risk'])
                Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.spaceSm),
                  child: ChoiceChip(
                    label: Text(
                      f == 'At Risk'
                          ? '<${AppConstants.attendanceWarningThreshold.round()}% At Risk'
                          : f,
                    ),
                    selected: filter == f,
                    onSelected: (_) => onFilter(f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        Row(
          children: [
            Expanded(
              child: Text(
                'Enrolled Cohort (${students.length} Students)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        for (final student in students)
          StudentRosterItem(
            student: student,
            summary:
                summaryByStudent[student.id] ??
                AttendanceModel(
                  studentId: student.id,
                  totalSessions: 0,
                  presentCount: 0,
                  lateCount: 0,
                  absentCount: 0,
                ),
            latestRecord: recordByStudent[student.id],
            onAdjust: () =>
                _adjust(context, student, data.latestSession, onReload),
            onHistory: () => _history(context, student),
          ),
        const SizedBox(height: AppDimensions.spaceMd),
        SecondaryButton(
          label: 'Export CSV',
          icon: Icons.download,
          onPressed: () =>
              exportAndNotify(context, reportIdForCourse(data.course)),
        ),
      ],
    );
  }

  Future<void> _adjust(
    BuildContext context,
    StudentModel student,
    ClassSessionModel? session,
    Future<void> Function() reload,
  ) async {
    if (session == null) {
      Helpers.showSnackBar(
        context,
        'No session available to adjust.',
        isError: true,
      );
      return;
    }
    try {
      await context.read<AttendanceRepository>().markAttendance(
        sessionId: session.id,
        studentId: student.id,
        status: AttendanceStatus.present,
      );
      if (!context.mounted) return;
      Helpers.showSnackBar(
        context,
        'Attendance adjusted for ${student.user.fullName}.',
      );
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _history(BuildContext context, StudentModel student) async {
    final records = await context
        .read<AttendanceRepository>()
        .getStudentRecords(student.id, courseId: data.course.id);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(AppDimensions.pageMargin),
        children: [
          Text(
            '${student.user.fullName} History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          for (final record in records)
            ListTile(
              leading: Icon(
                record.status.countsAsAttended
                    ? Icons.check_circle
                    : Icons.cancel,
                color: StatusChip.colorsFor(
                  context,
                  toneForStatus(record.status),
                ).$2,
              ),
              title: Text(record.status.label),
              subtitle: Text(Formatters.dateTime(record.sessionStart)),
            ),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.sessions});
  final List<ClassSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.spaceMd),
      children: [
        for (final session in sessions)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
            onTap: () => Navigator.of(context)
                .pushNamed(RouteNames.liveAttendance, arguments: session.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LecturerSessionMeta(session: session),
                const SizedBox(height: AppDimensions.spaceSm),
                Text(
                  session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(session.room ?? 'Virtual room'),
              ],
            ),
          ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: AppDimensions.spaceMd),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              LecturerInfoRow(
                icon: Icons.meeting_room_outlined,
                label: 'Default Room',
                value: course.room ?? 'Not assigned',
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              LecturerInfoRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: course.category ?? 'Not set',
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              LecturerInfoRow(
                icon: Icons.schedule_outlined,
                label: 'Schedule',
                value: course.scheduleSummary ?? 'Flexible',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RosterData {
  const _RosterData({
    required this.course,
    required this.roster,
    required this.summaries,
    required this.sessions,
    required this.latestSession,
    required this.latestRecords,
  });

  final CourseModel course;
  final List<StudentModel> roster;
  final List<AttendanceModel> summaries;
  final List<ClassSessionModel> sessions;
  final ClassSessionModel? latestSession;
  final List<AttendanceRecordModel> latestRecords;
}
