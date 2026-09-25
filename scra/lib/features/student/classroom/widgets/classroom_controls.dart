import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../providers/classroom_controller.dart';

class ClassroomControls extends StatelessWidget {
  const ClassroomControls({
    super.key,
    required this.controller,
    required this.onChat,
    required this.onLeave,
    this.onQuestion,
  });

  final ClassroomController controller;
  final VoidCallback onChat;
  final VoidCallback onLeave;
  final VoidCallback? onQuestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _RoundControl(
              icon: controller.micEnabled ? Icons.mic : Icons.mic_off,
              active: !controller.micEnabled,
              onPressed: () => controller.toggleMicrophone(),
            ),
            _RoundControl(
              icon: controller.cameraEnabled
                  ? Icons.videocam
                  : Icons.videocam_off,
              onPressed: () => controller.toggleCamera(),
            ),
            _RoundControl(
              icon: Icons.front_hand,
              active: controller.handRaised,
              onPressed: () => controller.toggleHand(),
            ),
            Badge(
              label: Text(
                '${controller.messages.where((m) => m.isQuestion).length}',
              ),
              child: _RoundControl(
                icon: Icons.chat_bubble_outline,
                onPressed: onChat,
              ),
            ),
            _RoundControl(icon: Icons.quiz_outlined, onPressed: onQuestion),
            const SizedBox(width: AppDimensions.spaceSm),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.liveRed),
              onPressed: onLeave,
              icon: const Icon(Icons.call_end),
              label: const Text('Leave'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    this.active = false,
    this.onPressed,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: active ? AppColors.warning : AppColors.slate700,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
