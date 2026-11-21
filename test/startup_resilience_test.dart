import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/main.dart';
import 'package:dino_control_lab/ui/results.dart';

void main() {
  testWidgets('app opens and plays without local storage', (tester) async {
    final store = AppStore(null);
    expect(store.notice, contains('Armazenamento local indisponível'));
    await tester.pumpWidget(DinoApp(store: store));
    expect(find.text('Pule. Experimente. Compare.'), findsOneWidget);
    expect(find.textContaining('Armazenamento local'), findsOneWidget);
    await tester.tap(find.byTooltip('Dispensar aviso'));
    await tester.pump();
    expect(find.textContaining('Armazenamento local'), findsNothing);
    // Writes are skipped instead of throwing.
    await store.addSession(compareRun(LabConfig(), seconds: 1));
    await store.saveExperiment('sem disco');
    await store.settings(soundEnabled: false);
    expect(store.sessions, hasLength(1));
    expect(store.experiments.keys, ['sem disco']);
  });

  testWidgets('restore notice is visible on the home page', (tester) async {
    SharedPreferences.setMockInitialValues({'sessions': '{'});
    final store = AppStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(DinoApp(store: store));
    expect(find.textContaining('Dados locais inválidos'), findsOneWidget);
  });

  testWidgets('results drop a selection trimmed out of the history', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
    final first = Session(LabConfig(), classic: false, restoredId: 'first');
    store.sessions.add(first);
    await tester.pumpWidget(MaterialApp(home: ResultsPage(store: store)));
    store.sessions
      ..clear()
      ..add(compareRun(LabConfig(seed: 7), seconds: 1));
    await tester.pumpWidget(MaterialApp(home: ResultsPage(store: store)));
    expect(tester.takeException(), isNull);
    // The stale, sample-less session must no longer be the one charted.
    expect(find.text('Sessão sem amostras.'), findsNothing);
    store.sessions.clear();
    await tester.pumpWidget(MaterialApp(home: ResultsPage(store: store)));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Nenhuma sessão concluída'), findsOneWidget);
  });
}
