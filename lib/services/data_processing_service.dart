import '../models/imu_data.dart';
import '../utils/calculations.dart';
import '../utils/constants.dart';

/// Amostra + grandezas resultantes.
class ProcessedSample {
  final IMUData imu;
  final double a; // aceleração resultante (g)
  final double w; // velocidade angular resultante (°/s)
  ProcessedSample(this.imu)
      : a = magnitude(imu.ax, imu.ay, imu.az),
        w = magnitude(imu.gx, imu.gy, imu.gz);
  int get t => imu.t;
}

class DataProcessingService {
  /// Buffer rolante usado nos gráficos.
  final List<ProcessedSample> display = [];

  ProcessedSample process(IMUData d) {
    final p = ProcessedSample(d);
    display.add(p);
    final cutoff = d.t - Constants.chartWindowSeconds * 1000;
    while (display.isNotEmpty && display.first.t < cutoff) {
      display.removeAt(0);
    }
    return p;
  }

  void clear() => display.clear();
}
