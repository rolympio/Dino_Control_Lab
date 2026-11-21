import '../domain/config.dart';
import '../domain/controller.dart';
import '../domain/simulation.dart';
import 'session.dart';

class ComparisonProgress {
  const ComparisonProgress(this.controller, this.fraction);
  final ControllerKind controller;
  final double fraction;
}

class ComparisonCancelled implements Exception {}

class ComparisonRunner {
  ComparisonRunner(LabConfig config) : _config = config.copy();

  final LabConfig _config;
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<List<Session>> run({
    required void Function(ComparisonProgress) onProgress,
  }) async {
    final results = <Session>[];
    for (final kind in ControllerKind.values) {
      final config = _config.copy()..controller = kind;
      final sim = Simulation(config.copy());
      final controller = Controller();
      final result = Session(config, classic: false);
      while (!sim.crashed && sim.time < 60) {
        if (_cancelled) throw ComparisonCancelled();
        for (var tick = 0; tick < 24 && !sim.crashed && sim.time < 60; tick++) {
          final move = controller.decide(sim);
          sim.advance(move);
          result.record(sim, move);
        }
        final complete = sim.crashed || sim.time >= 60;
        onProgress(
          ComparisonProgress(
            kind,
            (results.length + (complete ? 1 : sim.time / 60)) /
                ControllerKind.values.length,
          ),
        );
        // A timer yields to browser input and painting; a microtask does not.
        await Future<void>.delayed(Duration.zero);
        if (_cancelled) throw ComparisonCancelled();
      }
      result.outcome = sim.crashed ? 'colisão' : 'limite de tempo';
      results.add(result);
    }
    return results;
  }
}
