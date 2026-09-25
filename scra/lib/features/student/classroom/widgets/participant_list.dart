import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common/user_avatar.dart';

class ParticipantList extends StatelessWidget {
  const ParticipantList({super.key, required this.participants});

  final List<ParticipantModel> participants;

  @override
  Widget build(BuildContext context) {
    final students = participants.where((p) => !p.isLecturer).take(4).toList();
    return GridView.builder(
      itemCount: students.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimensions.spaceSm,
        mainAxisSpacing: AppDimensions.spaceSm,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final p = students[index];
        return Container(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Stack(
            children: [
              Center(child: UserAvatar(name: p.name, size: 52)),
              Positioned(
                left: 0,
                bottom: 0,
                right: 26,
                child: Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  p.isMuted ? Icons.mic_off : Icons.mic,
                  color: p.isMuted ? AppColors.error : AppColors.success,
                  size: 18,
                ),
              ),
              if (p.isHandRaised)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: const Text('✋ Raised'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
