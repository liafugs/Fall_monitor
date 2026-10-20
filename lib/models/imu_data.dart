/// Uma amostra da IMU. aceleração em g, velocidade angular em °/s.
/// [t] = instante de recepção no app (epoch, ms).
class IMUData {
  final int t;
  final double ax, ay, az, gx, gy, gz;
  const IMUData(
      {required this.t,
      required this.ax,
      required this.ay,
      required this.az,
      required this.gx,
      required this.gy,
      required this.gz});

  /// Formato esperado: "ax,ay,az,gx,gy,gz"
  static IMUData? tryParse(String line, int t) {
    final p = line.trim().split(',');
    if (p.length != 6) return null;
    final v = p.map((e) => double.tryParse(e.trim())).toList();
    if (v.any((e) => e == null)) return null;
    return IMUData(
        t: t, ax: v[0]!, ay: v[1]!, az: v[2]!, gx: v[3]!, gy: v[4]!, gz: v[5]!);
  }
}
