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
  late DateTime _selected = _initialDay();
  Future<List<ClassSessionModel>>? _future;

  DateTime _initialDay() {
    final now = DateTime.now();
    if (now.weekday >= DateTime.monday && now.weekday <= DateTime.friday) {
      return app_dates.AppDateUtils.dateOnly(now);
    }
    return app_dates.AppDateUtils.dateOnly(
      now.subtract(Duration(days: now.weekday - DateTime.monday)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<ClassSessionModel>> _load() {
    final id = context.read<AuthProvider>().user!.id;
    final from = _selected;
    final to = from.add(const Duration(days: 1));
    return context.read<ScheduleRepository>().getStudentSessions(
      id,
      from: from,
      to: to,
    );
  }

  void _select(DateTime day) {
    setState(() {
      _selected = day;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: SmartAppBar(title: 'Schedule', showBack: false),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              Chip(
                label: Text(
                  '${app_dates.AppDateUtils.monthsLong[_selected.month - 1]} ${_selected.year}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          _WeekSelector(selected: _selected, onSelected: _select),
          const SizedBox(height: AppDimensions.spaceLg),
          FutureBuilder<List<ClassSessionModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return ErrorState(
                  error: snapshot.error,
                  onRetry: () => setState(() => _future = _load()),
                );
              }
              final sessions = snapshot.data ?? const <ClassSessionModel>[];
              if (sessions.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No classes this day',
                  message: 'Pick another day in the week.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${app_dates.AppDateUtils.isToday(_selected) ? 'Today' : app_dates.AppDateUtils.weekdaysLong[_selected.weekday - 1]} • ${sessions.length} Classes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _select(_initialDay()),
                        child: const Text('Jump to Today →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
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
            },
          ),
        ],
      ),
    );
  }
}

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({required this.selected, required this.onSelected});

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          Expanded(
            child: _DayButton(
              day: monday.add(Duration(days: i)),
              selected: app_dates.AppDateUtils.isSameDay(
                selected,
                monday.add(Duration(days: i)),
              ),
              onTap: onSelected,
            ),
          ),
          if (i < 4) const SizedBox(width: AppDimensions.spaceSm),
        ],
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerLow;
    final fg = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: () => onTap(day),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
          child: Column(
            children: [
              Text(
                app_dates.AppDateUtils.weekdaysShort[day.weekday - 1]
                    .toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: fg),
              ),
              Text(
                '${day.day}',
                style: theme.textTheme.titleLarge?.copyWith(color: fg),
              ),
              if (app_dates.AppDateUtils.isToday(day))
                Icon(
                  Icons.circle,
                  size: 6,
                  color: selected ? fg : theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
