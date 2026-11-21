import 'dart:ui';

import '../domain/config.dart';
import '../domain/simulation.dart';

void drawDino(Canvas canvas, Simulation s, double ground, Paint paint) {
  canvas.save();
  canvas.translate(Simulation.playerX, ground - s.y);
  final duck = s.ducking && s.y == 0;
  final leg = s.y > 0
      ? 0.0
      : (s.time * 12).floor().isEven
      ? 4.0
      : -4.0;
  if (s.config.character == CharacterKind.dino) {
    final path = Path();
    if (duck) {
      path.moveTo(0, -20);
      path.lineTo(28, -20);
      path.lineTo(28, -25);
      path.lineTo(48, -25);
      path.lineTo(48, -13);
      path.lineTo(29, -13);
      path.lineTo(22, -6);
      path.lineTo(6, -6);
      path.lineTo(0, -13);
    } else {
      path.moveTo(0, -30);
      path.lineTo(7, -22);
      path.lineTo(14, -22);
      path.lineTo(14, -44);
      path.lineTo(34, -44);
      path.lineTo(34, -29);
      path.lineTo(24, -29);
      path.lineTo(24, -16);
      path.lineTo(18, -6);
      path.lineTo(6, -6);
      path.lineTo(0, -15);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawRect(Rect.fromLTWH(8, -8, 5, 8 + leg), paint);
    canvas.drawRect(Rect.fromLTWH(19, -8, 5, 8 - leg), paint);
    canvas.drawCircle(
      Offset(duck ? 41 : 28, duck ? -21 : -39),
      2,
      Paint()..color = const Color(0xfff6f7f3),
    );
  } else {
    final robot = s.config.character == CharacterKind.robot;
    canvas.drawRect(
      Rect.fromLTWH(4, duck ? -22 : -30, duck ? 40 : 24, 20),
      paint,
    );
    if (robot) {
      canvas.drawRect(
        Rect.fromLTWH(duck ? 28 : 8, duck ? -24 : -44, 20, 14),
        paint,
      );
    } else {
      canvas.drawCircle(Offset(duck ? 38 : 19, duck ? -17 : -37), 8, paint);
    }
    canvas.drawRect(Rect.fromLTWH(7, -10, 6, 10 + leg), paint);
    canvas.drawRect(Rect.fromLTWH(22, -10, 6, 10 - leg), paint);
  }
  canvas.restore();
}

void drawObstacle(Canvas c, Obstacle o, double ground, double time, Paint p) {
  final y = ground - o.bottom - o.height;
  if (o.bird) {
    c.drawOval(Rect.fromLTWH(o.x, y + 8, o.width, 12), p);
    final flap = (time * 8).floor().isEven ? -8.0 : 16.0;
    final wing = Path()
      ..moveTo(o.x + 13, y + 12)
      ..lineTo(o.x + 23, y + flap)
      ..lineTo(o.x + 28, y + 12)
      ..close();
    c.drawPath(wing, p);
  } else {
    c.drawRect(
      Rect.fromLTWH(o.x + o.width * .35, y, o.width * .3, o.height),
      p,
    );
    c.drawRect(Rect.fromLTWH(o.x, y + 12, o.width, 8), p);
    c.drawRect(Rect.fromLTWH(o.x, y + 5, 6, 14), p);
    c.drawRect(Rect.fromLTWH(o.x + o.width - 6, y + 2, 6, 17), p);
  }
}
