import 'dart:convert';

import '../domain/config.dart';
import '../domain/json_values.dart';
import 'session_values.dart';
import '../domain/controller.dart';
import '../domain/simulation.dart';

class Session {
  Session(LabConfig config, {required this.classic, String? restoredId})
    : initial = config.copy(),
      id = restoredId ?? DateTime.now().microsecondsSinceEpoch.toString();
  final String id;
  final LabConfig initial;
  final bool classic;
  String outcome = 'em andamento';
  final List<Map<String, dynamic>> samples = [];
  final List<Map<String, dynamic>> events = [];
  int score = 0, jumps = 0, passed = 0;
  double duration = 0;
  factory Session.fromJson(Map<String, dynamic> j) {
    if (j['schema_version'] != 1 ||
        j['engine'] != 'fixed-step-v1' ||
        j['step_s'] != Simulation.step ||
        j['classic'] is! bool) {
      throw const FormatException('Esquema de sessão incompatível');
    }
    final session = Session(
      LabConfig.fromJson(jsonObject(j['initial'])),
      classic: j['classic'] as bool,
      restoredId: jsonString(j['id']),
    );
    session.outcome = jsonString(j['outcome']);
    session.score = jsonInt(j['score'], min: 0);
    session.jumps = jsonInt(j['jumps'], min: 0);
    session.passed = jsonInt(j['passed'], min: 0);
    session.duration = jsonNumber(j['duration_s'], min: 0);
    session.samples.addAll(parseSamples(j['samples']));
    session.events.addAll(parseEvents(j['events']));
    return session;
  }
  void record(Simulation s, Move move) {
    if (move != Move.run) events.add({'tick': s.ticks, 'move': move.name});
    if (s.ticks % 12 == 0 || s.crashed) {
      samples.add({
        'tick': s.ticks,
        'time_s': s.time,
        'height_px': s.y,
        'velocity_px_s': s.vy,
        'speed_px_s': s.speed,
        'distance_px': s.distance,
        'score': s.score,
        'move': move.name,
      });
    }
    score = s.score;
    jumps = s.jumps;
    passed = s.passed;
    duration = s.time;
  }

  void changed(int tick, LabConfig config) =>
      events.add({'tick': tick, 'config': config.toJson()});
  Map<String, dynamic> toJson() => {
    'schema_version': 1,
    'engine': 'fixed-step-v1',
    'step_s': Simulation.step,
    'id': id,
    'classic': classic,
    'initial': initial.toJson(),
    'outcome': outcome,
    'score': score,
    'jumps': jumps,
    'passed': passed,
    'duration_s': duration,
    'samples': samples,
    'events': events,
  };
  String get json => const JsonEncoder.withIndent('  ').convert(toJson());
  String get csv {
    const columns = [
      'tick',
      'time_s',
      'height_px',
      'velocity_px_s',
      'speed_px_s',
      'distance_px',
      'score',
      'move',
    ];
    return '${columns.join(',')}\n${samples.map((s) => columns.map((k) => s[k]).join(',')).join('\n')}\n';
  }
}

Session compareRun(LabConfig config, {double seconds = 60}) {
  final sim = Simulation(config.copy());
  final controller = Controller();
  final result = Session(config, classic: false);
  while (!sim.crashed && sim.time < seconds) {
    final move = controller.decide(sim);
    sim.advance(move);
    result.record(sim, move);
  }
  result.outcome = sim.crashed ? 'colisão' : 'limite de tempo';
  return result;
}
