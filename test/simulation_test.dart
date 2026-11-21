import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/domain/simulation.dart';
import 'package:dino_control_lab/domain/controller.dart';
import 'package:dino_control_lab/domain/fuzzy.dart';
import 'package:dino_control_lab/data/session.dart';

void main() {
  test('Manual run collides without input and never jumps automatically', () {
    final sim = Simulation(LabConfig());
    while (!sim.crashed && sim.time < 10) {
      sim.advance(Move.run);
    }
    expect(sim.crashed, isTrue);
    expect(sim.jumps, 0);
  });
  test('Jump clears a cactus; duck clears a low bird', () {
    final jumper = Simulation(LabConfig());
    jumper.obstacles.add(Obstacle(180));
    jumper.advance(Move.jump);
    for (var i = 0; i < 90; i++) {
      jumper.advance(Move.run);
    }
    expect(jumper.crashed, isFalse);
    expect(jumper.y, 0);
    final duck = Simulation(LabConfig());
    duck.obstacles.add(Obstacle(150, bird: true, bottom: 30, height: 24));
    for (var i = 0; i < 60; i++) {
      duck.advance(Move.duck);
    }
    expect(duck.crashed, isFalse);
  });
  test('Mass changes jump response for the same impulse', () {
    final light = Simulation(LabConfig());
    final heavy = Simulation(LabConfig(physics: const Physics(mass: 2)));
    light.advance(Move.jump);
    heavy.advance(Move.jump);
    expect(light.vy, closeTo(635, .0001));
    expect(heavy.vy, closeTo(310, .0001));
  });
  for (final kind in ControllerKind.values) {
    test('${kind.name} jumps and survives the first ground obstacle', () {
      final sim = Simulation(LabConfig(controller: kind));
      final controller = Controller();
      while (!sim.crashed && sim.time < 6) {
        sim.advance(controller.decide(sim));
      }
      expect(sim.crashed, isFalse);
      expect(sim.jumps, greaterThanOrEqualTo(1));
    });
  }
  test('Repeated seeds reproduce full time series and export valid data', () {
    final config = LabConfig(seed: 817, controller: ControllerKind.adaptive);
    final first = compareRun(config, seconds: 15);
    final second = compareRun(config, seconds: 15);
    expect(first.samples, second.samples);
    expect(first.events, second.events);
    final json = jsonDecode(first.json) as Map<String, dynamic>;
    expect(json['initial']['seed'], 817);
    expect((json['samples'] as List).length, first.samples.length);
    expect(first.csv.split('\n')[1].split(',').length, 8);
  });
  test('All input memberships are bounded and peak/inflexion is editable', () {
    for (final shape in MembershipShape.values) {
      final c = LabConfig(shape: shape);
      for (var i = 0; i < 100; i++) {
        expect(membership(i / 100, c), inInclusiveRange(0, 1));
      }
      final before = membership(.24, c);
      c.center = .55;
      expect(membership(.24, c), isNot(before));
    }
  });
  test(
    'Fuzzy centroid favors jump at the center and run for distant obstacles',
    () {
      final c = LabConfig();
      expect(fuzzyDecision(.24, c), closeTo(.8, .01));
      expect(fuzzyDecision(1, c), closeTo(.2, .01));
    },
  );
}
