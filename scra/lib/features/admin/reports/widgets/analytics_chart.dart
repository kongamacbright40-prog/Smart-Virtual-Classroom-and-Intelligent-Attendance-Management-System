
import 'package:flutter/material.dart';

import 'package:smart_class/core/constants/app_colors.dart';
import 'package:smart_class/models/models.dart';

class AnalyticsChart extends StatelessWidget {
  const AnalyticsChart({
    super.key,
    required this.current,
    required this.previous,
  });

  final List<ReportDataPoint> current;
  final List<ReportDataPoint> previous;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: CustomPaint(
        painter: _AnalyticsChartPainter(current: current, previous: previous, textColor: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _AnalyticsChartPainter extends CustomPainter {
  _AnalyticsChartPainter({required this.current, required this.previous, required this.textColor});

  final List<ReportDataPoint> current;
  final List<ReportDataPoint> previous;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = textColor.withValues(alpha: 0.12)..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = 12 + (size.height - 34) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    void drawSeries(List<ReportDataPoint> data, Color color, bool dashed) {
      if (data.isEmpty) return;
      final path = Path();
      for (var i = 0; i < data.length; i++) {
        final x = data.length == 1 ? size.width / 2 : i * size.width / (data.length - 1);
        final y = 12 + (100 - data[i].value.clamp(0, 100)) / 100 * (size.height - 34);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      if (dashed) {
        final metrics = path.computeMetrics();
        final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;
        for (final metric in metrics) {
          var distance = 0.0;
          while (distance < metric.length) {
            canvas.drawPath(metric.extractPath(distance, (distance + 8).clamp(0, metric.length)), paint);
            distance += 14;
          }
        }
      } else {
        canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
      }
    }
    drawSeries(previous, AppColors.slate400, true);
    drawSeries(current, AppColors.primaryContainer, false);
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < current.length; i++) {
      final x = current.length == 1 ? size.width / 2 : i * size.width / (current.length - 1);
      labelPainter.text = TextSpan(text: current[i].label, style: TextStyle(color: textColor, fontSize: 10));
      labelPainter.layout();
      labelPainter.paint(canvas, Offset((x - labelPainter.width / 2).clamp(0, size.width - labelPainter.width), size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _AnalyticsChartPainter oldDelegate) => oldDelegate.current != current || oldDelegate.previous != previous;
}
