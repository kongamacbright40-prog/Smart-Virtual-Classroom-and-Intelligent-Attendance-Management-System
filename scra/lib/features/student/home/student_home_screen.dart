import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/icon_button.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/cards/course_card.dart' as shared;
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/progress_bar.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../../widgets/navigation/role_shell.dart';
import '../../authentication/providers/auth_provider.dart';
import 'widgets/student_header.dart';
import 'widgets/student_summary.dart';
import 'widgets/upcoming_class_card.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return AsyncView<_HomeData>(
      load: () => _HomeData.load(context, user.id),
      builder: (context, data, reload) {
        final unread = data.notifications.where((n) => !n.isRead).length;
        return AppScaffold(
          appBar: SmartAppBar(
            title: 'Home',
            showBack: false,
            leading: const Padding(
              padding: EdgeInsets.only(left: AppDimensions.spaceMd),
              child: Icon(Icons.school, color: AppColors.primary),
            ),
            actions: [
              AppIconButton(
                icon: Icons.notifications_outlined,
                tooltip: 'Notifications',
                badgeCount: unread == 0 ? null : unread,
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.notifications),
              ),
              AppIconButton(
                icon: Icons.person_outline,
                tooltip: 'Profile',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () =>
                    ShellScope.maybeOf(context)?.selectTab(StudentTabs.profile),
              ),
            ],
          ),
          scrollable: true,
          onRefresh: reload,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudentHeader(
                student: data.profile,
                unreadCount: unread,
                onSearch: () =>
                    Navigator.of(context).pushNamed(RouteNames.studentCourses),
                onNotifications: () =>
                    Navigator.of(context).pushNamed(RouteNames.notifications),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              if (data.liveSession != null)
                _LiveClassCard(session: data.liveSession!)
              else if (data.nextSession != null)
                UpcomingClassCard(
                  session: data.nextSession!,
                  onTap: () =>
                      ShellScope.maybeOf(context)
                          ?.selectTab(StudentTabs.schedule),
                )
              else
                const EmptyState(
                  compact: true,
                  icon: Icons.event_available_outlined,
                  title: 'No classes scheduled',
                  message: 'You are clear for now.',
                ),
              const SizedBox(height: AppDimensions.spaceLg),
              StudentSummary(student: data.profile),
              SectionHeader(
                title: 'MY COURSES',
                actionLabel: 'View All (${data.courses.length})',
                onAction: () =>
                    Navigator.of(context).pushNamed(RouteNames.studentCourses),
              ),
              for (final course in data.courses.take(2)) ...[
                shared.CourseCard(
                  course: course,
                  attendancePercent: data.attendance[course.id],
                  nextSessionLabel: data.nextLabels[course.id],
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(RouteNames.courseDetails, arguments: course.id),
                ),
                const SizedBox(height: AppDimensions.spaceMd),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LiveClassCard extends StatelessWidget {
  const _LiveClassCard({required this.session});

  final ClassSessionModel session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elapsed = DateTime.now().difference(session.startTime);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        gradient: const LinearGradient(
          colors: [AppColors.inverseSurface, Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              const StatusChip(
                label: 'LIVE NOW',
                tone: StatusTone.live,
                showDot: true,
                uppercase: true,
              ),
              CodeTag(session.courseCode, onDark: true),
              if (session.attendanceActive)
                const StatusChip(
                  label: 'Smart Attendance Active',
                  tone: StatusTone.info,
                  icon: Icons.sensors,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          Text(
            session.courseTitle.replaceAll(' & Algorithms', ''),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Row(
            children: [
              UserAvatar(name: session.lecturerName ?? 'Lecturer', size: 32),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  session.lecturerName ?? 'Course Lecturer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.live),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  Formatters.timeRange(session.startTime, session.endTime),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${elapsed.inMinutes.clamp(0, 999)}m elapsed',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          AppProgressBar(
            value: session.progressAt(DateTime.now()),
            color: AppColors.live,
            backgroundColor: Colors.white24,
          ),
          if (session.room != null) ...[
            const SizedBox(height: AppDimensions.spaceMd),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMd,
                vertical: AppDimensions.spaceSm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.meeting_room_outlined,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Text(
                      'Room: ${session.room}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceLg),
          PrimaryButton(
            key: const Key('join_live_session'),
            label: 'Join Live Session',
            icon: Icons.play_circle_outline,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(RouteNames.studentLiveClassroom, arguments: session.id),
          ),
        ],
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.profile,
    required this.courses,
    required this.sessions,
    required this.notifications,
    required this.attendance,
    required this.nextLabels,
  });

  final StudentModel profile;
  final List<CourseModel> courses;
  final List<ClassSessionModel> sessions;
  final List<NotificationModel> notifications;
  final Map<String, double> attendance;
  final Map<String, String> nextLabels;

  ClassSessionModel? get liveSession {
    for (final session in sessions) {
      if (session.status == SessionStatus.live) return session;
    }
    return null;
  }

  ClassSessionModel? get nextSession {
    final now = DateTime.now();
    for (final session in sessions) {
      if (session.startTime.isAfter(now)) return session;
    }
    return null;
  }

  static Future<_HomeData> load(BuildContext context, String studentId) async {
    final userRepo = context.read<UserRepository>();
    final courseRepo = context.read<CourseRepository>();
    final scheduleRepo = context.read<ScheduleRepository>();
    final attendanceRepo = context.read<AttendanceRepository>();
    final notificationRepo = context.read<NotificationRepository>();
    final now = DateTime.now();
    final results = await Future.wait<Object>([
      userRepo.getStudentProfile(studentId),
      courseRepo.getStudentCourses(studentId),
      scheduleRepo.getStudentSessions(
        studentId,
        from: now.subtract(const Duration(hours: 3)),
        to: now.add(const Duration(days: 7)),
      ),
      notificationRepo.getNotifications(studentId),
    ]);
    final profile = results[0] as StudentModel;
    final courses = results[1] as List<CourseModel>;
    final sessions = results[2] as List<ClassSessionModel>;
    final notifications = results[3] as List<NotificationModel>;
    final summaries = await Future.wait(
      courses.map(
        (c) => attendanceRepo.getStudentSummary(studentId, courseId: c.id),
      ),
    );
    final attendance = <String, double>{
      for (final summary in summaries)
        if (summary.courseId != null) summary.courseId!: summary.percentage,
    };
    final nextLabels = <String, String>{};
    for (final course in courses) {
      final next = sessions
          .where((s) => s.courseId == course.id && s.startTime.isAfter(now))
          .toList();
      if (next.isNotEmpty) {
        nextLabels[course.id] = Formatters.relativeDay(
          next.first.startTime,
          now: now,
        );
      }
    }
    return _HomeData(
      profile: profile,
      courses: courses,
      sessions: sessions,
      notifications: notifications,
      attendance: attendance,
      nextLabels: nextLabels,
    );
  }
}
