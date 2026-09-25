import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/cards/schedule_card.dart';

class ScheduleItem extends StatelessWidget {
  const ScheduleItem({super.key, required this.session, this.onJoin});

  final ClassSessionModel session;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final live = session.isLive;
    return ScheduleCard(
      session: session,
      footer: live
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppColors.slate300),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${DateTime.now().difference(session.startTime).inMinutes.clamp(0, 999)}m elapsed',
                        ),
                      ),
                      Text(
                        '${session.endTime.difference(DateTime.now()).inMinutes.clamp(0, 999)}m remaining',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSm),
                LinearProgressIndicator(
                  value: session.progressAt(DateTime.now()),
                ),
              ],
            )
          : session.status == SessionStatus.completed
          ? Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16),
                const SizedBox(width: AppDimensions.spaceXs),
                Expanded(
                  child: Text(
                    'Attended • ${Formatters.duration(session.duration)} logged',
                  ),
                ),
              ],
            )
          : null,
      action: live
          ? Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Join Now',
                    icon: Icons.videocam,
                    onPressed: onJoin,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ],
            )
          : null,
    );
  }
}
