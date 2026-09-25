import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';

class ClassroomToolbar extends StatelessWidget {
  const ClassroomToolbar({
    super.key,
    required this.micOn,
    required this.cameraOn,
    required this.screenSharing,
    required this.onMic,
    required this.onCamera,
    required this.onShare,
    required this.onQuestion,
    required this.onChat,
    required this.onEnd,
  });

  final bool micOn;
  final bool cameraOn;
  final bool screenSharing;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final VoidCallback onShare;
  final VoidCallback onQuestion;
  final VoidCallback onChat;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppDimensions.spaceMd,
            runSpacing: AppDimensions.spaceSm,
            children: [
              _ToolButton(
                icon: micOn ? Icons.mic : Icons.mic_off,
                label: micOn ? 'Mute' : 'Unmute',
                onTap: onMic,
              ),
              _ToolButton(
                icon: cameraOn ? Icons.videocam : Icons.videocam_off,
                label: 'Camera',
                onTap: onCamera,
              ),
              _ToolButton(
                icon: screenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                label: screenSharing ? 'Sharing' : 'Share',
                onTap: onShare,
              ),
              _ToolButton(
                icon: Icons.quiz_outlined,
                label: 'Poll',
                badge: '1',
                onTap: onQuestion,
              ),
              _ToolButton(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                badge: '3',
                onTap: onChat,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('end_class'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: onEnd,
              icon: const Icon(Icons.call_end),
              label: const Text('End Class'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
              if (badge != null)
                Positioned(
                  right: -2,
                  top: -2,
                  child: CircleAvatar(
                    radius: 10,
                    child: Text(badge!, style: const TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
