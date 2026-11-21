import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/domain/config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, Object> disk;
  Future<Object?> write(MethodCall call) async {
    if (call.method == 'getAll') return disk;
    final args = call.arguments as Map;
    disk[args['key'] as String] = args['value'] as Object;
    return true;
  }

  setUp(() {
    SharedPreferences.resetStatic();
    disk = {};
    messenger.setMockMethodCallHandler(channel, write);
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  for (final method in ['setString', 'setInt', 'setBool']) {
    for (final throwing in [false, true]) {
      test(
        '$method ${throwing ? 'exception' : 'false'} gives notice and retains exportable session',
        () async {
          messenger.setMockMethodCallHandler(channel, (call) async {
            if (call.method == method) {
              if (throwing) throw PlatformException(code: 'quota');
              return false;
            }
            return write(call);
          });
          final store = AppStore(await SharedPreferences.getInstance());
          final session = Session(
            LabConfig(),
            classic: true,
            restoredId: 'retained',
          )..score = 12;
          await store.addSession(session);
          await store.settings(soundEnabled: false);
          expect(store.notice, isNotNull);
          expect(
            Session.fromJson(jsonDecode(store.sessions.single.json)).id,
            'retained',
          );
        },
      );
    }
  }

  test('unawaited save failure is reported through listeners', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') return disk;
      throw PlatformException(code: 'quota');
    });
    final store = AppStore(await SharedPreferences.getInstance());
    final observed = Completer<void>();
    store.addListener(() {
      if (store.notice != null && !observed.isCompleted) observed.complete();
    });
    unawaited(store.addSession(Session(LabConfig(), classic: false)));
    await observed.future.timeout(const Duration(seconds: 5));
    expect(store.sessions, hasLength(1));
  });

  test('history retains newest 20 records across reopen', () async {
    final store = AppStore(await SharedPreferences.getInstance());
    for (var i = 0; i < 25; i++) {
      await store.addSession(
        Session(LabConfig(), classic: false, restoredId: '$i'),
      );
    }
    SharedPreferences.resetStatic();
    final reopened = AppStore(await SharedPreferences.getInstance());
    expect(
      reopened.sessions.map((s) => s.id),
      List.generate(20, (i) => '${i + 5}'),
    );
    expect(store.notice, isNotNull);
  });

  test(
    'oversized current session remains exportable while disk stays bounded',
    () async {
      final store = AppStore(await SharedPreferences.getInstance());
      await store.addSession(
        Session(LabConfig(), classic: false, restoredId: 'small'),
      );
      final large = Session(LabConfig(), classic: false, restoredId: 'large')
        ..outcome = 'x' * (1024 * 1024);
      await store.addSession(large);
      expect(
        (disk['flutter.sessions'] as String).length * 2,
        lessThanOrEqualTo(2 * 1024 * 1024),
      );
      expect(store.sessions.last.json, contains('large'));
      SharedPreferences.resetStatic();
      expect(
        AppStore(await SharedPreferences.getInstance()).sessions.single.id,
        'small',
      );
      expect(store.notice, isNotNull);
    },
  );

  test(
    'queued saves preserve newer settings when first write is delayed',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'setBool' && !started.isCompleted) {
          started.complete();
          await release.future;
        }
        return write(call);
      });
      final store = AppStore(await SharedPreferences.getInstance());
      final first = store.settings(soundEnabled: false);
      await started.future;
      final second = store.settings(soundEnabled: true);
      release.complete();
      await Future.wait([first, second]);
      SharedPreferences.resetStatic();
      expect(AppStore(await SharedPreferences.getInstance()).sound, true);
    },
  );
}
