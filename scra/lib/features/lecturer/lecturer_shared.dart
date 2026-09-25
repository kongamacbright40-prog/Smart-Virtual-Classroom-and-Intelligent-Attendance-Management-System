import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/cards/statistic_card.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/status_chip.dart';
import '../authentication/providers/auth_provider.dart';

String lecturerIdOf(BuildContext context) =>
    context.read<AuthProvider>().user!.id;

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime endOfDay(DateTime date) =>
    startOfDay(date).add(const Duration(days: 1));

String attendanceFraction(AttendanceModel summary) =>
    '${summary.attendedCount} / ${summary.totalSessions}';

String attendancePercent(double value) => '${value.round()}%';

StatusTone toneForAttendance(double percent) {
  if (percent >= 85) return StatusTone.success;
  if (percent >= 75) return StatusTone.warning;
  return StatusTone.error;
}

StatusTone toneForStatus(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => StatusTone.success,
  AttendanceStatus.late => StatusTone.warning,
  AttendanceStatus.absent => StatusTone.error,
  AttendanceStatus.excused => StatusTone.info,
};

Color colorForAttendance(BuildContext context, double percent) {
  if (percent >= 85) return AppColors.success;
  if (percent >= 75) return AppColors.warning;
  return Theme.of(context).colorScheme.error;
}

String reportIdForSession(ClassSessionModel session) =>
    'attendance-${session.courseCode}-${session.id}'.toLowerCase();

String reportIdForCourse(CourseModel course) =>
    'course-${course.code}-${course.id}'.toLowerCase();

Future<void> exportAndNotify(
  BuildContext context,
  String reportId, {
  ReportFormat format = ReportFormat.csv,
}) async {
  try {
    final file = await context.read<ReportRepository>().exportReport(
      reportId,
      format: format,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Export ready: $file')));
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class LecturerStatGrid extends StatelessWidget {
  const LecturerStatGrid({super.key, required this.cards});

  final List<StatisticCard> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: cards.length > 2 ? 3 : 2,
      mainAxisSpacing: AppDimensions.spaceSm,
      crossAxisSpacing: AppDimensions.spaceSm,
      childAspectRatio: cards.length > 2 ? 0.85 : 1.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

class LecturerInfoRow extends StatelessWidget {
  const LecturerInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class LecturerActionTile extends StatelessWidget {
  const LecturerActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SecondaryButton(
      label: label,
      icon: icon,
      expanded: false,
      style: SecondaryButtonStyle.tonal,
      backgroundColor: color ?? scheme.surfaceContainerHigh,
      onPressed: onTap,
    );
  }
}

class LecturerEmptyPanel extends StatelessWidget {
  const LecturerEmptyPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spaceXs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class LecturerSessionMeta extends StatelessWidget {
  const LecturerSessionMeta({super.key, required this.session});

  final ClassSessionModel session;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spaceSm,
      runSpacing: AppDimensions.spaceXs,
      children: [
        CodeTag(session.courseCode),
        StatusChip(
          label: session.status.label,
          tone: session.status == SessionStatus.live
              ? StatusTone.live
              : session.status == SessionStatus.completed
              ? StatusTone.success
              : StatusTone.neutral,
          showDot: session.status == SessionStatus.live,
        ),
        StatusChip(
          label: Formatters.timeRange(session.startTime, session.endTime),
          icon: Icons.schedule,
          tone: StatusTone.neutral,
        ),
      ],
    );
  }
}
