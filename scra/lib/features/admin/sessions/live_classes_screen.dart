import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_class/core/constants/app_dimensions.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/core/utils/helpers.dart';
import 'package:smart_class/features/admin/admin_ui.dart';
import 'package:smart_class/models/models.dart';
import 'package:smart_class/repositories/repositories.dart';
import 'package:smart_class/widgets/common/app_card.dart';
import 'package:smart_class/widgets/common/app_scaffold.dart';
import 'package:smart_class/widgets/common/async_view.dart';
import 'package:smart_class/widgets/common/empty_state.dart';
import 'package:smart_class/widgets/common/status_chip.dart';
import 'package:smart_class/widgets/dialogs/confirmation_dialog.dart';

/// Classes running right now. Admins can end a class left open by mistake.
class LiveClassesScreen extends StatelessWidget {
  const LiveClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AdminScreenHeader(title: 'Active Classes', showBack: true),
      body: AsyncView<List<ClassSessionModel>>(
        load: () => context.read<AdminRepository>().getLiveSessions(),
        builder: (context, sessions, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            children: [
              if (sessions.isEmpty)
                const EmptyState(
                  icon: Icons.sensors_off_outlined,
                  title: 'No class is live right now',
                  message:
                      'Classes appear here while a lecturer is teaching. '
                      'Classes left open long after their end time are '
                      'closed automatically.',
                )
              else
                for (final session in sessions) ...[
                  _LiveClassTile(
                    session: session,
                    onEnd: () => _end(context, session, reload),
                  ),
                  const SizedBox(height: AppDimensions.spaceSm),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _end(
    BuildContext context,
    ClassSessionModel session,
    Future<void> Function() reload,
  ) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'End this class?',
      message:
          '${session.courseCode}: ${session.title}\nEveryone connected will '
          'be disconnected.',
      confirmLabel: 'End class',
      destructive: true,
      icon: Icons.stop_circle_outlined,
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<ClassroomRepository>().endClass(session.id);
      if (context.mounted) Helpers.showSnackBar(context, 'Class ended.');
      await reload();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }
}

class _LiveClassTile extends StatelessWidget {
  const _LiveClassTile({required this.session, required this.onEnd});

  final ClassSessionModel session;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.courseCode,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const StatusChip(label: 'Live', tone: StatusTone.live),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            session.title,
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            [
              session.lecturerName ?? 'Lecturer',
              'Started ${Formatters.relativeDay(session.startTime)}',
              '${session.participantCount}/${session.expectedCount} connected',
            ].join(' \u2022 '),
            style: theme.textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: Key('end_class_${session.id}'),
              onPressed: onEnd,
              icon: Icon(
                Icons.stop_circle_outlined,
                color: theme.colorScheme.error,
              ),
              label: Text(
                'End class',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
