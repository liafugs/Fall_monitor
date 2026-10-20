/// Todos os limiares são PARÂMETROS EXPERIMENTAIS (não validados clinicamente).
/// Centralizados aqui e editáveis em Ajustes. Persistidos em thresholds.json.
class Thresholds {
  static const Map<String, double> defaults = {
    // Detecção
    'impactAccelG': 2.5, // pico de aceleração resultante que inicia candidato
    'impactGyroDps': 150, // velocidade angular mínima ao redor do impacto
    'orientationChangeDeg': 35, // mudança mínima de orientação (pré x pós)
    'impactWindowSec': 0.5, // janela ao redor do impacto p/ picos
    'preWindowSec': 1.0, // janela pré-impacto p/ orientação de referência
    'settleSec': 1.5, // espera após impacto antes de avaliar orientação
    'postWindowSec': 20, // duração da análise pós-impacto (desde o impacto)
    'refractorySec': 5, // ignora novos impactos após um evento
    // Baixa movimentação
    'lowMotionAccelDevG': 0.15, // |A - 1g| abaixo disso = parado
    'lowMotionGyroDps': 20, // ω abaixo disso = parado
    // Normalização do índice
    'maxPeakAccelG': 8,
    'maxPeakGyroDps': 800,
    'maxOrientationDeg': 90,
    'maxImmobilitySec': 18,
    // Pesos do índice
    'wAccel': 0.3,
    'wGyro': 0.2,
    'wOrient': 0.2,
    'wImmo': 0.3,
    // Classes (0–lowMax baixa, até moderateMax moderada, resto alta)
    'lowMax': 30,
    'moderateMax': 60,
    // Alerta
    'responseTimeoutSec': 30,
  };

  final Map<String, double> _v;
  Thresholds([Map<String, double>? v]) : _v = {...defaults, ...?v};

  factory Thresholds.fromJson(Map<String, dynamic> j) =>
      Thresholds(j.map((k, v) => MapEntry(k, (v as num).toDouble())));
  Map<String, double> toJson() => Map.of(_v);

  double operator [](String k) => _v[k]!;
  void operator []=(String k, double val) => _v[k] = val;

  double get impactAccelG => _v['impactAccelG']!;
  double get impactGyroDps => _v['impactGyroDps']!;
  double get orientationChangeDeg => _v['orientationChangeDeg']!;
  double get impactWindowSec => _v['impactWindowSec']!;
  double get preWindowSec => _v['preWindowSec']!;
  double get settleSec => _v['settleSec']!;
  double get postWindowSec => _v['postWindowSec']!;
  double get refractorySec => _v['refractorySec']!;
  double get lowMotionAccelDevG => _v['lowMotionAccelDevG']!;
  double get lowMotionGyroDps => _v['lowMotionGyroDps']!;
  double get maxPeakAccelG => _v['maxPeakAccelG']!;
  double get maxPeakGyroDps => _v['maxPeakGyroDps']!;
  double get maxOrientationDeg => _v['maxOrientationDeg']!;
  double get maxImmobilitySec => _v['maxImmobilitySec']!;
  double get wAccel => _v['wAccel']!;
  double get wGyro => _v['wGyro']!;
  double get wOrient => _v['wOrient']!;
  double get wImmo => _v['wImmo']!;
  double get lowMax => _v['lowMax']!;
  double get moderateMax => _v['moderateMax']!;
  double get responseTimeoutSec => _v['responseTimeoutSec']!;
}
