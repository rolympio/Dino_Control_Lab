import 'dart:math' as math;

import 'config.dart';

double membership(double x, LabConfig config) {
  final d = (x - config.center) / config.width;
  return switch (config.shape) {
    MembershipShape.triangular => math.max(0, 1 - d.abs()),
    MembershipShape.trapezoidal => ((1 - d.abs()) * 2).clamp(0, 1),
    MembershipShape.gaussian => math.exp(-.5 * d * d),
    MembershipShape.sigmoid => 1 / (1 + math.exp(6 * d)),
  };
}

double triangle(double x, double center, double width) =>
    math.max(0, 1 - (x - center).abs() / width);

// Mamdani: proximidade ativa a saída "pular"; complemento ativa "correr".
// Ambas as funções de saída são estritamente triangulares.
double fuzzyDecision(double ttc, LabConfig config) {
  final urgent = membership(ttc, config);
  var weight = 0.0;
  var moment = 0.0;
  for (var i = 0; i <= 100; i++) {
    final x = i / 100;
    final value = math.max(
      math.min(urgent, triangle(x, config.jumpCenter, config.outputWidth)),
      math.min(1 - urgent, triangle(x, config.runCenter, config.outputWidth)),
    );
    weight += value;
    moment += x * value;
  }
  return weight == 0 ? 0 : moment / weight;
}
