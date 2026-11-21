import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/game/dino_game.dart';
import 'package:dino_control_lab/ui/game_page.dart';
import 'package:dino_control_lab/ui/fuzzy_editor.dart';

void main() {
  testWidgets('Space and tap jump; pause freezes; restart clears collision', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'sound': false});
    final store = AppStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MaterialApp(home: GamePage(store: store, classic: true)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final widget = tester.widget<GameWidget<DinoGame>>(
      find.byType(GameWidget<DinoGame>),
    );
    final game = widget.game!;
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    game.update(.02);
    expect(game.sim.y, greaterThan(0));
    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    final y = game.sim.y;
    game.update(.1);
    expect(game.sim.y, y);
    await tester.tap(find.text('Retomar'));
    await tester.pump();
    for (var i = 0; i < 60; i++) {
      game.update(.1);
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Fim de jogo'), findsOneWidget);
    await tester.tap(find.text('Jogar novamente'));
    await tester.pump();
    final restarted = tester
        .widget<GameWidget<DinoGame>>(find.byType(GameWidget<DinoGame>))
        .game!;
    expect(restarted.sim.score, 0);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    restarted.update(.02);
    expect(restarted.sim.playerHeight, 24);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    restarted.update(.02);
    expect(restarted.sim.playerHeight, 44);
    final held = await tester.startGesture(
      tester.getCenter(find.text('Segure para abaixar')),
    );
    restarted.update(.02);
    expect(restarted.sim.playerHeight, 24);
    await held.up();
    restarted.update(.02);
    expect(restarted.sim.playerHeight, 44);
    await tester.tap(find.byType(GameWidget<DinoGame>));
    restarted.update(.02);
    expect(restarted.sim.y, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });
  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets(
      'Fuzzy input and triangular output respond to ${kind.name} drag',
      (tester) async {
        final config = LabConfig();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FuzzyEditor(config: config, onChanged: () {}),
              ),
            ),
          ),
        );
        final graph = tester.getRect(find.byKey(const Key('fuzzy-graph')));
        final start = Offset(
          graph.left + 24 + (graph.width - 48) * .24,
          graph.top + 20,
        );
        await tester.dragFrom(start, const Offset(80, 0), kind: kind);
        expect(config.center, greaterThan(.3));
        await tester.ensureVisible(find.byKey(const Key('fuzzy-output')));
        final output = tester.getRect(find.byKey(const Key('fuzzy-output')));
        final outputStart = Offset(
          output.left + 24 + (output.width - 48) * .2,
          output.top + 12,
        );
        await tester.dragFrom(outputStart, const Offset(70, 0), kind: kind);
        expect(config.runCenter, greaterThan(.25));
      },
    );
  }
}
