import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/session.dart';

class TraceChart extends StatefulWidget {
  const TraceChart({super.key, required this.session});
  final Session session;
  @override
  State<TraceChart> createState() => _TraceChartState();
}

class _TraceChartState extends State<TraceChart> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final points = widget.session.samples;
    if (points.isEmpty) return const Text('Sessão sem amostras.');
    final sample = points[index.clamp(0, points.length - 1)];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, bounds) {
            void inspect(Offset p) => setState(
              () => index = ((p.dx / bounds.maxWidth) * (points.length - 1))
                  .round()
                  .clamp(0, points.length - 1),
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => inspect(d.localPosition),
              onTapDown: (d) => inspect(d.localPosition),
              child: CustomPaint(
                size: Size(bounds.maxWidth, 220),
                painter: TracePainter(
                  points,
                  index,
                  Theme.of(context).colorScheme,
                ),
              ),
            );
          },
        ),
        Text(
          't = ${(sample['time_s'] as num).toStringAsFixed(2)} s · '
          'altura = ${(sample['height_px'] as num).toStringAsFixed(1)} px',
        ),
        Slider(
          value: index.toDouble(),
          max: math.max(1, points.length - 1).toDouble(),
          onChanged: (v) => setState(() => index = v.round()),
        ),
      ],
    );
  }
}

class TracePainter extends CustomPainter {
  TracePainter(this.points, this.index, this.colors);
  final List<Map<String, dynamic>> points;
  final int index;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final maximum = points.fold<double>(
      100,
      (v, p) => math.max(v, (p['height_px'] as num).toDouble()),
    );
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / math.max(1, points.length - 1) * size.width;
      final y =
          size.height -
          16 -
          (points[i]['height_px'] as num) / maximum * (size.height - 32);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final x = index / math.max(1, points.length - 1) * size.width;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()..color = colors.outline,
    );
  }

  @override
  bool shouldRepaint(covariant TracePainter oldDelegate) => true;
}
