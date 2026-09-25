import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/classroom_controller.dart';
import '../../../providers/classroom_registry.dart';

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
  final List<_Stroke> _strokes = [];
  Color _color = AppColors.sky400;
  double _width = 5;
  bool _eraser = false;

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
            GestureDetector(
              onPanStart: (details) => setState(
                () => _strokes.add(
                  _Stroke(
                    color: _eraser ? AppColors.darkNavy : _color,
                    width: _eraser ? 18 : _width,
                    points: [details.localPosition],
                  ),
                ),
              ),
              onPanUpdate: (details) => setState(
                () => _strokes.last.points.add(details.localPosition),
              ),
              child: Container(
                height: 420,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  border: Border.all(color: Colors.white12),
                ),
                child: CustomPaint(
                  painter: _WhiteboardPainter(_strokes),
                  child: const SizedBox.expand(),
                ),
              ),
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
                  onPressed: _strokes.isEmpty
                      ? null
                      : () => setState(() => _strokes.removeLast()),
                  icon: const Icon(Icons.undo),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(_strokes.clear),
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

class _Stroke {
  _Stroke({required this.color, required this.width, required this.points});
  final Color color;
  final double width;
  final List<Offset> points;
}

class _WhiteboardPainter extends CustomPainter {
  const _WhiteboardPainter(this.strokes);
  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 1; i < stroke.points.length; i++) {
        canvas.drawLine(stroke.points[i - 1], stroke.points[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) => true;
}
