enum SeverityLevel { baixa, moderada, alta }

extension SeverityLevelX on SeverityLevel {
  String get label => switch (this) {
        SeverityLevel.baixa => 'Baixa',
        SeverityLevel.moderada => 'Moderada',
        SeverityLevel.alta => 'Alta',
      };
}

/// Estimativa computacional da severidade do evento (não é avaliação médica).
class SeverityResult {
  final int score; // 0–100
  final SeverityLevel level;
  final double cAccel, cGyro, cOrient, cImmo; // componentes normalizados 0–1

  const SeverityResult(
      {required this.score,
      required this.level,
      required this.cAccel,
      required this.cGyro,
      required this.cOrient,
      required this.cImmo});

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level.name,
        'cAccel': cAccel,
        'cGyro': cGyro,
        'cOrient': cOrient,
        'cImmo': cImmo,
      };

  factory SeverityResult.fromJson(Map<String, dynamic> j) => SeverityResult(
        score: j['score'] as int,
        level: SeverityLevel.values.byName(j['level'] as String),
        cAccel: (j['cAccel'] as num).toDouble(),
        cGyro: (j['cGyro'] as num).toDouble(),
        cOrient: (j['cOrient'] as num).toDouble(),
        cImmo: (j['cImmo'] as num).toDouble(),
      );
}
