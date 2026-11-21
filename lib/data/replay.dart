import '../domain/config.dart';
import '../domain/simulation.dart';
import 'session.dart';

Session replay(Session original) {
  final config = original.initial.copy();
  final sim = Simulation(config);
  final result = Session(config, classic: original.classic);
  final actions = <int, Move>{};
  final changes = <int, LabConfig>{};
  for (final event in original.events) {
    final tick = event['tick'] as int;
    if (event.containsKey('move')) {
      actions[tick] = Move.values.byName(event['move'] as String);
    }
    if (event.containsKey('config')) {
      changes[tick] = LabConfig.fromJson(
        event['config'] as Map<String, dynamic>,
      );
    }
  }
  final end = (original.duration / Simulation.step).round();
  while (sim.ticks < end && !sim.crashed) {
    final change = changes[sim.ticks];
    if (change != null) {
      config.physics = change.physics;
      config.character = change.character;
      result.changed(sim.ticks, change);
    }
    final move = actions[sim.ticks + 1] ?? Move.run;
    sim.advance(move);
    result.record(sim, move);
  }
  result.outcome = original.outcome;
  return result;
}
