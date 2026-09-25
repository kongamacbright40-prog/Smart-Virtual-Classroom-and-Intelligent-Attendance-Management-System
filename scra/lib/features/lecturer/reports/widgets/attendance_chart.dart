import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../models/models.dart';

class AttendanceChart extends StatelessWidget {
  const AttendanceChart({super.key, required this.points});

  final List<ReportDataPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _AttendanceChartPainter(
          points: points,
          color: Theme.of(context).colorScheme.primary,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
          textColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AttendanceChartPainter extends CustomPainter {
  const _AttendanceChartPainter({
    required this.points,
    required this.color,
    required this.gridColor,
    required this.textColor,
  });

  final List<ReportDataPoint> points;
  final Color color;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..color = color;
    final fill = Paint()..color = color.withValues(alpha: 0.16);
    final grid = Paint()
      ..strokeWidth = 1
      ..color = gridColor.withValues(alpha: 0.5);
    final chart = Rect.fromLTWH(8, 8, size.width - 16, size.height - 32);
    for (var i = 0; i < 4; i++) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    if (points.isEmpty) return;
    final step = points.length == 1
        ? chart.width
        : chart.width / (points.length - 1);
    final path = Path();
    final area = Path();
    for (var i = 0; i < points.length; i++) {
      final x = chart.left + step * i;
      final y =
          chart.bottom - (points[i].value.clamp(0, 100) / 100) * chart.height;
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, chart.bottom);
        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 40);
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, chart.bottom + AppDimensions.spaceXs),
      );
    }
    area.lineTo(chart.right, chart.bottom);
    area.close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AttendanceChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
