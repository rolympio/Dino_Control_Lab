import 'json_values.dart';

enum ControllerKind { onOff, adaptive, fuzzy, mpc }

enum MembershipShape { triangular, trapezoidal, gaussian, sigmoid }

enum CharacterKind { dino, robot, runner }

enum Move { run, jump, duck }

extension ControllerLabel on ControllerKind {
  String get label => switch (this) {
    ControllerKind.onOff => 'ON/OFF',
    ControllerKind.adaptive => 'Adaptativo',
    ControllerKind.fuzzy => 'Fuzzy',
    ControllerKind.mpc => 'MPC',
  };
}

extension MembershipLabel on MembershipShape {
  String get label => switch (this) {
    MembershipShape.triangular => 'Triangular',
    MembershipShape.trapezoidal => 'Trapezoidal',
    MembershipShape.gaussian => 'Gaussiana',
    MembershipShape.sigmoid => 'Sigmoidal',
  };
}

class Physics {
  const Physics({
    this.mass = 1,
    this.gravity = 1800,
    this.impulse = 650,
    this.drag = 0,
  });
  final double mass, gravity, impulse, drag;
  double get launchSpeed => impulse / mass;
  double get flightTime => 2 * launchSpeed / gravity;
  Map<String, dynamic> toJson() => {
    'mass': mass,
    'gravity': gravity,
    'impulse': impulse,
    'drag': drag,
  };
  factory Physics.fromJson(Map<String, dynamic> j) => Physics(
    mass: jsonNumber(j['mass'], min: .5, max: 2),
    gravity: jsonNumber(j['gravity'], min: 800, max: 2400),
    impulse: jsonNumber(j['impulse'], min: 400, max: 1000),
    drag: jsonNumber(j['drag'], min: 0, max: 2),
  );
}

class LabConfig {
  LabConfig({
    this.seed = 42,
    this.physics = const Physics(),
    this.character = CharacterKind.dino,
    this.controller = ControllerKind.onOff,
    this.threshold = .23,
    this.adaptation = .35,
    this.shape = MembershipShape.triangular,
    this.center = .24,
    this.width = .18,
    this.horizon = 1.2,
    this.runCenter = .2,
    this.jumpCenter = .8,
    this.outputWidth = .2,
  });
  int seed;
  Physics physics;
  CharacterKind character;
  ControllerKind controller;
  double threshold, adaptation, center, width, horizon;
  double runCenter, jumpCenter, outputWidth;
  MembershipShape shape;

  /// The parameters the selected controller actually reads, in display form.
  String get controllerParameters => switch (controller) {
    ControllerKind.onOff => 'antecipação ${threshold.toStringAsFixed(2)} s',
    ControllerKind.adaptive => 'ganho ${adaptation.toStringAsFixed(2)}',
    ControllerKind.fuzzy =>
      '${shape.label} centro ${center.toStringAsFixed(2)} s, '
          'largura ${width.toStringAsFixed(2)} s; '
          'saídas correr ${runCenter.toStringAsFixed(2)} / '
          'pular ${jumpCenter.toStringAsFixed(2)} '
          '± ${outputWidth.toStringAsFixed(2)}',
    ControllerKind.mpc => 'horizonte ${horizon.toStringAsFixed(2)} s',
  };
  LabConfig copy() => LabConfig.fromJson(toJson());
  Map<String, dynamic> toJson() => {
    'seed': seed,
    'physics': physics.toJson(),
    'character': character.name,
    'controller': controller.name,
    'threshold': threshold,
    'adaptation': adaptation,
    'shape': shape.name,
    'center': center,
    'width': width,
    'horizon': horizon,
    'runCenter': runCenter,
    'jumpCenter': jumpCenter,
    'outputWidth': outputWidth,
  };
  factory LabConfig.fromJson(Map<String, dynamic> j) => LabConfig(
    seed: jsonInt(j['seed']),
    physics: Physics.fromJson(jsonObject(j['physics'])),
    character: jsonEnum(j['character'], CharacterKind.values),
    controller: jsonEnum(j['controller'], ControllerKind.values),
    threshold: jsonNumber(j['threshold'], min: .08, max: .5),
    adaptation: jsonNumber(j['adaptation'], min: .05, max: 1),
    shape: jsonEnum(j['shape'], MembershipShape.values),
    center: jsonNumber(j['center'], min: .08, max: .6),
    width: jsonNumber(j['width'], min: .05, max: .4),
    horizon: jsonNumber(j['horizon'], min: .6, max: 2),
    runCenter: jsonNumber(j['runCenter'] ?? .2, min: .1, max: .4),
    jumpCenter: jsonNumber(j['jumpCenter'] ?? .8, min: .6, max: .9),
    outputWidth: jsonNumber(j['outputWidth'] ?? .2, min: .05, max: .3),
  );
}
