import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../services/webrtc_service.dart';

/// Live video of the local user ([peerId] == null) or of a remote participant.
///
/// Shows [placeholder] whenever there is no video to render: media not
/// connected, the peer has not sent a stream yet, the camera is off, or a
/// non-WebRTC [WebRTCService] (tests) is in use. Rebuild it when the
/// [MediaState] changes (e.g. from a ClassroomController listener).
class VideoTile extends StatelessWidget {
  const VideoTile({
    super.key,
    this.peerId,
    required this.placeholder,
    this.screen = false,
    this.showVideo = true,
    this.mirror = false,
    this.fit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
  });

  /// Remote peer (profile) id; `null` shows the local camera / screen share.
  final String? peerId;

  /// Show [peerId]'s shared screen instead of their camera.
  final bool screen;
  final Widget placeholder;

  /// Set to `false` when the camera is known to be off.
  final bool showVideo;
  final bool mirror;
  final RTCVideoViewObjectFit fit;

  @override
  Widget build(BuildContext context) {
    final service = context.read<WebRTCService>();
    if (!showVideo || service is! FlutterWebRTCService) return placeholder;
    final RTCVideoRenderer? renderer = peerId == null
        ? (service.hasLocalVideo ? service.localRenderer : null)
        : screen
        ? service.remoteScreenRenderers[peerId]
        : service.remoteRenderers[peerId];
    if (renderer == null) return placeholder;
    return RTCVideoView(
      renderer,
      objectFit: fit,
      mirror: mirror,
      // Shown until the first frame arrives.
      placeholderBuilder: (_) => placeholder,
    );
  }
}
