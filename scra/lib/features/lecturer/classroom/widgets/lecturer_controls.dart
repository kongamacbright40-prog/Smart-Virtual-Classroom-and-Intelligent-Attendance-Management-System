import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';

class LecturerControls extends StatelessWidget {
  const LecturerControls({
    super.key,
    required this.onWhiteboard,
    required this.onAttendance,
    required this.onBroadcastNote,
  });

  final VoidCallback onWhiteboard;
  final VoidCallback onAttendance;
  final VoidCallback onBroadcastNote;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spaceSm,
      runSpacing: AppDimensions.spaceSm,
      children: [
        FilledButton.tonalIcon(
          onPressed: onWhiteboard,
          icon: const Icon(Icons.draw),
          label: const Text('Board'),
        ),
        FilledButton.tonalIcon(
          onPressed: onAttendance,
          icon: const Icon(Icons.how_to_reg),
          label: const Text('Attendance'),
        ),
        FilledButton.tonalIcon(
          onPressed: onBroadcastNote,
          icon: const Icon(Icons.campaign),
          label: const Text('Broadcast'),
        ),
      ],
    );
  }
}
