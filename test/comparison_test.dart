import 'dart:async';

import 'package:dino_control_lab/data/comparison.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final seed in [42, 817]) {
    test(
      'Batched comparison preserves every simulation record for seed $seed',
      () async {
        final config = LabConfig(seed: seed);
        final expected = [
          for (final kind in ControllerKind.values)
            compareRun(config.copy()..controller = kind).toJson()..remove('id'),
        ];
        final runner = ComparisonRunner(config);
        config.seed = 999;
        config.horizon = 2;

        final actual = await runner.run(onProgress: (_) {});

        expect(
          actual.map((session) => session.toJson()..remove('id')).toList(),
          expected,
        );
      },
    );
  }

  test(
    'Event queue runs between batches while progress is incomplete',
    () async {
      final runner = ComparisonRunner(LabConfig());
      final progress = <ComparisonProgress>[];
      var completed = false;
      bool? completedAtEvent;
      double? progressAtEvent;

      await runner.run(
        onProgress: (value) {
          progress.add(value);
          if (progress.length == 1) {
            Timer.run(() {
              completedAtEvent = completed;
              progressAtEvent = progress.last.fraction;
            });
          }
        },
      );
      completed = true;

      expect(completedAtEvent, isFalse);
      expect(progressAtEvent, inExclusiveRange(0, 1));
      expect(progress.last.fraction, 1);
      expect(
        progress.map((p) => p.controller).toSet(),
        ControllerKind.values.toSet(),
      );
      expect(
        progress.map((p) => p.fraction),
        orderedEquals(progress.map((p) => p.fraction).toList()..sort()),
      );
    },
  );

  test(
    'Cancellation stops the comparison before another batch or result',
    () async {
      final runner = ComparisonRunner(LabConfig());
      var batches = 0;

      final result = runner.run(
        onProgress: (_) {
          batches++;
          runner.cancel();
        },
      );

      await expectLater(result, throwsA(isA<ComparisonCancelled>()));
      expect(batches, 1);
    },
  );

  test('Comparison failures propagate to the caller', () async {
    final runner = ComparisonRunner(LabConfig());
    final failure = StateError('progress receiver failed');

    final result = runner.run(onProgress: (_) => throw failure);

    await expectLater(result, throwsA(same(failure)));
  });
}
