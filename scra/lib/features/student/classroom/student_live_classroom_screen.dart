import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show RTCVideoViewObjectFit;
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../../providers/classroom_controller.dart';
import '../../../providers/classroom_registry.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/loading_state.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/user_avatar.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';
import '../../../widgets/media/media_notice_banner.dart';
import '../../../widgets/media/video_tile.dart';
import '../../../widgets/media/whiteboard_view.dart';
import 'widgets/classroom_controls.dart';
import 'widgets/participant_list.dart';
import 'widgets/question_card.dart';

class StudentLiveClassroomScreen extends StatelessWidget {
  const StudentLiveClassroomScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return ClassroomScope(
      sessionId: sessionId,
      child: const _StudentLiveClassroomBody(),
    );
  }
}

class _StudentLiveClassroomBody extends StatelessWidget {
  const _StudentLiveClassroomBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClassroomController>();
    if (controller.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: LoadingState(message: 'Joining live classroom...'),
      );
    }
    if (controller.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: SafeArea(
          child: ErrorState(
            title: 'Could not join class',
            message: controller.errorMessage,
            onRetry: () => controller.init(),
          ),
        ),
      );
    }
    final session = controller.session!;
    return AppScaffold(
      backgroundColor: AppColors.darkNavy,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ClassroomHeader(controller: controller, session: session),
          const SizedBox(height: AppDimensions.spaceMd),
          if (controller.myAttendance != null)
            _AttendanceBanner(record: controller.myAttendance!),
          if (controller.mediaNotice != null) ...[
            const SizedBox(height: AppDimensions.spaceSm),
            MediaNoticeBanner(message: controller.mediaNotice!),
          ],
          const SizedBox(height: AppDimensions.spaceMd),
          Expanded(
            child: ListView(
              children: [
                _LecturerStage(controller: controller, session: session),
                const SizedBox(height: AppDimensions.spaceMd),
                ParticipantList(participants: controller.participants),
                const SizedBox(height: AppDimensions.spaceMd),
                if (controller.activeQuestion != null &&
                    controller.myResponse == null)
                  QuestionCard(
                    question: controller.activeQuestion!,
                    onTap: () => Navigator.of(context).pushNamed(
                      RouteNames.liveQuestion,
                      arguments: controller.sessionId,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          ClassroomControls(
            controller: controller,
            onChat: () => Navigator.of(context).pushNamed(
              RouteNames.classroomChat,
              arguments: controller.sessionId,
            ),
            onQuestion: controller.activeQuestion == null
                ? null
                : () => Navigator.of(context).pushNamed(
                    RouteNames.liveQuestion,
                    arguments: controller.sessionId,
                  ),
            onLeave: () => _leave(context, controller),
          ),
        ],
      ),
    );
  }

  Future<void> _leave(
    BuildContext context,
    ClassroomController controller,
  ) async {
    final navigator = Navigator.of(context);
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Leave live classroom?',
      message: 'Your attendance remains logged, but you will disconnect from the session.',
      confirmLabel: 'Leave',
      destructive: true,
      icon: Icons.call_end,
    );
    if (!ok) return;
    await controller.leave();
    if (navigator.canPop()) navigator.pop();
  }
}

class _ClassroomHeader extends StatelessWidget {
  const _ClassroomHeader({required this.controller, required this.session});

  final ClassroomController controller;
  final ClassSessionModel session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.courseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    const StatusChip(
                      label: 'LIVE',
                      tone: StatusTone.error,
                      showDot: true,
                    ),
                  ],
                ),
                Text(
                  '${session.lecturerName ?? 'Lecturer'} • ${Formatters.duration(DateTime.now().difference(session.startTime))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate300,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            avatar: const Icon(Icons.group, size: 18),
            label: Text('${controller.participantCount}'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceBanner extends StatelessWidget {
  const _AttendanceBanner({required this.record});

  final AttendanceRecordModel record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.successContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  record.checkedInAt == null
                      ? 'Attendance Logged • ${record.status.label}'
                      : 'Attendance Logged • ${record.status.label} (${Formatters.time(record.checkedInAt!)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (record.verificationMethod != null) ...[
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              record.verificationMethod!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _LecturerStage extends StatelessWidget {
  const _LecturerStage({required this.controller, required this.session});

  final ClassroomController controller;
  final ClassSessionModel session;

  @override
  Widget build(BuildContext context) {
    final lecturer = controller.lecturer;
    final theme = Theme.of(context);
    final lecturerPeerId = lecturer?.userId ?? session.lecturerId;
    final sharing = controller.board.screenSharing && !controller.boardActive;
    final camera = VideoTile(
      key: ValueKey('lecturer-video-$lecturerPeerId'),
      peerId: lecturerPeerId,
      fit: sharing
          ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
          : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
      placeholder: Center(
        child: Icon(
          sharing ? Icons.person_outline : Icons.smart_display_outlined,
          size: sharing ? 28 : 92,
          color: Colors.white.withValues(alpha: sharing ? 0.5 : 0.18),
        ),
      ),
    );
    return Container(
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.primaryContainer, width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF10203A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          if (sharing) ...[
            // The lecturer's shared screen (with its sound), shown whole.
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: VideoTile(
                  key: ValueKey('lecturer-screen-$lecturerPeerId'),
                  peerId: lecturerPeerId,
                  screen: true,
                  fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  placeholder: const Center(
                    child: Text(
                      'Waiting for the shared screen…',
                      key: Key('student_screen_waiting'),
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            // Lecturer camera as a small picture-in-picture.
            Positioned(
              top: AppDimensions.spaceSm,
              left: AppDimensions.spaceSm,
              width: 112,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: ColoredBox(
                  color: const Color(0xFF0F172A),
                  child: camera,
                ),
              ),
            ),
          ] else
            Positioned.fill(child: camera),
          if (controller.boardActive)
            Positioned.fill(
              child: ColoredBox(
                key: const Key('student_whiteboard'),
                color: const Color(Whiteboard.background),
                child: Center(
                  child: WhiteboardView(
                    board: controller.board,
                    borderRadius: 0,
                  ),
                ),
              ),
            ),
          // Keeps the name readable on top of bright video.
          if (!controller.boardActive && !sharing)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          Positioned(
            top: AppDimensions.spaceMd,
            right: AppDimensions.spaceMd,
            child: StatusChip(
              label: controller.boardActive
                  ? 'Whiteboard'
                  : sharing
                  ? 'Screen share'
                  : session.mode.label,
              tone: controller.boardActive
                  ? StatusTone.info
                  : StatusTone.neutral,
            ),
          ),
          if (!controller.boardActive && !sharing)
            Positioned(
              left: AppDimensions.spaceMd,
              right: AppDimensions.spaceMd,
              bottom: AppDimensions.spaceMd,
              child: Row(
                children: [
                  UserAvatar(
                    name: lecturer?.name ?? session.lecturerName ?? 'Lecturer',
                  ),
                  const SizedBox(width: AppDimensions.spaceMd),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lecturer?.name ??
                              session.lecturerName ??
                              'Course Lecturer',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Course Lecturer • ${session.courseCode}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.slate300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
