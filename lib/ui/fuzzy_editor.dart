import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;

import 'package:material_ui/material_ui.dart';

import '../domain/config.dart';
import '../domain/fuzzy.dart';
import 'controls.dart';

class FuzzyEditor extends StatefulWidget {
  const FuzzyEditor({super.key, required this.config, required this.onChanged});
  final LabConfig config;
  final VoidCallback onChanged;
  @override
  State<FuzzyEditor> createState() => _FuzzyEditorState();
}

class _FuzzyEditorState extends State<FuzzyEditor> {
  bool movingWidth = false;
  bool movingRun = false;
  void drag(Offset position, double width) {
    final x = ((position.dx - 24) / (width - 48)).clamp(0, 1).toDouble();
    if (movingWidth) {
      widget.config.width = (x - widget.config.center).abs().clamp(.05, .4);
    } else {
      widget.config.center = x.clamp(.08, .6);
    }
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<MembershipShape>(
        initialValue: widget.config.shape,
        decoration: const InputDecoration(labelText: 'Função fuzzy de entrada'),
        items: MembershipShape.values
            .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
            .toList(),
        onChanged: (s) {
          if (s != null) {
            widget.config.shape = s;
            widget.onChanged();
            setState(() {});
          }
        },
      ),
      const SizedBox(height: 16),
      const Text(
        'Entrada: tempo até impacto (s) × pertinência (0–1). Arraste os pontos.',
      ),
      LayoutBuilder(
        builder: (context, bounds) => GestureDetector(
          key: const Key('fuzzy-graph'),
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanDown: (d) {
            final x = (d.localPosition.dx - 24) / (bounds.maxWidth - 48);
            movingWidth =
                (x - widget.config.center - widget.config.width).abs() <
                (x - widget.config.center).abs();
          },
          onPanUpdate: (d) => drag(d.localPosition, bounds.maxWidth),
          child: CustomPaint(
            size: Size(bounds.maxWidth, 180),
            painter: FuzzyPainter(
              widget.config.copy(),
              Theme.of(context).colorScheme,
            ),
          ),
        ),
      ),
      NumberControl(
        label: 'Centro / inflexão (s)',
        value: widget.config.center,
        min: .08,
        max: .6,
        onChanged: (v) {
          widget.config.center = v;
          widget.onChanged();
          setState(() {});
        },
      ),
      NumberControl(
        label: 'Largura / dispersão (s)',
        value: widget.config.width,
        min: .05,
        max: .4,
        onChanged: (v) {
          widget.config.width = v;
          widget.onChanged();
          setState(() {});
        },
      ),
      const Text(
        'Saída Mamdani: correr e pular, exclusivamente triangulares. Centroide em [0, 1].',
      ),
      LayoutBuilder(
        builder: (context, bounds) => GestureDetector(
          key: const Key('fuzzy-output'),
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanDown: (d) {
            final x = (d.localPosition.dx - 24) / (bounds.maxWidth - 48);
            movingRun =
                (x - widget.config.runCenter).abs() <
                (x - widget.config.jumpCenter).abs();
          },
          onPanUpdate: (d) {
            final x = (d.localPosition.dx - 24) / (bounds.maxWidth - 48);
            if (movingRun) {
              widget.config.runCenter = x.clamp(.1, .4);
            } else {
              widget.config.jumpCenter = x.clamp(.6, .9);
            }
            widget.onChanged();
            setState(() {});
          },
          child: CustomPaint(
            size: Size(bounds.maxWidth, 120),
            painter: FuzzyPainter(
              widget.config.copy(),
              Theme.of(context).colorScheme,
              output: true,
            ),
          ),
        ),
      ),
      NumberControl(
        label: 'Saída correr — centro',
        value: widget.config.runCenter,
        min: .1,
        max: .4,
        onChanged: (v) {
          widget.config.runCenter = v;
          widget.onChanged();
          setState(() {});
        },
      ),
      NumberControl(
        label: 'Saída pular — centro',
        value: widget.config.jumpCenter,
        min: .6,
        max: .9,
        onChanged: (v) {
          widget.config.jumpCenter = v;
          widget.onChanged();
          setState(() {});
        },
      ),
      NumberControl(
        label: 'Largura das saídas triangulares',
        value: widget.config.outputWidth,
        min: .05,
        max: .3,
        onChanged: (v) {
          widget.config.outputWidth = v;
          widget.onChanged();
          setState(() {});
        },
      ),
    ],
  );
}

class FuzzyPainter extends CustomPainter {
  FuzzyPainter(this.config, this.colors, {this.output = false});
  final LabConfig config;
  final ColorScheme colors;
  final bool output;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - 48, h = size.height - 32;
    final axes = Paint()
      ..color = colors.outline
      ..strokeWidth = 1;
    canvas.drawLine(Offset(24, 8), Offset(24, h), axes);
    canvas.drawLine(Offset(24, h), Offset(w + 24, h), axes);
    for (var curve = 0; curve < (output ? 2 : 1); curve++) {
      final path = Path();
      for (var i = 0; i <= 200; i++) {
        final x = i / 200;
        final y = output
            ? triangle(
                x,
                curve == 0 ? config.runCenter : config.jumpCenter,
                config.outputWidth,
              )
            : membership(x, config);
        final point = Offset(24 + x * w, h - y * (h - 12));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = curve == 0 ? colors.primary : colors.tertiary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (output) {
      for (final x in [config.runCenter, config.jumpCenter]) {
        canvas.drawCircle(
          Offset(24 + x * w, 12),
          9,
          Paint()..color = colors.primary,
        );
      }
    } else {
      for (final x in [
        config.center,
        math.min(1.0, config.center + config.width),
      ]) {
        canvas.drawCircle(
          Offset(24 + x * w, h - membership(x, config) * (h - 12)),
          9,
          Paint()..color = colors.primary,
        );
      }
    }
    for (var i = 0; i <= 4; i++) {
      final label = TextPainter(
        text: TextSpan(
          text: (i / 4).toStringAsFixed(2),
          style: TextStyle(color: colors.onSurface, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(18 + w * i / 4, h + 3));
    }
  }

  @override
  bool shouldRepaint(covariant FuzzyPainter oldDelegate) => true;
}
