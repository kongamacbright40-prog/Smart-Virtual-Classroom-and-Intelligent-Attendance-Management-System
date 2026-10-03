import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Warning shown in a live classroom when audio/video can't connect.
class MediaNoticeBanner extends StatelessWidget {
  const MediaNoticeBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('media_notice'),
      padding: const EdgeInsets.all(AppDimensions.spaceSm),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
