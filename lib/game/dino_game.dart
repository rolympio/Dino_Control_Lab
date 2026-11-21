import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';

import '../data/session.dart';
import '../domain/config.dart';
import '../domain/controller.dart';
import '../domain/simulation.dart';
import 'scene.dart';

class DinoGame extends FlameGame {
  DinoGame(
    LabConfig config, {
    required this.classic,
    required this.onFinished,
    required this.onSound,
  }) : sim = Simulation(config.copy()),
       session = Session(config, classic: classic);
  final bool classic;
  final void Function(Session) onFinished;
  final void Function(String) onSound;
  final Simulation sim;
  final Session session;
  final Controller controller = Controller();
  bool userPaused = false,
      heldDuck = false,
      pendingJump = false,
      finished = false;
  double accumulator = 0;
  Color ink = const Color(0xff202820);
  Color paper = const Color(0xfff6f7f3);
  void jump() {
    if (!userPaused && !sim.crashed) pendingJump = true;
  }

  void change(LabConfig config) {
    final next = config.copy();
    sim.config.physics = next.physics;
    sim.config.controller = next.controller;
    sim.config.character = next.character;
    sim.config.threshold = next.threshold;
    sim.config.adaptation = next.adaptation;
    sim.config.shape = next.shape;
    sim.config.center = next.center;
    sim.config.width = next.width;
    sim.config.horizon = next.horizon;
    sim.config.runCenter = next.runCenter;
    sim.config.jumpCenter = next.jumpCenter;
    sim.config.outputWidth = next.outputWidth;
    session.changed(sim.ticks, sim.config);
  }

  void finish(String reason) {
    if (finished) return;
    finished = true;
    session.outcome = reason;
    onFinished(session);
  }

  @override
  Color backgroundColor() => paper;
  @override
  void update(double dt) {
    super.update(dt);
    if (userPaused || sim.crashed || finished) return;
    accumulator += math.min(dt, .1);
    while (accumulator >= Simulation.step) {
      final move = classic
          ? (pendingJump
                ? Move.jump
                : heldDuck
                ? Move.duck
                : Move.run)
          : controller.decide(sim);
      pendingJump = false;
      final jumps = sim.jumps;
      sim.advance(move);
      if (sim.jumps != jumps) onSound('jump');
      session.record(sim, move);
      accumulator -= Simulation.step;
      if (sim.crashed) {
        onSound('hit');
        finish('colisão');
        break;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x == 0 || size.y == 0) return;
    canvas.save();
    // Obstacles spawn at x = 1000, so the whole 1000 px world width must fit
    // or narrow phones lose part of the preview. Also keep ~220 px of height
    // (ground margin + highest jump) visible in short, wide windows.
    final factor = math.min(size.x / 1000, size.y / 220);
    canvas.scale(factor);
    final ground = size.y / factor - 30;
    final paint = Paint()..color = ink;
    canvas.drawLine(Offset(0, ground), Offset(size.x / factor, ground), paint);
    for (var i = 0; i < 25; i++) {
      final x = (i * 53 - sim.distance * .5) % 1100;
      canvas.drawLine(Offset(x, ground + 9), Offset(x + 9, ground + 9), paint);
    }
    drawDino(canvas, sim, ground, paint);
    for (final obstacle in sim.obstacles) {
      drawObstacle(canvas, obstacle, ground, sim.time, paint);
    }
    canvas.restore();
  }
}
