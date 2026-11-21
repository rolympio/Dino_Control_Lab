import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/domain/config.dart';

void main() {
  test(
    'corrupt preferences recover without losing valid experiments',
    () async {
      SharedPreferences.setMockInitialValues({
        'theme': 'unknown',
        'sessions': '{',
        'experiments': jsonEncode({
          'broken': {},
          'valid': LabConfig(seed: 901).toJson(),
        }),
      });
      final store = AppStore(await SharedPreferences.getInstance());
      expect(store.sessions, isEmpty);
      expect(store.experiments.keys, ['valid']);
    },
  );
  test('bad record is skipped while neighboring session survives', () async {
    final valid = Session(LabConfig(), classic: false, restoredId: 'valid');
    SharedPreferences.setMockInitialValues({
      'sessions': jsonEncode([{}, valid.toJson()]),
    });
    final store = AppStore(await SharedPreferences.getInstance());
    expect(store.sessions.map((s) => s.id), ['valid']);
  });
  test('unknown schema is rejected at input boundary', () {
    final json = Session(LabConfig(), classic: false).toJson()
      ..['schema_version'] = 99;
    expect(() => Session.fromJson(json), throwsFormatException);
  });
}
