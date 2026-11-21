import 'package:material_ui/material_ui.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/game/dino_game.dart';
import 'package:dino_control_lab/ui/game_page.dart';

void main() {
  test('time scale changes pace, not results', () {
    Session run(double scale, double frames) {
      final config = LabConfig(controller: ControllerKind.mpc);
      final game = DinoGame(
        config,
        classic: false,
        onFinished: (_) {},
        onSound: (_) {},
      )..timeScale = scale;
      // Same simulated time (20 s) delivered as 60 fps frames.
      for (var i = 0; i < frames; i++) {
        game.update(1 / 60);
      }
      return game.session;
    }

    final normal = run(1, 20 * 60);
    final fast = run(8, 20 * 60 / 8);
    final slow = run(.25, 20 * 60 * 4);
    expect(fast.duration, closeTo(normal.duration, 1e-9));
    expect(slow.duration, closeTo(normal.duration, 1e-9));
    expect(fast.samples, normal.samples);
    expect(slow.events, normal.events);
  });

  testWidgets('lab speed buttons step, cap and reset', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'sound': false});
    final store = AppStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MaterialApp(home: GamePage(store: store, classic: false)),
    );
    DinoGame game() => tester
        .widget<GameWidget<DinoGame>>(find.byType(GameWidget<DinoGame>))
        .game!;
    expect(game().timeScale, 1);
    expect(find.text('1× normal'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('Acelerar'));
      await tester.pump();
    }
    expect(game().timeScale, 8);
    final faster = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(faster.onPressed, isNull);
    expect(find.text('8× · voltar a 1×'), findsOneWidget);

    // Speed survives a restart.
    await tester.tap(find.byTooltip('Reiniciar'));
    await tester.pump();
    expect(game().timeScale, 8);

    await tester.tap(find.byKey(const Key('speed-normal')));
    await tester.pump();
    expect(game().timeScale, 1);

    await tester.tap(find.byTooltip('Desacelerar'));
    await tester.pump();
    await tester.tap(find.byTooltip('Desacelerar'));
    await tester.pump();
    expect(game().timeScale, .25);
    expect(find.text('0,25× · voltar a 1×'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('classic mode has no speed controls', (tester) async {
    SharedPreferences.setMockInitialValues({'sound': false});
    final store = AppStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MaterialApp(home: GamePage(store: store, classic: true)),
    );
    expect(find.byTooltip('Acelerar'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
