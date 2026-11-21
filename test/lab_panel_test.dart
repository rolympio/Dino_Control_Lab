import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/ui/fuzzy_editor.dart';
import 'package:dino_control_lab/ui/lab_panel.dart';

void main() {
  const labels = {
    ControllerKind.onOff: 'Antecipação ON/OFF',
    ControllerKind.adaptive: 'Ganho de adaptação',
    ControllerKind.mpc: 'Horizonte MPC',
  };

  for (final kind in ControllerKind.values) {
    testWidgets('lab shows only ${kind.name} settings', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = AppStore(await SharedPreferences.getInstance());
      store.config.controller = kind;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LabPanel(store: store, onChanged: () {}),
            ),
          ),
        ),
      );
      for (final MapEntry(key: other, value: label) in labels.entries) {
        expect(
          find.textContaining(label),
          other == kind ? findsOneWidget : findsNothing,
        );
      }
      expect(
        find.byType(FuzzyEditor),
        kind == ControllerKind.fuzzy ? findsOneWidget : findsNothing,
      );
      expect(find.text('Parâmetros — ${kind.label}'), findsOneWidget);
      // Common settings stay visible for every controller.
      expect(find.text('Personagem e física ao vivo'), findsOneWidget);
    });
  }

  testWidgets('switching controller swaps the settings shown', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LabPanel(store: store, onChanged: () {}),
          ),
        ),
      ),
    );
    expect(find.textContaining('Antecipação ON/OFF'), findsOneWidget);
    await tester.tap(find.text('ON/OFF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MPC').last);
    await tester.pumpAndSettle();
    expect(store.config.controller, ControllerKind.mpc);
    expect(find.textContaining('Horizonte MPC'), findsOneWidget);
    expect(find.textContaining('Antecipação ON/OFF'), findsNothing);
  });
}
