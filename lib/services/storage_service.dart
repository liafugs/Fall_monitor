import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/fall_event.dart';
import '../models/imu_data.dart';
import '../utils/calculations.dart';
import '../utils/thresholds.dart';

class StorageService {
  Future<File> _file(String name) async {
    final d = await getApplicationDocumentsDirectory();
    return File('${d.path}/$name');
  }

  Future<Thresholds> loadThresholds() async {
    try {
      final f = await _file('thresholds.json');
      if (await f.exists()) {
        return Thresholds.fromJson(jsonDecode(await f.readAsString()));
      }
    } catch (_) {}
    return Thresholds();
  }

  Future<void> saveThresholds(Thresholds t) async =>
      (await _file('thresholds.json')).writeAsString(jsonEncode(t.toJson()));

  Future<List<FallEvent>> loadEvents() async {
    try {
      final f = await _file('events.json');
      if (await f.exists()) {
        final l = jsonDecode(await f.readAsString()) as List;
        return l.map((e) => FallEvent.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveEvents(List<FallEvent> ev) async => (await _file('events.json'))
      .writeAsString(jsonEncode(ev.map((e) => e.toJson()).toList()));

  Future<String> rawPath(String id) async => (await _file('raw_$id.csv')).path;

  /// Dados brutos do evento (3 s antes do impacto até o fim da análise).
  Future<void> saveRaw(FallEvent e) async {
    final sb = StringBuffer('t_ms,ax,ay,az,gx,gy,gz,a_res,w_res\n');
    for (final s in e.raw) {
      sb.writeln([
        s.t, s.ax, s.ay, s.az, s.gx, s.gy, s.gz,
        magnitude(s.ax, s.ay, s.az), magnitude(s.gx, s.gy, s.gz)
      ].join(','));
    }
    await (await _file('raw_${e.id}.csv')).writeAsString(sb.toString());
  }

  /// flag: 0 nada, 1 candidato rejeitado, 2 possível queda, 3 marcador manual.
  Future<File> saveTestSession(
      List<IMUData> samples, List<String> labels, Map<int, int> flags) async {
    final sb = StringBuffer('t_ms,ax,ay,az,gx,gy,gz,a_res,w_res,atividade,flag\n');
    for (int i = 0; i < samples.length; i++) {
      final s = samples[i];
      sb.writeln([
        s.t, s.ax, s.ay, s.az, s.gx, s.gy, s.gz,
        magnitude(s.ax, s.ay, s.az), magnitude(s.gx, s.gy, s.gz),
        labels[i], flags[s.t] ?? 0
      ].join(','));
    }
    final f = await _file('teste_${DateTime.now().millisecondsSinceEpoch}.csv');
    return f.writeAsString(sb.toString());
  }
}
