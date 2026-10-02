import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../models/whiteboard_model.dart';

/// Renders the class whiteboard at a fixed aspect ratio. When the pan
/// callbacks are given (lecturer) it reports pointer positions as fractions
/// of the board size; without them (students) it is read-only.
class WhiteboardView extends StatelessWidget {
  const WhiteboardView({
    super.key,
    required this.board,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.borderRadius = 16,
  });

  final Whiteboard board;
  final ValueChanged<Offset>? onPanStart;
  final ValueChanged<Offset>? onPanUpdate;
  final VoidCallback? onPanEnd;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: Whiteboard.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          Offset norm(Offset p) => Offset(
            (p.dx / size.width).clamp(0.0, 1.0),
            (p.dy / size.height).clamp(0.0, 1.0),
          );
          return GestureDetector(
            onPanStart: onPanStart == null
                ? null
                : (d) => onPanStart!(norm(d.localPosition)),
            onPanUpdate: onPanUpdate == null
                ? null
                : (d) => onPanUpdate!(norm(d.localPosition)),
            onPanEnd: onPanEnd == null ? null : (_) => onPanEnd!(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(Whiteboard.background),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: CustomPaint(
                  painter: _BoardPainter(board),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter(this.board);
  final Whiteboard board;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in board.strokes) {
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = (stroke.width * size.width).clamp(1.0, 60.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final points = [
        for (final p in stroke.points)
          Offset(p.dx * size.width, p.dy * size.height),
      ];
      if (points.length == 1) {
        canvas.drawPoints(PointMode.points, points, paint);
        continue;
      }
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  // The board is mutated in place; repaint on every rebuild.
  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
