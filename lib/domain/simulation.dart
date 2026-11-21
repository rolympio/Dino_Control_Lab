import 'dart:math' as math;

import 'config.dart';

class Obstacle {
  Obstacle(
    this.x, {
    this.bird = false,
    this.height = 46,
    this.width = 26,
    this.bottom = 0,
  });
  double x;
  final bool bird;
  final double height, width, bottom;
  Obstacle copy() =>
      Obstacle(x, bird: bird, height: height, width: width, bottom: bottom);
}

class Simulation {
  Simulation(this.config) : _random = config.seed & 0x7fffffff;
  static const step = 1 / 120;
  static const playerX = 90.0;
  final LabConfig config;
  int _random;
  int ticks = 0, jumps = 0, passed = 0;
  double y = 0, vy = 0, distance = 0, nextSpawn = 1.7;
  bool ducking = false, crashed = false;
  final List<Obstacle> obstacles = [];
  double get time => ticks * step;
  double get speed => math.min(650, 300 + time * 2.5);
  int get score => (distance / 10).floor();
  double get playerHeight => ducking && y == 0 ? 24 : 44;
  double get playerWidth => ducking && y == 0 ? 48 : 30;
  Obstacle? get nearest {
    for (final o in obstacles) {
      if (o.x + o.width >= playerX) return o;
    }
    return null;
  }

  double random() {
    _random = (1664525 * _random + 1013904223) & 0xffffffff;
    return _random / 4294967296;
  }

  void advance(Move move) {
    if (crashed) return;
    ducking = move == Move.duck;
    if (move == Move.jump && y == 0) {
      vy = config.physics.launchSpeed;
      jumps++;
    }
    final p = config.physics;
    if (vy != 0 || y > 0) {
      vy -= (p.gravity + p.drag * vy / p.mass) * step;
      y = math.max(0, y + vy * step);
      if (y == 0) vy = 0;
    }
    final dx = speed * step;
    distance += dx;
    for (final o in obstacles) {
      o.x -= dx;
      if (hits(o)) crashed = true;
    }
    obstacles.removeWhere((o) {
      if (o.x + o.width < 0) {
        passed++;
        return true;
      }
      return false;
    });
    ticks++;
    if (time >= nextSpawn) {
      final bird = time > 8 && random() < .3;
      obstacles.add(
        Obstacle(
          1000,
          bird: bird,
          height: bird ? 24 : 38 + random() * 18,
          width: bird ? 36 : 22 + random() * 14,
          bottom: bird ? (random() < .65 ? 30 : 75) : 0,
        ),
      );
      nextSpawn = time + 1.45 + random() * .85;
    }
  }

  bool hits(Obstacle o) =>
      playerX + playerWidth - 3 > o.x + 3 &&
      playerX + 3 < o.x + o.width - 3 &&
      y + playerHeight - 3 > o.bottom + 3 &&
      y + 3 < o.bottom + o.height - 3;
}
