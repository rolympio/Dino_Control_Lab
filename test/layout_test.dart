import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/ui/home.dart';
import 'package:dino_control_lab/ui/lab_panel.dart';
import 'package:dino_control_lab/ui/results.dart';
import 'package:dino_control_lab/ui/saved_settings.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('All menu pages lay out at $width in ${brightness.name}', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({'sound': false});
        final store = AppStore(await SharedPreferences.getInstance());
        store.sessions.add(compareRun(LabConfig(), seconds: 1));
        final pages = <Widget>[
          HomePage(store: store),
          PhysicsPage(store: store),
          ResultsPage(store: store),
          SavedPage(store: store),
          SettingsPage(store: store),
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LabPanel(store: store, onChanged: () {}),
              ),
            ),
          ),
        ];
        for (final page in pages) {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: page,
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType} at $width',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }
}
