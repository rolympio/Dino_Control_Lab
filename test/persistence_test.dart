import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/data/replay.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/domain/simulation.dart';

void main() {
  test('History, record and experiments survive reopening storage', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = AppStore(preferences);
    final session = Session(LabConfig(), classic: true)..score = 123;
    await store.addSession(session);
    store.config.seed = 901;
    await store.saveExperiment('Teste');
    final reopened = AppStore(preferences);
    expect(reopened.best, 123);
    expect(reopened.sessions.single.id, session.id);
    expect(reopened.experiments['Teste']!.seed, 901);
  });
  test('JSON replay reproduces actions and live physics changes exactly', () {
    final sim = Simulation(LabConfig());
    final original = Session(sim.config, classic: false);
    for (var tick = 0; tick < 360; tick++) {
      if (tick == 100) {
        sim.config.physics = const Physics(
          mass: 1.3,
          gravity: 1200,
          impulse: 800,
          drag: .1,
        );
        original.changed(sim.ticks, sim.config);
      }
      final move = tick == 0 || tick == 130 ? Move.jump : Move.run;
      sim.advance(move);
      original.record(sim, move);
    }
    final restored = Session.fromJson(
      jsonDecode(original.json) as Map<String, dynamic>,
    );
    final reproduced = replay(restored);
    expect(reproduced.samples, original.samples);
    expect(reproduced.score, original.score);
  });
}
