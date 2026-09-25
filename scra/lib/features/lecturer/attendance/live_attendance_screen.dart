import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../providers/classroom_controller.dart';
import '../../../providers/classroom_registry.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/cards/statistic_card.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/async_view.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/inputs/search_field.dart';
import '../lecturer_shared.dart';
import 'widgets/attendance_student_item.dart';

class LiveAttendanceScreen extends StatefulWidget {
  const LiveAttendanceScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  String _query = '';
  String _filter = 'All';

  Future<ClassSessionModel?> _resolveSession(BuildContext context) async {
    if (widget.sessionId != null) {
      return context.read<ScheduleRepository>().getSession(widget.sessionId!);
    }
    final lecturerId = lecturerIdOf(context);
    final today = DateTime.now();
    final sessions = await context
        .read<ScheduleRepository>()
        .getLecturerSessions(
          lecturerId,
          from: startOfDay(today),
          to: endOfDay(today),
        );
    final live = sessions
        .where((s) => s.status == SessionStatus.live)
        .firstOrNull;
    if (live != null) return live;
    final completed =
        sessions.where((s) => s.status == SessionStatus.completed).toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return completed.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Live Attendance',
        subtitle: widget.sessionId == null ? null : 'Session log',
        showBack: widget.sessionId != null ? null : false,
      ),
      body: AsyncView<ClassSessionModel?>(
        load: () => _resolveSession(context),
        isEmpty: (session) => session == null,
        empty: const EmptyState(
          title: 'No attendance session',
          message: 'There is no live or recent class to show.',
        ),
        builder: (context, session, reload) {
          if (session == null) return const SizedBox.shrink();
          if (session.status == SessionStatus.live) {
            return ClassroomScope(
              sessionId: session.id,
              child: _LiveAttendanceBody(
                session: session,
                query: _query,
                filter: _filter,
                onQuery: (v) => setState(() => _query = v),
                onFilter: (v) => setState(() => _filter = v),
                reload: reload,
              ),
            );
          }
          return _CompletedAttendanceBody(
            session: session,
            query: _query,
            filter: _filter,
            onQuery: (v) => setState(() => _query = v),
            onFilter: (v) => setState(() => _filter = v),
            reload: reload,
          );
        },
      ),
    );
  }
}

class _LiveAttendanceBody extends StatelessWidget {
  const _LiveAttendanceBody({
    required this.session,
    required this.query,
    required this.filter,
    required this.onQuery,
    required this.onFilter,
    required this.reload,
  });

  final ClassSessionModel session;
  final String query;
  final String filter;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onFilter;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClassroomController>();
    return _AttendanceContent(
      session: controller.session ?? session,
      records: controller.sessionAttendance,
      query: query,
      filter: filter,
      onQuery: onQuery,
      onFilter: onFilter,
      onStatus: (studentId, status) async {
        await controller.markAttendance(studentId, status);
        if (context.mounted) {
          Helpers.showSnackBar(context, 'Attendance updated.');
        }
      },
      onLock: () async {
        if (controller.attendanceActive) {
          await controller.endAttendance();
        } else {
          await controller.startAttendance();
        }
      },
      attendanceActive: controller.attendanceActive,
    );
  }
}

class _CompletedAttendanceBody extends StatelessWidget {
  const _CompletedAttendanceBody({
    required this.session,
    required this.query,
    required this.filter,
    required this.onQuery,
    required this.onFilter,
    required this.reload,
  });

  final ClassSessionModel session;
  final String query;
  final String filter;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onFilter;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<AttendanceRecordModel>>(
      load: () =>
          context.read<AttendanceRepository>().getSessionAttendance(session.id),
      builder: (context, records, _) => _AttendanceContent(
        session: session,
        records: records,
        query: query,
        filter: filter,
        onQuery: onQuery,
        onFilter: onFilter,
        attendanceActive: false,
        onStatus: (studentId, status) async {
          await context.read<AttendanceRepository>().markAttendance(
            sessionId: session.id,
            studentId: studentId,
            status: status,
          );
          if (context.mounted) {
            Helpers.showSnackBar(context, 'Attendance updated.');
            await reload();
          }
        },
        onLock: null,
      ),
    );
  }
}

class _AttendanceContent extends StatelessWidget {
  const _AttendanceContent({
    required this.session,
    required this.records,
    required this.query,
    required this.filter,
    required this.onQuery,
    required this.onFilter,
    required this.onStatus,
    required this.attendanceActive,
    required this.onLock,
  });

  final ClassSessionModel session;
  final List<AttendanceRecordModel> records;
  final String query;
  final String filter;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onFilter;
  final Future<void> Function(String studentId, AttendanceStatus status)
  onStatus;
  final bool attendanceActive;
  final Future<void> Function()? onLock;

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final present = records
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    final absent = records
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
    final cohort = session.expectedCount == 0
        ? records.length
        : session.expectedCount;
    final attended = present + late;
    final attendanceRate = cohort == 0 ? 0.0 : attended / cohort * 100;
    final visible = records.where((r) {
      final matchesQuery =
          q.isEmpty ||
          r.studentName.toLowerCase().contains(q) ||
          (r.matricule ?? '').toLowerCase().contains(q);
      final matchesFilter = switch (filter) {
        'Present' => r.status == AttendanceStatus.present,
        'Late' => r.status == AttendanceStatus.late,
        'Absent' => r.status == AttendanceStatus.absent,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pageMargin),
      children: [
        Wrap(
          spacing: AppDimensions.spaceSm,
          runSpacing: AppDimensions.spaceSm,
          children: [
            const Chip(label: Text('LIVE NOW')),
            Text(
              '${Formatters.duration(DateTime.now().difference(session.startTime))} elapsed',
            ),
          ],
        ),
        Text(
          session.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          [
            if (session.room != null) session.room!,
            session.mode.label,
          ].join(' • '),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimensions.spaceSm,
          crossAxisSpacing: AppDimensions.spaceSm,
          children: [
            StatisticCard(
              value: '$cohort',
              label: 'Cohort',
              icon: Icons.groups_outlined,
              alignment: CrossAxisAlignment.start,
            ),
            StatisticCard(
              value: '$present',
              label: 'Present',
              icon: Icons.how_to_reg,
              valueColor: colorForAttendance(context, attendanceRate),
              alignment: CrossAxisAlignment.start,
            ),
            StatisticCard(
              value: '$late',
              label: 'Late Arrival',
              icon: Icons.schedule,
              valueColor: Colors.orange,
              alignment: CrossAxisAlignment.start,
            ),
            StatisticCard(
              value: '$absent',
              label: 'Absent',
              icon: Icons.person_off_outlined,
              valueColor: Theme.of(context).colorScheme.error,
              alignment: CrossAxisAlignment.start,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in ['All', 'Present', 'Late', 'Absent'])
                Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.spaceSm),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: filter == f,
                    onSelected: (_) => onFilter(f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        SearchField(
          hint: 'Search student by name or matricule...',
          onChanged: onQuery,
        ),
        const SizedBox(height: AppDimensions.spaceMd),
        for (final record in visible)
          AttendanceStudentItem(
            record: record,
            onStatus: (status) => onStatus(record.studentId, status),
          ),
        const SizedBox(height: AppDimensions.spaceMd),
        SecondaryButton(
          label: attendanceActive ? 'Lock Session' : 'Start Attendance',
          icon: attendanceActive ? Icons.lock_open : Icons.play_arrow,
          onPressed: onLock == null ? null : () => onLock!(),
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        SecondaryButton(
          label: 'Export Report',
          icon: Icons.ios_share,
          onPressed: () =>
              exportAndNotify(context, reportIdForSession(session)),
        ),
      ],
    );
  }
}
