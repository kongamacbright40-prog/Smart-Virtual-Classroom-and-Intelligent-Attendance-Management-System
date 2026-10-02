import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/whiteboard_model.dart';
import '../../../providers/classroom_controller.dart';
import '../../../providers/classroom_registry.dart';
import '../../../widgets/media/whiteboard_view.dart';

class WhiteboardScreen extends StatelessWidget {
  const WhiteboardScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return ClassroomScope(sessionId: sessionId, child: const _WhiteboardBody());
  }
}

class _WhiteboardBody extends StatefulWidget {
  const _WhiteboardBody();

  @override
  State<_WhiteboardBody> createState() => _WhiteboardBodyState();
}

class _WhiteboardBodyState extends State<_WhiteboardBody> {
  /// Pen width as a fraction of the board width (same look on every screen).
  static const double _penScale = 1 / 600;
  static const double _eraserWidth = 18 * _penScale;

  Color _color = AppColors.sky400;
  double _width = 5;
  bool _eraser = false;
  ClassroomController? _controller;

  @override
  void initState() {
    super.initState();
    // Opening the whiteboard shows it on the students' screens (unless the
    // screen is being shared; then it appears when sharing stops).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller?.setBoardVisible(true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = context.read<ClassroomController>();
  }

  @override
  void dispose() {
    // Leaving the whiteboard hides it again for students (the drawing stays).
    // Deferred: listeners must not be notified while the tree is unmounting.
    final controller = _controller;
    Future.microtask(() {
      controller?.endStroke();
      controller?.setBoardVisible(false);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClassroomController>();
    final session = controller.session;
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageMargin),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    session == null
                        ? 'Whiteboard'
                        : '${session.courseCode} • ${session.courseTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
                Text(
                  '${controller.participantCount}',
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(Icons.groups, color: Colors.white70),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Text(
              controller.screenSharing
                  ? 'Students now see your shared screen. The board is hidden '
                        'for them until you stop sharing.'
                  : 'Students see this board live while this screen is open.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: controller.screenSharing
                    ? Colors.red.shade700
                    : AppColors.primaryContainer,
              ),
              onPressed: () async {
                try {
                  await controller.toggleScreenShare();
                } on Object catch (e) {
                  if (context.mounted) Helpers.showError(context, e);
                }
              },
              icon: Icon(
                controller.screenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
              ),
              label: Text(
                controller.screenSharing ? 'Stop Share' : 'Share Screen',
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            WhiteboardView(
              key: const Key('whiteboard_canvas'),
              board: controller.board,
              onPanStart: (p) => controller.beginStroke(
                color: _eraser ? Whiteboard.background : _color.toARGB32(),
                width: _eraser ? _eraserWidth : _width * _penScale,
                point: p,
              ),
              onPanUpdate: controller.extendStroke,
              onPanEnd: controller.endStroke,
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppDimensions.spaceSm,
              runSpacing: AppDimensions.spaceSm,
              children: [
                IconButton.filled(
                  onPressed: () => setState(() => _eraser = false),
                  icon: const Icon(Icons.edit),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _eraser = true),
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
                for (final c in [
                  AppColors.sky400,
                  Colors.amber,
                  Colors.pinkAccent,
                  Colors.white,
                ])
                  GestureDetector(
                    onTap: () => setState(() {
                      _color = c;
                      _eraser = false;
                    }),
                    child: CircleAvatar(backgroundColor: c, radius: 18),
                  ),
                SizedBox(
                  width: 120,
                  child: Slider(
                    value: _width,
                    min: 2,
                    max: 12,
                    onChanged: (v) => setState(() => _width = v),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Undo',
                  onPressed: controller.board.strokes.isEmpty
                      ? null
                      : controller.undoStroke,
                  icon: const Icon(Icons.undo),
                ),
                IconButton.filledTonal(
                  tooltip: 'Clear board',
                  onPressed: controller.clearBoard,
                  icon: const Icon(Icons.delete_sweep),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      RouteNames.createQuestion,
                      arguments: controller.sessionId,
                    ),
                    icon: const Icon(Icons.live_help),
                    label: const Text('Questions'),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      RouteNames.lecturerChat,
                      arguments: controller.sessionId,
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
