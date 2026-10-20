import 'imu_data.dart';
import 'severity_result.dart';

enum UserResponse { okay, needHelp, noResponse }

extension UserResponseX on UserResponse {
  String get label => switch (this) {
        UserResponse.okay => 'Estou bem',
        UserResponse.needHelp => 'Precisa de ajuda',
        UserResponse.noResponse => 'Não respondeu',
      };
}

class FallEvent {
  final String id;
  final int startMs; // instante do impacto
  final double durationSec; // duração da análise (impacto → fim da janela)
  final double peakAccelG;
  final double peakGyroDps;
  final double orientationChangeDeg;
  final double immobilitySec;
  final double meanAccelPostG;
  final double meanGyroPostDps;
  final double motionLevelPost; // média de |A - 1g| no pós-impacto
  final bool recovered; // movimento retomado no fim da janela
  final double detectionDelaySec; // impacto → "possível queda"
  final SeverityResult severity;
  UserResponse? response;
  final List<IMUData> raw; // dados brutos (salvos em CSV à parte)

  FallEvent({
    required this.id,
    required this.startMs,
    required this.durationSec,
    required this.peakAccelG,
    required this.peakGyroDps,
    required this.orientationChangeDeg,
    required this.immobilitySec,
    required this.meanAccelPostG,
    required this.meanGyroPostDps,
    required this.motionLevelPost,
    required this.recovered,
    required this.detectionDelaySec,
    required this.severity,
    this.response,
    this.raw = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startMs': startMs,
        'durationSec': durationSec,
        'peakAccelG': peakAccelG,
        'peakGyroDps': peakGyroDps,
        'orientationChangeDeg': orientationChangeDeg,
        'immobilitySec': immobilitySec,
        'meanAccelPostG': meanAccelPostG,
        'meanGyroPostDps': meanGyroPostDps,
        'motionLevelPost': motionLevelPost,
        'recovered': recovered,
        'detectionDelaySec': detectionDelaySec,
        'severity': severity.toJson(),
        'response': response?.name,
      };

  factory FallEvent.fromJson(Map<String, dynamic> j) => FallEvent(
        id: j['id'] as String,
        startMs: j['startMs'] as int,
        durationSec: (j['durationSec'] as num).toDouble(),
        peakAccelG: (j['peakAccelG'] as num).toDouble(),
        peakGyroDps: (j['peakGyroDps'] as num).toDouble(),
        orientationChangeDeg: (j['orientationChangeDeg'] as num).toDouble(),
        immobilitySec: (j['immobilitySec'] as num).toDouble(),
        meanAccelPostG: (j['meanAccelPostG'] as num).toDouble(),
        meanGyroPostDps: (j['meanGyroPostDps'] as num).toDouble(),
        motionLevelPost: (j['motionLevelPost'] as num).toDouble(),
        recovered: j['recovered'] as bool,
        detectionDelaySec: (j['detectionDelaySec'] as num).toDouble(),
        severity: SeverityResult.fromJson(j['severity'] as Map<String, dynamic>),
        response: j['response'] == null
            ? null
            : UserResponse.values.byName(j['response'] as String),
      );
}
