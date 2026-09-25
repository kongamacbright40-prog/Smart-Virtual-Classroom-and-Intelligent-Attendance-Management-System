import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/common/status_chip.dart';

class UpcomingClassCard extends StatelessWidget {
  const UpcomingClassCard({super.key, required this.session});

  final ClassSessionModel session;

  @override
  Widget build(BuildContext context) {
    final isLive = session.status == SessionStatus.live;
    final starts = session.startTime.difference(DateTime.now()).inMinutes;
    final label = isLive
        ? 'LIVE NOW'
        : starts > 0
        ? 'Starts in $starts min'
        : 'Ready to start';
    return AppCard(
      color: AppColors.primary,
      borderColor: AppColors.primaryContainer,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppDimensions.spaceSm,
              runSpacing: AppDimensions.spaceSm,
              children: [
                StatusChip(
                  label: label,
                  tone: isLive ? StatusTone.live : StatusTone.info,
                  showDot: true,
                  uppercase: true,
                ),
                const StatusChip(
                  label: 'BLE Active',
                  icon: Icons.sensors,
                  tone: StatusTone.info,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            Wrap(
              spacing: AppDimensions.spaceXs,
              children: [
                CodeTag(session.courseCode, onDark: true),
                Text('• ${session.mode.label}'),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Text(
              session.courseTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _WhiteMeta(
                      icon: Icons.meeting_room_outlined,
                      label: 'Location',
                      value: session.room ?? 'Virtual room',
                    ),
                  ),
                  Expanded(
                    child: _WhiteMeta(
                      icon: Icons.group_outlined,
                      label: 'Cohort',
                      value: '${session.expectedCount} Enrolled',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    key: Key(isLive ? 'open_live_class' : 'start_class'),
                    label: isLive ? 'Open Live Class' : 'Start Class',
                    icon: isLive ? Icons.open_in_new : Icons.play_arrow,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    onPressed: () => Navigator.of(context).pushNamed(
                      RouteNames.lecturerLiveClassroom,
                      arguments: session.id,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_scanner),
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteMeta extends StatelessWidget {
  const _WhiteMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: AppDimensions.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
