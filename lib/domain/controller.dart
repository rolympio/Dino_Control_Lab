import 'dart:math' as math;

import 'config.dart';
import 'fuzzy.dart';
import 'simulation.dart';

class Controller {
  double learnedLead = .23;
  int decisions = 0;
  Move decide(Simulation s) {
    decisions++;
    final o = s.nearest;
    if (o == null) return Move.run;
    final gap = o.x - Simulation.playerX - s.playerWidth;
    final ttc = gap / s.speed;
    if (o.bird && o.bottom >= 60) return Move.run;
    if (o.bird && o.bottom >= 25 && ttc < .45) return Move.duck;
    if (s.y > 0 || gap < -o.width) return Move.run;
    final c = s.config;
    return switch (c.controller) {
      ControllerKind.onOff => ttc < c.threshold ? Move.jump : Move.run,
      ControllerKind.adaptive => _adaptive(s, o, ttc),
      ControllerKind.fuzzy =>
        fuzzyDecision(ttc, c) > .53 ? Move.jump : Move.run,
      ControllerKind.mpc => _mpc(s),
    };
  }

  Move _adaptive(Simulation s, Obstacle o, double ttc) {
    final p = s.config.physics;
    final clearance = o.height + 8;
    final discriminant =
        p.launchSpeed * p.launchSpeed - 2 * p.gravity * clearance;
    final rise = discriminant > 0
        ? (p.launchSpeed - math.sqrt(discriminant)) / p.gravity
        : .24;
    final target = (rise + .09 + o.width / s.speed * .25).clamp(.12, .4);
    learnedLead +=
        s.config.adaptation * (target - learnedLead) * Simulation.step * 8;
    return ttc < learnedLead ? Move.jump : Move.run;
  }

  Move _mpc(Simulation s) {
    var bestCost = double.infinity;
    var bestDelay = .4;
    // Receding horizon: evaluate multiple future input sequences, execute one step.
    for (final delay in [double.infinity, 0.0, .08, .16, .24, .4]) {
      var y = s.y, vy = s.vy, cost = delay.isFinite ? 1.0 : 0.0;
      var launched = false;
      final p = s.config.physics;
      for (var t = 0.0; t < s.config.horizon; t += 1 / 60) {
        if (!launched && t >= delay) {
          vy = p.launchSpeed;
          launched = true;
        }
        if (y > 0 || vy != 0) {
          vy -= (p.gravity + p.drag * vy / p.mass) / 60;
          y = math.max(0, y + vy / 60);
          if (y == 0) vy = 0;
        }
        for (final o in s.obstacles) {
          final x = o.x - s.speed * t - 1.25 * t * t;
          if (Simulation.playerX + 27 > x + 3 &&
              Simulation.playerX + 3 < x + o.width - 3 &&
              y + 41 > o.bottom + 3 &&
              y + 3 < o.bottom + o.height - 3) {
            cost += 1000;
          }
        }
        cost += y * .00001;
      }
      if (cost < bestCost) {
        bestCost = cost;
        bestDelay = delay;
      }
    }
    return bestDelay == 0 ? Move.jump : Move.run;
  }
}
