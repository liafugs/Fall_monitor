import 'dart:math';
import '../models/fall_event.dart';
import '../utils/calculations.dart';
import '../utils/thresholds.dart';
import 'data_processing_service.dart';

class PossibleFall {
  final int impactT;
  final double peakAccelG, peakGyroDps, orientationDeg, detectionDelaySec;
  PossibleFall(this.impactT, this.peakAccelG, this.peakGyroDps,
      this.orientationDeg, this.detectionDelaySec);
}

/// Registro de cada candidato avaliado (aceito ou rejeitado) — útil p/ métricas.
class DetectionLog {
  final int tMs;
  final bool accepted;
  final String reason;
  final double peakAccelG;
  DetectionLog(this.tMs, this.accepted, this.reason, this.peakAccelG);
}

/// Interface do detector. Para trocar por machine learning, basta implementar
/// esta classe e instanciá-la no AppController.
abstract class FallDetector {
  void Function(PossibleFall)? onPossibleFall;
  void Function(DetectionLog)? onLog;
  void Function(FallEvent)? onEventAnalyzed;
  void process(ProcessedSample s);
  void reset();
}

enum _Phase { idle, settling, analyzing }

/// Detector baseado em regras (janela temporal):
/// 1) pico de aceleração → candidato; 2) aguarda "settle";
/// 3) exige ω alto ao redor do impacto; 4) exige mudança de orientação
/// (vetor de gravidade antes x depois); 5) analisa pós-impacto até o fim da janela.
class RuleBasedFallDetector extends FallDetector {
  final Thresholds th;
  RuleBasedFallDetector(this.th);

  final List<ProcessedSample> _buf = [];
  _Phase _phase = _Phase.idle;
  int _impactT = 0;
  int _ignoreUntil = 0;
  double _peakA = 0, _peakW = 0, _orient = 0, _delay = 0;

  @override
  void reset() {
    _buf.clear();
    _phase = _Phase.idle;
    _ignoreUntil = 0;
  }

  @override
  void process(ProcessedSample s) {
    _buf.add(s);
    switch (_phase) {
      case _Phase.idle:
        final cutoff = s.t - 6000;
        while (_buf.isNotEmpty && _buf.first.t < cutoff) {
          _buf.removeAt(0);
        }
        if (s.t >= _ignoreUntil && s.a >= th.impactAccelG) {
          _phase = _Phase.settling;
          _impactT = s.t;
        }
        break;
      case _Phase.settling:
        if (s.t - _impactT >= th.settleSec * 1000) _evaluate(s);
        break;
      case _Phase.analyzing:
        if (s.t - _impactT >= th.postWindowSec * 1000) _finish(s);
        break;
    }
  }

  List<double>? _meanAccel(int from, int to) {
    double x = 0, y = 0, z = 0;
    int n = 0;
    for (final p in _buf) {
      if (p.t >= from && p.t <= to) {
        x += p.imu.ax;
        y += p.imu.ay;
        z += p.imu.az;
        n++;
      }
    }
    return n == 0 ? null : [x / n, y / n, z / n];
  }

  bool _isLow(ProcessedSample p) =>
      (p.a - 1).abs() < th.lowMotionAccelDevG && p.w < th.lowMotionGyroDps;

  void _evaluate(ProcessedSample s) {
    final win = (th.impactWindowSec * 1000).round();
    double peakA = 0, peakW = 0;
    for (final p in _buf) {
      if (p.t >= _impactT && p.t <= _impactT + win && p.a > peakA) peakA = p.a;
      if (p.t >= _impactT - win && p.t <= _impactT + win && p.w > peakW) peakW = p.w;
    }
    // Referência pré-impacto (evita os 300 ms anteriores: queda livre/pré-impacto)
    final preEnd = _impactT - 300;
    final preStart = preEnd - (th.preWindowSec * 1000).round();
    final postStart = _impactT + (th.settleSec * 1000).round() - 500;
    final pre = _meanAccel(preStart, preEnd);
    final post = _meanAccel(postStart, s.t);
    final orient = (pre == null || post == null) ? 0.0 : angleBetweenDeg(pre, post);

    String? reason;
    if (peakW < th.impactGyroDps) {
      reason = 'velocidade angular baixa';
    } else if (orient < th.orientationChangeDeg) {
      reason = 'sem mudança de orientação';
    }
    if (reason != null) {
      onLog?.call(DetectionLog(_impactT, false, reason, peakA));
      _phase = _Phase.idle;
      return;
    }
    _peakA = peakA;
    _peakW = peakW;
    _orient = orient;
    _delay = (s.t - _impactT) / 1000.0;
    _phase = _Phase.analyzing;
    onLog?.call(DetectionLog(_impactT, true, 'possível queda', peakA));
    onPossibleFall?.call(PossibleFall(_impactT, _peakA, _peakW, _orient, _delay));
  }

  void _finish(ProcessedSample s) {
    final from = _impactT + (th.settleSec * 1000).round();
    final post = _buf.where((p) => p.t >= from).toList();
    double immo = 0, run = 0, sumA = 0, sumW = 0, sumDev = 0;
    for (int i = 0; i < post.length; i++) {
      final p = post[i];
      final double dt = i == 0 ? 0.0 : (p.t - post[i - 1].t) / 1000.0;
      if (_isLow(p)) {
        run += dt;
        if (run > immo) immo = run;
      } else {
        run = 0;
      }
      sumA += p.a;
      sumW += p.w;
      sumDev += (p.a - 1).abs();
    }
    final n = max(post.length, 1);
    final tail = post.where((p) => p.t >= s.t - 1000).toList();
    final recovered =
        tail.isNotEmpty && tail.where(_isLow).length < tail.length * 0.5;

    final sev = computeSeverity(th,
        peakAccelG: _peakA,
        peakGyroDps: _peakW,
        orientationDeg: _orient,
        immobilitySec: immo);
    final rawFrom = _impactT - 3000;
    final ev = FallEvent(
      id: _impactT.toString(),
      startMs: _impactT,
      durationSec: (s.t - _impactT) / 1000.0,
      peakAccelG: _peakA,
      peakGyroDps: _peakW,
      orientationChangeDeg: _orient,
      immobilitySec: immo,
      meanAccelPostG: sumA / n,
      meanGyroPostDps: sumW / n,
      motionLevelPost: sumDev / n,
      recovered: recovered,
      detectionDelaySec: _delay,
      severity: sev,
      raw: _buf.where((p) => p.t >= rawFrom).map((p) => p.imu).toList(),
    );
    _buf.clear();
    _phase = _Phase.idle;
    _ignoreUntil = s.t + (th.refractorySec * 1000).round();
    onEventAnalyzed?.call(ev);
  }
}
