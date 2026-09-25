import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../providers/classroom_controller.dart';
import '../../../providers/classroom_registry.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/loading_state.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/dialogs/confirmation_dialog.dart';
import 'widgets/classroom_toolbar.dart';
import 'widgets/lecturer_controls.dart';
import 'widgets/participant_panel.dart';

class LecturerLiveClassroomScreen extends StatelessWidget {
  const LecturerLiveClassroomScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return ClassroomScope(
      sessionId: sessionId,
      child: const _LecturerLiveClassroomBody(),
    );
  }
}

class _LecturerLiveClassroomBody extends StatefulWidget {
  const _LecturerLiveClassroomBody();

  @override
  State<_LecturerLiveClassroomBody> createState() =>
      _LecturerLiveClassroomBodyState();
}

class _LecturerLiveClassroomBodyState
    extends State<_LecturerLiveClassroomBody> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClassroomController>();
    final session = controller.session;
    if (controller.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: LoadingState(),
      );
    }
    if (controller.errorMessage != null || session == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.darkNavy,
          foregroundColor: Colors.white,
        ),
        backgroundColor: AppColors.darkNavy,
        body: ErrorState(
          title: 'Classroom unavailable',
          message: controller.errorMessage ?? 'Session not found',
        ),
      );
    }
    final present = controller.sessionAttendance
        .where((r) => r.status.countsAsAttended)
        .length;
    final elapsed = DateTime.now().difference(session.startTime);
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageMargin),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.expand_more),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppDimensions.spaceSm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CodeTag(session.courseCode, onDark: true),
                          const StatusChip(
                            label: 'REC',
                            tone: StatusTone.error,
                            showDot: true,
                          ),
                          StatusChip(
                            label: Formatters.duration(elapsed),
                            icon: Icons.schedule,
                            tone: StatusTone.neutral,
                          ),
                        ],
                      ),
                      Text(
                        session.courseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Wrap(
              spacing: AppDimensions.spaceSm,
              runSpacing: AppDimensions.spaceSm,
              children: [
                StatusChip(
                  label: '$present / ${session.expectedCount} Present',
                  tone: StatusTone.live,
                  showDot: true,
                ),
                const StatusChip(
                  label: 'BLE Active',
                  icon: Icons.sensors,
                  tone: StatusTone.info,
                ),
                const StatusChip(
                  label: '1080p HD',
                  icon: Icons.wifi_tethering,
                  tone: StatusTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            _Stage(controller: controller, session: session),
            const SizedBox(height: AppDimensions.spaceMd),
            LecturerControls(
              onWhiteboard: () =>
                  Navigator.of(context)
                      .pushNamed(RouteNames.whiteboard, arguments: session.id),
              onAttendance: () => Navigator.of(context)
                  .pushNamed(RouteNames.liveAttendance, arguments: session.id),
              onBroadcastNote: () =>
                  Helpers.showSnackBar(context, 'Broadcast sent to the class.'),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            if (controller.lastQuestion != null)
              _QuestionSummary(question: controller.lastQuestion!),
            const SizedBox(height: AppDimensions.spaceLg),
            ParticipantPanel(
              participants: controller.participants,
              onLowerHand: (id) => controller.lowerHand(id),
            ),
            const SizedBox(height: AppDimensions.spaceLg),
            ClassroomToolbar(
              micOn: controller.micEnabled,
              cameraOn: controller.cameraEnabled,
              screenSharing: controller.screenSharing,
              onMic: () => controller.toggleMicrophone(),
              onCamera: () => controller.toggleCamera(),
              onShare: () =>
                  Navigator.of(context)
                      .pushNamed(RouteNames.whiteboard, arguments: session.id),
              onQuestion: () => Navigator.of(context)
                  .pushNamed(RouteNames.createQuestion, arguments: session.id),
              onChat: () => Navigator.of(context)
                  .pushNamed(RouteNames.lecturerChat, arguments: session.id),
              onEnd: () => _endClass(context, controller),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _endClass(
    BuildContext context,
    ClassroomController controller,
  ) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'End Class?',
      message: 'This will end the live room and lock attendance.',
      confirmLabel: 'End Class',
      destructive: true,
      icon: Icons.call_end,
    );
    if (!ok) return;
    try {
      await controller.endClass();
      if (context.mounted) Navigator.of(context).maybePop();
    } on Object catch (e) {
      if (context.mounted) Helpers.showError(context, e);
    }
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.controller, required this.session});

  final ClassroomController controller;
  final ClassSessionModel session;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.screenSharing
                    ? 'SCREEN SHARE'
                    : 'ALGORITHM VISUALIZATION',
                style: const TextStyle(
                  color: AppColors.sky400,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                session.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              const Text(
                'AVL_Rotations_Deck.pdf (14/28)',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: Icon(
              controller.screenSharing
                  ? Icons.screen_share
                  : Icons.account_tree_outlined,
              size: 86,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 112,
              height: 130,
              padding: const EdgeInsets.all(AppDimensions.spaceSm),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryContainer, width: 3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                color: Colors.black26,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const StatusChip(label: 'Host', tone: StatusTone.primary),
                  const Spacer(),
                  Text(
                    controller.user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionSummary extends StatelessWidget {
  const _QuestionSummary({required this.question});
  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Question Results',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            question.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      option.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: question.percentFor(option.id) / 100,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Text(
                    '${option.responseCount}${option.id == question.correctOptionId ? ' ★' : ''}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
