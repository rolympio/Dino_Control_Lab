import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dino_control_lab/data/session.dart';
import 'package:dino_control_lab/data/store.dart';
import 'package:dino_control_lab/domain/config.dart';
import 'package:dino_control_lab/ui/results.dart';

void main() {
  test('each controller summarizes only the parameters it reads', () {
    final c = LabConfig(
      threshold: .31,
      adaptation: .5,
      horizon: 1.6,
      shape: MembershipShape.gaussian,
      center: .3,
      width: .1,
      runCenter: .25,
      jumpCenter: .7,
      outputWidth: .15,
    );
    String summary(ControllerKind kind) =>
        (c.copy()..controller = kind).controllerParameters;
    expect(summary(ControllerKind.onOff), 'antecipação 0.31 s');
    expect(summary(ControllerKind.adaptive), 'ganho 0.50');
    expect(summary(ControllerKind.mpc), 'horizonte 1.60 s');
    expect(
      summary(ControllerKind.fuzzy),
      'Gaussiana centro 0.30 s, largura 0.10 s; '
      'saídas correr 0.25 / pular 0.70 ± 0.15',
    );
  });

  testWidgets('results table shows parameters per session', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance());
    store.sessions
      ..add(Session(LabConfig(), classic: true, restoredId: 'classic'))
      ..add(
        Session(
          LabConfig(controller: ControllerKind.mpc, horizon: 1.4),
          classic: false,
          restoredId: 'mpc',
        ),
      );
    await tester.pumpWidget(MaterialApp(home: ResultsPage(store: store)));
    expect(find.text('Parâmetros iniciais'), findsOneWidget);
    expect(find.text('horizonte 1.40 s'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });
}
