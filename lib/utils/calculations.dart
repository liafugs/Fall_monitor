import 'dart:math';
import '../models/severity_result.dart';
import 'thresholds.dart';

/// A = sqrt(x² + y² + z²) — vale para aceleração e velocidade angular.
double magnitude(double x, double y, double z) => sqrt(x * x + y * y + z * z);

double angleBetweenDeg(List<double> a, List<double> b) {
  final na = magnitude(a[0], a[1], a[2]);
  final nb = magnitude(b[0], b[1], b[2]);
  if (na == 0 || nb == 0) return 0;
  final dot = a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
  return acos((dot / (na * nb)).clamp(-1.0, 1.0).toDouble()) * 180 / pi;
}

double norm01(double v, double lo, double hi) =>
    hi <= lo ? 0.0 : ((v - lo) / (hi - lo)).clamp(0.0, 1.0).toDouble();

/// Índice 0–100: soma ponderada de componentes normalizados.
/// Estimativa computacional — NÃO é avaliação médica.
SeverityResult computeSeverity(Thresholds th,
    {required double peakAccelG,
    required double peakGyroDps,
    required double orientationDeg,
    required double immobilitySec}) {
  final cA = norm01(peakAccelG, th.impactAccelG, th.maxPeakAccelG);
  final cW = norm01(peakGyroDps, th.impactGyroDps, th.maxPeakGyroDps);
  final cO = norm01(orientationDeg, th.orientationChangeDeg, th.maxOrientationDeg);
  final cI = norm01(immobilitySec, 0, th.maxImmobilitySec);
  final wSum = th.wAccel + th.wGyro + th.wOrient + th.wImmo;
  final raw = wSum <= 0
      ? 0.0
      : 100 * (th.wAccel * cA + th.wGyro * cW + th.wOrient * cO + th.wImmo * cI) / wSum;
  final score = raw.round().clamp(0, 100).toInt();
  final level = score <= th.lowMax
      ? SeverityLevel.baixa
      : (score <= th.moderateMax ? SeverityLevel.moderada : SeverityLevel.alta);
  return SeverityResult(
      score: score, level: level, cAccel: cA, cGyro: cW, cOrient: cO, cImmo: cI);
}

String fmtNum(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

String fmtDateTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)}/${d.year} — ${p(d.hour)}:${p(d.minute)}';
}
