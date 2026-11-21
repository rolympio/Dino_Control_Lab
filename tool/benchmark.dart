import 'dart:convert';
import 'dart:io';

import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/data/replay.dart';

void main() {
  Directory('evidence').createSync(recursive: true);
  final summary = <Map<String, dynamic>>[];
  for (final kind in ControllerKind.values) {
    final watch = Stopwatch()..start();
    final session = compareRun(LabConfig(controller: kind));
    watch.stop();
    final restored = Session.fromJson(
      jsonDecode(session.json) as Map<String, dynamic>,
    );
    final reproduced = replay(restored);
    if (jsonEncode(reproduced.samples) != jsonEncode(session.samples)) {
      throw StateError('Replay diverged: ${kind.name}');
    }
    File('evidence/${kind.name}.csv').writeAsStringSync(session.csv);
    File('evidence/${kind.name}.json').writeAsStringSync(session.json);
    summary.add({
      'controller': kind.name,
      'seed': session.initial.seed,
      'duration_s': session.duration,
      'score': session.score,
      'jumps': session.jumps,
      'outcome': session.outcome,
      'runtime_ms': watch.elapsedMilliseconds,
      'replay': 'identical',
    });
  }
  final text = const JsonEncoder.withIndent('  ').convert(summary);
  File('evidence/comparison.json').writeAsStringSync(text);
  stdout.writeln(text);
}
