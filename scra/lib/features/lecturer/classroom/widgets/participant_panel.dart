import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common/user_avatar.dart';

class ParticipantPanel extends StatelessWidget {
  const ParticipantPanel({
    super.key,
    required this.participants,
    required this.onLowerHand,
  });

  final List<ParticipantModel> participants;
  final ValueChanged<String> onLowerHand;

  @override
  Widget build(BuildContext context) {
    final students = participants.where((p) => !p.isLecturer).toList()
      ..sort(
        (a, b) =>
            b.isHandRaised.toString().compareTo(a.isHandRaised.toString()),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Active Classroom Participants',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Text(
              '${students.length} Students',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.take(4).length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppDimensions.spaceSm,
            crossAxisSpacing: AppDimensions.spaceSm,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final p = students[index];
            return Container(
              padding: const EdgeInsets.all(AppDimensions.spaceSm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: p.isHandRaised ? Colors.orangeAccent : Colors.white24,
                ),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    name: p.name,
                    size: 40,
                    statusColor: p.isSpeaking ? Colors.greenAccent : null,
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          p.isHandRaised
                              ? 'Hand Raised'
                              : p.isMuted
                              ? 'Audio muted'
                              : 'Speaking...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  if (p.isHandRaised)
                    IconButton(
                      tooltip: 'Lower hand',
                      onPressed: () => onLowerHand(p.userId),
                      icon: const Icon(
                        Icons.front_hand,
                        color: Colors.orangeAccent,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
