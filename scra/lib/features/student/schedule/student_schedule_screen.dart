import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../../core/utils/date_utils.dart' as app_dates;
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/loading_state.dart';
import '../../authentication/providers/auth_provider.dart';
import 'widgets/schedule_item.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  late DateTime _selected = _today();
  Future<List<ClassSessionModel>>? _future;

  /// Last week loaded, shown while a background refresh runs.
  List<ClassSessionModel>? _shown;
  Timer? _timer;

  static DateTime _today() => app_dates.AppDateUtils.dateOnly(DateTime.now());

  DateTime get _weekStart => app_dates.AppDateUtils.startOfWeek(_selected);

  @override
  void initState() {
    super.initState();
    // Picks up classes the lecturer schedules while this screen is open.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Loads the whole week of [_selected] (Monday to Sunday).
  Future<List<ClassSessionModel>> _load() {
    final id = context.read<AuthProvider>().user!.id;
    final from = _weekStart;
    final to = DateTime(from.year, from.month, from.day + 7);
    return context.read<ScheduleRepository>().getStudentSessions(
      id,
      from: from,
      to: to,
    );
  }

  void _refresh() {
    if (mounted) setState(() => _future = _load());
  }

  void _select(DateTime day) {
    final newWeek = !app_dates.AppDateUtils.isSameDay(
      app_dates.AppDateUtils.startOfWeek(day),
      _weekStart,
    );
    setState(() {
      _selected = app_dates.AppDateUtils.dateOnly(day);
      if (newWeek) {
        _shown = null;
        _future = _load();
      }
    });
  }

  void _shiftWeek(int weeks) => _select(
    DateTime(_selected.year, _selected.month, _selected.day + 7 * weeks),
  );

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: SmartAppBar(
        title: 'Schedule',
        showBack: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      scrollable: true,
      body: FutureBuilder<List<ClassSessionModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) _shown = snapshot.data;
          final week = _shown;
          final classDays = {
            for (final s in week ?? const <ClassSessionModel>[])
              app_dates.AppDateUtils.dateOnly(s.startTime),
          };
          final Widget content;
          if (week == null &&
              snapshot.connectionState == ConnectionState.waiting) {
            content = const LoadingState();
          } else if (week == null && snapshot.hasError) {
            content = ErrorState(error: snapshot.error, onRetry: _refresh);
          } else {
            final sessions =
                (week ?? const <ClassSessionModel>[])
                    .where(
                      (s) => app_dates.AppDateUtils.isSameDay(
                        s.startTime,
                        _selected,
                      ),
                    )
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
            content = _DayClasses(
              day: _selected,
              sessions: sessions,
              onToday: () => _select(_today()),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WeekHeader(
                weekStart: _weekStart,
                onPrevious: () => _shiftWeek(-1),
                onNext: () => _shiftWeek(1),
              ),
              const SizedBox(height: AppDimensions.spaceMd),
              _WeekSelector(
                selected: _selected,
                classDays: classDays,
                onSelected: _select,
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              content,
            ],
          );
        },
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
    String label(DateTime d) =>
        '${app_dates.AppDateUtils.monthsShort[d.month - 1]} ${d.day}';
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous week',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${label(weekStart)} – ${label(end)}, ${end.year}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Next week',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DayClasses extends StatelessWidget {
  const _DayClasses({
    required this.day,
    required this.sessions,
    required this.onToday,
  });

  final DateTime day;
  final List<ClassSessionModel> sessions;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final isToday = app_dates.AppDateUtils.isToday(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${isToday ? 'Today' : app_dates.AppDateUtils.weekdaysLong[day.weekday - 1]} • '
                '${sessions.length} ${sessions.length == 1 ? 'Class' : 'Classes'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (!isToday)
              TextButton(
                onPressed: onToday,
                child: const Text('Jump to Today →'),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        if (sessions.isEmpty)
          const EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No classes this day',
            message: 'Days with classes are marked with a dot.',
          ),
        for (final session in sessions) ...[
          ScheduleItem(
            session: session,
            onJoin: session.isLive
                ? () => Navigator.of(context).pushNamed(
                    RouteNames.studentLiveClassroom,
                    arguments: session.id,
                  )
                : null,
          ),
          const SizedBox(height: AppDimensions.spaceMd),
        ],
      ],
    );
  }
}

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.selected,
    required this.classDays,
    required this.onSelected,
  });

  final DateTime selected;
  final Set<DateTime> classDays;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final days = app_dates.AppDateUtils.weekDays(selected);
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          Expanded(
            child: _DayButton(
              day: days[i],
              selected: app_dates.AppDateUtils.isSameDay(selected, days[i]),
              hasClasses: classDays.any(
                (d) => app_dates.AppDateUtils.isSameDay(d, days[i]),
              ),
              onTap: onSelected,
            ),
          ),
          if (i < days.length - 1) const SizedBox(width: AppDimensions.spaceXs),
        ],
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.selected,
    required this.hasClasses,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool hasClasses;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = app_dates.AppDateUtils.isToday(day);
    final bg = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerLow;
    final fg = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: isToday && !selected
            ? BorderSide(color: theme.colorScheme.primary)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => onTap(day),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSm),
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  app_dates.AppDateUtils.weekdaysShort[day.weekday - 1]
                      .toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(color: fg),
                ),
              ),
              FittedBox(
                child: Text(
                  '${day.day}',
                  style: theme.textTheme.titleMedium?.copyWith(color: fg),
                ),
              ),
              Icon(
                Icons.circle,
                size: 6,
                color: hasClasses
                    ? (selected ? fg : theme.colorScheme.primary)
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
