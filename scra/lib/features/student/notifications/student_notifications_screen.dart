import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/empty_state.dart';
import '../../authentication/providers/auth_provider.dart';
import 'widgets/notification_item.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return AsyncView<List<NotificationModel>>(
      load: () =>
          context.read<NotificationRepository>().getNotifications(user.id),
      builder: (context, notifications, reload) {
        final unread = notifications.where((n) => !n.isRead).length;
        final filtered = _applyFilter(notifications);
        return AppScaffold(
          appBar: SmartAppBar(
            title: 'Notifications',
            actions: [
              IconButton(
                onPressed: () => _markAll(context, user.id, reload),
                tooltip: 'Mark all as read',
                icon: const Icon(Icons.done_all),
              ),
            ],
          ),
          scrollable: true,
          onRefresh: reload,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: notifications.length,
                      selected: _filter == 'All',
                      onTap: () => setState(() => _filter = 'All'),
                    ),
                    _FilterChip(
                      label: 'Unread',
                      count: unread,
                      selected: _filter == 'Unread',
                      onTap: () => setState(() => _filter = 'Unread'),
                    ),
                    _FilterChip(
                      label: 'Classes',
                      selected: _filter == 'Classes',
                      onTap: () => setState(() => _filter = 'Classes'),
                    ),
                    _FilterChip(
                      label: 'Attendance',
                      selected: _filter == 'Attendance',
                      onTap: () => setState(() => _filter = 'Attendance'),
                    ),
                    _FilterChip(
                      label: 'Grades',
                      selected: _filter == 'Grades',
                      onTap: () => setState(() => _filter = 'Grades'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              Wrap(
                spacing: AppDimensions.spaceSm,
                runSpacing: AppDimensions.spaceXs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('TODAY', style: Theme.of(context).textTheme.titleMedium),
                  Chip(label: Text('$unread new')),
                  const Text('Auto-clears in 48h'),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              if (filtered.isEmpty)
                const EmptyState(
                  icon: Icons.task_alt,
                  title: "You're completely caught up!",
                  message: 'No unreviewed notifications remain from this week.',
                )
              else
                for (final notification in filtered) ...[
                  StudentNotificationItem(
                    notification: notification,
                    onTap: () => _open(context, user, notification, reload),
                    onAction: () => _open(context, user, notification, reload),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                ],
              const EmptyState(
                compact: true,
                icon: Icons.task_alt,
                title: "You're completely caught up!",
                message: 'No unreviewed notifications remain from this week.',
              ),
            ],
          ),
        );
      },
    );
  }

  List<NotificationModel> _applyFilter(List<NotificationModel> items) {
    return items.where((n) {
      return switch (_filter) {
        'Unread' => !n.isRead,
        'Classes' =>
          n.type == NotificationType.classReminder ||
              n.type == NotificationType.liveQuestion,
        'Attendance' => n.type == NotificationType.attendanceUpdate,
        'Grades' => n.type == NotificationType.announcement,
        _ => true,
      };
    }).toList();
  }

  Future<void> _markAll(
    BuildContext context,
    String userId,
    Future<void> Function() reload,
  ) async {
    try {
      await context.read<NotificationRepository>().markAllAsRead(userId);
      await reload();
    } catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<void> _open(
    BuildContext context,
    UserModel user,
    NotificationModel notification,
    Future<void> Function() reload,
  ) async {
    final navigator = Navigator.of(context);
    try {
      await context.read<NotificationRepository>().markAsRead(notification.id);
      await reload();
      if (!context.mounted) return;
      if (user.role != UserRole.student) return;
      final ref = notification.referenceId;
      if (ref == null) return;
      if (ref.startsWith('crs-')) {
        navigator.pushNamed(RouteNames.courseDetails, arguments: ref);
      } else if (ref.startsWith('ses-')) {
        navigator.pushNamed(RouteNames.studentLiveClassroom, arguments: ref);
      } else if (notification.type == NotificationType.liveQuestion) {
        final live = await _findLiveSession(context, user.id);
        if (live != null && context.mounted) {
          navigator.pushNamed(RouteNames.liveQuestion, arguments: live.id);
        }
      }
    } catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }

  Future<ClassSessionModel?> _findLiveSession(
    BuildContext context,
    String userId,
  ) async {
    final now = DateTime.now();
    final sessions = await context
        .read<ScheduleRepository>()
        .getStudentSessions(
          userId,
          from: now.subtract(const Duration(hours: 3)),
          to: now.add(const Duration(hours: 3)),
        );
    for (final s in sessions) {
      if (s.status == SessionStatus.live) return s;
    }
    return null;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spaceSm),
      child: ChoiceChip(
        selected: selected,
        label: Text(count == null ? label : '$label  $count'),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
