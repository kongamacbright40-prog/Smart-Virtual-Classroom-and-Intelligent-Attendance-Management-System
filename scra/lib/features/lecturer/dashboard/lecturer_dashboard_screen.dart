import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../authentication/providers/auth_provider.dart';
import '../lecturer_shared.dart';
import 'widgets/lecturer_summary.dart';
import 'widgets/upcoming_class_card.dart';

class LecturerDashboardScreen extends StatelessWidget {
  const LecturerDashboardScreen({super.key});

  Future<_DashboardData> _load(BuildContext context) async {
    final lecturerId = lecturerIdOf(context);
    final courseRepository = context.read<CourseRepository>();
    final scheduleRepository = context.read<ScheduleRepository>();
    final reportRepository = context.read<ReportRepository>();
    final notificationRepository = context.read<NotificationRepository>();
    final attendanceRepository = context.read<AttendanceRepository>();
    final now = DateTime.now();
    // Independent requests: load them at the same time.
    final results = await Future.wait<Object>([
      courseRepository.getLecturerCourses(lecturerId),
      scheduleRepository.getLecturerSessions(
        lecturerId,
        from: now.subtract(const Duration(days: 7)),
        to: now.add(const Duration(days: 7)),
      ),
      reportRepository.getLecturerReport(lecturerId),
      notificationRepository.getNotifications(lecturerId),
    ]);
    final courses = results[0] as List<CourseModel>;
    final sessions = results[1] as List<ClassSessionModel>;
    final report = results[2] as ReportModel;
    final notifications = results[3] as List<NotificationModel>;
    final recent =
        sessions.where((s) => s.status == SessionStatus.completed).toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final latest = recent.take(3).toList();
    final records = await Future.wait(
      latest.map((s) => attendanceRepository.getSessionAttendance(s.id)),
    );
    final attendance = <String, List<AttendanceRecordModel>>{
      for (var i = 0; i < latest.length; i++) latest[i].id: records[i],
    };
    return _DashboardData(
      courses: courses,
      sessions: sessions,
      report: report,
      pendingAppeals: notifications
          .where((n) => !n.isRead && n.title.toLowerCase().contains('appeal'))
          .length,
      attendance: attendance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Lecturer Dashboard',
        showBack: false,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.15),
            child: Icon(
              Icons.school_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.lecturerProfile),
            icon: const Icon(Icons.account_circle),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(RouteNames.scheduleClass),
        icon: const Icon(Icons.add),
        label: const Text('Create Class'),
      ),
      body: AsyncView<_DashboardData>(
        load: () => _load(context),
        builder: (context, data, reload) {
          final live = data.sessions
              .where((s) => s.status == SessionStatus.live)
              .cast<ClassSessionModel?>()
              .firstOrNull;
          final upcoming =
              live ??
              (data.sessions
                      .where(
                        (s) =>
                            s.status == SessionStatus.scheduled &&
                            s.startTime.isAfter(DateTime.now()),
                      )
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime)))
                  .cast<ClassSessionModel?>()
                  .firstOrNull;
          final recent = data.attendance.keys
              .map((id) => data.sessions.firstWhere((s) => s.id == id))
              .toList();
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.pageMargin),
              children: [
                Row(
                  children: [
                    UserAvatar(
                      name: user.fullName,
                      size: 56,
                      imageUrl: user.avatarUrl,
                      showOnline: true,
                    ),
                    const SizedBox(width: AppDimensions.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.departmentName == null
                                ? 'Faculty Portal'
                                : 'Faculty Portal • ${user.departmentName}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 0.7,
                                ),
                          ),
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .pushNamed(RouteNames.notifications),
                      icon: const Icon(Icons.notifications_active_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      LecturerActionTile(
                        icon: Icons.poll_outlined,
                        label: 'Launch Quick Poll',
                        onTap: () {
                          if (live == null) {
                            Helpers.showSnackBar(
                              context,
                              'No live class is running.',
                            );
                            return;
                          }
                          Navigator.of(context).pushNamed(
                            RouteNames.createQuestion,
                            arguments: live.id,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                LecturerSummary(
                  assignedCourses: data.courses.length,
                  averageAttendance: data.report.metricOrNull('average_rate'),
                  pendingAppeals: data.pendingAppeals,
                ),
                const SizedBox(height: AppDimensions.spaceLg),
                if (upcoming != null)
                  UpcomingClassCard(session: upcoming)
                else
                  const LecturerEmptyPanel(
                    title: 'No classes scheduled',
                    message: 'Create a class to open a new room.',
                  ),
                SectionHeader(
                  title: 'Recent Sessions',
                  subtitle: 'This Week',
                  actionLabel: 'View All',
                  onAction: () =>
                      Navigator.of(context)
                          .pushNamed(RouteNames.attendanceReports),
                ),
                for (final session in recent)
                  _RecentSessionCard(
                    session: session,
                    records: data.attendance[session.id] ?? const [],
                  ),
                const SizedBox(height: 96),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  const _RecentSessionCard({required this.session, required this.records});

  final ClassSessionModel session;
  final List<AttendanceRecordModel> records;

  @override
  Widget build(BuildContext context) {
    final present = records.where((r) => r.status.countsAsAttended).length;
    final total = records.isEmpty ? session.expectedCount : records.length;
    final rate = total == 0 ? 0.0 : present / total * 100;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CodeTag(session.courseCode),
              const Spacer(),
              const StatusChip(
                label: 'Completed',
                tone: StatusTone.success,
                showDot: true,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            session.courseTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            '${Formatters.relativeDay(session.startTime)} • ${Formatters.duration(session.duration)}',
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceSm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.how_to_reg_outlined),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(child: Text('$present / $total Present')),
                Text(
                  attendancePercent(rate),
                  style: TextStyle(
                    color: colorForAttendance(context, rate),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Wrap(
            spacing: AppDimensions.spaceSm,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(RouteNames.liveAttendance, arguments: session.id),
                icon: const Icon(Icons.chevron_right),
                label: const Text('View Attendance Log'),
              ),
              TextButton.icon(
                onPressed: () =>
                    exportAndNotify(context, reportIdForSession(session)),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.courses,
    required this.sessions,
    required this.report,
    required this.pendingAppeals,
    required this.attendance,
  });

  final List<CourseModel> courses;
  final List<ClassSessionModel> sessions;
  final ReportModel report;
  final int pendingAppeals;
  final Map<String, List<AttendanceRecordModel>> attendance;
}
